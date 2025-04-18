import Vapor
import Cryptos
import ErrorHandle
import NIOCore

public protocol RequestIOHandler: Sendable {
    func send(request: ClientRequest, context: ChannelHandlerContext, allocator: ByteBufferAllocator) -> EventLoopFuture<ByteBuffer>
    func get(response: ByteBuffer, context: ChannelHandlerContext) -> EventLoopFuture<ClientResponse>
    func connectionStart(context: ChannelHandlerContext) -> EventLoopFuture<Void>
    func connectionEnd(context: ChannelHandlerContext) -> EventLoopFuture<Void>
}

public extension RequestIOHandler {
    func connectionStart(context: ChannelHandlerContext) -> EventLoopFuture<Void> { context.eventLoop.makeSucceededVoidFuture() }
    func connectionEnd(context: ChannelHandlerContext) -> EventLoopFuture<Void> { context.eventLoop.makeSucceededVoidFuture() }
}

final class RequestHandler: ChannelDuplexHandler, Sendable {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = ClientResponse
    typealias OutboundIn = ClientRequest
    typealias OutboundOut = ByteBuffer
    
    let promise: EventLoopPromise<ClientResponse>
    
    private let logger: Logger?
    private let byteBufferAllocator: ByteBufferAllocator
    private let ioHandler: RequestIOHandler?
    
    init(promise: EventLoopPromise<ClientResponse>, logger: Logger?, byteBufferAllocator: ByteBufferAllocator, ioHandler: RequestIOHandler? = nil) {
        self.promise = promise
        self.ioHandler = ioHandler
        self.byteBufferAllocator = byteBufferAllocator
        self.logger = logger
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = unwrapInboundIn(data)
        if let ioHandler = self.ioHandler {
            ioHandler.get(response: buffer, context: context).flatMapThrowing { response in
                var res = response
                res.channel = context.channel
                self.promise.succeed(res)
            }.flatMapErrorThrowing { err in
                self.errorCaught(context: context, label: "Read", error: err)
                self.promise.fail(err)
            }.whenComplete { _ in }
        } else {
            let res = try! ClientResponse(data: buffer)
            promise.succeed(res)
        }
    }
    
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let buffer = unwrapOutboundIn(data)
        if let ioHandler = self.ioHandler {
            ioHandler.send(request: buffer, context: context, allocator: byteBufferAllocator).flatMapThrowing { req in
                context.writeAndFlush(self.wrapOutboundOut(req), promise: promise)
            }.flatMapErrorThrowing { err in
                self.errorCaught(context: context, label: "Write", error: err)
            }.whenComplete { _ in }
        } else {
            context.writeAndFlush(data, promise: promise)
        }
    }
    
    func channelRegistered(context: ChannelHandlerContext) {
        ioHandler?.connectionStart(context: context).flatMapErrorThrowing { err in
            self.errorCaught(context: context, label: "连线建立", error: err)
        }.whenComplete { _ in }
    }
    
    func channelUnregistered(context: ChannelHandlerContext) {
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
}
