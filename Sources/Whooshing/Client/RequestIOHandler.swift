import Vapor
import Cryptos
import ErrorHandle
import NIO

extension WooClient {
    protocol RequestIOHandler: Sendable {
        func send(request: ByteBuffer, context: ChannelHandlerContext) throws -> ByteBuffer
        func get(response: ByteBuffer, context: ChannelHandlerContext) throws -> ByteBuffer
        func connectionStart(context: ChannelHandlerContext) throws
        func connectionEnd(context: ChannelHandlerContext) throws
    }
    
    final class RequestHandler: ChannelDuplexHandler, Sendable {
        typealias InboundIn = ByteBuffer
        typealias OutboundIn = ByteBuffer
        typealias OutboundOut = ByteBuffer
        
        private let logger: Logger?
        private let promise: EventLoopPromise<ClientResponse>
        private let ioHandler: RequestIOHandler?
        
        init(promise: EventLoopPromise<ClientResponse>, logger: Logger?, ioHandler: RequestIOHandler? = nil) {
            self.promise = promise
            self.ioHandler = ioHandler
            self.logger = logger
        }
        
        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let buffer = unwrapInboundIn(data)
            if let ioHandler = self.ioHandler {
                do {
                    let res = try ioHandler.get(response: buffer, context: context)
                    promise.succeed(try .init(data: res))
                } catch let err {
                    errorCaught(context: context, label: "Read", error: err)
                    promise.fail(err)
                }
            } else {
                let res = try! ClientResponse(data: buffer)
                promise.succeed(res)
            }
        }
        
        func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
            let buffer = unwrapInboundIn(data)
            if let ioHandler = self.ioHandler {
                do {
                    let req = try ioHandler.send(request: buffer, context: context)
                    context.writeAndFlush(self.wrapOutboundOut(req), promise: promise)
                } catch let err {
                    errorCaught(context: context, label: "Write", error: err)
                }
            } else {
                context.writeAndFlush(data, promise: promise)
            }
        }
        
        func channelRegistered(context: ChannelHandlerContext) {
            do {
                try ioHandler?.connectionStart(context: context)
            } catch let err {
                errorCaught(context: context, label: "连线建立", error: err)
            }
        }
        
        func channelUnregistered(context: ChannelHandlerContext) {
            do {
                try ioHandler?.connectionEnd(context: context)
            } catch let err {
                errorCaught(context: context, label: "连线终止", error: err)
            }
            context.fireChannelInactive()
        }
        
        func errorCaught(context: ChannelHandlerContext, label: String, error: Error) {
            if let logger = self.logger {
                logger.debug("HTTP 流 \(label) 时加解密失败: \(String(reflecting: error))")
            }
            context.fireErrorCaught(error)
        }
    }
}

extension WooClient.RequestIOHandler {
    func connectionStart(context: ChannelHandlerContext) throws {}
    func connectionEnd(context: ChannelHandlerContext) throws {}
}
