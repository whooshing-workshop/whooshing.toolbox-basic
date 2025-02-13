import Vapor
import Fluent
import FluentPostgresDriver

public extension Application {
    var project: Env.Project! { self.storage[Env.Project.self] }
    
    /// 通过 Whooshing 系统自动配置数据库以及监听端口号
    static func configure(_ app: Application) async throws {
        let project = try Env.get()
        app.storage[Env.Project.self] = project
        app.http.server.configuration.port = project.port
        for db in project.databases { app.databases.use(db.config, as: db.id) }
        // 初始化 Inline 扩展
        #if INLINE
        try await Inline.config(app)
        #elseif HTTPS
        try await Https.config(app)
        #endif
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
