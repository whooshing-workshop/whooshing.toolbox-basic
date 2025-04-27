import Vapor
import Cryptos
import ErrorHandle
import NIOConcurrencyHelpers
import NIO

public final class ApiClient {
    private let client: ReqClient<API>
    public init(app: Application, credential: String, token: String) {
        self.client = .new(eventLoop: app.eventLoopGroup.next(), logger: app.logger, byteBufferAllocator: .init())
        client.storage[API.RequestIOData.self] = .init(credential: credential, token: token)
    }
}

extension ApiClient: CustomClient {
    public func send(
        _ method: HTTPMethod,
        headers: HTTPHeaders,
        to url: URI,
        beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> (),
        afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>
    ) -> EventLoopFuture<ClientResponse> {
        client.send(method, headers: headers, to: url, beforeSend: beforeSend, afterSend: afterSend)
    }
}