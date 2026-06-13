import Foundation
import Logging
import Puppy

public struct LoggerStrategy: Sendable {
    public let label: String
    public let level: Logger.Level      // 记录所有高于该等级的 log，实际记录的日志取决于具体 Logger 所提供的日志
    public let config: Config
    
    @frozen
    public enum Config: Sendable {
        case console
        case file(
            logPrefix: String,          // 针对不同的 Log Label 前缀分流
            url: URL,
            filePermission: String = "640",
            delegate: FileRotationLoggerDelegate? = nil
        )
    }
    
    @usableFromInline
    let puppy: Puppy
    
    @inlinable
    init(
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
        case .file(_, let url, let filePermission, let delegate):
            try puppy.add(FileRotationLogger(
                label,
                logLevel: level.toPuppy(),
                logFormat: LoggingFormatter(),
                fileURL: url,
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
        case .file(let logPrefix, _, _, _): label.hasPrefix(logPrefix)
        }
    }
}

public struct LoggerHandler: LogHandler {
    /// var logger = Logger(label: "woo.filestorage")
    /// logger.logLevel = .warning // 用于业务层直接修改 logger 的级别
    /// 业务层闸门，对业务层的 Log 输出等级进行约束
    /// 策略层另有一道闸门
    public var logLevel: Logger.Level = .info
    /// 业务层 Metadata 存储器，用于业务层直接修改 metadata
    public var metadata: Logger.Metadata = [:]
    
    public let label: String
    public let strategies: [LoggerStrategy]
    
    @inlinable
    public init(
        label: String,
        strategies: [LoggerStrategy]
    ) {
        self.label = label
        self.strategies = strategies
    }
    
    @inlinable
    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get {
            return metadata[key]
        }
        set(newValue) {
            metadata[key] = newValue
        }
    }
    
    @inlinable
    public func log(event: LogEvent) {
        // 闸门一：最外层 Handler 自身的全局最低防线（外界调用 logger.logLevel 修改的结果）
        // 若业务层闸门等级低于策略层闸门等级，则无需输出该 log
        guard event.level >= self.logLevel else { return }
        let mergedMetadata = mergedMetadata(event.metadata)
        let metadata = !mergedMetadata.isEmpty ? "\(mergedMetadata)" : ""
        let swiftLogInfo = ["label": label, "source": event.source, "metadata": metadata]
        for strategy in strategies {
            // 只有当前日志级别，大于或等于该策略配置指定的级别时，才允许输出！
            guard event.level >= strategy.level else { continue }
            strategy.puppy.logMessage(
                event.level.toPuppy(),
                message: "\(event.message)",
                tag: "swiftlog",
                function: event.function,
                file: event.file,
                line: event.line,
                swiftLogInfo: swiftLogInfo
            )
        }
    }
    
    @usableFromInline
    func mergedMetadata(_ metadata: Logger.Metadata?) -> Logger.Metadata {
        var mergedMetadata: Logger.Metadata
        if let metadata = metadata {
            mergedMetadata = self.metadata.merging(metadata, uniquingKeysWith: { _, new in new })
        } else {
            mergedMetadata = self.metadata
        }
        return mergedMetadata
    }
}

extension Logger.Level {
    @inlinable
    func toPuppy() -> LogLevel {
        switch self {
        case .trace:
            return .trace
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            return .notice
        case .warning:
            return .warning
        case .error:
            return .error
        case .critical:
            return .critical
        }
    }
}
