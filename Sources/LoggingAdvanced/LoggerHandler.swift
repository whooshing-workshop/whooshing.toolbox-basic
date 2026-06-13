import Foundation
import Logging
import Puppy

public struct LoggerHandler: LogHandler {
    /// var logger = Logger(label: "woo.filestorage")
    /// logger.logLevel = .warning // 用于业务层直接修改 logger 的级别
    /// 业务层闸门，对业务层的 Log 输出等级进行约束
    /// 策略层另有一道闸门
    public var logLevel: Logger.Level = .info
    /// 业务层 Metadata 存储器，用于业务层直接修改 metadata
    public var metadata: Logger.Metadata = [:]
    // 官方要求的 metadataProvider 属性
    // 它是系统自动抓取上下文指纹（如 TaskLocal 的 TraceID）的超级后门
    public var metadataProvider: Logger.MetadataProvider?
    
    public let label: String
    public let strategies: [LoggerStrategy]
    
    @inlinable
    public init(
        label: String,
        strategies: [LoggerStrategy],
        metadataProvider: Logger.MetadataProvider? = nil // 默认为 nil 保证向前兼容
    ) {
        self.label = label
        self.strategies = strategies
        self.metadataProvider = metadataProvider
    }
    
    @inlinable
    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
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
    func mergedMetadata(_ eventMetadata: Logger.Metadata?) -> Logger.Metadata {
        // Provider 自动从上下文自动榨取出来的最新 TraceID 等元数据
        var baseMetadata = self.metadataProvider?.get() ?? [:]
        
        // Handler 实例长期持有的元数据
        if !self.metadata.isEmpty {
            baseMetadata.merge(self.metadata, uniquingKeysWith: { _, new in new })
        }
        
        // 单条日志临时附加的局部元数据
        if let eventMeta = eventMetadata, !eventMeta.isEmpty {
            baseMetadata.merge(eventMeta, uniquingKeysWith: { _, new in new })
        }
        
        return baseMetadata
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
