import Foundation
import Logging
import Puppy

/// 日志分流策略
/// 可配置自由的 ConsoleLog
/// 或是根据 Logger label 决定目标 Log 文件
public struct LoggerStrategy: Sendable {
    /// 该分流策略的标签，用于区分不同的策略，也会体现在输出目标中(Console/File)
    public let label: String
    /// 策略层阀门
    /// 记录所有高于该等级的 log，实际记录的日志取决于具体 Logger 所提供的日志
    public let level: Logger.Level
    /// 该日志器的配置
    public let config: Config
    
    /// 日志分流的配置
    @frozen
    public enum Config: Sendable {
        /// 控制台输出，一般用于开发环境
        case console
        /// 文件轮转输出，若文件不存在会自动创建，包括中间文件夹
        ///
        /// - parameters:
        ///     match: 针对不同的 Log Label 前缀分流，返回 true 表示命中
        ///     directory: 目标目录的路径，日志文件将存在该目录之下，包括所有轮转备份日志文件
        ///     name: 日志文件的名称，轮转备份文件会自动增加后缀
        ///     filePermission: 目标文件的文件权限
        ///     delegate: 轮转代理
        case file(
            match: @Sendable (String) -> Bool,
            directory: URL,
            name: String,
            filePermission: String = "640",
            delegate: FileRotationLoggerDelegate? = nil
        )
        
        /// 文件轮转输出，若文件不存在会自动创建，包括中间文件夹
        ///
        /// - parameters:
        ///     logPrefix: 针对不同的 Log Label 前缀分流
        ///     directory: 目标目录的路径，日志文件将存在该目录之下，包括所有轮转备份日志文件
        ///     name: 日志文件的名称，轮转备份文件会自动增加后缀
        ///     filePermission: 目标文件的文件权限
        ///     delegate: 轮转代理
        public static func file(
            logPrefix: String,
            directory: URL,
            name: String,
            filePermission: String = "640",
            delegate: FileRotationLoggerDelegate? = nil
        ) -> Self {
            .file(
                match: { $0.hasPrefix(logPrefix) },
                directory: directory,
                name: name,
                filePermission: filePermission,
                delegate: delegate
            )
        }
    }
    
    @usableFromInline
    let puppy: Puppy
    
    /// 初始化 Console 日志分流策略
    ///
    /// - parameters:
    ///     label: 该分流策略的标签，用于区分不同的策略，也会体现在输出目标中(Console/File)
    ///     level: 策略层阀门
    @inlinable
    public init(
        label: String,
        level: Logger.Level = .info
    ) {
        self.label = label
        self.level = level
        self.config = .console
        
        var puppy = Puppy()
        
        puppy.add(ConsoleLogger(
            label,
            logLevel: level.toPuppy(),
            logFormat: LoggingFormatter()
        ))
        
        self.puppy = puppy
    }
    
    /// 初始化日志分流策略
    ///
    /// - parameters:
    ///     label: 该分流策略的标签，用于区分不同的策略，也会体现在输出目标中(Console/File)
    ///     level: 策略层阀门
    ///     config: 该日志器的配置
    @inlinable
    public init(
        label: String,
        level: Logger.Level = .info,
        config: Config
    ) throws {
        self.label = label
        self.level = level
        self.config = config
        
        var puppy = Puppy()
        
        switch config {
        case .console:
            puppy.add(ConsoleLogger(
                label,
                logLevel: level.toPuppy(),
                logFormat: LoggingFormatter()
            ))
        case .file(_, let directory, let name, let filePermission, let delegate):
            try puppy.add(FileRotationLogger(
                label,
                logLevel: level.toPuppy(),
                logFormat: LoggingFormatter(),
                fileURL: directory.appendingPathComponent(name),
                filePermission: filePermission,
                rotationConfig: .init(      // 设置：每个文件最大 10MB，保留最近 20 个备份，总共占用约 240MB 空间
                    suffixExtension: .date_uuid,
                    maxFileSize: 10 * 1024 * 1024,
                    maxArchivedFilesCount: 20
                ),
                delegate: delegate
            ))
        }
        
        self.puppy = puppy
    }
    
    @inlinable
    func conform(to label: String) -> Bool {
        switch config {
        case .console: true
        case .file(let match, _, _, _, _): match(label)
        }
    }
}
