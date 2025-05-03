import Vapor
import Cryptos
import ErrorHandle
import NIOCore
import NIOConcurrencyHelpers

public protocol RequestIOHandler: Sendable {
    func send(request: ClientRequest, dataChunk: ByteBuffer, context: ChannelHandlerContext, allocator: ByteBufferAllocator, streaming: Bool) -> EventLoopFuture<ByteBuffer>
    func get(response: ByteBuffer, bufferStrategy: BufferStrategy, context: ChannelHandlerContext, streaming: Bool) -> EventLoopFuture<(ClientResponse?, ByteBuffer)>
    func connectionStart(context: ChannelHandlerContext) -> EventLoopFuture<Void>
    func connectionEnd(context: ChannelHandlerContext) -> EventLoopFuture<Void>
}

public extension RequestIOHandler {
    func connectionStart(context: ChannelHandlerContext) -> EventLoopFuture<Void> { context.eventLoop.makeSucceededVoidFuture() }
    func connectionEnd(context: ChannelHandlerContext) -> EventLoopFuture<Void> { context.eventLoop.makeSucceededVoidFuture() }
}

public final class RequestHandler: ChannelDuplexHandler, @unchecked Sendable {
    public typealias InboundIn = ByteBuffer
    public typealias InboundOut = ClientResponse
    public typealias OutboundIn = ClientRequest
    public typealias OutboundOut = ByteBuffer
    
    var promise: EventLoopPromise<ClientResponse?>!
    var progress: (ProgressContext<Bool>) throws -> Void = { _ in }
    var bufferStrategy: BufferStrategy = .collect

    private let logger: Logger?
    private let byteBufferAllocator: ByteBufferAllocator
    private let ioHandler: RequestIOHandler?
    private let progressPool: SendableDictionary<ObjectIdentifier, TempProgress> = .init()
    
    final class TempProgress: @unchecked Sendable {
        var index: Int {
            get { lock.withLock { _index } }
            set { lock.withLock { _index = newValue } }
        }
        var curBytes: Int {
            get { lock.withLock { _curBytes } }
            set { lock.withLock { _curBytes = newValue } }
        }
        var totalBytes: Int? {
            get { lock.withLock { _totalBytes } }
            set { lock.withLock { _totalBytes = newValue } }
        }
        var startDate: Date {
            get { lock.withLock { _startDate } }
            set { lock.withLock { _startDate = newValue } }
        }

        private var _index: Int = 0
        private var _curBytes: Int = 0
        private var _totalBytes: Int? = nil
        private var _startDate = Date.now
        let lock = NIOLock()
    }

    init(promise: EventLoopPromise<ClientResponse?>?, logger: Logger?, byteBufferAllocator: ByteBufferAllocator, ioHandler: RequestIOHandler? = nil) {
        self.promise = promise
        self.ioHandler = ioHandler
        self.byteBufferAllocator = byteBufferAllocator
        self.logger = logger
    }
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)

        guard let ioHandler = self.ioHandler else {  let res = try! ClientResponse(data: buffer); promise.succeed(res); return }
        
        let streaming: Bool
        if let bufferSuffix = buffer.readSlice(length: ChunkTool.eof.readableBytes) { streaming = bufferSuffix != ChunkTool.eof } 
        else { streaming = true }
        print("Streaming2: \(streaming)")
        if streaming { buffer.moveReaderIndex(to: 0) }

        let id = ObjectIdentifier(context.channel)

        ioHandler.get(response: buffer, bufferStrategy: bufferStrategy, context: context, streaming: streaming).whenComplete { result in
            switch result {
            case .success(let response):
                if self.progressPool[id] == nil { 
                    self.progressPool[id] = .init()
                    if let res = try? ClientResponse(data: response.1) {
                        if let sizeStr = res.headers.first(name: .contentLength), let size = Int(sizeStr) {
                            self.progressPool[id]!.totalBytes = size
                        }
                    }
                }
                let tempProgress = self.progressPool[id]!
                do {
                    try self.progress(.init(index: tempProgress.index, data: response.1, done: !streaming, curBytes: tempProgress.curBytes, totalBytes: tempProgress.totalBytes, startDate: tempProgress.startDate, channel: context.channel, response: true))
                    tempProgress.curBytes += response.1.readableBytes
                } catch let err {
                    self.errorCaught(context: context, label: "Read", error: err)
                    self.promise.fail(err)
                }
                if !streaming {
                    self.progressPool[id] = nil
                    if case .collect = self.bufferStrategy {
                        guard var res = response.0 else { fatalError("这里 response 不应为空") }
                        res.channel = context.channel
                        self.promise.succeed(res)
                    } else {
                        self.promise.succeed(nil)
                    }
                }
            case .failure(let err):
                self.errorCaught(context: context, label: "Read", error: err)
                self.promise.fail(err)
            }
        }
    }
    
    public func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        guard let ioHandler = self.ioHandler else { context.writeAndFlush(data, promise: promise); return }
        let request = unwrapOutboundIn(data)
        let buffers: (ByteBuffer, ByteBuffer?)
        do { 
            buffers = try request.data(bufferAllocator: .init()) 
        } catch let err { 
            promise?.fail(err)
            return 
        }

        let (headerBuffer, bodyBuffer) = buffers
        var r = context.eventLoop.makeSucceededVoidFuture()

        let startDate = Date.now

        // 处理请求体，分片发出
        if case let .streaming(totalSize, action) = bufferStrategy {
            // 将请求头单独先发出
            r = r.flatMap {
                send(chunk: headerBuffer, streaming: totalSize > 0, index: 0, curBytes: 0, totalSize: totalSize)
            }

            // stream 发送，需要从调用者不断读取块数据
            r = r.flatMap { sendData(streamIndex: 0, currentSize: 0) }

            @Sendable func sendData(streamIndex: Int, currentSize: Int) -> EventLoopFuture<Void> {
                action(request, context.channel, ChunkTool.maxChunk, streamIndex).flatMap { data in
                    guard ChunkTool.isProperSize(bytes: data.readableBytes) else {
                        return context.eventLoop.makeFailedFuture(Err.chunkSizeExceed.d("不应当超过 \(ChunkTool.maxChunkStr), 但得到大小 \(ChunkTool.formatByteSize(data.readableBytes))", 13030, (#file, #line)))
                    }
                    let nextSize = currentSize + data.readableBytes
                    let isLast = nextSize >= totalSize
                    print("CurSize: \(nextSize), total: \(totalSize)")
                    if isLast {
                        let lastSize = currentSize + data.readableBytes 
                        guard lastSize == totalSize else {
                            return context.eventLoop.makeFailedFuture(Err.chunkSizeExceed.d("预期数据流的总大小应为 \(ChunkTool.formatByteSize(totalSize)), 但得到大小 \(ChunkTool.formatByteSize(lastSize))", 13031, (#file, #line)))
                        }
                        return send(chunk: data, streaming: false, index: streamIndex + 1, curBytes: currentSize, totalSize: totalSize)
                    }
                    return send(chunk: data, streaming: true, index: streamIndex + 1, curBytes: currentSize, totalSize: totalSize).flatMap { sendData(streamIndex: streamIndex + 1, currentSize: nextSize) }
                }
            }
        } else {
            // 将请求头单独先发出
            r = r.flatMap {
                send(chunk: headerBuffer, streaming: bodyBuffer != nil, index: 0, curBytes: 0, totalSize: bodyBuffer == nil ? 0 : bodyBuffer!.readableBytes )
            }

            if var body = bodyBuffer {
                let tSize = body.readableBytes
                // 直接发送 Request 的数据，但仍然分块发送
                var i = 1
                while body.readableBytes > 0 {
                    let index = i
                    guard let chunk = body.readSlice(length: min(ChunkTool.maxChunk, body.readableBytes)) else { break }
                    let eof = body.readableBytes == 0
                    r = r.flatMap {
                        return send(chunk: chunk, streaming: !eof, index: index, curBytes: (index - 1) * ChunkTool.maxChunk, totalSize: tSize)
                    }
                    i += 1
                }
            }
        }
        
        r.whenFailure { err in
            self.errorCaught(context: context, label: "Write", error: err)
            promise?.fail(err)
        }

        if let p = promise { r.cascade(to: p) }

        @Sendable
        func send(chunk: ByteBuffer, streaming: Bool, index: Int, curBytes: Int, totalSize: Int) -> EventLoopFuture<Void> {
            ioHandler.send(request: request, dataChunk: chunk, context: context, allocator: byteBufferAllocator, streaming: streaming).flatMap { req in
                do {
                    try self.progress(.init(index: index, data: chunk, done: !streaming, curBytes: curBytes, totalBytes: totalSize, startDate: startDate, channel: context.channel, response: false))
                } catch let err {
                    return context.eventLoop.makeFailedFuture(err)
                }
                if !streaming {
                    var r = req
                    var eof = ChunkTool.eof
                    return context.writeAndFlush(self.wrapOutboundOut(ChunkTool.concatenateBuffers(&eof, &r))) 
                }
                return context.writeAndFlush(self.wrapOutboundOut(req)) 
            }
        }
    }
    
    public func channelRegistered(context: ChannelHandlerContext) {
        ioHandler?.connectionStart(context: context).flatMapErrorThrowing { err in
            self.errorCaught(context: context, label: "连线建立", error: err)
        }.whenComplete { _ in }
    }
    
    public func channelUnregistered(context: ChannelHandlerContext) {
        self.progressPool[ObjectIdentifier(context.channel)] = nil
        ioHandler?.connectionEnd(context: context).flatMapThrowing {
            context.fireChannelInactive()
        }.flatMapErrorThrowing { err in
            self.errorCaught(context: context, label: "连线终止", error: err)
        }.whenComplete { _ in }
    }
    
    func errorCaught(context: ChannelHandlerContext, label: String, error: Error) {
        if let logger = self.logger {
            logger.debug("HTTP 流 \(label) 时加解密失败: \(String(reflecting: error))")
        }
        context.fireErrorCaught(error)
    }

    enum Err: String, ErrList {
        var domain: String { "woo.sys.client.err" }
        case chunkSizeExceed = "流式传输块大小不正确"
    }
}
