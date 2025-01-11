import Testing
@testable import ToolboxBsc
import Foundation
import Vapor
import Fluent
@preconcurrency import FluentPostgresDriver

@Suite("PostgreSQL 数据定义测试", .serialized)
struct PGSQLTests {
    
    func start() async -> (app: Application?, db: PostgresDatabase?) {
        let app = try! await Application.make(.testing)
        do {
            app.databases.use(
                .postgres(
                    configuration: .init(
                        hostname: "localhost",
                        port: 5432,
                        username: "testing",
                        password: "testing",
                        database: "testing",
                        tls: .disable
                    )
                ),
                as: .psql
            )
            app.migrations.add(User.MIG())
            try await app.autoMigrate()
            return (app, app.db as? PostgresDatabase)
        } catch {
            try! await app.asyncShutdown()
            return (nil, nil)
        }
    }
    
    @Test("测试 PGFieldParam 初始化")
    func testPGFieldParamInitialization() {
        let param = PGFieldParam("email", .string, true)
        #expect(param.name == "email")
        #expect(param.isUnique == true)
    }

    @Test("测试 User 模型字段定义")
    func testUserFieldsDefinition() {
        let fields = User.Fields()
        #expect(fields.id.name == "id")
        #expect(fields.email.name == "email")
        #expect(fields.age.name == "age")
    }
    
    @Test("测试 SQL 语句运行") func testSQLStatement() async throws {
        let res = await start()
        guard let app = res.app, let db = res.db else { try #require(Bool(false), "数据库连接失败"); return }
        
        defer { Task { if !app.didShutdown { try! await app.asyncShutdown() } } }
        
        do {
            let res = try await db.query("DROP SCHEMA public CASCADE").get()
            #expect(res.metadata.command == "DROP SCHEMA")
            let res2 = try await db.query("CREATE SCHEMA public").get()
            #expect(res2.metadata.command == "CREATE SCHEMA")
            try #require(await app.asyncShutdown())
        } catch let err {
            try #require(Bool(false), "\(String(reflecting: err))")
        }
    }
    
    @Test("检查所创建的表结构") func testPropertyWrappers() async throws {
        let res = await start()
        guard let app = res.app, let db = res.db else { try #require(Bool(false), "数据库连接失败"); return }
        
        defer { Task { if !app.didShutdown { try! await app.asyncShutdown() } } }
        
        let user1 = User(id: .init(), email: "test1@test.com", age: 24)
        let user2 = User(id: .init(), email: "test2@test.com", age: 24)
        let id3 = UUID()
        let id4 = UUID()
        let user3 = User(id: id3)
        let user4 = User(id: id4, age: 45)
        user4.email = nil
        
        do {
            try await user1.save(on: db as! any Database)
            do {
                try await user2.save(on: db as! any Database)
                #expect(Bool(false), "唯一约束设置失败")
            } catch {
                try #require(await user3.save(on: db as! any Database))
                let res = try #require(await User.query(on: db as! Database).filter(\User.$id == id3).first())
                try #require(res.email != nil)
                try #require(res.age != nil)
                #expect(res.email! == "null@null.com")
                #expect(res.age! == 30)
                do {
                    try await user4.save(on: db as! Database)
                    #expect(Bool(false), "非空约束设置失败")
                } catch {
                    #expect(Bool(true))
                }
            }
        } catch let err {
            try #require(Bool(false), "\(String(reflecting: err))")
        }
    }
    
}

final class User: PGModel, @unchecked Sendable {

    static let schema = "users"
    
    struct Fields: PGFields {
        let id = PGFieldParam("id", .bool)
        let email = PGFieldParam("email", .string, cons: [.sql(.default("null@null.com")), .required])
        let age = PGFieldParam("age", .int, true).def(30)
        let createdAt = PGFieldParam("create_at", .string, true)
        let updateAt = PGFieldParam("update_at", .string).def("2001-02-27")
    }
    
    static let fields = Fields()
    
    @ID(key: .id)                                                   var id: UUID?
    @Field(fields.email)                                            var email: String?
    @Field(fields.age)                                              var age: Int?
    @Timestamp(fields.createdAt, on: .create,
               format: .iso8601(withMilliseconds: true))            var createdAt: Date?
    @Timestamp(fields.updateAt, on: .update,
               format: .iso8601(withMilliseconds: true))            var updatedAt: Date?

    struct DTO: Content, Sendable {
        let id: UUID
        let email: String
    }
    
    @Sendable func dto(req: Request) throws -> DTO { fatalError() }
    
    struct MIG: PGMigration, Sendable { typealias DataModel = User }
}

extension User {
    
    convenience init(id: UUID, email: String? = nil, age: Int? = nil) {
        self.init()
        self.id = id
        if email != nil { self.email = email }
        if age != nil { self.age = age }
    }
    
}
