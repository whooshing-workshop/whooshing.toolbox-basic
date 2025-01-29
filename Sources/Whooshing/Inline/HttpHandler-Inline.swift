import Vapor
import Cryptos
import ErrorHandle
import DataConvertable
import NIO
import Logging

extension Application {
    var serviceData: Inline.ServiceData! { self.storage[Inline.ServiceData.self] }
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
        func input(request: Data, context: ChannelHandlerContext) throws -> Data {
            let id = ObjectIdentifier(context.channel)
            let req: Data
            if let key = app.serviceData.connectionKeys[id] { req = try Crypto.Symm.decrypt(request, key: key) }
            else { req = try Crypto.Symm.decrypt(request, key: app.serviceData.rootKey) }
            return req
        }
        
        /// 将有服务器响应请求发出
        func output(response: Data, context: ChannelHandlerContext, info: ChannelInfo) throws -> Data {
            let id = ObjectIdentifier(context.channel)
            let res: Data
            // 若 key 存在，但 validate 不存在，则仍然使用 rootKey 加密
            if let key = app.serviceData.connectionKeys[id], let _ = app.serviceData.connectionValidate[id] {
                res = try Crypto.Symm.encrypt(response, key: key) }
            else { res = try Crypto.Symm.encrypt(response, key: app.serviceData.rootKey) }
            return res
        }
        
        /// 连线结束
        func connectionEnd(context: ChannelHandlerContext, info: ChannelInfo) throws {
            let id = ObjectIdentifier(context.channel)
            app.serviceData.connectionKeys[id] = nil
            app.serviceData.connectionValidate[id] = nil
        }
    }
}
