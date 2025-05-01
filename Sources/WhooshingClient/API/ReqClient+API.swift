import Vapor
import ErrorHandle
import DataConvertable
import NIOCore
import Logging
import Cryptos

extension API: WhooshingServiceType {}

public extension ReqClient where ServiceType == API {
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

extension ReqClient where ServiceType == API {
    
    enum APIReqErr: String, ErrList {
        var domain: String { "woo.sys.api.reqclient.err" }
        case unknowSendError = "请求时发生未知的错误"
        case requestParaMissing = "请求参数缺失"
        case badResponse = "响应状态码表示请求未成功"
        case authenticationBadProtocol = "认证时协议协商错误"
        case parseParaFailed = "解析请求参数时失败"
    }

    public static func new(eventLoop: EventLoop, logger: Logger? = nil, byteBufferAllocator: ByteBufferAllocator) -> Self {
        let res = Self(eventLoop: eventLoop, logger: logger, byteBufferAllocator: byteBufferAllocator)
        res.ioHandler = API.RequestIOCrypto(client: res)
        return res
    }
    
    func send(
        _ method: HTTPMethod,
        headers: HTTPHeaders = [:],
        to url: URI,
        beforeSend: @escaping @Sendable (inout ClientRequest, Channel) throws -> () = { _, _ in },
        afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend,
        progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void = { _ in }
    ) -> EventLoopFuture<ClientResponse> {
        let req = ClientRequest(method: method, url: url, headers: headers, body: nil, byteBufferAllocator: self.byteBufferAllocator)
        return self.makeChannel(url: req.url).flatMap { (channel, handler) in
            do {
                var request = req
                try beforeSend(&request, channel)
                request.channel = channel
                return self._send(request: request, channel: channel, handler: handler, progress: progress).flatMapError { err in
                    return channel.eventLoop.makeFailedFuture(err)
                }.flatMap { res in
                    afterSend(channel).map { res }
                }
            } catch {
                return channel.eventLoop.makeFailedFuture(error)
            }
        }
    }

    struct JSONData: Content {
        let data: Data
    }
    
    private func _send(request: ClientRequest, channel: Channel, handler: RequestHandler, progress: @escaping @Sendable (ProgressContext<ClientResponse?>) throws -> Void) -> EventLoopFuture<ClientResponse> {
        let id = ObjectIdentifier(channel)
        var r = eventLoop.makeSucceededVoidFuture()
        guard let ioData = self.apiRequestIoData else { return eventLoop.makeFailedFuture(APIReqErr.requestParaMissing.d("apiRequestIoData", 12013, (#file, #line))) }
        if ioData.connectionKeys[id] == nil {
            print("// 需要进行认证")
            r = r.flatMap { 
                self.authExchange(request: request, handler: handler, channel: channel)
            }
        }
        return r.flatMap{
            print("// 发送具体的请求")
            return self.send(request, channel: channel, handler: handler, progress: progress)
        }.flatMapError { err in 
            channel.eventLoop.makeFailedFuture(APIReqErr.unknowSendError.d(12012, (#file, #line)).subErr(err))
        }
    }

    struct AuthExchangeJSON: Content {
        let credential: Data
        let tokenEncrypted: Data
    }

    /// 发送用户凭据以及用户口令，其中用户凭据明文发送，口令则进行加密并哈希
    func authExchange(request: ClientRequest, handler: RequestHandler, channel: Channel) -> EventLoopFuture<Void> {
        do {
            let ioData = self.apiRequestIoData!
            let id = ObjectIdentifier(channel)
            guard let credential = Data(base64Encoded: ioData.credential) else { throw APIReqErr.parseParaFailed.d("用户凭据", 12007, (#file, #line)) }
            print("// 使用用户口令加密用户口令本身")
            guard let token = Data(base64Encoded: ioData.token) else { throw APIReqErr.parseParaFailed.d("用户口令", 12008, (#file, #line)) }
            let tokenKey = Crypto.Symm.Key(data: token)
            let tokenEncrypted = try Crypto.Symm.encrypt(token, key: tokenKey)
            print("// 将凭据和加密后的用户口令进行 json 编码")
            guard let body = try? JSONEncoder().encode(AuthExchangeJSON(credential: credential, tokenEncrypted: tokenEncrypted)) else { return eventLoop.makeFailedFuture(APIReqErr.unknowSendError.d("JSON 编码失败", 14001, (#file, #line))) }
            print("// 发送用户凭据以及用户口令")
            return self.send(.init(method: .POST, url: request.url, headers: ["content-type": "application/json"], body: .init(data: body)), channel: channel, handler: handler, progress: { _ in }).flatMapThrowing { res in
                print("// 认证请求发送完成")
                guard res.status == .ok else { throw APIReqErr.badResponse.d(14002, (#file, #line))}
                print("// 向认证模块发送认证请求，最终应当得到一个使用用户口令加密的新密钥，并使用该新密钥进行后续的通讯加密")
                guard let token = Data(base64Encoded: ioData.token) else { throw APIReqErr.parseParaFailed.d("用户口令", 14003, (#file, #line)) }
                let tokenKey = Crypto.Symm.Key(data: token)
                print("// 获取对方发来的加密新密钥")
                let keyEncrypted = try res.content.decode(JSONData.self).data
                print("// 使用用户口令解密新密钥")
                let newKey: Crypto.Symm.Key = try Crypto.Symm.decrypt(keyEncrypted, key: tokenKey)
                print("// 注册该新密钥，用于将来的连线加密")
                ioData.connectionKeys[id] = newKey
            }
        } catch let err {
            return channel.eventLoop.makeFailedFuture(err)
        }
    }
}
