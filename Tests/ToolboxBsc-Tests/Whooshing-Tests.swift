import Testing
@testable import Whooshing
import Foundation

@Suite("Whooshing 工具测试")
struct WhooshingTests {
    
    @Test("测试环境变量读取") func testEnvironmentDetect() async throws {
        let project = try #require(Woo.Env.Project.parse(prefix: Woo.EnvBase) { key in [
            "WHOOSHING_API_SERVICE_NAME": "Testing Project",
            "WHOOSHING_API_SERVICE_DOMAIN": "testing.whooshing.space",
            "WHOOSHING_API_SERVICE_DB_COUNT": "3",
            "WHOOSHING_API_SERVICE_DB_1_NAME": "testdb",
            "WHOOSHING_API_SERVICE_DB_1_PORT": "5432",
            "WHOOSHING_API_SERVICE_DB_2_NAME": "testdb_2",
            "WHOOSHING_API_SERVICE_DB_2_PORT": "6000",
            "WHOOSHING_API_SERVICE_DB_3_NAME": "testdb_3",
            "WHOOSHING_API_SERVICE_DB_3_PORT": "7000",
        ][key] })
        #expect(project.name == "Testing Project")
        #expect(project.domain == "testing.whooshing.space")
        #expect(project.databases.count == 3)
        #expect(project.databases[0].name == "testdb")
        #expect(project.databases[0].port == 5432)
        #expect(project.databases[1].name == "testdb_2")
        #expect(project.databases[1].port == 6000)
        #expect(project.databases[2].name == "testdb_3")
        #expect(project.databases[2].port == 7000)
    }
    
    @Test("测试环境变量读取2") func testEnvironmentDetect2() async throws {
        let project = try #require(Woo.Env.Project.parse(prefix: Woo.EnvBase) { key in [
            "WHOOSHING_API_SERVICE_NAME": "Testing Project",
            "WHOOSHING_API_SERVICE_DB_COUNT": "3",
            "WHOOSHING_API_SERVICE_DB_1_NAME": "testdb",
            "WHOOSHING_API_SERVICE_DB_1_PORT": "5432",
            "WHOOSHING_API_SERVICE_DB_2_NAME": "testdb_2",
            "WHOOSHING_API_SERVICE_DB_2_PORT": "6000",
            "WHOOSHING_API_SERVICE_DB_3_NAME": "testdb_3",
            "WHOOSHING_API_SERVICE_DB_3_PORT": "7000",
        ][key] })
        #expect(project.name == "Testing Project")
        #expect(project.domain == nil)
        #expect(project.databases.count == 3)
        #expect(project.databases[0].name == "testdb")
        #expect(project.databases[0].port == 5432)
        #expect(project.databases[1].name == "testdb_2")
        #expect(project.databases[1].port == 6000)
        #expect(project.databases[2].name == "testdb_3")
        #expect(project.databases[2].port == 7000)
    }
    
    @Test("测试环境变量读取3") func testEnvironmentDetect3() async throws {
        do {
            let _ = try #require(Woo.Env.Project.parse(prefix: Woo.EnvBase) { key in [
                "WHOOSHING_API_SERVICE_NAME": "Testing Project",
                "WHOOSHING_API_SERVICE_DB_COUNT": "3",
                "WHOOSHING_API_SERVICE_DB_1_NAME": "testdb",
                "WHOOSHING_API_SERVICE_DB_1_PORT": "5432",
                "WHOOSHING_API_SERVICE_DB_2_NAME": "testdb_2",
                "WHOOSHING_API_SERVICE_DB_2_PORT": "6000",
                "WHOOSHING_API_SERVICE_DB_3_NAME": "testdb_3",
            ][key] })
            #expect(Bool(false), "错误的环境变量仍然成功运行了")
        } catch {
            #expect(Bool(true))
        }
    }
    
    @Test("测试环境变量读取4") func testEnvironmentDetect4() async throws {
        do {
            let _ = try #require(Woo.Env.Project.parse(prefix: Woo.EnvBase) { key in [
                "WHOOSHING_API_SERVICE_NAME": "Testing Project",
                "WHOOSHING_API_SERVICE_DB_COUNT": "3",
                "WHOOSHING_API_SERVICE_DB_1_NAME": "testdb",
                "WHOOSHING_API_SERVICE_DB_1_PORT": "5432",
                "WHOOSHING_API_SERVICE_DB_2_NAME": "testdb_2",
                "WHOOSHING_API_SERVICE_DB_2_PORT": "6000",
                "WHOOSHING_API_SERVICE_DB_3_NAME": "testdb_3",
                "WHOOSHING_API_SERVICE_DB_3_PORT": "HELLOWORLD!",
            ][key] })
            #expect(Bool(false), "错误的环境变量仍然成功运行了")
        } catch {
            #expect(Bool(true))
        }
    }
}
