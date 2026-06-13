import Testing
import Foundation
import Logging
import Puppy
import Logging
@testable import LoggingAdvanced

nonisolated(unsafe) let fileManager = FileManager.default
let homeDir = fileManager.homeDirectoryForCurrentUser
let logDir = homeDir.appendingPathComponent(".opa_logs")

@Suite("日志管理模块-测试", .serialized)
struct LoggingTests {
    
    @Test("puppy usage testing")
    func puppy() async throws {
        let console = ConsoleLogger("com.example.yourapp.console", logLevel: .info)
        let fileURL = logDir.appendingPathComponent("prelog.log")
        let file = try FileLogger(
            "com.example.yourapp.file",
            logLevel: .info,
            fileURL: fileURL,
            filePermission: "600"   // Default permission is "640".
        )

        let puppy = Puppy(loggers: [console, file])
        
        let log = Logger(label: "puppy.usage.testing")
        
        puppy.debug("DEBUG message")  // Will NOT be logged.
        puppy.info("INFO message")    // Will be logged.
        puppy.error("ERROR message")  // Will be logged.
        
        log.debug("DEBUG message common")  // Console 生效，log file 未生效 Will NOT be logged.
        log.info("INFO message common")    // Console 生效，log file 未生效 Will be logged.
        log.error("ERROR message common")  // Console 生效，log file 未生效 Will be logged.
    }
    
    static let setupLogging: Void = {
        let logFile = logDir.appendingPathComponent("opa.log")
        let logFile3 = logDir.appendingPathComponent("errors.log")
        
        let factory = try! LoggingFactory(strategies: [
            .init(label: "console", level: .info, config: .console),
            .init(label: "file", level: .info, config: .file(
                logPrefix: "com.test.module",
                url: logFile
            )),
            .init(label: "file2", level: .trace, config: .file(
                logPrefix: "com.test.module2",
                url: logFile
            )),
            .init(label: "errors", level: .error, config: .file(
                logPrefix: "",
                url: logFile3
            ))
        ])
        
        // 在 bootstrap 之前的 log 不会生效，只会默认在 console 中打印
        let logger = Logger(label: "PreTest")
        logger.notice("Ready to bootstrap")
        
        factory.bootstrap()
    }()

    @Test("反复创建 Log，只会在 Console 和 errors 文件打印")
    func logGenerateOnlyConsole() async throws {
        // 触发静态初始化
        _ = Self.setupLogging
        
        var logger = Logger(label: "Log.Testing")
        logger.logLevel = .trace
        
        logger.trace("不应出现在 Console 或 File 中，因为 Console 闸门高于 trace 等级", metadata: ["ERROR": "!!!"])
        
        logger.info("Hello World", metadata: ["WEW": "HERE"])
        
        let _ = logger.errThrow(
            ErrorTypes2.error3.d("测试错误1", category: .internal).subErr(
                ErrorTypes2.error4.d("SubError", category: .external).subErr(
                    TestingError.Test1
                )
            )
        )
        
        let _ = logger.errThrow(ErrorTypes2.error4.d("SubError", category: .external), metadata: [
            "1": "1"
        ])
        
        var logger2 = Logger(label: "log.with.metadata")
        logger2.logLevel = .trace
        logger2[metadataKey: "meta"] = "data"
        
        logger2.trace("HELLO!", metadata: ["any": "any"])
        
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    @Test("Log Chain 测试，只会在 Console 和 errors 文件打印")
    func logChainGenerateOnlyConsole() async throws {
        // 触发静态初始化
        _ = Self.setupLogging
        
        var logger = Logger(label: "Log.Chain.Testing")
        logger.logLevel = .trace
        
        logger.traces("不应出现在 Console 或 File 中，因为 Console 闸门高于 trace 等级", paras: [
            (["ERROR": "!"], nil),
            (["ERROR": "!!"], nil),
            (["ERROR": "!!!"], "file|1:2"),
            (["ERROR": "!!!!"], nil),
            (["ERROR": "!!!!!"], "file.txt|10:21")
        ])
        
        logger.warnings("warning", paras: [
            (["id": "one"], nil),
            (["id": "two"], nil),
            (["id": "three"], "file|1:2"),
            (["id": "four"], nil),
            (["id": "five"], "file.txt|10:21")
        ])
        
        logger.infos(
            ("info1", ["meta": "H"], nil),
            ("info2", ["meta": "E"], nil),
            ("info3", ["meta": "L"], nil),
            ("info4", ["meta": "L"], nil),
            ("info4", ["meta": "O"], nil),
            id: .init(uuidString: "F441E87E-3B5F-4E0E-BABA-45101BB6456B")!
        )
        
        logger.errors(
            ("error1", ["meta": "H"], nil),
            ("error2", ["meta": "E"], nil),
            ("error3", ["meta": "L"], nil),
            ("error4", ["meta": "L"], nil),
            ("error4", ["meta": "O"], nil),
            id: .init(uuidString: "F441E87E-3B5F-4E0E-BABA-45101BB6456B")!
        )
    }
    
    @Test("反复创建 Log，只会在 File 中打印")
    func logGenerateOnlyFile() async throws {
        // 触发静态初始化
        _ = Self.setupLogging
        
        var logger = Logger(label: "com.test.module")
        logger.logLevel = .trace
        
        logger.trace("不应出现在 Console 或 File 中，因为闸门高于 trace 等级", metadata: ["ERROR": "!!!"])
        
        logger.info("Hello World", metadata: ["WEW": "HERE"])
        
        let _ = logger.errThrow(
            ErrorTypes2.error3.d("测试错误1", category: .internal).subErr(
                ErrorTypes2.error4.d("SubError", category: .external).subErr(
                    TestingError.Test1
                )
            )
        )
        
        let _ = logger.errThrow(ErrorTypes2.error4.d("SubError", category: .external), metadata: [
            "1": "1"
        ])
        
        var logger2 = Logger(label: "log.with.metadata")
        logger2.logLevel = .trace
        logger2[metadataKey: "meta"] = "data"
        
        logger2.trace("HELLO!", metadata: ["any": "any"])
        
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    @Test("Log Chain 测试，只会在 File 打印")
    func logChainGenerateOnlyFile() async throws {
        // 触发静态初始化
        _ = Self.setupLogging
        
        var logger = Logger(label: "com.test.module2")
        logger.logLevel = .trace
        
        logger.traces("不应出现在 Console 中，因为 Console 闸门高于 trace 等级", paras: [
            (["ERROR": "!"], nil),
            (["ERROR": "!!"], nil),
            (["ERROR": "!!!"], "file|1:2"),
            (["ERROR": "!!!!"], nil),
            (["ERROR": "!!!!!"], "file.txt|10:21")
        ])
        
        logger.warnings("warning", paras: [
            (["id": "one"], nil),
            (["id": "two"], nil),
            (["id": "three"], "file|1:2"),
            (["id": "four"], nil),
            (["id": "five"], "file.txt|10:21")
        ])
        
        logger.infos(
            ("info1", ["meta": "H"], nil),
            ("info2", ["meta": "E"], nil),
            ("info3", ["meta": "L"], nil),
            ("info4", ["meta": "L"], nil),
            ("info4", ["meta": "O"], nil),
            id: .init(uuidString: "F441E87E-3B5F-4E0E-BABA-45101BB6456B")!
        )
        
        logger.errors(
            ("error1", ["meta": "H"], nil),
            ("error2", ["meta": "E"], nil),
            ("error3", ["meta": "L"], nil),
            ("error4", ["meta": "L"], nil),
            ("error4", ["meta": "O"], nil),
            id: .init(uuidString: "F441E87E-3B5F-4E0E-BABA-45101BB6456B")!
        )
    }
}

enum TestingError: String, Error {
    case Test1
}
