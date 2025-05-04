import FluentPostgresDriver
import ErrorHandle

/// 数据库模块所有可能出现的错误
public enum PGErrorTypes: String, ErrList {
    public var domain: String { "ToolboxBsc.PgSQL" }
    case dataBaseError = "数据库出现问题"
    case fieldDefineError = "Field 定义出现错误"
    case dataBaseTdeError = "数据库 TDE 加密失败"
}

public typealias PgErr = PGErrorTypes
public typealias PGField = PGFieldParam

/**
    #### 描述数据库表字段信息
    
    与数据库中的表字段一一对应，描述字段的名称，数据类型，是否唯一，外键等等约束，支持使用追加的方式设置约束：
    
    以下该示例定义了一个名为 user_name 的字段，其数据类型为 string，且不允许重复(即唯一约束)：
    ``` swift
    // PGField 是 PGFieldParam 的别名
    let userName = PGField("user_name", .string, true)
    ```
    若你想要为其设置默认值：
    ``` swift
    let userName = PGField("user_name", .string, true).def("默认名称")
    ```
    或者设置与表 role 的 id 字段建立外键关系，则：
    ``` swift
    // 表 "role" 的定义
    final class Role: PGModel, @unchecked Sendable {
        static let name = "role"

        struct Fields: PGFields {
            let id = PGField("id", .uuid)
            let admin = PGField("admin", .string)

            // ... 该表 role 的其他字段
        }
        // ...
    }

    // 表 "users" 的定义
    final class User: PGModel, @unchecked Sendable {

        static let name = "users"
        
        struct Fields: PGFields {
            let id = PGField("id", .uuid)
            let email = PGField("email", .string)
            // 建立外键关系
            let foreign = PGField("foreign", .uuid).foreign(Role.self, Role.fields.id)
            // 当然，你也可以为该键建立多个外键，继续往后追加即可
            // let foreign = PGField("foreign", .uuid).foreign(Role.self, Role.fields.id).foreign(..., ...).foreign(..., ...) ...
        }
        // ...
    }
    ```
    若还要设置其他约束，可以进一步使用 cons() 追加。下面这个例子增加了一个额外的非空约束：
    ``` swift
    // 注意到，最后一个参数是一个数组，因此你可以放置任意数量的约束。
    // 所有支持的约束列表见 DatabaseSchema.FieldConstraint 的定义
    let userName = PGField("user_name", .string, true).cons([.require])
    ```
*/
public struct PGFieldParam: Sendable {
    /// 字段的名称
    public let name: String
    /// 字段的数据类型
    public let dataType: DatabaseSchema.DataType
    /// 该阻断是否唯一？
    public let isUnique: Bool
    /// 该字段的默认值约束
    public let defaultValue: DatabaseSchema.FieldConstraint?
    /// 该字段的外建约束，通过 `foreign(_)` 函数增加外键
    public let foreigns: [DatabaseSchema.FieldConstraint]
    /// 其他约束，所有支持的约束列表见 DatabaseSchema.FieldConstraint 的定义
    public let constraints: [DatabaseSchema.FieldConstraint]
    
    /// 返回 FieldKey，用于在 @Field 中引用。不过几乎可以不用该计算属性。
    public var key: FieldKey { .string(self.name) }
    
    /// 为字段设置默认值
    /// 
    /// - 参数
    ///     - value：即要设置的默认值，可以为多种类型。
    /// - 返回：被设置了默认值的新字段实例
    /// ``` swift
    /// let field = PGField(..., ...)
    /// let newField = field.def(100)
    /// // 或直接追加设置
    /// let field2 = PGField(..., ...).def(100)
    /// ```
    public func def(_ value: any SQLExpression) -> Self { .init(self, def: .sql(.default(value))) }
    /// 为字段设置默认值
    public func def(_ value: String) -> Self { .init(self, def: .sql(.default(value))) }
    /// 为字段设置默认值
    public func def<T: BinaryInteger>(_ value: T) -> Self { .init(self, def: .sql(.default(value))) }
    /// 为字段设置默认值
    public func def<T: FloatingPoint>(_ value: T) -> Self { .init(self, def: .sql(.default(value))) }
    /// 为字段设置默认值
    public func def(_ value: Bool) -> Self { .init(self, def: .sql(.default(value))) }
    
    /// 为字段设置外键
    /// 
    /// - 参数
    ///     - model：要创建外键的目标数据表模型
    ///     - space：可选参数，表示命名空间或特定的表范围。如果 schema 中存在嵌套结构或多级分隔，space 可以帮助进一步细化表的范围
    ///     - field：目标数据表模型的目标字段
    ///     - onDelete：当外键约束的父记录被删除时，触发的动作(如 CASCADE)
    ///     - onUpdate：当外键约束的父记录被更新时，触发的动作(如 RESTRICT)
    /// - 返回：更新了外键约束的新字段实例
    /// 
    /// 可以像下面一样，多次叠加该函数以为一个字段创建多个外键引用，但这是不推荐的。
    /// ``` swift
    /// let field = PGField(..., ...).foreign(User.self, User.fields.id).foreign(Infos.self, Infos.fields.id).foreign(...)...
    /// ```
    public func foreign<S: PGModel>(
        _ model: S.Type,
        space: String? = nil,
        _ field: PGFieldParam,
        onDelete: DatabaseSchema.ForeignKeyAction = .noAction,
        onUpdate: DatabaseSchema.ForeignKeyAction = .noAction
    ) -> Self {
        .init(self, foreign: .references(model.schema, space: space, .string(field.name), onDelete: onDelete, onUpdate: onUpdate))
    }

    /// 为字段设置其他约束
    /// 
    /// - 参数
    ///     - constraints：约束数组，即你要添加的约束
    /// - 返回：更新了约束的新字段实例
    /// 
    /// 可进行追加设置，而叠加只会覆盖：
    /// ``` swift
    /// // 单次追加
    /// let field = PGField(..., ...).cons([..., ...])
    /// // 叠加，只会采用最后一个约束设置
    /// let field = PGField(..., ...).cons([..., ...]).cons([..., ...]).cons([..., ...])
    /// ```
    public func cons(_ constraints: [DatabaseSchema.FieldConstraint]) -> Self { .init(self, constraints: constraints) }
    
    /// 初始化字段，并设置基本信息
    /// 
    /// - 参数
    ///     - name：字段名称
    ///     - dataType：字段数据类型，完整的定义请见 DatabaseSchema.DataType 的定义
    ///     - isUnique：该字段是否唯一(即其中的值是否可以重复)？
    /// - 返回：包括以上基本信息的字段实例
    public init(
        _ name: String,
        _ dataType: DatabaseSchema.DataType,
        _ isUnique: Bool = false
    ) {
        self = Self.init(name: name, dataType: dataType, isUnique: isUnique, defaultValue: nil, foreigns: [], constraints: [])
    }
}

/**
    #### 实现该协议，以创建表的字段列表

    可以在你的自定义类型中列出所有的字段详细配置，使得数据库可以得知如何生成和存取数据。你始终应当为你的表中设置 `id` 字段，这非常重要且强制要求

    -----
    ### 创建字段配置列表
    创建一个结构体，并实现该协议，列出所有的字段。以下示例列出了 5 个字段，分别是 "id", "email", "age", "create_at", "update_at"，并为其详细配置了参数
    ```
    struct Fields: PGFields {
        // id 索引字段，每个表中都应当有
        let id = PGField("id", .uuid)
        // 设置了默认值 null@null.com 并非空
        let email = PGField("email", .string).cons([.sql(.default("null@null.com")), .required])
        // 设置了默认值 30，且唯一(不允许重复)
        let age =  ("age", .int, true).def(30)
        // 仅设置了唯一约束
        let createdAt = PGField("create_at", .string, true)
        // 仅设置了默认值
        let updateAt = PGField("update_at", .string).def("2001-02-27")
    }
    ```
    关于字段的具体配置，可见 `PGField` 的定义，`PGField` 实际上是 `PGFieldParam` 的别名
*/
public protocol PGFields: Sendable {
    
    /// 指定该表是否应当使用 tde 加密，默认为 true
    static var tdeEncrypt: Bool { get }
    
    /// id 索引字段，每个表必须设置
    var id: PGFieldParam { get }
    init()
}

/**
    #### 实现该协议以创建数据库表数据模型

    一个 PGModel 类型对应着数据库中的一个表，你需要集成该协议，并完成一系列设置以创建你的表结构模型

    -----
    ### 创建表数据模型
    以下列出了一个完整的 `users` 数据表的数据模型
    ``` swift
    // 实现协议 PGModel
    final class User: PGModel, @unchecked Sendable {

        // 设置表的名称，请注意不要与其他类型的表冲突
        static let name = "users"

        // 定义该表的所有字段信息，详见 PGFields 协议
        struct Fields: PGFields {
            let id = PGField("id", .uuid)
            let email = PGField("email", .string).cons([.sql(.default("null@null.com")), .required])
            let age = PGField("age", .int, true).def(30)
            let createdAt = PGField("create_at", .string, true)
            let updateAt = PGField("update_at", .string).def("2001-02-27")
        }
        
        // 生成字段信息实例
        static let fields = Fields()
        
        // 以下关于键值绑定的 @ID, @Field, @Timestamp 等等属性包装器，可参见 [Vapor 官方文档](https://docs.vapor.codes/fluent/model/)

        // 将数据库表 users 中的 id 字段绑定到该模型的 id 属性
        @ID(key: .id)                                                   var id: UUID?
        // 将数据库表 users 中的 email 字段绑定到该模型的 email 属性
        @Field(fields.email)                                            var email: String?
        // 将数据库表 users 中的 age 字段绑定到该模型的 age 属性
        @Field(fields.age)                                              var age: Int?
        // 将数据库表 users 中的 create_at 字段绑定到该模型的 createAt 属性
        @Timestamp(fields.createdAt, on: .create,
                format: .iso8601(withMilliseconds: true))               var createdAt: Date?
        // 将数据库表 users 中的 update_at 字段绑定到该模型的 updateAt 属性
        @Timestamp(fields.updateAt, on: .update,
                format: .iso8601(withMilliseconds: true))               var updatedAt: Date?
        
        // 数据库表结构生成和迁移，负责与数据库交互，进行表创建，迁移，恢复等等交涉
        // 你需要确保 typealias DataModel = User 中，DataModel 正确地指向你的表数据模块
        // 在此例中指向为 User
        struct MIG: PGMigration, Sendable { typealias DataModel = User }
    }

    // 以上便完全实现了 PGModel 协议
    // 若你愿意，你可以添加一些其他的功能
    extension User {
        convenience init(id: UUID, email: String? = nil, age: Int? = nil) {
            self.init()
            self.id = id
            if email != nil { self.email = email }
            if age != nil { self.age = age }
        }
    }
    ```
    以上创建的表结构等效于使用下面 SQL 语句创建：
    ``` SQL
    CREATE TABLE IF NOT EXISTS public.users (
        id uuid GENERATED BY DEFAULT AS IDENTITY NOT NULL,
        email text GENERATED BY DEFAULT AS IDENTITY DEFAULT 'null@null.com'::text NOT NULL,
        age bigint GENERATED BY DEFAULT AS IDENTITY DEFAULT 30,
        create_at text GENERATED BY DEFAULT AS IDENTITY,
        update_at text GENERATED BY DEFAULT AS IDENTITY DEFAULT '2001-02-27'::text,
        PRIMARY KEY(id)
    );
    ```
*/
public protocol PGModel: Model, Sendable where Self.MIG.DataModel == Self {
    associatedtype MIG: PGMigration
    associatedtype Fields: PGFields
    /// 表的名称
    static var name: String { get }
    /// 表字段列表的实例
    static var fields: Fields { get }
}

/**
    #### 实现该协议，以进行表结构生成和迁移

    你不需要实现它的所有细节，实际上你的实现非常简单。见 `PGModel` 的解释中 `PGMigration` 的用法

    你可以覆写 `migrationFinished(on:)` 函数来获取表结构生成完成的通知，该函数默认不进行任何动作
*/
public protocol PGMigration: Migration, Sendable {
    associatedtype DataModel: PGModel
    /// 你可以覆写 `migrationFinished(on:)` 函数来获取表结构生成完成的通知，该函数默认不进行任何动作
    func migrationFinished(on database: Database)
}

// MARK: - 以下为协议扩展实现

extension PostgresQueryResult: @unchecked @retroactive Sendable {}

public extension PGMigration {
    func prepare(on database: Database) -> EventLoopFuture<Void> { Self.tableCreate(DataModel.schema, database: database, fields: DataModel.Fields().params(), encrypt: DataModel.Fields.tdeEncrypt).map { migrationFinished(on: database) } }
    func revert(on database: Database) -> EventLoopFuture<Void> { database.schema(DataModel.schema).delete() }
    func migrationFinished(on database: Database) {}
    
    private static func tableCreate(_ name: String, database: Database, fields: [PGFieldParam], encrypt: Bool) -> EventLoopFuture<Void> {
        var s = database.schema(name).id()
        var uniques: [FieldKey] = []
        for params in fields {
            if params.name == "id" { continue }
            if params.isUnique == true { uniques.append(.string(params.name)) }
            typealias Old = (FieldKey, DatabaseSchema.DataType, DatabaseSchema.FieldConstraint...) -> SchemaBuilder
            typealias Function = (FieldKey, DatabaseSchema.DataType, [DatabaseSchema.FieldConstraint]) -> SchemaBuilder
            let fieldConfig = unsafeBitCast(s.field as Old, to: Function.self)
            let constraints = params.constraints + (params.defaultValue != nil ? [params.defaultValue!] : []) + params.foreigns
            s = fieldConfig(.string(params.name), params.dataType, constraints)
        }
        for unique in uniques { s = s.unique(on: unique) }

        return s.create().flatMap {
            guard encrypt == true else { return database.eventLoop.makeSucceededVoidFuture() }
            guard let db = database as? PostgresDatabase else { return database.eventLoop.future(error: PgErr.dataBaseError.d("数据库类型不是 PostgreSQL", 1023, (#file, #line))) }
            return db.query("ALTER TABLE \(name) SET ACCESS METHOD tde_heap;").flatMapError { err in
                database.schema(name).delete().flatMapError { return database.eventLoop.future(error: PgErr.dataBaseTdeError.d("恢复失败", 1025, (#file, #line)).subErr($0))}
                .flatMap { _ in database.eventLoop.future(error: PgErr.dataBaseTdeError.d("加密未成功，已删除该表格", 1024, (#file, #line)).subErr(err)) }
            }.transform(to: ())
        }
    }
}

public extension PGFields {
    static var tdeEncrypt: Bool { true }
}

public extension PGModel {
    static var schema: String { Self.name }
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
        format: TimestampFormatFactory<Format> = .iso8601(withMilliseconds: true)
    ) {
        self.init(key: .string(params.name), on: trigger, format: format.makeFormat())
    }
    
    convenience init(_ params: PGFieldParam, on trigger: TimestampTrigger, format: Format) {
        self.init(key: .string(params.name), on: trigger, format: format)
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
    init(_ s: Self, def: DatabaseSchema.FieldConstraint) { self = Self.init(name: s.name, dataType: s.dataType, isUnique: s.isUnique, defaultValue: def, foreigns: s.foreigns, constraints: s.constraints) }
    init(_ s: Self, foreign: DatabaseSchema.FieldConstraint) { self = Self.init(name: s.name, dataType: s.dataType, isUnique: s.isUnique, defaultValue: s.defaultValue, foreigns: s.foreigns + [foreign], constraints: s.constraints) }
    init(_ s: Self, constraints: [DatabaseSchema.FieldConstraint]) { self = Self.init(name: s.name, dataType: s.dataType, isUnique: s.isUnique, defaultValue: s.defaultValue, foreigns: s.foreigns, constraints: constraints) }
    init(name: String, dataType: DatabaseSchema.DataType, isUnique: Bool, defaultValue: DatabaseSchema.FieldConstraint?, foreigns: [DatabaseSchema.FieldConstraint], constraints: [DatabaseSchema.FieldConstraint]) {
        self.name = name
        self.dataType = dataType
        self.constraints = constraints
        self.defaultValue = defaultValue
        self.foreigns = foreigns
        self.isUnique = isUnique
    }
}
