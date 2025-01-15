import Vapor

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
            public let databases: [DB]
            public let domain: String?
        }
        
        public struct DB {
            public let name: String
            public let port: Int
        }
    }
    
}
