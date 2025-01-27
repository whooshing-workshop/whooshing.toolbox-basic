import Vapor
import Cryptos
import ErrorHandle
import NIO

struct WooClient: Client {
    
    let eventLoop: EventLoop
    var logger: Logger?
    var byteBufferAllocator: ByteBufferAllocator
    var ioHandler: RequestIOHandler?
    
    func delegating(to eventLoop: any EventLoop) -> any Client {
        WooClient(eventLoop: eventLoop, logger: self.logger, byteBufferAllocator: self.byteBufferAllocator)
    }
    
    func send(
        _ client: ClientRequest
    ) -> EventLoopFuture<ClientResponse> {
        let promise = eventLoop.makePromise(of: ClientResponse.self)
        let urlString = client.url.string
        guard let url = URL(string: urlString) else {
            self.logger?.debug("\(urlString) is an invalid URL")
            return self.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "\(urlString) is an invalid URL"))
        }
        do {
            guard let host = client.url.host else { throw Err.requestFormatError.d("无法获取 Host", 10080, (#file, #line)) }
            guard let port = client.url.port else { throw Err.requestFormatError.d("无法获取 Port", 10081, (#file, #line)) }
            
            let bootstrap = ClientBootstrap(group: eventLoop)
                .channelInitializer { channel in
                    channel.pipeline.addHandler(RequestHandler(promise: promise, logger: logger, ioHandler: ioHandler))
                }
                .channelOption(.socketOption(.tcp_nodelay), value: 1)
                .channelOption(.socketOption(.so_reuseaddr), value: 1)
                .channelOption(.maxMessagesPerRead, value: 1)
            
            let channel = try bootstrap.connect(host: host, port: port).wait()
            let buffer = try client.data(bufferAllocator: byteBufferAllocator)
            try channel.writeAndFlush(buffer).wait()
        } catch {
            promise.fail(error)
        }
        return promise.futureResult
    }
    
    enum Err: String, ErrList {
        var domain: String { "woo.sys.http.client.err" }
        case requestFormatError = "请求格式有误"
    }
}

extension ClientRequest {
    
    enum Err: String, ErrList {
        var domain: String { "woo.sys.client.request.err" }
        case requestToDataFailed = "将请求转为 Data 失败"
    }
    
    func data(bufferAllocator: ByteBufferAllocator) throws -> ByteBuffer {
        var buffer = bufferAllocator.buffer(capacity: 0)
        
        // 转换 HTTP 方法和 URL
        let requestLine = "\(method.rawValue) \(url.path) HTTP/1.1\r\n"
        buffer.writeString(requestLine)
        
        // 转换 headers
        headers.forEach { (name, value) in buffer.writeString("\(name): \(value)\r\n") }
        
        // 添加一个空行，表示头部结束
        buffer.writeString("\r\n")

        // 如果有请求体 (body)，则添加请求体的内容
        if var body = body {
            buffer.writeBuffer(&body)
        }
        return buffer
    }
}

extension ClientResponse {
    
    enum Err: String, ErrList {
        var domain: String { "woo.sys.client.response.err" }
        case responseParseFailed = "响应解析失败"
        case unknowErr = "解析响应时出现未知错误"
    }
    
    init(data: ByteBuffer) throws {
        var (header, body) = try Self.parseHTTPResponse(from: data)
        guard let headers = header.readString(length: header.readableBytes)?.components(separatedBy: "\r\n") else { throw Err.responseParseFailed.d("无法将请求转为 String", 10070, (#file, #line)) }
        
        // Headers 解析
        guard headers.count >= 1 else { throw Err.responseParseFailed.d("格式不正确，无效的 Header", 10072, (#file, #line)) }
        let requestLine = headers[0].components(separatedBy: " ")
        guard requestLine.count == 3 else { throw Err.responseParseFailed.d("第一行 Header 格式不正确", 10073, (#file, #line)) }
        guard let statusCode = Int(requestLine[1]) else { throw Err.responseParseFailed.d("状态码无效", 10074, (#file, #line)) }
        let status = HTTPStatus(statusCode: statusCode, reasonPhrase: requestLine[2])
        var hs: [(String, String)] = []
        for (i, h) in headers.enumerated() {
            if i == 0 { continue }
            let comps = h.components(separatedBy: " ")
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
