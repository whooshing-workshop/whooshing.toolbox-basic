import Testing
import Foundation
import Logging
@testable import LoggingAdvanced

@Suite("日志管理模块-测试", .serialized)
struct LoggingTests {
    static let setupLogging: Void = {
        var factory = LoggingFactory()
        
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let logDir = homeDir.appendingPathComponent(".opa_logs")
        let logFile = logDir.appendingPathComponent("opa.log")
        if !fileManager.fileExists(atPath: logDir.path) {
            try? fileManager.createDirectory(at: logDir, withIntermediateDirectories: true, attributes: [
                .posixPermissions: 0o700
            ])
        }
        
        factory.add("Console.Testing")
        try? factory.add("File.Testing", fileURL: logFile)
        factory.bootstrap()
    }()

    @Test("反复创建 Log")
    func logGenerate() async throws {
        // 触发静态初始化
        _ = Self.setupLogging
        
        let logger = Logger(label: "Log.Testing")
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
}

enum TestingError: String, Error {
    case Test1
}
