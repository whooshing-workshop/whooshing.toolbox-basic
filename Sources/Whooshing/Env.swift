import Vapor
import ErrorHandle

internal extension Whooshing {
    static var EnvBase: String { "WHOOSHING_API_SERVICE" }
}

extension Woo.Env.Project: Woo.Env.Template {
    internal static var envs: [String: Woo.Env.Types] { [ "name": .string, "port": .int, "#domain": .string, "db": .dataTemplate(Woo.Env.DB.self) ] }
    internal init() { self.name = ""; self.databases = []; self.port = 0; self.domain = nil }
    internal init(data: [String : Any]) {
        self.name = data["name"] as! String
        self.port = data["port"] as! Int
        self.databases = data["db"] as! [Woo.Env.DB]
        self.domain = data["domain"] as? String
    }
}

extension Woo.Env.DB: Woo.Env.Template {
    internal static var envs: [String: Woo.Env.Types] { [ "name": .string, "port": .int, "user": .string, "password": .string ] }
    internal init() { self.name = ""; self.port = 0; self.user = ""; self.password = "" }
    internal init(data: [String : Any]) {
        self.name = data["name"] as! String
        self.port = data["port"] as! Int
        self.user = data["user"] as! String
        self.password = data["password"] as! String
    }
}

internal extension Woo.Env {
    enum Types {
        case string
        case int
        case stringArr
        case intArr
        case dataTemplate(Template.Type)
    }

    protocol Template {
        static var envs: [String: Types] { get }
        static func parse(prefix: String?, getValue: @escaping ((String) -> String?)) throws -> Self
        init(data: [String: Any])
        init()
    }

    enum Err: String, ErrList {
        var domain: String { "\(Woo.main).\(Woo.template).sys.err" }
        case parseFailed = "环境变量解析失败"
        case typeIncorrect = "环境变量配置类型不匹配"
        case missingKey = "环境变量配置字段缺失"
    }
}

internal extension Woo.Env.Template {
    static func parse(prefix: String?, getValue: @escaping ((String) -> String?) = { Environment.get($0) }) throws -> Self {
        var values: [String: Any] = [:]
        for (key, v) in Self.envs {
            if key.hasPrefix("#") {
                let key = String(key.dropFirst())
                let k = prefix == nil ? key : "\(prefix!)_\(key.uppercased())"
                values[key] = getValue(k)
                continue
            }
            let k = prefix == nil ? key : "\(prefix!)_\(key.uppercased())"
            let value: String!
            
            switch v {
                case .string, .int, .intArr, .stringArr: guard let vv = getValue(k) else { throw Woo.Env.Err.missingKey.d(k, 10000, (#file, #line)) }; value = vv
                default: value = nil
            }
            
            switch v {
                case .string: values[key] = value
                case .int: guard let v = Int(value) else { throw Woo.Env.Err.typeIncorrect.d(k, (#file, #line)) }; values[key] = v
                case .stringArr: values[key] = value.split(separator: ",").map { String($0) }
                case .intArr: values[key] = try value.split(separator: ",").map { guard let v = Int($0) else { throw Woo.Env.Err.typeIncorrect.d(k, (#file, #line)) }; return v }
                case .dataTemplate(let template):
                    guard let countStr = getValue(k + "_COUNT") else { throw Woo.Env.Err.missingKey.d(k, 10001, (#file, #line)) }
                    guard let count = Int(countStr) else { throw Woo.Env.Err.typeIncorrect.d(k, 10002, (#file, #line)) }
                    var vs: [Woo.Env.Template] = []
                    for i in 1...count {
                        vs.append(try template.parse(prefix: "\(k)_\(i)", getValue: getValue))
                    }
                    values[key] = vs
            }
        }
        return Self(data: values)
    }
}
