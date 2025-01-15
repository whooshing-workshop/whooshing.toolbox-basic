import Vapor
import FluentPostgresDriver

public typealias Woo = Whooshing

public struct Whooshing {
    
    public static let main: String = "woo"
    public static let template: String = "api"
    public static let project: String = { Environment.get("\(Self.EnvBase)_NAME")! }()
    public static let domain: String = { "\(main).\(template).\(project)" }()
    
    public enum Env {
        
        public static func get() throws -> Project { try .parse(prefix: EnvBase) }
        
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
}
