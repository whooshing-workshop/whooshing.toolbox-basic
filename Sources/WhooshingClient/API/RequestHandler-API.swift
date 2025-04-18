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
    }
    
    struct RequestIOCrypto: RequestIOHandler, Sendable {
        let client: ReqClient<API>
        
        /// 发送请求时，进行编码并加密
        func send(request: ClientRequest, context: ChannelHandlerContext, allocator: ByteBufferAllocator) -> EventLoopFuture<ByteBuffer> {
            let id = ObjectIdentifier(context.channel)
            do {
                guard let ioData = client.apiRequestIoData else { throw Err.requestParaMissing.d("apiRequestIoData", 12006, (#file, #line)) }
                if request.headers.contains(name: ioData.authenticationHeader) {
                    // 表示该请求是一个认证请求，需要发送用户凭据以及用户口令，其中用户凭据明文发送，口令则进行加密并哈希。
                    guard let credential = Data(base64Encoded: ioData.credential) else { throw Err.parseParaFailed.d("用户凭据", 12007, (#file, #line)) }
                    guard let token = Data(base64Encoded: ioData.credential) else { throw Err.parseParaFailed.d("用户口令", 12008, (#file, #line)) }
                    let tokenKey = Crypto.Symm.Key(data: token)
                    let data = try Data(base64Encoded: "[auth]")! + credential + Crypto.hash(Crypto.Symm.encrypt(token, key: tokenKey))
                    var buffer = allocator.buffer(capacity: 0)
                    buffer.writeData(data)
                    return context.eventLoop.makeSucceededFuture(buffer)
                } else {
                    // 该请求已经经过了认证，需要进行加密后发送
                    guard let key = ioData.connectionKeys[id] else { throw Err.userTokenMissing.d(12009, (#file, #line)) }
                    var plain = try request.data(bufferAllocator: allocator)
                    let cipher = try Crypto.Symm.encrypt(plain, key: key)
                    plain.clear()
                    plain.writeData(cipher)
                    return context.eventLoop.makeSucceededFuture(plain)
                }
            } catch let err {
                return context.eventLoop.makeFailedFuture(err)
            }
        }
        
        /// 收到响应时，进行解密并解码
        func get(response: ByteBuffer, context: ChannelHandlerContext) -> EventLoopFuture<ClientResponse> {
            let id = ObjectIdentifier(context.channel)
            do {
                guard let ioData = client.apiRequestIoData else { throw Err.requestParaMissing.d("apiRequestIoData", 12010, (#file, #line)) }
                if let key = ioData.connectionKeys[id] {
                    // 该响应数据是已经通过了认证的，直接使用密钥进行解密
                    let request: ByteBuffer = try Crypto.Symm.decrypt(Data(buffer: response), key: key)
                    return try context.eventLoop.makeSucceededFuture(.init(data: request))
                } else {
                    // 该响应应当是一个认证请求的响应
                    // 向认证模块发送认证请求，最终应当得到一个使用用户口令加密的新密钥，并使用该新密钥进行后续的通讯加密
                    guard let token = Data(base64Encoded: ioData.credential) else { throw Err.parseParaFailed.d("用户口令", 120011, (#file, #line)) }
                    let tokenKey = Crypto.Symm.Key(data: token)
                    let newKey: Crypto.Symm.Key = try Crypto.Symm.decrypt(Data(buffer: response), key: tokenKey)
                    // 注册该新密钥，确保后续将会使用该密钥加密
                    ioData.connectionKeys[id] = newKey
                    // 返回一个拥有 “Whooshing-Authentication” 头的响应，作为标记，表示该响应是一个认证成功响应
                    return context.eventLoop.makeSucceededFuture(.init(status: .ok, headers: .init([(ioData.authenticationHeader.description, "true")])))
                }
            } catch let err {
                return context.eventLoop.makeFailedFuture(err)
            }
        }
        
        // 连线结束，进行清理
        func connectionEnd(context: ChannelHandlerContext) -> EventLoopFuture<Void> {
            let id = ObjectIdentifier(context.channel)
            client.apiRequestIoData?.connectionKeys[id] = nil
            return context.eventLoop.makeSucceededVoidFuture()
        }
    }
}
