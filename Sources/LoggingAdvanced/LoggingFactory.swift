import Puppy
import Foundation

/// 日志工厂，用于配置和初始化日志系统。
public struct LoggingFactory: Sendable {
    @usableFromInline
    var puppy = Puppy()
    
    /// 初始化一个新的日志工厂。
    @inlinable
    public init() {}
    
    /// 启动日志系统。
    ///
    /// 调用此方法后，SwiftLog 的 `LoggingSystem` 将被初始化。
    @inlinable
    public func bootstrap() {
        LoggingSystem.bootstrap { label in
            PuppyLogHandler(label: label, puppy: self.puppy)
        }
    }
    
    /// 添加一个控制台日志记录器。
    ///
    /// - Parameter label: 日志记录器的标签。
    @inlinable
    public mutating func add(
        _ label: String
    ) {
        puppy.add(ConsoleLogger(
            label,
            logLevel: .trace,
            logFormat: LoggingFormatter()
        ))
    }
    
    /// 添加一个文件日志记录器，支持日志轮转。
    ///
    /// - Parameters:
    ///   - label: 日志记录器的标签。
    ///   - fileURL: 日志文件的路径。
    ///   - filePermission: 文件权限，默认为 "640"。
    ///   - delegate: 文件轮转代理。
    /// - Throws: 如果文件创建失败，抛出错误。
    @inlinable
    public mutating func add(
        _ label: String,
        fileURL: URL,
        filePermission: String = "640",
        delegate: FileRotationLoggerDelegate? = nil
    ) throws {
        try puppy.add(FileRotationLogger(
            label,
            logLevel: .trace,
            logFormat: LoggingFormatter(),
            fileURL: fileURL,
            filePermission: filePermission,
            rotationConfig: .init(      // 设置：每个文件最大 10MB，保留最近 20 个备份，总共占用约 240MB 空间
                suffixExtension: .date_uuid,
                maxFileSize: 10 * 1024 * 1024,
                maxArchivedFilesCount: 20
            ),
            delegate: delegate
        ))
    }
}
