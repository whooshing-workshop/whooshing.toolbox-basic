import Vapor
import Fluent
import FluentPostgresDriver

public extension Application {
    enum ServiceType: String {
        case inline = "WHOOSHING_INLINE_SERVICE"
        case https = "WHOOSHING_HTTPS_SERVICE"
        case api = "WHOOSHING_API_SERVICE"
    }
    
    var project: Env.Project! { self.storage[Env.Project.self] }
    
    /// 通过 Whooshing 系统自动配置数据库以及监听端口号
    func configure(for service: ServiceType) async throws {
        let project = try Env.get(with: service.rawValue)
        self.storage[Env.Project.self] = project
        self.http.server.configuration.port = project.port
        for db in project.databases { self.databases.use(db.config, as: db.id) }
        // 初始化对应的服务扩展
        switch service {
            case .inline: try await Inline.config(self)
            case .https: try await Https.config(self)
            case .api: try await API.config(self)
        }
    }
}

public enum Env {
    public struct Project: StorageKey, Sendable {
        public typealias Value = Self
        public let name: String
        public let port: Int
        public let databases: [DB]
        public let managerUrl: URL
        public let domain: String?
    }
    
    public struct DB: Sendable {
        public let name: String
        public let port: Int
        public let user: String
        
        public var maxConnectionsPerEventLoop: Int = 1
        public var connectionPoolTimeout: TimeAmount = .seconds(10)
        public var sqlLogLevel: Logger.Level = .info
        
        internal let password: String
        
        public var id: DatabaseID { .init(string: name) }
        
        public var config: DatabaseConfigurationFactory {
            .postgres(configuration: .init(
                hostname: "localhost",
                port: port,
                username: user,
                password: password,
                database: name,
                tls: .disable
            ),
            maxConnectionsPerEventLoop: maxConnectionsPerEventLoop,
            connectionPoolTimeout: connectionPoolTimeout,
            sqlLogLevel: sqlLogLevel)
        }
    }
}
