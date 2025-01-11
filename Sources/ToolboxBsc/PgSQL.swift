import Vapor
import FluentPostgresDriver

public enum PGErrorTypes: String, ErrList {
    public var domain: String { "ToolboxBsc.PgSQL" }
    case fieldDefineError = "Field 定义错误"
}

public typealias PgErr = PGErrorTypes

public class PGFieldParam {
    public let dataType: DatabaseSchema.DataType
    public let isUnique: Bool
    public private(set) var defaultValue: DatabaseSchema.FieldConstraint?
    public let constraints: [DatabaseSchema.FieldConstraint]
    
    public init(
        _ dataType: DatabaseSchema.DataType,
        _ isUnique: Bool = false,
        _ constraints: [DatabaseSchema.FieldConstraint] = []
    ) {
        self.dataType = dataType
        self.constraints = constraints
        self.defaultValue = nil
        self.isUnique = isUnique
    }
    
    public func def(_ value: any SQLExpression) -> Self { self.defaultValue = .sql(.default(value)); return self }
    public func def(_ value: String) -> Self { self.defaultValue = .sql(.default(value)); return self }
    public func def<T: BinaryInteger>(_ value: T) -> Self { self.defaultValue = .sql(.default(value)); return self }
    public func def<T: FloatingPoint>(_ value: T) -> Self { self.defaultValue = .sql(.default(value)); return self }
    public func def(_ value: Bool) -> Self { self.defaultValue = .sql(.default(value)); return self }
}

public protocol PGFields {
    var id: PGFieldParam { get }
    init()
}

public protocol PGModel: Model, AsyncResponseEncodable, Sendable {
    associatedtype DTO: Content & Sendable
    associatedtype MIG: PGMigration
    associatedtype Fields: PGFields
    static var schema: String { get }
    static var pgsql: PGSQL { get set }
    @Sendable func dto(req: Request) async throws -> DTO
}

public protocol PGMigration: Migration, Sendable {
    associatedtype DataModel: PGModel
    func migrationFinished(on database: Database)
}

public extension PGModel {
    @Sendable func encodeResponse(for request: Request) async throws -> Response {
        let dto = try await self.dto(req: request)
        return try await dto.encodeResponse(for: request)
    }
    
    static func n(_ keypath: KeyPath<Self.Fields, PGFieldParam>) -> FieldKey {
        .string(Self.pgsql.getName(k: keypath))
    }
}

public extension PGMigration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let params = Self.DataModel.pgsql.addFieldPara(field: Self.DataModel.Fields())
        return Self.tableCreate(DataModel.schema, database: database, fields: params).map { migrationFinished(on: database) }
    }
    func revert(on database: Database) -> EventLoopFuture<Void> { database.schema(DataModel.schema).delete() }
    func migrationFinished(on database: Database) {}
    
    private static func tableCreate(_ name: String, database: Database, fields: [String: PGFieldParam]) -> EventLoopFuture<Void> {
        var s = database.schema(name).id()
        var uniques: [FieldKey] = []
        for (name, params) in fields {
            if name == "id" { continue }
            if params.isUnique == true { uniques.append(.string(name)) }
            typealias Old = (FieldKey, DatabaseSchema.DataType, DatabaseSchema.FieldConstraint...) -> SchemaBuilder
            typealias Function = (FieldKey, DatabaseSchema.DataType, [DatabaseSchema.FieldConstraint]) -> SchemaBuilder
            let sumOfArray = unsafeBitCast(s.field as Old, to: Function.self)
            let constraints = params.constraints + (params.defaultValue != nil ? [params.defaultValue!] : [])
            s = sumOfArray(.string(name), params.dataType, constraints)
        }
        for unique in uniques { s = s.unique(on: unique) }
        return s.create()
    }
}

extension Array where Element: PGModel {
    @Sendable public func dtos(req: Request) async throws -> [Element.DTO] {
        try await self.asyncMap { try await $0.dto(req: req) }
    }
}

public extension Array {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async throws -> [T] {
        var results = [T]()
        for element in self {
            try await results.append(transform(element))
        }
        return results
    }
}

public extension PostgresRow {
    func datas() -> [String: PostgresData] {
        var row: [String: PostgresData] = [:]
        for cell in self {
            row[cell.columnName] = PostgresData(
                type: cell.dataType,
                typeModifier: 0,
                formatCode: cell.format,
                value: cell.bytes
            )
        }
        return row
    }
}

// MARK: - 以下为内部私有实现

public class PGSQL {
    fileprivate var fieldParamsResolved: [String: [String: String]]  = [:]
    fileprivate var fieldParams: [String: [String: PGFieldParam]] = [:]
    fileprivate var fields: [String: Any] = [:]
    
    public init() {}
    
    fileprivate func getName<K: PGFields>(k: KeyPath<K, PGFieldParam>) -> String {
        let typeName = String(describing: type(of: k).rootType)
        guard
            let resolved = self.fieldParamsResolved[typeName],
            let params = self.fieldParams[typeName],
            let fs = self.fields[typeName] as? K
        else { fatalError(PgErr.fieldDefineError.d("解析失败", 1022, (#file, #line)).description) }
        
        let kk = "\(k)"
        if let name = resolved[kk] { return name }
        for (key, value) in params {
            if value === fs[keyPath: k] {
                self.fieldParamsResolved[typeName]![kk] = key
                return key
            }
        }
        fatalError(PgErr.fieldDefineError.d("解析失败", 1021, (#file, #line)).description)
    }
    
    fileprivate func addFieldPara<K: PGFields>(field: K) -> [String: PGFieldParam] {
        let typeName = String(describing: type(of: field))
        var properties: [String: Any] = [:]
        let mirror = Mirror(reflecting: field)
        for case let (label?, value) in mirror.children {
            properties[label] = value
        }
        guard let props = properties as? [String: PGFieldParam] else { fatalError(PgErr.fieldDefineError.d("解析失败", 1020, (#file, #line)).description) }
        
        self.fields[typeName] = field
        self.fieldParams[typeName] = props
        self.fieldParamsResolved[typeName] = [:]
        
        return props
    }
}
