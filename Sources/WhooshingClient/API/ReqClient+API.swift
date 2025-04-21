import Vapor
import ErrorHandle
import DataConvertable
import NIOCore
import Logging
import Cryptos

extension API: WhooshingServiceType {}

public extension ReqClient where ServiceType == API {
    func get(_ url: URI, headers: HTTPHeaders = [:], beforeSend: (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend) -> EventLoopFuture<ClientResponse> {
        return self.send(.GET, headers: headers, to: url, beforeSend: beforeSend, afterSend: afterSend)
    }

    func post(_ url: URI, headers: HTTPHeaders = [:], beforeSend: (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend) -> EventLoopFuture<ClientResponse> {
        return self.send(.POST, headers: headers, to: url, beforeSend: beforeSend, afterSend: afterSend)
    }

    func patch(_ url: URI, headers: HTTPHeaders = [:], beforeSend: (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend) -> EventLoopFuture<ClientResponse> {
        return self.send(.PATCH, headers: headers, to: url, beforeSend: beforeSend, afterSend: afterSend)
    }

    func put(_ url: URI, headers: HTTPHeaders = [:], beforeSend: (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend) -> EventLoopFuture<ClientResponse> {
        return self.send(.PUT, headers: headers, to: url, beforeSend: beforeSend, afterSend: afterSend)
    }

    func delete(_ url: URI, headers: HTTPHeaders = [:], beforeSend: (inout ClientRequest, Channel) throws -> () = { _, _ in }, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend) -> EventLoopFuture<ClientResponse> {
        return self.send(.DELETE, headers: headers, to: url, beforeSend: beforeSend, afterSend: afterSend)
    }
    
    func post<T>(_ url: URI, headers: HTTPHeaders = [:], content: T, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend) -> EventLoopFuture<ClientResponse> where T: Content {
        return self.post(url, headers: headers, beforeSend: { req, _ in try req.content.encode(content) }, afterSend: afterSend)
    }

    func patch<T>(_ url: URI, headers: HTTPHeaders = [:], content: T, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend) -> EventLoopFuture<ClientResponse> where T: Content {
        return self.patch(url, headers: headers, beforeSend: { req, _ in try req.content.encode(content) }, afterSend: afterSend)
    }

    func put<T>(_ url: URI, headers: HTTPHeaders = [:], content: T, afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend) -> EventLoopFuture<ClientResponse> where T: Content {
        return self.put(url, headers: headers, beforeSend: { req, _ in try req.content.encode(content) }, afterSend: afterSend)
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
    }
    
    func send(
        _ method: HTTPMethod,
        headers: HTTPHeaders = [:],
        to url: URI,
        beforeSend: (inout ClientRequest, Channel) throws -> () = { _, _ in },
        afterSend: @escaping @Sendable (Channel) -> EventLoopFuture<Void> = defaultAfterSend
    ) -> EventLoopFuture<ClientResponse> {
        var request = ClientRequest(method: method, url: url, headers: headers, body: nil, byteBufferAllocator: self.byteBufferAllocator)
        do {
            let (channel, handler) = try self.makeChannel(url: request.url)
            try beforeSend(&request, channel)
            request.channel = channel
            return self._send(request: request, channel: channel, handler: handler).flatMap { res in
                afterSend(channel).map { res }
            }
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }
    
    private func _send(request: ClientRequest, channel: Channel, handler: RequestHandler) -> EventLoopFuture<ClientResponse> {
        let id = ObjectIdentifier(channel)
        do {
            guard let ioData = self.apiRequestIoData else { throw APIReqErr.requestParaMissing.d("apiRequestIoData", 12013, (#file, #line)) }
            if ioData.connectionKeys[id] == nil {
                // 需要进行认证
                let res = try self.send(.init(method: .POST, url: request.url, headers: .init([(ioData.authenticationHeader.description, "true")])), channel: channel, handler: handler).wait()
                guard res.status == .ok else { throw APIReqErr.badResponse.d(12014, (#file, #line))}
                guard res.headers.contains(name: ioData.authenticationHeader) else { throw APIReqErr.authenticationBadProtocol.d("目标回复的响应不包括认证头信息", 12015, (#file, #line)) }
                guard ioData.connectionKeys[id] != nil else { throw APIReqErr.unknowSendError.d("预期应当读取到密钥，但得到空值", 12016, (#file, #line)) }
            }
            // 发送具体的请求
            return eventLoop.makeSucceededFuture(try self.send(request, channel: channel, handler: handler).wait())
        } catch let err {
            return eventLoop.makeFailedFuture(APIReqErr.unknowSendError.d(12012, (#file, #line)).subErr(err))
        }
    }
}
