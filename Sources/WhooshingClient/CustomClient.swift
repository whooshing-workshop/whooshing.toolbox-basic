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
    
    func streamGet(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> (), afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void) -> EventLoopFuture<Void>
    func streamPost(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> (), afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void) -> EventLoopFuture<Void>
    func streamPatch(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> (), afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void) -> EventLoopFuture<Void>
    func streamPut(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> (), afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void) -> EventLoopFuture<Void>
    func streamDelete(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> (), afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void) -> EventLoopFuture<Void>
    func streamPost<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void) -> EventLoopFuture<Void> where T: Content
    func streamPatch<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void) -> EventLoopFuture<Void> where T: Content
    func streamPut<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void) -> EventLoopFuture<Void> where T: Content


    static func defaultAfterSend(channel: Channel) -> EventLoopFuture<Void>

    func send(
        _ method: HTTPMethod,
        headers: HTTPHeaders,
        to url: URI,
        bufferStrategy: BufferStrategy,
        beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> (),
        afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void>,
        progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void
    ) -> EventLoopFuture<ClientResponse?>
}

public extension CustomClient {
    static func defaultAfterSend(channel: Channel) -> EventLoopFuture<Void> { channel.eventLoop.makeSucceededFuture(()) }
}

public extension CustomClient {
    func get(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.GET, headers: headers, to: url, bufferStrategy: .collect, beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { $0! }
    }

    func post(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.POST, headers: headers, to: url, bufferStrategy: .collect, beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { $0! }
    }

    func patch(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.PATCH, headers: headers, to: url, bufferStrategy: .collect, beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { $0! }
    }

    func put(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.PUT, headers: headers, to: url, bufferStrategy: .collect, beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { $0! }
    }

    func delete(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.DELETE, headers: headers, to: url, bufferStrategy: .collect, beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { $0! }
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
}

public extension CustomClient {
    func streamGet(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<Void> {
        return self.send(.GET, headers: headers, to: url, bufferStrategy: .streaming, beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { _ in }
    }

    func streamPost(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<Void> {
        return self.send(.POST, headers: headers, to: url, bufferStrategy: .streaming, beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { _ in }
    }

    func streamPatch(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<Void> {
        return self.send(.PATCH, headers: headers, to: url, bufferStrategy: .streaming, beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { _ in }
    }

    func streamPut(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<Void> {
        return self.send(.PUT, headers: headers, to: url, bufferStrategy: .streaming, beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { _ in }
    }

    func streamDelete(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<Void> {
        return self.send(.DELETE, headers: headers, to: url, bufferStrategy: .streaming, beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { _ in }
    }
    
    func streamPost<T>(_ url: URI, headers: HTTPHeaders = [:], content: T, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<Void> where T: Content {
        return self.streamPost(url, headers: headers, beforeSend: { req, _ in try req.content.encode(content) }, afterSend: afterSend, progress: progress)
    }

    func streamPatch<T>(_ url: URI, headers: HTTPHeaders = [:], content: T, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<Void> where T: Content {
        return self.streamPatch(url, headers: headers, beforeSend: { req, _ in try req.content.encode(content) }, afterSend: afterSend, progress: progress)
    }

    func streamPut<T>(_ url: URI, headers: HTTPHeaders = [:], content: T, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }) -> EventLoopFuture<Void> where T: Content {
        return self.streamPut(url, headers: headers, beforeSend: { req, _ in try req.content.encode(content) }, afterSend: afterSend, progress: progress)
    }
}