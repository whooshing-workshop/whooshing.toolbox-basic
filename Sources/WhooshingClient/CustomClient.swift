import Vapor
import Cryptos
import ErrorHandle
import NIOConcurrencyHelpers
import NIO

public protocol CustomClient {
    func get(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> (), afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void) -> EventLoopFuture<ClientResponse>
    func post(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> (), afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void) -> EventLoopFuture<ClientResponse>
    func patch(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> (), afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void) -> EventLoopFuture<ClientResponse>
    func put(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> (), afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void) -> EventLoopFuture<ClientResponse>
    func delete(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> (), afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void) -> EventLoopFuture<ClientResponse>
    func post<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void) -> EventLoopFuture<ClientResponse> where T: Content
    func patch<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void) -> EventLoopFuture<ClientResponse> where T: Content
    func put<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void) -> EventLoopFuture<ClientResponse> where T: Content
    static func defaultAfterSend(channel: Channel) -> EventLoopFuture<Void>

    func send(
        _ method: HTTPMethod,
        headers: HTTPHeaders,
        to url: URI,
        beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> (),
        afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>,
        progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void
    ) -> EventLoopFuture<ClientResponse>
}

public extension CustomClient {
    func get(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.GET, headers: headers, to: url, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    func post(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.POST, headers: headers, to: url, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    func patch(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.PATCH, headers: headers, to: url, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    func put(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.PUT, headers: headers, to: url, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    func delete(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.DELETE, headers: headers, to: url, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }
    
    func post<T>(_ url: URI, headers: HTTPHeaders = [:], content: T, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<ClientResponse> where T: Content {
        return self.post(url, headers: headers, beforeSend: { req, _ in try req.content.encode(content) }, afterSend: afterSend, progress: progress)
    }

    func patch<T>(_ url: URI, headers: HTTPHeaders = [:], content: T, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<ClientResponse> where T: Content {
        return self.patch(url, headers: headers, beforeSend: { req, _ in try req.content.encode(content) }, afterSend: afterSend, progress: progress)
    }

    func put<T>(_ url: URI, headers: HTTPHeaders = [:], content: T, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<ClientResponse> where T: Content {
        return self.put(url, headers: headers, beforeSend: { req, _ in try req.content.encode(content) }, afterSend: afterSend, progress: progress)
    }

    static func defaultAfterSend(channel: Channel) -> EventLoopFuture<Void> { channel.eventLoop.makeSucceededFuture(()) }
}