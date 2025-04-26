import Vapor
import Cryptos
import ErrorHandle
import DataConvertable
import NIO
import Logging
import WhooshingClient

/// 该文件实现了 API 模块接收和发出的加密机制 Socket 流处理
/// 每个 API 请求前必须经过身份验证

extension Application {
    var apiServiceData: API.ServiceData! { self.storage[API.ServiceData.self] }
}

extension API {
    
    enum Err: String, ErrList {
        var domain: String { "woo.api.sys.httpcrypto.err" }
        case requestIllegal = "客户端 API 请求不合法"
        case requestFailed = "向认证模块请求失败"
        case needAuthenticationFirst = "请求未认证，需要先进行认证"
    }
    
    final class ServiceData: StorageKey, Sendable {
        typealias Value = ServiceData
        let clientKeys: SendableDictionary<ObjectIdentifier, Crypto.Symm.Key> = .init()
        let inlineClient: ReqClient<Inline>

        init(inlineClient: ReqClient<Inline>) {
            self.inlineClient = inlineClient
        }
    }
    
    struct HttpIOCrypto: HTTPIOHandler, Sendable {
        let app: Application
        let authenticationURL: URL
        
        /// 有客户端请求进入
        func input(request: Data, context: ChannelHandlerContext) -> EventLoopFuture<Data?> {
            let header = request.count >= 6 ? String(data: request.subdata(in: 0..<6), encoding: .utf8) : nil
            if let h = header, h == "[auth]" {
                print("// 为该客户端发来的第一个请求，需要进行身份认证")
                return tokenAuthentication(request: request, context: context).map { nil }
            } else {
                print("// 该客户端发来了加密请求，应当已经经过了身份认证，进行数据解密")
                return decrypt(request: request, context: context).map { $0 }
            }
        }
        
        /// 有服务器响应请求发出
        func output(response: Data, context: ChannelHandlerContext, info: ChannelInfo) -> EventLoopFuture<Data?> {
            return encrypt(response: response, context: context).map { $0 }
        }
        
        /// 连线结束
        func connectionEnd(context: ChannelHandlerContext, info: ChannelInfo) -> EventLoopFuture<Void> {
            let id = ObjectIdentifier(context.channel)
            app.apiServiceData.clientKeys[id] = nil
            return context.eventLoop.makeSucceededVoidFuture()
        }
        
        // 向认证模块请求身份认证
        func tokenAuthentication(request: Data, context: ChannelHandlerContext) -> EventLoopFuture<Void> {
            // 用户凭据有 16 字节，在 6 ～ 6+16 的字节区
            // 用户口令 Hashed 有 64 字节，在 22 ～ 22+64 字节区
            // 因此，认证请求总共为 86 字节
            guard request.count == 86 else { return context.eventLoop.makeFailedFuture(Err.requestIllegal.d("请求长度不符合要求，应当为 86 字节，却收到 \(request.count)", 12000, (#file, #line))) }
            let credential = request.subdata(in: 6..<22).base64EncodedString()
            let tokenHashed = request.subdata(in: 22..<86)
            print("// 向认证模块发送认证请求")
            return app.apiServiceData.inlineClient.post(authenticationURL.toUri(with: "/user/auth"), beforeSend: { request, _ in
                try request.content.encode(TokenAuth(credential: credential, tokenHashed: tokenHashed), as: .json)
            }).flatMapThrowing { res in
                guard res.status == .ok else { throw Err.requestFailed.d("请求的状态码结果为: \(res.status)", 12001, (#file, #line)) }
                print("// 从结果解析用户口令")
                let token = try res.content.decode(Crypto.Symm.Key.self)
                print("// 生成新的密钥，用做通讯加密")
                let newKey = Crypto.Symm.makeKey()
                print("// 将新密钥使用用户口令加密，作为响应直接返回给客户端")
                return (newKey, try Crypto.Symm.encrypt(newKey, key: token))
            }.flatMap { (newKey, keyData) in
                context.writeAndFlush(.init(ByteBuffer(data: keyData))).flatMap {
                    print("// 将密钥注册，以用于将来的通讯加密")
                    app.apiServiceData.clientKeys[ObjectIdentifier(context.channel)] = newKey
                    return context.eventLoop.makeSucceededVoidFuture()
                }
            }.flatMapError { err in
                context.eventLoop.makeFailedFuture(err)
            }
            
            struct TokenAuth: Content {
                let credential: String
                let tokenHashed: Data
            }
        }
        
        // 解密请求数据
        func decrypt(request: Data, context: ChannelHandlerContext) -> EventLoopFuture<Data> {
            let id = ObjectIdentifier(context.channel)
            do {
                print("guard")
                guard let key = app.apiServiceData.clientKeys[id] else { throw Err.needAuthenticationFirst.d(12002, (#file, #line)) }
                print("// 解密请求")
                let req: Data = try Crypto.Symm.decrypt(request, key: key)
                return context.eventLoop.makeSucceededFuture(req)
            } catch let err {
                print(err)
                return context.eventLoop.makeFailedFuture(err)
            }
        }
        
        // 加密响应数据
        func encrypt(response: Data, context: ChannelHandlerContext) -> EventLoopFuture<Data> {
            let id = ObjectIdentifier(context.channel)
            do {
                guard let key = app.apiServiceData.clientKeys[id] else { throw Err.needAuthenticationFirst.d(12003, (#file, #line)) }
                print("// 加密响应")
                let req: Data = try Crypto.Symm.encrypt(response, key: key)
                return context.eventLoop.makeSucceededFuture(req)
            } catch let err {
                return context.eventLoop.makeFailedFuture(err)
            }
        }
    }
}
