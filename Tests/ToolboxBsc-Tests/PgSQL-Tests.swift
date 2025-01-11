import Testing
@testable import ToolboxBsc
import Foundation
import Vapor
import FluentPostgresDriver

@Suite("PostgreSQL 数据定义测试")
struct PGSQLTests {
    
}


nonisolated(unsafe) let pgSQL = PGSQL()

final class User: PGModel, @unchecked Sendable {

    static var pgsql: ToolboxBsc.PGSQL { pgSQL }
    static let schema = "asdfasdf"
    
    struct Fields: PGFields {
        let id = PGFieldParam(.bool)
        let email = PGFieldParam(.string)
        let age = PGFieldParam(.int)
    }
    
    @ID(key: .id)                                       var id: UUID?
    @Field(key: n(\Fields.email))                       var email: String?
    @Field(key: n(\Fields.age))                         var age: Int?

    struct DTO: Content, Sendable {
        let id: UUID
        let email: String
    }
    
    init() {}
}

extension User {
    
    @Sendable func dto(req: Request) throws -> DTO { fatalError() }
    
    struct MIG: PGMigration, @unchecked Sendable { typealias DataModel = User }
}
