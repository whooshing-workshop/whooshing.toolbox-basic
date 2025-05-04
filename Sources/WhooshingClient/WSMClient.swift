import Vapor
import Cryptos
import ErrorHandle
import NIOConcurrencyHelpers
import NIO
import NIOFileSystem

public typealias BeforeSendAction = @Sendable (_ request: inout ClientRequest, _ channel: Channel) throws -> ()
public typealias AfterSendAction =  @Sendable (_ channel: Channel) async throws -> ()
public typealias ProgressAction = @Sendable (_ progress: ProgressContext<ClientResponse?>) throws -> Void
public typealias StreamingDataAction = @Sendable (_ request: ClientRequest, _ channel: Channel, _ maxChunk: Int, _ currentIndex: Int) async throws -> ByteBuffer
public typealias AsyncAfterSendAction =  @Sendable (_ channel: Channel) -> EventLoopFuture<Void>
public typealias AsyncStreamingDataAction = @Sendable (_ request: ClientRequest, _ channel: Channel, _ maxChunk: Int, _ currentIndex: Int) -> EventLoopFuture<ByteBuffer>

public protocol WSMClient: Sendable {

    func get(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws -> ClientResponse
    func post(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws -> ClientResponse
    func patch(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws -> ClientResponse
    func put(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws -> ClientResponse
    func delete(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws -> ClientResponse
    func send(_ method: HTTPMethod, to url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws -> ClientResponse
    func post<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws -> ClientResponse where T: Content
    func patch<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws -> ClientResponse where T: Content
    func put<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws -> ClientResponse where T: Content

    func streamPost(_ url: URI, headers: HTTPHeaders, bodySize: Int, stream: @escaping StreamingDataAction, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws
    func streamPatch(_ url: URI, headers: HTTPHeaders, bodySize: Int, stream: @escaping StreamingDataAction, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws
    func streamPut(_ url: URI, headers: HTTPHeaders, bodySize: Int, stream: @escaping StreamingDataAction, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws
    func streamSend(_ method: HTTPMethod, to url: URI, headers: HTTPHeaders, bodySize: Int, stream: @escaping StreamingDataAction, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws
    
    func filePost(_ url: URI, file: String, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws
    func filePatch(_ url: URI, file: String, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws
    func filePut(_ url: URI, file: String, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws
    func fileSend(_ method: HTTPMethod, to url: URI, file: String, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AfterSendAction, progress: @escaping ProgressAction) async throws


    @Sendable func asyncGet(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<ClientResponse>
    @Sendable func asyncPost(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<ClientResponse>
    @Sendable func asyncPatch(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<ClientResponse>
    @Sendable func asyncPut(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<ClientResponse>
    @Sendable func asyncDelete(_ url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<ClientResponse>
    @Sendable func asyncSend(_ method: HTTPMethod, to url: URI, headers: HTTPHeaders, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<ClientResponse>
    @Sendable func asyncPost<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<ClientResponse> where T: Content
    @Sendable func asyncPatch<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<ClientResponse> where T: Content
    @Sendable func asyncPut<T>(_ url: URI, headers: HTTPHeaders, content: T, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<ClientResponse> where T: Content
    
    @Sendable func asyncStreamPost(_ url: URI, headers: HTTPHeaders, bodySize: Int, stream: @escaping AsyncStreamingDataAction, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<Void>
    @Sendable func asyncStreamPatch(_ url: URI, headers: HTTPHeaders, bodySize: Int, stream: @escaping AsyncStreamingDataAction, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<Void>
    @Sendable func asyncStreamPut(_ url: URI, headers: HTTPHeaders, bodySize: Int, stream: @escaping AsyncStreamingDataAction, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<Void>
    @Sendable func asyncStreamSend(_ method: HTTPMethod, to url: URI, headers: HTTPHeaders, bodySize: Int, stream: @escaping AsyncStreamingDataAction, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<Void>

    @Sendable func asyncFilePost(_ url: URI, file: String, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<Void>
    @Sendable func asyncFilePatch(_ url: URI, file: String, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<Void>
    @Sendable func asyncFilePut(_ url: URI, file: String, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<Void>
    @Sendable func asyncFileSend(_ method: HTTPMethod, to url: URI, file: String, beforeSend: @escaping BeforeSendAction, afterSend: @escaping AsyncAfterSendAction, progress: @escaping ProgressAction) -> EventLoopFuture<Void>


    static func defaultAfterSend(channel: Channel) -> EventLoopFuture<Void>

    @Sendable func send(
        _ method: HTTPMethod,
        headers: HTTPHeaders,
        to url: URI,
        bufferStrategy: BufferStrategy,
        beforeSend: @escaping BeforeSendAction,
        afterSend: @escaping AsyncAfterSendAction,
        progress: @escaping ProgressAction
    ) -> EventLoopFuture<ClientResponse?>

    var fileEventLoop: EventLoop { get }
}

public extension WSMClient {
    func get(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws -> ClientResponse {
        try await send(.GET, to: url, headers: headers, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    func post(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws -> ClientResponse {
        try await send(.POST, to: url, headers: headers, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    func patch(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws -> ClientResponse {
        try await send(.PATCH, to: url, headers: headers, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    func put(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws -> ClientResponse {
        try await send(.PUT, to: url, headers: headers, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    func delete(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws -> ClientResponse {
        try await send(.DELETE, to: url, headers: headers, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    func send(_ method: HTTPMethod, to url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws -> ClientResponse {
        try await asyncSend(method, to: url, headers: headers, beforeSend: beforeSend, afterSend: { b in b.eventLoop.makeFutureWithTask { return try await afterSend(b) } }, progress: progress).get()
    }

    func post<T>(_ url: URI, headers: HTTPHeaders = [:], content: T, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws -> ClientResponse where T: Content {
        try await reflect(url, headers, content, afterSend, progress, to: asyncPost)
    }

    func patch<T>(_ url: URI, headers: HTTPHeaders = [:], content: T, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws -> ClientResponse where T: Content {
        try await reflect(url, headers, content, afterSend, progress, to: asyncPatch)
    }

    func put<T>(_ url: URI, headers: HTTPHeaders = [:], content: T, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws -> ClientResponse where T: Content {
        try await reflect(url, headers, content, afterSend, progress, to: asyncPut)
    }

    private func reflect<T>(
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
    func streamPost(_ url: URI, headers: HTTPHeaders = [:], bodySize: Int, stream: @escaping StreamingDataAction, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws {
        try await streamSend(.POST, to: url, headers: headers, bodySize: bodySize, stream: stream, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    func streamPatch(_ url: URI, headers: HTTPHeaders = [:], bodySize: Int, stream: @escaping StreamingDataAction, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws {
        try await streamSend(.PATCH, to: url, headers: headers, bodySize: bodySize, stream: stream, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    func streamPut(_ url: URI, headers: HTTPHeaders = [:], bodySize: Int, stream: @escaping StreamingDataAction, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws {
        try await streamSend(.PUT, to: url, headers: headers, bodySize: bodySize, stream: stream, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    func streamSend(_ method: HTTPMethod, to url: URI, headers: HTTPHeaders = [:], bodySize: Int, stream: @escaping StreamingDataAction, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws {
        try await asyncStreamSend(method, to: url, headers: headers, bodySize: bodySize, stream: { a, b, c, d in b.eventLoop.makeFutureWithTask { return try await stream(a, b, c, d) } }, beforeSend: beforeSend, afterSend: { b in b.eventLoop.makeFutureWithTask { return try await afterSend(b) } }, progress: progress).get()
    }
}



public extension WSMClient {
    static func defaultAfterSend(channel: Channel) -> EventLoopFuture<Void> { channel.eventLoop.makeSucceededFuture(()) }
}

public extension WSMClient {
    @Sendable func asyncGet(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.asyncSend(.GET, to: url, headers: headers, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    @Sendable func asyncPost(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.asyncSend(.POST, to: url, headers: headers, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    @Sendable func asyncPatch(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.asyncSend(.PATCH, to: url, headers: headers, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    @Sendable func asyncPut(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.asyncSend(.PUT, to: url, headers: headers, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    @Sendable func asyncDelete(_ url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.asyncSend(.DELETE, to: url, headers: headers, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    @Sendable func asyncSend(_ method: HTTPMethod, to url: URI, headers: HTTPHeaders = [:], beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<ClientResponse> {
        return self.send(method, headers: headers, to: url, bufferStrategy: .collect, beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { $0! }
    }
    
    @Sendable func asyncPost<T>(_ url: URI, headers: HTTPHeaders = [:], content: T, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<ClientResponse> where T: Content {
        return self.asyncPost(url, headers: headers, beforeSend: { req, _ in try req.content.encode(content) }, afterSend: afterSend, progress: progress)
    }

    @Sendable func asyncPatch<T>(_ url: URI, headers: HTTPHeaders = [:], content: T, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<ClientResponse> where T: Content {
        return self.asyncPatch(url, headers: headers, beforeSend: { req, _ in try req.content.encode(content) }, afterSend: afterSend, progress: progress)
    }

    @Sendable func asyncPut<T>(_ url: URI, headers: HTTPHeaders = [:], content: T, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<ClientResponse> where T: Content {
        return self.asyncPut(url, headers: headers, beforeSend: { req, _ in try req.content.encode(content) }, afterSend: afterSend, progress: progress)
    }
}

public extension WSMClient {
    @Sendable func asyncStreamPost(_ url: URI, headers: HTTPHeaders = [:], bodySize: Int, stream: @escaping AsyncStreamingDataAction, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<Void> {
        self.asyncStreamSend(.POST, to: url, headers: headers, bodySize: bodySize, stream: stream, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    @Sendable func asyncStreamPatch(_ url: URI, headers: HTTPHeaders = [:], bodySize: Int, stream: @escaping AsyncStreamingDataAction, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<Void> {
        self.asyncStreamSend(.PATCH, to: url, headers: headers, bodySize: bodySize, stream: stream, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    @Sendable func asyncStreamPut(_ url: URI, headers: HTTPHeaders = [:], bodySize: Int, stream: @escaping AsyncStreamingDataAction, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<Void> {
        self.asyncStreamSend(.PUT, to: url, headers: headers, bodySize: bodySize, stream: stream, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    @Sendable func asyncStreamSend(_ method: HTTPMethod, to url: URI, headers: HTTPHeaders = [:], bodySize: Int, stream: @escaping AsyncStreamingDataAction, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<Void> {
        self.send(method, headers: headers, to: url, bufferStrategy: .streaming(totalSize: bodySize, stream: stream), beforeSend: beforeSend, afterSend: afterSend, progress: progress).map { _ in }
    }
}

public extension WSMClient {
    func filePost(_ url: URI, file: String, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws {
        try await self.fileSend(.POST, to: url, file: file, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    func filePatch(_ url: URI, file: String, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws {
        try await self.fileSend(.PATCH, to: url, file: file, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    func filePut(_ url: URI, file: String, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws {
        try await self.fileSend(.PUT, to: url, file: file, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    func fileSend(_ method: HTTPMethod, to url: URI, file: String, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AfterSendAction = { _ in }, progress: @escaping ProgressAction = { _ in }) async throws {
        try await asyncFileSend(method, to: url, file: file, beforeSend: beforeSend, afterSend: { b in b.eventLoop.makeFutureWithTask { return try await afterSend(b) } }, progress: progress).get()
    }
}

public extension WSMClient {

    @Sendable func asyncFilePost(_ url: URI, file: String, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<Void> {
        self.asyncFileSend(.POST, to: url, file: file, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    @Sendable func asyncFilePatch(_ url: URI, file: String, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<Void> {
        self.asyncFileSend(.PATCH, to: url, file: file, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    @Sendable func asyncFilePut(_ url: URI, file: String, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<Void> {
        self.asyncFileSend(.PUT, to: url, file: file, beforeSend: beforeSend, afterSend: afterSend, progress: progress)
    }

    @Sendable func asyncFileSend(_ method: HTTPMethod, to url: URI, file: String, beforeSend: @escaping BeforeSendAction = { _, _ in }, afterSend: @escaping AsyncAfterSendAction = defaultAfterSend, progress: @escaping ProgressAction = { _ in }) -> EventLoopFuture<Void> {
        return fileEventLoop.makeFutureWithTask {
            let filePath = FilePath(file)
            let fileHandle = try await FileSystem.shared.openFile(forReadingAt: filePath, options: .init())
            do {
                guard 
                    let fileName = filePath.lastComponent?.string,
                    let info = try await FileSystem.shared.info(forFileAt: filePath)
                else {
                    throw WSMClientErr.fileInfoGetFailed.d(14034, #file, #line)
                }
                let chunkIterator = FileChunksIterator(fileHandle.readChunks(in: 0..<info.size, chunkLength: .bytes(.init(ChunkTool.maxChunk))).makeAsyncIterator())
                try await streamSend(method, to: url, headers: ["Content-Disposition": fileName], bodySize: Int(info.size), stream: { request, channel, maxChunk, currentIndex in
                    guard let data = try await chunkIterator.next() else {
                        throw WSMClientErr.fileOperationUnknowErr.d("未成功读出数据", 14035, (#file, #line))
                    }
                    return data
                }, beforeSend: beforeSend, afterSend: { try await afterSend($0).get() }, progress: progress)
                try await fileHandle.close()
            } catch let err {
                try await fileHandle.close()
                throw WSMClientErr.fileOperationUnknowErr.d(14033, #file, #line).subErr(err)
            }
        }
    }
}

final class FileChunksIterator: @unchecked Sendable {
    var iterator: FileChunks.FileChunkIterator {
        get {
            lock.withLock {
                return _iterator
            }
        }
        set {
            lock.withLock {
                _iterator = newValue
            }
        }
    }

    private let lock = NIOLock()
    private var _iterator: FileChunks.FileChunkIterator

    init(_ iterator: FileChunks.FileChunkIterator) {
        self._iterator = iterator
    }

    @Sendable func next() async throws -> ByteBuffer? { try await iterator.next() }
}

enum WSMClientErr: String, ErrList {
    var domain: String { "woo.sys.wsmclient.err" }
    case fileInfoGetFailed = "文件信息获取失败"
    case fileOperationUnknowErr = "文件操作时出现未知错误"
    case fileReadFailed = "文件读取时失败"
    case fileReadUnknowErr = "文件读取时遇到未知错误"
}