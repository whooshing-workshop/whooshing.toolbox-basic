#if INLINE

import Vapor
import Cryptos
import ErrorHandle
import DataConvertable
import NIO
import Logging

public extension Application {
    var inlineClient: Client { self.storage[ReqClient<Inline>.self]! }
}

enum Inline {
    enum Err: String, ErrList {
        var domain: String { "woo.inline.sys.init.err" }
        case initializeFailed = "服务初始化失败"
    }
    
    static func config(_ app: Application) async throws {
        // 取得该服务模块的参数
        let env = try ServicePara.parse(prefix: "WHOOSHING_INLINE_SERVICE_PRIVATE")
        // 创建非对称公私钥
        let keyPair = Crypto.Asym.makeCryptoKeyPair()
        // 向模块管理器请求取得服务模块信息，首先将自己的公钥发出
        let res = try await app.client.post(app.project.managerUrl.toUri(with: "/params/init")) { postRequest in
            try postRequest.content.encode(keyPair.public, as: .json)
        }
        guard res.status == .ok else { throw Err.initializeFailed.d("请求模块管理器的结果为: \(res.status)", 10010, (#file, #line)) }
        // 解包服务器回复
        let paras = try res.content.decode(InitParaRes.self)
        // 生成共享密钥
        let sharedKey = try Crypto.Asym.keyEncapsulate(key: keyPair.private, partyPublic: paras.pub, salt: Crypto.hash("manager.shared.key"), info: "")
        let rootKey: Crypto.Symm.Key = try Crypto.Symm.decrypt(paras.root, key: sharedKey)
        // 保存到上下文
        app.storage[ServiceData.self] = try ServiceData(
            rootKey: rootKey,
            moduleDatas: paras.modules.map { try Crypto.Symm.decrypt($0, key: sharedKey) }
        )
        // 注册 HTTP IO 加密模块
        app.use(httpIOHandler: HttpIOCrypto(app: app))
        // 注册服务来源验证中间件
        app.middleware.use(GuardMiddleware())
        
        // 创建请求 API 提供者
        let client = ReqClient<Inline>(eventLoop: app.eventLoopGroup.next(), logger: app.logger, byteBufferAllocator:.init() )
        let ioHandler = RequestIOCrypto(client: client)
        client.ioHandler = ioHandler
        client.storage[Inline.RequestIOData.self] = .init(rootKey: rootKey, serviceID: env.serviceID)
        app.storage[ReqClient<Inline>.self] = client
        
        struct InitParaRes: Content {
            let pub: Crypto.Asym.CPublicKey
            let root: Data
            let modules: [Data]
        }
    }
    
    struct ModuleData: Content, Sendable, ThrowableDataConvertable {
        let name: String
        let serviceId: UUID
        let connection: String?
        init(data: Data) throws {
            let paras = try [String: AnyThrowableDataConvertable](data: data)
            self.name = try paras["name"]!.cast(to: String.self)
            self.serviceId = try paras["serviceId"]!.cast(to: UUID.self)
            self.connection = try? paras["connection"]?.cast(to: String.self)
        }

        func data() throws -> Data {
            let d: [String: (any ThrowableDataConvertable)?] = [
                "name": name,
                "serviceId": serviceId,
                "connection": connection
            ]
            return try d.filtered.anyValue.data()
        }
    }
}

#endif
