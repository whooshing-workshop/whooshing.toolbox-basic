import Vapor
import FluentPostgresDriver

public enum PGErrorTypes: String, ErrList {
    public var domain: String { "ToolboxBsc.PgSQL" }
    case fieldDefineError = "Field 定义出现错误"
}

public typealias PgErr = PGErrorTypes
public typealias PGField = PGFieldParam

public struct PGFieldParam: Sendable {
    public let name: String
    public let dataType: DatabaseSchema.DataType
    public let isUnique: Bool
    public let defaultValue: DatabaseSchema.FieldConstraint?
    public let foreign: DatabaseSchema.FieldConstraint?
    public let constraints: [DatabaseSchema.FieldConstraint]
    
    public var key: FieldKey { .string(self.name) }
    
    public func def(_ value: any SQLExpression) -> Self { .init(self, def: .sql(.default(value))) }
    public func def(_ value: String) -> Self { .init(self, def: .sql(.default(value))) }
    public func def<T: BinaryInteger>(_ value: T) -> Self { .init(self, def: .sql(.default(value))) }
    public func def<T: FloatingPoint>(_ value: T) -> Self { .init(self, def: .sql(.default(value))) }
    public func def(_ value: Bool) -> Self { .init(self, def: .sql(.default(value))) }
    
    public func foreign<S: PGModel>(
        _ schema: S.Type,
        space: String? = nil,
        _ field: PGFieldParam,
        onDelete: DatabaseSchema.ForeignKeyAction = .noAction,
        onUpdate: DatabaseSchema.ForeignKeyAction = .noAction
    ) -> Self {
        .init(self, foreign: .references(schema.schema, space: space, .string(field.name), onDelete: onDelete, onUpdate: onUpdate))
    }
    
    public init(
        _ name: String,
        _ dataType: DatabaseSchema.DataType,
        _ isUnique: Bool = false,
        cons constraints: [DatabaseSchema.FieldConstraint] = []
    ) {
        self = Self.init(name: name, dataType: dataType, isUnique: isUnique, defaultValue: nil, foreign: nil, constraints: constraints)
    }
}

public protocol PGFields: Sendable {
    var id: PGFieldParam { get }
    init()
}

public protocol PGModel: Model, AsyncResponseEncodable, Sendable where Self.MIG.DataModel == Self {
    associatedtype DTO: Content & Sendable
    associatedtype MIG: PGMigration
    associatedtype Fields: PGFields
    static var schema: String { get }
    static var fields: Fields { get }
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
}

public extension PGMigration {
    func prepare(on database: Database) -> EventLoopFuture<Void> { Self.tableCreate(DataModel.schema, database: database, fields: DataModel.Fields().params()).map { migrationFinished(on: database) } }
    func revert(on database: Database) -> EventLoopFuture<Void> { database.schema(DataModel.schema).delete() }
    func migrationFinished(on database: Database) {}
    
    private static func tableCreate(_ name: String, database: Database, fields: [PGFieldParam]) -> EventLoopFuture<Void> {
        var s = database.schema(name).id()
        var uniques: [FieldKey] = []
        for params in fields {
            if params.name == "id" { continue }
            if params.isUnique == true { uniques.append(.string(params.name)) }
            typealias Old = (FieldKey, DatabaseSchema.DataType, DatabaseSchema.FieldConstraint...) -> SchemaBuilder
            typealias Function = (FieldKey, DatabaseSchema.DataType, [DatabaseSchema.FieldConstraint]) -> SchemaBuilder
            let fieldConfig = unsafeBitCast(s.field as Old, to: Function.self)
            let constraints = params.constraints + (params.defaultValue != nil ? [params.defaultValue!] : []) + (params.foreign != nil ? [params.foreign!] : [])
            s = fieldConfig(.string(params.name), params.dataType, constraints)
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

public extension FieldProperty {
    convenience init(_ params: PGFieldParam) {
        self.init(key: .string(params.name))
    }
}

public extension TimestampProperty {
    convenience init(
        _ params: PGFieldParam,
        on trigger: TimestampTrigger,
        format: TimestampFormatFactory<Format>
    ) {
        self.init(key: .string(params.name), on: trigger, format: format.makeFormat())
    }
    
    convenience init(_ params: PGFieldParam, on trigger: TimestampTrigger, format: Format) {
        self.init(key: .string(params.name), on: trigger, format: format)
    }
}

public extension TimestampProperty where Format == DefaultTimestampFormat {
    convenience init(_ params: PGFieldParam, on trigger: TimestampTrigger) {
        self.init(key: .string(params.name), on: trigger, format: .default)
    }
}

public extension ParentProperty {
    convenience init(_ params: PGFieldParam) {
        self.init(key: .string(params.name))
    }
}

// MARK: - 以下为内部私有实现

fileprivate extension PGFields {
    func params() -> [PGFieldParam] {
        var properties: [PGFieldParam] = []
        let mirror = Mirror(reflecting: self)
        for case let (_, value) in mirror.children {
            guard let val = value as? PGFieldParam else { fatalError(PgErr.fieldDefineError.d("解析失败", 1020, (#file, #line)).description) }
            properties.append(val)
        }
        return properties
    }
}

private extension PGFieldParam {
    init(_ s: Self, def: DatabaseSchema.FieldConstraint) { self = Self.init(name: s.name, dataType: s.dataType, isUnique: s.isUnique, defaultValue: def, foreign: s.foreign, constraints: s.constraints) }
    init(_ s: Self, foreign: DatabaseSchema.FieldConstraint) { self = Self.init(name: s.name, dataType: s.dataType, isUnique: s.isUnique, defaultValue: s.defaultValue, foreign: foreign, constraints: s.constraints) }
    init(name: String, dataType: DatabaseSchema.DataType, isUnique: Bool, defaultValue: DatabaseSchema.FieldConstraint?, foreign: DatabaseSchema.FieldConstraint?, constraints: [DatabaseSchema.FieldConstraint]) {
        self.name = name
        self.dataType = dataType
        self.constraints = constraints
        self.defaultValue = defaultValue
        self.foreign = foreign
        self.isUnique = isUnique
    }
}
