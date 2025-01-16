import Vapor
import Fluent
import FluentPostgresDriver

public typealias Woo = Whooshing

public struct Whooshing {
    
    public enum TemplateType: String, Sendable { case api = "api", https = "https", inline = "inline" }
    
    public static let main: String = "woo"
    public static let template = TemplateType.api
    public static let project: String = { Environment.get("\(Self.EnvBase)_NAME")! }()
    public static let domain: String = { "\(main).\(template).\(project)" }()
    
    /// 通过 Whooshing 系统自动配置数据库以及监听端口号
    public static func configure(_ app: Application) async throws {
        let project = try Env.get()
        app.http.server.configuration.port = project.port
        for db in project.databases { app.databases.use(db.config, as: db.id) }
    }
}

enum Env {
    public static func get() throws -> Project { try .parse(prefix: Woo.EnvBase) }
    
    public struct Project {
        public let name: String
        public let port: Int
        public let databases: [DB]
        public let domain: String?
    }
    
    public struct DB {
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
