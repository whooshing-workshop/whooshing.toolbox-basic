import Vapor
import Cryptos
import ErrorHandle
import NIOConcurrencyHelpers
import NIO
import NIOExtras

public enum BufferStrategy: Sendable { 
    case collect
    case streaming(AsyncStreamingDataAction)
}

public struct ProgressContext<Value>: CustomStringConvertible {
    public let data: ByteBuffer
    public let done: Bool
    public let channel: Channel
    public let response: Value

    public var description: String {
        "Progress(data: \(data.readableBytes), done: \(done), response: \(response))"
    }
}

open class ReqClient: Client, @unchecked Sendable {
    public let eventLoop: EventLoop
    public let logger: Logger?
    public let byteBufferAllocator: ByteBufferAllocator
    public var ioHandler: RequestIOHandler?
    public var storage: Storage {
        get { lock.withLock { self._storage } }
        set { lock.withLock { self._storage = newValue } }
    }
    public internal(set) var channelPool: SendableDictionary<String, Channel> = .init()
    private let headerPool: SendableDictionary<ObjectIdentifier, ClientResponse> = .init()
    lazy private var _storage: Storage = .init(logger: self.logger ?? .init(label: "ReqClient"))
    private var lock: NIOLock = .init()
    
    public func delegating(to eventLoop: EventLoop) -> Client {
        Self(eventLoop: eventLoop, logger: self.logger, byteBufferAllocator: self.byteBufferAllocator)
    }

    public func logging(to logger: Logger) -> Client {
        Self(eventLoop: self.eventLoop, logger: logger, byteBufferAllocator: self.byteBufferAllocator)
    }

    public func allocating(to byteBufferAllocator: ByteBufferAllocator) -> Client {
        Self(eventLoop: self.eventLoop, logger: self.logger, byteBufferAllocator: byteBufferAllocator)
    }
    
    public required init(eventLoop: EventLoop, logger: Logger? = nil, byteBufferAllocator: ByteBufferAllocator, ioHandler: RequestIOHandler? = nil) {
        self.eventLoop = eventLoop
        self.logger = logger
        self.byteBufferAllocator = byteBufferAllocator
        self.ioHandler = ioHandler
    }
    
    public func makeChannel(url: URI) -> EventLoopFuture<(Channel, RequestHandler)> {
        guard let host = url.host else { return eventLoop.makeFailedFuture(Err.requestFormatError.d("无法获取 Host", 10080, (#file, #line))) }
        guard let port = url.port else { return eventLoop.makeFailedFuture(Err.requestFormatError.d("无法获取 Port", 10081, (#file, #line))) }
        print("\(host):\(port) -- \(channelPool["\(host):\(port)"] != nil ? ObjectIdentifier(channelPool["\(host):\(port)"]!) : nil)")
        if let channel = channelPool["\(host):\(port)"], channel.isActive {
            return channel.pipeline.handler(type: RequestHandler.self).flatMap { handler in
                return channel.eventLoop.makeSucceededFuture((channel, handler))
            }
        }

        let handler = RequestHandler(promise: nil, logger: logger, byteBufferAllocator: byteBufferAllocator, ioHandler: ioHandler)

        let bootstrap = ClientBootstrap(group: eventLoop)
            .channelInitializer { channel in
                channel.pipeline.addHandlers([
                    LengthFieldPrepender(lengthFieldLength: .eight, lengthFieldEndianness: .big),
                    ByteToMessageHandler(LengthFieldBasedFrameDecoder(lengthFieldLength: .eight, lengthFieldEndianness: .big)),
                    handler
                ])
            }
            .channelOption(.socketOption(.tcp_nodelay), value: 1)
            .channelOption(.socketOption(.so_reuseaddr), value: 1)
            .channelOption(.maxMessagesPerRead, value: 1)

        return bootstrap.connect(host: host, port: port).map { channel in
            self.channelPool["\(host):\(port)"] = channel
            return (channel, handler)
        }
    }
    
    public func send(
        _ c: ClientRequest,
        channel: Channel,
        handler: RequestHandler,
        bufferStrategy: BufferStrategy,
        progress: @escaping ProgressAction
    ) -> EventLoopFuture<ClientResponse?> {
        let promise = channel.eventLoop.makePromise(of: ClientResponse?.self)
        let id = ObjectIdentifier(channel)
        var client = c
        if case .streaming(_) = bufferStrategy {
            client.body = nil
            client.headers.add(name: .contentLength, value: "-1")
        } else if let body = client.body {
            client.headers.add(name: .contentLength, value: String(body.readableBytes))
        }
        handler.promise = promise
        handler.bufferStrategy = bufferStrategy
        handler.progress = { prog in
            if prog.response {
                if self.headerPool[id] == nil {
                    self.headerPool[id] = try Guard( { try .init(data: prog.data) }, throw: Err.requestParseFailed.d(14010, #file, #line))
                }
                let header = self.headerPool[id]!
                try progress(.init(data: prog.data, done: prog.done, channel: prog.channel, response: header))
                return
            }
            try progress(.init(data: prog.data, done: prog.done, channel: prog.channel, response: nil))
            if prog.done { self.headerPool[id] = nil }
        }
        return channel.writeAndFlush(client).flatMapError { err in
            self.logger?.error("发送请求失败，\(err)")
            promise.fail(err)
            return channel.eventLoop.makeFailedFuture(err)
        }.flatMap {
            promise.futureResult
        }
    }
    
    public func send(_ request: ClientRequest) -> EventLoopFuture<ClientResponse> { fatalError("不应执行该方法") }
    
    enum Err: String, ErrList {
        var domain: String { "woo.sys.client.err" }
        case requestFormatError = "请求格式有误"
        case requestBodyTooLarge = "请求的内容过大"
        case requestParseFailed = "服务器响应头解包时出错"
    }
}

public extension ClientRequest {
    
    internal enum Err: String, ErrList {
        var domain: String { "woo.sys.client.request.err" }
        case requestToDataFailed = "将请求转为 Data 失败"
    }
    
    func data(bufferAllocator: ByteBufferAllocator) throws -> (ByteBuffer, ByteBuffer?) {
        var buffer = bufferAllocator.buffer(capacity: 0)
        // 转换 HTTP 方法和 URL
        let requestLine = "\(method.rawValue) \(url.path) HTTP/1.1\r\n"
        buffer.writeString(requestLine)
        // 转换 headers
        headers.forEach { (name, value) in buffer.writeString("\(name): \(value)\r\n") }
        // 添加一个空行，表示头部结束
        buffer.writeString("\r\n")
        // 如果有请求体 (body)，则添加请求体的内容
        return (buffer, body)
    }
}

extension ClientResponse {
    
     enum Err: String, ErrList {
        var domain: String { "woo.sys.client.response.err" }
        case responseParseFailed = "响应解析失败"
        case unknowErr = "解析响应时出现未知错误"
    }
    
    public init(data: ByteBuffer) throws {
        var (header, body) = try Self.parseHTTPResponse(from: data)
        guard let headers = header.readString(length: header.readableBytes)?.components(separatedBy: "\r\n") else { throw Err.responseParseFailed.d("无法将请求转为 String", 10070, (#file, #line)) }
        // Headers 解析
        guard headers.count >= 1 else { throw Err.responseParseFailed.d("格式不正确，无效的 Header", 10072, (#file, #line)) }
        let requestLine = headers[0].components(separatedBy: " ")
        guard requestLine.count >= 3 else { throw Err.responseParseFailed.d("第一行 Header 格式不正确", 10073, (#file, #line)) }
        guard let statusCode = Int(requestLine[1]) else { throw Err.responseParseFailed.d("状态码无效", 10074, (#file, #line)) }
        let status = HTTPStatus(statusCode: statusCode, reasonPhrase: requestLine[2])
        var hs: [(String, String)] = []
        for (i, h) in headers.enumerated() {
            if i == 0 { continue }
            let comps = h.components(separatedBy: ": ")
            guard comps.count == 2 else { throw Err.responseParseFailed.d("Header 解析失败：格式不正确", 10075, (#file, #line)) }
            hs.append((comps[0], comps[1]))
        }
        self = Self.init(status: status, headers: .init(hs), body: body)
    }
    
    // 解析 HTTP 响应，分割请求头和请求体
    static func parseHTTPResponse(from buffer: ByteBuffer) throws -> (headers: ByteBuffer, body: ByteBuffer?) {
        // 查找请求头和请求体的分隔符 `\r\n\r\n`
        if let headerEndIndex = findHeaderEndIndex(in: buffer) {
            guard let headers = buffer.getSlice(at: buffer.readerIndex, length: headerEndIndex) else { throw Err.unknowErr.d("无法获得 Header 数据片", 10076, (#file, #line)) }
            // +4 是跳过 \r\n\r\n
            guard let body = buffer.getSlice(at: headerEndIndex + 4, length: buffer.readableBytes - (headerEndIndex + 4)) else { throw Err.unknowErr.d("找到了分隔符，却无法获得 Body 数据片", 10077, (#file, #line)) }
            return (headers: headers, body: body)
        }
        
        // 表示没有找到分隔符，即没有 Body
        return (buffer, nil)
    }
    
    // 查找响应头结束的位置（即 \r\n\r\n）
    static func findHeaderEndIndex(in buffer: ByteBuffer) -> Int? {
        let searchPattern: [UInt8] = [13, 10, 13, 10]  // \r\n\r\n
        var index = buffer.readerIndex
        
        // 持续查找直到 buffer 中没有足够的字节
        while index + 3 < buffer.readableBytes {
            // 获取当前位置的 4 字节
            if let slice = buffer.getBytes(at: index, length: 4) {
                // 比较这 4 字节是否等于 \r\n\r\n
                if slice == searchPattern { return index }
            }
            index += 1
        }
        return nil
    }
}
