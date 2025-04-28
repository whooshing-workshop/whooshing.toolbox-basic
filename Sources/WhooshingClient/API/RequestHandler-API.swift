import Vapor
import Cryptos
import ErrorHandle
import DataConvertable
import NIO
import Logging

extension ReqClient where ServiceType == API {
    var apiRequestIoData: API.RequestIOData? { self.storage[API.RequestIOData.self] }
}

public enum API {
    public final class RequestIOData: StorageKey, Sendable {
        public typealias Value = RequestIOData
        public let credential: String
        public let token: String
        let connectionKeys: SendableDictionary<ObjectIdentifier, Crypto.Symm.Key> = .init()
        let readingBufferDatas: SendableDictionary<ObjectIdentifier, ByteBuffer> = .init()
        let writingBufferDatas: SendableDictionary<ObjectIdentifier, ByteBuffer> = .init()
        let authenticationHeader = HTTPHeaders.Name("Whooshing-Authentication")
        
        public init(credential: String, token: String) {
            self.credential = credential
            self.token = token
        }
    }
    
    enum Err: String, ErrList {
        var domain: String { "woo.sys.api.reqclient.err" }
        case requestParaMissing = "请求参数缺失"
        case parseParaFailed = "解析请求参数时失败"
        case userTokenMissing = "用户口令缺失"
        case internalError = "目标服务器发生错误"
        case protocolIncorrect = "加密机制协议错误"
    }
    
    struct RequestIOCrypto: RequestIOHandler, Sendable {
        let client: ReqClient<API>
        
        /// 发送请求时，进行编码并加密
        func send(request: ClientRequest, dataChunk: ByteBuffer, context: ChannelHandlerContext, allocator: ByteBufferAllocator, streaming: Bool) -> EventLoopFuture<ByteBuffer> {
            guard let ioData = client.apiRequestIoData else { return context.eventLoop.makeFailedFuture(Err.requestParaMissing.d("apiRequestIoData", 12006, (#file, #line))) }
            if request.headers.contains(name: ioData.authenticationHeader) {
                print("// 表示该请求是一个认证请求，需要发送用户凭据以及用户口令，其中用户凭据明文发送，口令则进行加密并哈希。")
                guard !streaming else { return context.eventLoop.makeFailedFuture(Err.protocolIncorrect.d("第一个身份认证请求过长", 13020, (#file, #line))) }
                return sendWithAuthExchange(context: context, allocator: allocator)
            } else {
                print("// 该请求已经经过了认证，需要进行加密后发送")
                return sendWithEncrypt(dataChunk: dataChunk, context: context, allocator: allocator, streaming: streaming)
            }
        }

        /// 收到响应时，进行解密并解码
        func get(response: ByteBuffer, context: ChannelHandlerContext, streaming: Bool) -> EventLoopFuture<ClientResponse?> {
            // 先检查对方回复的是不是一个标准的 http 回复
            // 因为此处不应当是一个 http 回复，如果是，则代表出错
            if let err = checkResponse(res: response) { return context.eventLoop.makeFailedFuture(err) }
            guard let ioData = client.apiRequestIoData else { return context.eventLoop.makeFailedFuture(Err.requestParaMissing.d("apiRequestIoData", 12010, (#file, #line))) }
            let id = ObjectIdentifier(context.channel)
            if let key = ioData.connectionKeys[id] {
                print("// 该响应数据是已经通过了认证的，直接使用密钥进行解密")
                return getWithDecrypt(response: response, key: key, context: context, streaming: streaming)
            } else {
                print("// 该响应应当是一个认证请求的响应")
                print("Response: \(Data(buffer: response).base64String())")
                guard !streaming else { return context.eventLoop.makeFailedFuture(Err.protocolIncorrect.d("认证信息过长", 13021, (#file, #line))) }
                return getWithAuthExchange(response: response, context: context)
            }
        }

        /// 发送用户凭据以及用户口令，其中用户凭据明文发送，口令则进行加密并哈希
        func sendWithAuthExchange(context: ChannelHandlerContext, allocator: ByteBufferAllocator) -> EventLoopFuture<ByteBuffer> {
            do {
                let ioData = client.apiRequestIoData!
                guard let credential = Data(base64Encoded: ioData.credential) else { throw Err.parseParaFailed.d("用户凭据", 12007, (#file, #line)) }
                guard let token = Data(base64Encoded: ioData.token) else { throw Err.parseParaFailed.d("用户口令", 12008, (#file, #line)) }
                let tokenKey = Crypto.Symm.Key(data: token)
                let tokenEncrypted = try Crypto.Symm.encrypt(token, key: tokenKey)
                print("解析前: \(tokenEncrypted.base64String())")
                let data = try "[auth]".data() + credential + tokenEncrypted
                print("解析前尝试: \(data.subdata(in: 22..<82).base64String())")
                var buffer = allocator.buffer(capacity: 0)
                print("// 将数据写入 buffer，准备发送")
                buffer.writeData(data)
                return context.eventLoop.makeSucceededFuture(buffer)
            } catch let err {
                return context.eventLoop.makeFailedFuture(err)
            }
        }

        /// 该请求已经经过了认证，加密后发送
        func sendWithEncrypt(dataChunk: ByteBuffer, context: ChannelHandlerContext, allocator: ByteBufferAllocator, streaming: Bool) -> EventLoopFuture<ByteBuffer> {
            do {
                print("chunck to encrypt: \(dataChunk.readableBytes)")
                let ioData = client.apiRequestIoData!
                let id = ObjectIdentifier(context.channel)
                guard let key = ioData.connectionKeys[id] else { throw Err.userTokenMissing.d(12009, (#file, #line)) }
                let cipher = try Crypto.Symm.encrypt(dataChunk, key: key)
                let buffer = allocator.buffer(data: cipher)
                return context.eventLoop.makeSucceededFuture(buffer)
            } catch let err {
                return context.eventLoop.makeFailedFuture(err)
            }
        }
        
        // 检查 response 是否为 HTTP 格式且包括错误状态码
        func checkResponse(res: ByteBuffer) -> Error? {
            struct BodyReply: Content {
                let error: Bool
                let reason: String
            }
            do {
                let res = try String(data: res.data())
                let parts = res.split(separator: "\r\n\r\n")
                if parts.count == 2, let body = parts[1].data(using: .utf8) {
                    let reply = try JSONDecoder().decode(BodyReply.self, from: body)
                    if reply.error {
                        return Err.internalError.d(reply.reason, 13001, (#file, #line))
                    }
                }
            } catch { }
            return nil
        }

        func getWithAuthExchange(response: ByteBuffer, context: ChannelHandlerContext) -> EventLoopFuture<ClientResponse?> {
            print("// 向认证模块发送认证请求，最终应当得到一个使用用户口令加密的新密钥，并使用该新密钥进行后续的通讯加密")
            let ioData = client.apiRequestIoData!
            let id = ObjectIdentifier(context.channel)
            do {
                guard let token = Data(base64Encoded: ioData.token) else { throw Err.parseParaFailed.d("用户口令", 12011, (#file, #line)) }
                let tokenKey = Crypto.Symm.Key(data: token)
                let newKey: Crypto.Symm.Key = try Crypto.Symm.decrypt(Data(buffer: response), key: tokenKey)
                print("// 注册该新密钥，确保后续将会使用该密钥加密")
                ioData.connectionKeys[id] = newKey
                print("// 返回一个拥有 “Whooshing-Authentication” 头的响应，作为标记，表示该响应是一个认证成功响应")
                return context.eventLoop.makeSucceededFuture(.init(status: .ok, headers: .init([(ioData.authenticationHeader.description, "true")])))
            } catch let err {
                return context.eventLoop.makeFailedFuture(err)
            }
        }

        func getWithDecrypt(response: ByteBuffer, key: Crypto.Symm.Key, context: ChannelHandlerContext, streaming: Bool) -> EventLoopFuture<ClientResponse?> {
            do {
                let ioData = client.apiRequestIoData!
                var res: ByteBuffer = try Crypto.Symm.decrypt(Data(buffer: response), key: key)
                return streamingHandle(
                    chunkData: &res, 
                    context: context, 
                    dic: ioData.readingBufferDatas,
                    streaming: streaming
                ).flatMapThrowing { data in
                    if let d = data { return try ClientResponse(data: d) } 
                    else { return nil }
                }
            } catch let err {
                return context.eventLoop.makeFailedFuture(err)
            }
        }

        // 连线结束，进行清理
        func connectionEnd(context: ChannelHandlerContext) -> EventLoopFuture<Void> {
            let id = ObjectIdentifier(context.channel)
            client.apiRequestIoData?.connectionKeys[id] = nil
            client.apiRequestIoData?.readingBufferDatas[id] = nil
            client.apiRequestIoData?.writingBufferDatas[id] = nil
            return context.eventLoop.makeSucceededVoidFuture()
        }
    }
}
