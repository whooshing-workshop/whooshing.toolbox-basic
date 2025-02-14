import Vapor
import Cryptos
import ErrorHandle
import DataConvertable
import NIO
import Logging

/// 该文件从 Http 的基层 TCP 的层级上配置加密中间件，使得服务使用自定加密算法，
/// 而非默认的 HTTPS。使用自定加密算法，这也意味着将不受浏览器的支持，
/// 因此，若配置了该加密中间件，则无法在浏览器上访问该服务

extension Application {
    var inlineServiceData: Inline.ServiceData! { self.storage[Inline.ServiceData.self] }
}

extension Inline {
    final class ServiceData: StorageKey, Sendable {
        typealias Value = ServiceData
        let rootKey: Crypto.Symm.Key
        let moduleDatas: [ModuleData]
        let connectionValidate: SendableDictionary<ObjectIdentifier, Bool> = .init()
        let connectionKeys: SendableDictionary<ObjectIdentifier, Crypto.Symm.Key> = .init()
        
        init(rootKey: Crypto.Symm.Key, moduleDatas: [ModuleData]) {
            self.rootKey = rootKey
            self.moduleDatas = moduleDatas
        }
    }
    
    /// 实现 HTTP IO 加解密处理
    struct HttpIOCrypto: HTTPIOHandler, Sendable {
        let app: Application
        /// 有客户端请求进入
        func input(request: Data, context: ChannelHandlerContext) throws -> Data? {
            let id = ObjectIdentifier(context.channel)
            let req: Data
            if let key = app.inlineServiceData.connectionKeys[id] { req = try Crypto.Symm.decrypt(request, key: key) }
            else { req = try Crypto.Symm.decrypt(request, key: app.inlineServiceData.rootKey) }
            return req
        }
        
        /// 将有服务器响应请求发出
        func output(response: Data, context: ChannelHandlerContext, info: ChannelInfo) throws -> Data? {
            let id = ObjectIdentifier(context.channel)
            let res: Data
            // 若 key 存在，但 validate 不存在，则仍然使用 rootKey 加密
            if let key = app.inlineServiceData.connectionKeys[id], let _ = app.inlineServiceData.connectionValidate[id] {
                res = try Crypto.Symm.encrypt(response, key: key) }
            else { res = try Crypto.Symm.encrypt(response, key: app.inlineServiceData.rootKey) }
            return res
        }
        
        /// 连线结束
        func connectionEnd(context: ChannelHandlerContext, info: ChannelInfo) throws {
            let id = ObjectIdentifier(context.channel)
            app.inlineServiceData.connectionKeys[id] = nil
            app.inlineServiceData.connectionValidate[id] = nil
        }
    }
}
