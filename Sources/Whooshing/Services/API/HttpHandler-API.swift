import Vapor
import Cryptos
import ErrorHandle
import DataConvertable
import NIO
import Logging

extension Application {
    var apiServiceData: API.ServiceData! { self.storage[API.ServiceData.self] }
}

extension API {
    
    enum Err: String, ErrList {
        var domain: String { "woo.api.sys.httpcrypto.err" }
        case requestIllegal = "客户端 API 请求不合法"
        case requestFailed = "向认证模块请求失败"
    }
    
    final class ServiceData: StorageKey, Sendable {
        typealias Value = ServiceData
    }
    
    struct HttpIOCrypto: HTTPIOHandler, Sendable {
        let app: Application
        let authenticationURL: URL
        /// 有客户端请求进入
        func input(request: Data, context: ChannelHandlerContext) async throws -> Data? {
            let header = request.count >= 6 ? request.subdata(in: 0..<6).base64EncodedString() : nil
            if let h = header, h == "[auth]" {
                // 为该客户端发来的第一个请求，需要进行身份认证
                // 用户凭据有 16 字节，在 6 ～ 6+16 的字节区
                // 用户口令 Hashed 有 64 字节，在 22 ～ 22+64 字节区
                // 因此，认证请求总共为 86 字节
                guard request.count == 86 else { throw Err.requestIllegal.d("请求长度不符合要求，应当为 86 字节，却收到 \(request.count)", 12000, (#file, #line)) }
                let credential = request.subdata(in: 6..<22).base64EncodedString()
                let tokenHashed = request.subdata(in: 22..<86)
                let res = try await app.inlineClient.post(authenticationURL.toUri(with: "/user/auth")) { request in
                    try request.content.encode(TokenAuth(credential: credential, tokenHashed: tokenHashed), as: .json)
                }
                guard res.status == .ok else { throw Err.requestFailed.d("请求的状态码结果为: \(res.status)", 12001, (#file, #line)) }
                // 从结果解析用户口令
                let token = try res.content.decode(Crypto.Symm.Key.self)
                // 生成新的密钥，用做通讯加密
                let newkey = Crypto.Symm.makeKey()
                // 将新密钥使用用户口令加密，作为响应直接返回给客户端
                let keyData = try Crypto.Symm.encrypt(newkey, key: token)
                try await context.writeAndFlush(.init(ByteBuffer(data: keyData)))
                return nil
                struct TokenAuth: Content {
                    let credential: String
                    let tokenHashed: Data
                }
            } else {
                // 该客户端发来了加密请求，应当已经经过了身份认证，这里进行确认
                
            }
        }
        
        /// 将有服务器响应请求发出
        func output(response: Data, context: ChannelHandlerContext, info: ChannelInfo) throws -> Data? {
            
        }
        
        /// 连线结束
        func connectionEnd(context: ChannelHandlerContext, info: ChannelInfo) throws {
            
        }
    }
}
