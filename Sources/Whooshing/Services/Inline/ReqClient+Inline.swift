import Vapor
import ErrorHandle
import DataConvertable
import NIOCore
import Logging
import Cryptos
import WhooshingClient

/// 该文件实现了发送加密请求的功能。由于目标模块的加密算法并非传统的 HTTPS，
/// 而是自定的加密算法，因此向其请求时需要使用特定的加密逻辑。

extension Inline: WhooshingServiceType {}

extension ReqClient where ServiceType == Inline {
    
    enum InlineReqErr: String, ErrList {
        var domain: String { "woo.sys.inline.reqclient.err" }
        case targetBadResponse = "目标返回了不正常的响应"
        case targetIncorrectResponseBody = "目标的响应体不正确"
        case unknowSendError = "发送时遇到未知错误"
    }
    
    @Sendable 
    func send(
        _ method: HTTPMethod,
        headers: HTTPHeaders = [:],
        to url: URI,
        bufferStrategy: BufferStrategy,
        beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> () = { _, _ in },
        afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend,
        progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }
    ) -> EventLoopFuture<ClientResponse?> {
        let req = ClientRequest(method: method, url: url, headers: headers, body: nil, byteBufferAllocator: self.byteBufferAllocator)
        return self.makeChannel(url: req.url).flatMap { (channel, handler) in
            do {
                var request = req
                try beforeSend(&request, channel)
                request.channel = channel
                return self._send(request: request, bufferStrategy: bufferStrategy, channel: channel, handler: handler, progress: progress).flatMapError { err in
                    return channel.eventLoop.makeFailedFuture(err)
                }.flatMap { res in
                    afterSend(channel).map { res }
                }
            } catch {
                return channel.eventLoop.makeFailedFuture(error)
            }
        }
    }
    
    private func _send(request: ClientRequest, bufferStrategy: BufferStrategy, channel: Channel, handler: RequestHandler, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void) -> EventLoopFuture<ClientResponse?> {
        let id = ObjectIdentifier(channel)
        let procedure: Int
        if self.requestIoData.connectionKeys[id] == nil { procedure = 0 }
        else if self.requestIoData.connectionValidate[id] != true { procedure = 1 }
        else { procedure = 2 }
        var r = channel.eventLoop.makeSucceededVoidFuture()
        switch (procedure) {
            case 0:
                r = r.flatMap {
                    print("// 首次请求，需要交换密钥")
                    return self.keyExchange(req: request, channel: channel, handler: handler)
                }
                fallthrough
            case 1:
                r = r.flatMap {
                    print("// 密钥交换已完成，配合对方进行验证")
                    return self.serviceValidate(req: request, channel: channel, handler: handler)
                }
                fallthrough
            default:
                return r.flatMap {
                    print("// 已成功经过验证，开始发送请求")
                    return self.send(request, channel: channel, handler: handler, bufferStrategy: bufferStrategy, progress: progress)
                }.flatMapError { err in
                    return channel.eventLoop.makeFailedFuture(InlineReqErr.unknowSendError.d(10095, (#file, #line)).subErr(err))
                }
        }
    }

    struct JSONData: Content {
        let data: Data
    }
    
    private func keyExchange(req: ClientRequest, channel: Channel, handler: RequestHandler) -> EventLoopFuture<Void> {
        print("// 创建公私钥对")
        let keyPair = Crypto.Asym.makeCryptoKeyPair()
        print("// 将公钥发送于目标")
        guard let body = try? JSONEncoder().encode(JSONData(data: keyPair.public.data())) else { return channel.eventLoop.makeFailedFuture(InlineReqErr.unknowSendError.d("JSON 编码失败", 13003, (#file, #line))) }
        return self.send(.init(method: .POST, url: req.url, headers: ["content-type": "application/json"], body: .init(data: body)), channel: channel, handler: handler, bufferStrategy: .collect, progress: { _ in }).flatMapThrowing { response in 
            // 此处 response 必定有值，因为 BufferStrategy 是 .collect
            let response = response!
            print("// 检查对方的响应，对方应当发来自己的公钥")
            guard response.status == .ok else { throw InlineReqErr.targetBadResponse.d("\(response.status.description)(\(response.status.code))", 10090, (#file, #line)) }
            guard let data = response.body?.data() else { throw InlineReqErr.targetIncorrectResponseBody.d("预期为公钥，但得到不正确回复", 10091, (#file, #line)) }
            print("// 解包对方发来的公钥")
            let targetPub = try Crypto.Asym.CPublicKey(data: data)
            print("// 计算共享密钥")
            let sharedKey = try Crypto.Asym.keyEncapsulate(key: keyPair.private, partyPublic: targetPub, salt: Crypto.hash("inline.shared.key"), info: "")
            print("// 设置标志位")
            self.requestIoData.connectionKeys[ObjectIdentifier(channel)] = sharedKey
        }.flatMapError { err in 
            return channel.eventLoop.makeFailedFuture(err)
        }
    }
    
    private func serviceValidate(req: ClientRequest, channel: Channel, handler: RequestHandler) -> EventLoopFuture<Void> {
        print("// 将自己的服务 ID 发送于目标")
        guard let body = try? JSONEncoder().encode(JSONData(data: self.requestIoData.serviceID.data())) else { return channel.eventLoop.makeFailedFuture(InlineReqErr.unknowSendError.d("JSON 编码失败", 13004, (#file, #line))) }
        return self.send(.init(method: .POST, url: req.url, headers: ["content-type": "application/json"], body: .init(data: body)), channel: channel, handler: handler, bufferStrategy: .collect, progress: { _ in }).flatMapThrowing { response in
            // 此处 response 必定有值，因为 BufferStrategy 是 .collect
            let response = response!
            print("// 检查对方的响应")
            guard response.status == .ok else { throw InlineReqErr.targetBadResponse.d("\(response.status.description)(\(response.status.code))", 10092, (#file, #line)) }
            print("// 设置标志位")
            self.requestIoData.connectionValidate[ObjectIdentifier(channel)] = true
        }.flatMapError { err in
            return channel.eventLoop.makeFailedFuture(err)
        }
    }
}


public extension ReqClient where ServiceType == Inline {
    static func defaultAfterSend(channel: Channel) -> EventLoopFuture<Void> { channel.eventLoop.makeSucceededFuture(()) }
}

public extension ReqClient where ServiceType == Inline {
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

public extension ReqClient where ServiceType == Inline {
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