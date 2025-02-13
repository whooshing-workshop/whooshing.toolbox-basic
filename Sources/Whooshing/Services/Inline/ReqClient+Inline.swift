import Vapor
import ErrorHandle
import DataConvertable
import NIOCore
import Logging
import Cryptos

/// 该文件实现了发送加密请求的功能。由于目标模块的加密算法并非传统的 HTTPS，
/// 而是自定的加密算法，因此向其请求时需要使用特定的加密逻辑。

extension Inline: WhooshingServiceType {}

extension ReqClient where ServiceType == Inline {
    
    enum InlineReqErr: String, ErrList {
        var domain: String { "woo.sys.inline.reqclient.inlinereqerr" }
        case targetBadResponse = "目标返回了不正常的响应"
        case targetIncorrectResponseBody = "目标的响应体不正确"
        case unknowSendError = "发送时遇到未知错误"
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
            let procedure: Int
            if self.requestIoData.connectionKeys[id] == nil { procedure = 0 }
            else if self.requestIoData.connectionValidate[id] != true { procedure = 1 }
            else { procedure = 2 }
            let response: ClientResponse
            switch (procedure) {
            case 0:
                // 首次请求，需要交换密钥
                try keyExchange(req: request, channel: channel, promise: promise)
                fallthrough
            case 1:
                // 密钥交换已完成，配合对方进行验证验证
                try serviceValidate(req: request, channel: channel, promise: promise)
                fallthrough
            default:
                // 已成功经过验证，开始发送请求
                response = try self.send(request, channel: channel, promise: promise).wait()
            }
            return eventLoop.makeSucceededFuture(response)
        } catch let err {
            return eventLoop.makeFailedFuture(InlineReqErr.unknowSendError.d(10095, (#file, #line)).subErr(err))
        }
    }
    
    private func keyExchange(req: ClientRequest, channel: Channel, promise: EventLoopPromise<ClientResponse>) throws {
        // 创建公私钥对
        let keyPair = Crypto.Asym.makeCryptoKeyPair()
        // 将公钥发送于目标
        let response = try self.send(.init(method: .POST, url: req.url, body: .init(data: keyPair.public.data())), channel: channel, promise: promise).wait()
        // 检查对方的响应，对方应当发来自己的公钥
        guard response.status == .ok else { throw InlineReqErr.targetBadResponse.d("\(response.status.description)(\(response.status.code))", 10090, (#file, #line)) }
        guard let data = response.body?.data() else { throw InlineReqErr.targetIncorrectResponseBody.d("预期为公钥，但得到不正确回复", 10091, (#file, #line)) }
        // 解包对方发来的公钥
        let targetPub = try Crypto.Asym.CPublicKey(data: data)
        // 计算共享密钥
        let sharedKey = try Crypto.Asym.keyEncapsulate(key: keyPair.private, partyPublic: targetPub, salt: Crypto.hash("inline.shared.key"), info: "")
        // 设置标志位
        self.requestIoData.connectionKeys[ObjectIdentifier(channel)] = sharedKey
    }
    
    private func serviceValidate(req: ClientRequest, channel: Channel, promise: EventLoopPromise<ClientResponse>) throws {
        // 将自己的服务 ID 发送于目标
        let response = try self.send(.init(method: .POST, url: req.url, body: .init(data: self.requestIoData.serviceID.data())), channel: channel, promise: promise).wait()
        // 检查对方的响应
        guard response.status == .ok else { throw InlineReqErr.targetBadResponse.d("\(response.status.description)(\(response.status.code))", 10092, (#file, #line)) }
        // 设置标志位
        self.requestIoData.connectionValidate[ObjectIdentifier(channel)] = true
    }
}
