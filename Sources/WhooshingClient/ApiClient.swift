import Vapor
import Cryptos
import ErrorHandle
import NIOConcurrencyHelpers
import NIO

public final class ApiClient {
    private let client: ReqClient<API>
    public init(credential: String, token: String, app: Application) {
        self.client = .new(eventLoop: app.eventLoopGroup.next(), logger: app.logger, byteBufferAllocator: .init())
        client.storage[API.RequestIOData.self] = .init(credential: credential, token: token)
    }
    public init(credential: String, token: String, eventLoop: EventLoop, logger: Logger? = nil) {
        self.client = .new(eventLoop: eventLoop, logger: logger, byteBufferAllocator: .init())
        client.storage[API.RequestIOData.self] = .init(credential: credential, token: token)
    }
}

extension ApiClient: CustomClient {
    public func send(
        _ method: HTTPMethod,
        headers: HTTPHeaders,
        to url: URI,
        bufferStrategy: BufferStrategy,
        beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> (),
        afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>,
        progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }
    ) -> EventLoopFuture<ClientResponse?> {
        client.send(method, headers: headers, to: url, bufferStrategy: bufferStrategy, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }
}