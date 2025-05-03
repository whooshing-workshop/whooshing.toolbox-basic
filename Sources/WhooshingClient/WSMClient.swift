import Vapor
import Cryptos
import ErrorHandle
import NIOConcurrencyHelpers
import NIO

public typealias BeforeSendAction = @Sendable (_ request: inout ClientRequest, _ channel: Channel) throws -> ()
public typealias AfterSendAction =  @Sendable (_ channel: Channel) async throws -> ()
public typealias ProgressAction = @Sendable (_ progress: ProgressContext<ClientResponse?>) throws -> Void
public typealias StreamingDataAction = @Sendable (_ request: ClientRequest, _ channel: Channel, _ maxChunk: Int) async throws -> ByteBuffer?
public typealias AsyncAfterSendAction =  @Sendable (_ channel: Channel) -> EventLoopFuture<Void>
public typealias AsyncStreamingDataAction = @Sendable (_ request: ClientRequest, _ channel: Channel, _ maxChunk: Int) -> EventLoopFuture<ByteBuffer?>

public protocol WSMClient {

    func get(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws -> ClientResponse
    func post(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws -> ClientResponse
    func patch(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws -> ClientResponse
    func put(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws -> ClientResponse
    func delete(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws -> ClientResponse
    func post<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws -> ClientResponse where T: Content
    func patch<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws -> ClientResponse where T: Content
    func put<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws -> ClientResponse where T: Content

    func streamGet(_ url: URI, headers: HTTPHeaders, stream: @escaping StreamingDataAction, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws
    func streamPost(_ url: URI, headers: HTTPHeaders, stream: @escaping StreamingDataAction, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws
    func streamPatch(_ url: URI, headers: HTTPHeaders, stream: @escaping StreamingDataAction, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws
    func streamPut(_ url: URI, headers: HTTPHeaders, stream: @escaping StreamingDataAction, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws
    func streamDelete(_ url: URI, headers: HTTPHeaders, stream: @escaping StreamingDataAction, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws


    func get(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<ClientResponse>
    func post(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<ClientResponse>
    func patch(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<ClientResponse>
    func put(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<ClientResponse>
    func delete(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<ClientResponse>
    func post<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<ClientResponse> where T: Content
    func patch<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<ClientResponse> where T: Content
    func put<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<ClientResponse> where T: Content
    
    func streamGet(_ url: URI, headers: HTTPHeaders, stream: @escaping AsyncStreamingDataAction, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<Void>
    func streamPost(_ url: URI, headers: HTTPHeaders, stream: @escaping AsyncStreamingDataAction, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<Void>
    func streamPatch(_ url: URI, headers: HTTPHeaders, stream: @escaping AsyncStreamingDataAction, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<Void>
    func streamPut(_ url: URI, headers: HTTPHeaders, stream: @escaping AsyncStreamingDataAction, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<Void>
    func streamDelete(_ url: URI, headers: HTTPHeaders, stream: @escaping AsyncStreamingDataAction, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<Void>

    static func defaultAfterSend(channel: Channel) -> EventLoopFuture<Void>

    func send(
        _ method: HTTPMethod,
        headers: HTTPHeaders,
        to url: URI,
        bufferStrategy: BufferStrategy,
        beforeSend: @escaping BeforeSendAction,
        afterSend: @escaping AsyncAfterSendAction,
        progress: @escaping ProgressAction
    ) -> EventLoopFuture<ClientResponse?>

}

public extension WSMClient {
    func get(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws -> ClientResponse {
        try await reflect(url, headers, beforeSend, afterSend, progress, to: get)
    }

    func post(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws -> ClientResponse {
        try await reflect(url, headers, beforeSend, afterSend, progress, to: post)
    }

    func patch(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws -> ClientResponse {
        try await reflect(url, headers, beforeSend, afterSend, progress, to: patch)
    }

    func put(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws -> ClientResponse {
        try await reflect(url, headers, beforeSend, afterSend, progress, to: put)
    }

    func delete(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws -> ClientResponse {
        try await reflect(url, headers, beforeSend, afterSend, progress, to: delete)
    }

    func post<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws -> ClientResponse where T: Content {
        try await reflect2(url, headers, content, afterSend, progress, to: post)
    }

    func patch<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws -> ClientResponse where T: Content {
        try await reflect2(url, headers, content, afterSend, progress, to: patch)
    }

    func put<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws -> ClientResponse where T: Content {
        try await reflect2(url, headers, content, afterSend, progress, to: put)
    }

    private func reflect(
        _ url: URI, _ headers: HTTPHeaders, _ beforeSend: @escaping BeforeSendAction = { _, _ in }, _ afterSend: @escaping AfterSendAction = { _ in }, _ progress: @escaping ProgressAction = { _ in },
        to: (URI, HTTPHeaders, @escaping BeforeSendAction, @escaping AsyncAfterSendAction, @escaping ProgressAction) -> EventLoopFuture<ClientResponse>
    ) async throws -> ClientResponse {
        try await to(
            url, 
            headers,
            beforeSend,
            { b in b.eventLoop.makeFutureWithTask { return try await afterSend(b) } }, 
            progress
        ).get()
    }

    private func reflect2<T>(
        _ url: URI, _ headers: HTTPHeaders, _ content: T,_ afterSend: @escaping AfterSendAction, _ progress: @escaping ProgressAction,
        to: (URI, HTTPHeaders, T, @escaping AsyncAfterSendAction, @escaping ProgressAction) -> EventLoopFuture<ClientResponse>
    ) async throws -> ClientResponse where T: Content {
        try await to(
            url, 
            headers,
            content,
            { b in b.eventLoop.makeFutureWithTask { return try await afterSend(b) } }, 
            progress
        ).get()
    }
}

public extension WSMClient {
    func streamGet(_ url: URI, headers: HTTPHeaders, stream: @escaping StreamingDataAction, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws {
        try await reflect(url, headers, stream, beforeSend, afterSend, progress, to: streamGet)
    }

    func streamPost(_ url: URI, headers: HTTPHeaders, stream: @escaping StreamingDataAction, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws {
        try await reflect(url, headers, stream, beforeSend, afterSend, progress, to: streamPost)
    }

    func streamPatch(_ url: URI, headers: HTTPHeaders, stream: @escaping StreamingDataAction, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws {
        try await reflect(url, headers, stream, beforeSend, afterSend, progress, to: streamPatch)
    }

    func streamPut(_ url: URI, headers: HTTPHeaders, stream: @escaping StreamingDataAction, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws {
        try await reflect(url, headers, stream, beforeSend, afterSend, progress, to: streamPut)
    }

    func streamDelete(_ url: URI, headers: HTTPHeaders, stream: @escaping StreamingDataAction, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws {
        try await reflect(url, headers, stream, beforeSend, afterSend, progress, to: streamDelete)
    }

    private func reflect(
        _ url: URI, _ headers: HTTPHeaders, _ stream: @escaping StreamingDataAction, _ beforeSend: @escaping BeforeSendAction, _ afterSend: @escaping AfterSendAction, _ progress: @escaping ProgressAction,
        to: (URI, HTTPHeaders, @escaping AsyncStreamingDataAction, @escaping BeforeSendAction, @escaping AsyncAfterSendAction, @escaping ProgressAction) -> EventLoopFuture<Void>
    ) async throws {
        try await to(
            url, 
            headers, 
            { a, b, c in b.eventLoop.makeFutureWithTask { return try await stream(a, b, c) } }, 
            beforeSend, 
            { b in b.eventLoop.makeFutureWithTask { return try await afterSend(b) } }, 
            progress
        ).get()
    }
}



public extension WSMClient {
    static func defaultAfterSend(channel: Channel) -> EventLoopFuture<Void> { channel.eventLoop.makeSucceededFuture(()) }
}

public extension WSMClient {
    func get(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.GET, headers: headers, to: url, bufferStrategy: .collect, beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { $0! }
    }

    func post(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.POST, headers: headers, to: url, bufferStrategy: .collect, beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { $0! }
    }

    func patch(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.PATCH, headers: headers, to: url, bufferStrategy: .collect, beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { $0! }
    }

    func put(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.PUT, headers: headers, to: url, bufferStrategy: .collect, beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { $0! }
    }

    func delete(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(.DELETE, headers: headers, to: url, bufferStrategy: .collect, beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { $0! }
    }
    
    func post<T>(_ url: URI, headers: HTTPHeaders = [:], content: T, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<ClientResponse> where T: Content {
        return self.post(url, headers: headers, beforeSend: { req, _ in try req.content.encode(content) }, afterSend: afterSend, progress: progress)
    }

    func patch<T>(_ url: URI, headers: HTTPHeaders = [:], content: T, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<ClientResponse> where T: Content {
        return self.patch(url, headers: headers, beforeSend: { req, _ in try req.content.encode(content) }, afterSend: afterSend, progress: progress)
    }

    func put<T>(_ url: URI, headers: HTTPHeaders = [:], content: T, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<ClientResponse> where T: Content {
        return self.put(url, headers: headers, beforeSend: { req, _ in try req.content.encode(content) }, afterSend: afterSend, progress: progress)
    }
}

public extension WSMClient {
    func streamGet(_ url: URI, headers: HTTPHeaders = [:], stream: @escaping AsyncStreamingDataAction, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<Void> {
        return self.send(.GET, headers: headers, to: url, bufferStrategy: .streaming(stream), beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { _ in }
    }

    func streamPost(_ url: URI, headers: HTTPHeaders = [:], stream: @escaping AsyncStreamingDataAction, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<Void> {
        return self.send(.POST, headers: headers, to: url, bufferStrategy: .streaming(stream), beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { _ in }
    }

    func streamPatch(_ url: URI, headers: HTTPHeaders = [:], stream: @escaping AsyncStreamingDataAction, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<Void> {
        return self.send(.PATCH, headers: headers, to: url, bufferStrategy: .streaming(stream), beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { _ in }
    }

    func streamPut(_ url: URI, headers: HTTPHeaders = [:], stream: @escaping AsyncStreamingDataAction, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<Void> {
        return self.send(.PUT, headers: headers, to: url, bufferStrategy: .streaming(stream), beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { _ in }
    }

    func streamDelete(_ url: URI, headers: HTTPHeaders = [:], stream: @escaping AsyncStreamingDataAction, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<Void> {
        return self.send(.DELETE, headers: headers, to: url, bufferStrategy: .streaming(stream), beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { _ in }
    }
}