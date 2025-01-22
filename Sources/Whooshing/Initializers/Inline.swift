import Vapor
import Cryptos
import ErrorHandle
import DataConvertable

public enum InlineInit {
    public struct ServiceData: StorageKey, Sendable {
        public typealias Value = Self
        public let rootKey: Crypto.Symm.Key
        public let moduleDatas: [ModuleData]
    }
    
    public enum Err: String, ErrList {
        public var domain: String { "woo.api.sys.init.err" }
        case initializeFailed = "服务初始化失败"
    }
    
    public static func inline(_ app: Application) async throws -> ServiceData {
        let keyPair = Crypto.Asym.makeCryptoKeyPair()
        let res = try await app.client.post(app.project.managerUrl.toUri(with: "/params/init")) { postRequest in
            try postRequest.content.encode(["pub": keyPair.private], as: .json)
        }
        guard res.status == .ok else { throw Err.initializeFailed.d("请求模块管理器的结果为: \(res.status)", 10010, (#file, #line)) }
        let paras = try res.content.decode(InitParaRes.self)
        let sharedKey = try Crypto.Asym.keyEncapsulate(key: keyPair.private, partyPublic: paras.pub, salt: Crypto.hash("manager.shared.key"), info: "")
        return try ServiceData(
            rootKey: Crypto.Symm.decrypt(paras.root, key: sharedKey),
            moduleDatas: paras.modules.map { try Crypto.Symm.decrypt($0, key: sharedKey) }
        )
    }
    
    public struct ModuleData: Content, Sendable, ThrowableDataConvertable {
        public let name: String
        public let serviceId: UUID
        public let connection: String?
        public init(data: Data) throws {
            let paras = try [String: AnyThrowableDataConvertable](data: data)
            self.name = try paras["name"]!.cast(to: String.self)
            self.serviceId = try paras["serviceId"]!.cast(to: UUID.self)
            self.connection = try? paras["connection"]?.cast(to: String.self)
        }

        public func data() throws -> Data {
            let d: [String: (any ThrowableDataConvertable)?] = [
                "name": name,
                "serviceId": serviceId,
                "connection": connection
            ]
            return try d.filtered.anyValue.data()
        }
    }
    
    private struct InitParaRes: Content {
        internal let pub: Crypto.Asym.CPublicKey
        internal let root: Data
        internal let modules: [Data]
    }
}

extension URL {
    func toUri(with path: String) -> URI { .init(string: self.absoluteString + path) }
}
