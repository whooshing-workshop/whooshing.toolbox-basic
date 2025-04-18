import Vapor
import ErrorHandle
import DataConvertable
import NIOCore
import Logging
import Cryptos

extension API: WhooshingServiceType {}

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
        beforeSend: (inout ClientRequest) throws -> () = { _ in }
    ) -> EventLoopFuture<ClientResponse> {
        var request = ClientRequest(method: method, url: url, headers: headers, body: nil, byteBufferAllocator: self.byteBufferAllocator)
        do {
            try beforeSend(&request)
            let (channel, promise) = try self.makeChannel(url: request.url)
            request.channel = channel
            return self._send(request: request, channel: channel, promise: promise)
        } catch {
            return self.eventLoop.makeFailedFuture(error)
        }
    }
    
    private func _send(request: ClientRequest, channel: Channel, promise: EventLoopPromise<ClientResponse>) -> EventLoopFuture<ClientResponse> {
        let id = ObjectIdentifier(channel)
        do {
            guard let ioData = self.apiRequestIoData else { throw APIReqErr.requestParaMissing.d("apiRequestIoData", 12013, (#file, #line)) }
            if ioData.connectionKeys[id] == nil {
                // 需要进行认证
                let res = try self.send(.init(method: .POST, url: request.url, headers: .init([(ioData.authenticationHeader.description, "true")])), channel: channel, promise: promise).wait()
                guard res.status == .ok else { throw APIReqErr.badResponse.d(12014, (#file, #line))}
                guard res.headers.contains(name: ioData.authenticationHeader) else { throw APIReqErr.authenticationBadProtocol.d("目标回复的响应不包括认证头信息", 12015, (#file, #line)) }
                guard ioData.connectionKeys[id] != nil else { throw APIReqErr.unknowSendError.d("预期应当读取到密钥，但得到空值", 12016, (#file, #line)) }
            }
            // 发送具体的请求
            return eventLoop.makeSucceededFuture(try self.send(request, channel: channel, promise: promise).wait())
        } catch let err {
            return eventLoop.makeFailedFuture(APIReqErr.unknowSendError.d(12012, (#file, #line)).subErr(err))
        }
    }
}
