import Logging
import Foundation

/// 日志提供者协议，用于让对象自定义其日志输出。
public protocol LoggerProvider {
    /// 日志消息内容。
    var logMessage: Logger.Message { get }
    /// 日志元数据。
    var metadata: Logger.Metadata? { get }
    /// 日志来源标识。
    var source: String? { get }
}

public extension Logger {
    /// 批量记录 Trace 级别的日志，并将它们链接在一起。
    ///
    /// - Parameters:
    ///   - msg: 主日志消息。
    ///   - paras: 包含元数据和来源的参数列表。
    ///   - id: 链 ID，默认为随机 UUID。
    @inlinable
    func traces(
        _ msg: Logger.Message,
        paras: [(metadata: Logger.Metadata, source: String?)],
        id: UUID = UUID()
    ) {
        chain(msg, paras: paras, level: .trace, id: id)
    }
    
    /// 批量记录 Debug 级别的日志，并将它们链接在一起。
    ///
    /// - Parameters:
    ///   - msg: 主日志消息。
    ///   - paras: 包含元数据和来源的参数列表。
    ///   - id: 链 ID，默认为随机 UUID。
    @inlinable
    func debugs(
        _ msg: Logger.Message,
        paras: [(metadata: Logger.Metadata, source: String?)],
        id: UUID = UUID()
    ) {
        chain(msg, paras: paras, level: .debug, id: id)
    }
    
    /// 批量记录 Info 级别的日志，并将它们链接在一起。
    ///
    /// - Parameters:
    ///   - msg: 主日志消息。
    ///   - paras: 包含元数据和来源的参数列表。
    ///   - id: 链 ID，默认为随机 UUID。
    @inlinable
    func infos(
        _ msg: Logger.Message,
        paras: [(metadata: Logger.Metadata, source: String?)],
        id: UUID = UUID()
    ) {
        chain(msg, paras: paras, level: .info, id: id)
    }
    
    /// 批量记录 Notice 级别的日志，并将它们链接在一起。
    ///
    /// - Parameters:
    ///   - msg: 主日志消息。
    ///   - paras: 包含元数据和来源的参数列表。
    ///   - id: 链 ID，默认为随机 UUID。
    @inlinable
    func notices(
        _ msg: Logger.Message,
        paras: [(metadata: Logger.Metadata, source: String?)],
        id: UUID = UUID()
    ) {
        chain(msg, paras: paras, level: .notice, id: id)
    }
    
    /// 批量记录 Warning 级别的日志，并将它们链接在一起。
    ///
    /// - Parameters:
    ///   - msg: 主日志消息。
    ///   - paras: 包含元数据和来源的参数列表。
    ///   - id: 链 ID，默认为随机 UUID。
    @inlinable
    func warnings(
        _ msg: Logger.Message,
        paras: [(metadata: Logger.Metadata, source: String?)],
        id: UUID = UUID()
    ) {
        chain(msg, paras: paras, level: .warning, id: id)
    }
    
    /// 批量记录 Error 级别的日志，并将它们链接在一起。
    ///
    /// - Parameters:
    ///   - msg: 主日志消息。
    ///   - paras: 包含元数据和来源的参数列表。
    ///   - id: 链 ID，默认为随机 UUID。
    @inlinable
    func errors(
        _ msg: Logger.Message,
        paras: [(metadata: Logger.Metadata, source: String?)],
        id: UUID = UUID()
    ) {
        chain(msg, paras: paras, level: .error, id: id)
    }
    
    /// 批量记录 Critical 级别的日志，并将它们链接在一起。
    ///
    /// - Parameters:
    ///   - msg: 主日志消息。
    ///   - paras: 包含元数据和来源的参数列表。
    ///   - id: 链 ID，默认为随机 UUID。
    @inlinable
    func criticals(
        _ msg: Logger.Message,
        paras: [(metadata: Logger.Metadata, source: String?)],
        id: UUID = UUID()
    ) {
        chain(msg, paras: paras, level: .critical, id: id)
    }
}

public extension Logger {
    /// 用于表示一条日志记录的元组别名。
    typealias LoggerBlock = (msg: Logger.Message, metadata: Metadata?, source: String?)
    
    /// 批量记录 Trace 级别的日志（可变参数版本）。
    @inlinable
    func traces(_ logs: LoggerBlock..., id: UUID = UUID()) {
        chain(logs, level: .trace, id: id)
    }
    
    /// 批量记录 Debug 级别的日志（可变参数版本）。
    @inlinable
    func debugs(_ logs: LoggerBlock..., id: UUID = UUID()) {
        chain(logs, level: .debug, id: id)
    }
    
    /// 批量记录 Info 级别的日志（可变参数版本）。
    @inlinable
    func infos(_ logs: LoggerBlock..., id: UUID = UUID()) {
        chain(logs, level: .info, id: id)
    }
    
    /// 批量记录 Notice 级别的日志（可变参数版本）。
    @inlinable
    func notices(_ logs: LoggerBlock..., id: UUID = UUID()) {
        chain(logs, level: .notice, id: id)
    }
    
    /// 批量记录 Warning 级别的日志（可变参数版本）。
    @inlinable
    func warnings(_ logs: LoggerBlock..., id: UUID = UUID()) {
        chain(logs, level: .warning, id: id)
    }
    
    /// 批量记录 Error 级别的日志（可变参数版本）。
    @inlinable
    func errors(_ logs: LoggerBlock..., id: UUID = UUID()) {
        chain(logs, level: .error, id: id)
    }
    
    /// 批量记录 Critical 级别的日志（可变参数版本）。
    @inlinable
    func criticals(_ logs: LoggerBlock..., id: UUID = UUID()) {
        chain(logs, level: .critical, id: id)
    }
}

public extension Logger {
    /// 批量记录 Trace 级别的日志（LoggerProvider 可变参数版本）。
    @inlinable
    func traces(_ logs: LoggerProvider..., id: UUID = UUID()) {
        chain(logs, level: .trace, id: id)
    }
    
    /// 批量记录 Debug 级别的日志（LoggerProvider 可变参数版本）。
    @inlinable
    func debugs(_ logs: LoggerProvider..., id: UUID = UUID()) {
        chain(logs, level: .debug, id: id)
    }
    
    /// 批量记录 Info 级别的日志（LoggerProvider 可变参数版本）。
    @inlinable
    func infos(_ logs: LoggerProvider..., id: UUID = UUID()) {
        chain(logs, level: .info, id: id)
    }
    
    /// 批量记录 Notice 级别的日志（LoggerProvider 可变参数版本）。
    @inlinable
    func notices(_ logs: LoggerProvider..., id: UUID = UUID()) {
        chain(logs, level: .notice, id: id)
    }
    
    /// 批量记录 Warning 级别的日志（LoggerProvider 可变参数版本）。
    @inlinable
    func warnings(_ logs: LoggerProvider..., id: UUID = UUID()) {
        chain(logs, level: .warning, id: id)
    }
    
    /// 批量记录 Error 级别的日志（LoggerProvider 可变参数版本）。
    @inlinable
    func errors(_ logs: LoggerProvider..., id: UUID = UUID()) {
        chain(logs, level: .error, id: id)
    }
    
    /// 批量记录 Critical 级别的日志（LoggerProvider 可变参数版本）。
    @inlinable
    func criticals(_ logs: LoggerProvider..., id: UUID = UUID()) {
        chain(logs, level: .critical, id: id)
    }
}

public extension Logger {
    /// 批量记录 Trace 级别的日志（LoggerProvider 数组版本）。
    @inlinable
    func traces(_ logs: [LoggerProvider], id: UUID = UUID()) {
        chain(logs, level: .trace, id: id)
    }
    
    /// 批量记录 Debug 级别的日志（LoggerProvider 数组版本）。
    @inlinable
    func debugs(_ logs: [LoggerProvider], id: UUID = UUID()) {
        chain(logs, level: .debug, id: id)
    }
    
    /// 批量记录 Info 级别的日志（LoggerProvider 数组版本）。
    @inlinable
    func infos(_ logs: [LoggerProvider], id: UUID = UUID()) {
        chain(logs, level: .info, id: id)
    }
    
    /// 批量记录 Notice 级别的日志（LoggerProvider 数组版本）。
    @inlinable
    func notices(_ logs: [LoggerProvider], id: UUID = UUID()) {
        chain(logs, level: .notice, id: id)
    }
    
    /// 批量记录 Warning 级别的日志（LoggerProvider 数组版本）。
    @inlinable
    func warnings(_ logs: [LoggerProvider], id: UUID = UUID()) {
        chain(logs, level: .warning, id: id)
    }
    
    /// 批量记录 Error 级别的日志（LoggerProvider 数组版本）。
    @inlinable
    func errors(_ logs: [LoggerProvider], id: UUID = UUID()) {
        chain(logs, level: .error, id: id)
    }
    
    /// 批量记录 Critical 级别的日志（LoggerProvider 数组版本）。
    @inlinable
    func criticals(_ logs: [LoggerProvider], id: UUID = UUID()) {
        chain(logs, level: .critical, id: id)
    }
}

public extension Logger {
    /// 批量记录 Trace 级别的日志（LoggerBlock 数组版本）。
    @inlinable
    func traces(_ logs: [LoggerBlock], id: UUID = UUID()) {
        chain(logs, level: .trace, id: id)
    }
    
    /// 批量记录 Debug 级别的日志（LoggerBlock 数组版本）。
    @inlinable
    func debugs(_ logs: [LoggerBlock], id: UUID = UUID()) {
        chain(logs, level: .debug, id: id)
    }
    
    /// 批量记录 Info 级别的日志（LoggerBlock 数组版本）。
    @inlinable
    func infos(_ logs: [LoggerBlock], id: UUID = UUID()) {
        chain(logs, level: .info, id: id)
    }
    
    /// 批量记录 Notice 级别的日志（LoggerBlock 数组版本）。
    @inlinable
    func notices(_ logs: [LoggerBlock], id: UUID = UUID()) {
        chain(logs, level: .notice, id: id)
    }
    
    /// 批量记录 Warning 级别的日志（LoggerBlock 数组版本）。
    @inlinable
    func warnings(_ logs: [LoggerBlock], id: UUID = UUID()) {
        chain(logs, level: .warning, id: id)
    }
    
    /// 批量记录 Error 级别的日志（LoggerBlock 数组版本）。
    @inlinable
    func errors(_ logs: [LoggerBlock], id: UUID = UUID()) {
        chain(logs, level: .error, id: id)
    }
    
    /// 批量记录 Critical 级别的日志（LoggerBlock 数组版本）。
    @inlinable
    func criticals(_ logs: [LoggerBlock], id: UUID = UUID()) {
        chain(logs, level: .critical, id: id)
    }
}

public extension Logger {
    /// 内部方法：将一批 LoggerBlock 链接起来并记录日志。
    /// 可以自动为每条日志添加链 ID 和序号。
    @inlinable
    func chain(_ logs: [LoggerBlock], level: Logger.Level, id: UUID = UUID()) {
        for (i, (msg, metadata, source)) in logs.enumerated() {
            var m = metadata ?? .init()
            m[Self.chainKey] = .stringConvertible(id)
            m[Self.chainIndexKey] = .stringConvertible(i + 1)
            self.log(level: level, msg, metadata: m, source: source)
        }
    }
    
    /// 内部方法：将一批 LoggerProvider 链接起来并记录日志。
    @inlinable
    func chain(_ logs: [LoggerProvider], level: Logger.Level, id: UUID = UUID()) {
        for (i, log) in logs.enumerated() {
            var metadata = log.metadata ?? .init()
            metadata[Self.chainKey] = .stringConvertible(id)
            metadata[Self.chainIndexKey] = .stringConvertible(i + 1)
            self.log(level: level, log.logMessage, metadata: metadata, source: log.source)
        }
    }
    
    /// 内部方法：将同一条消息与不同的参数组合，链接起来并记录日志。
    @inlinable
    func chain(
        _ msg: Logger.Message,
        paras: [(metadata: Metadata?, source: String?)],
        level: Logger.Level,
        id: UUID = UUID()
    ) {
        for (i, (metadata, source)) in paras.enumerated() {
            var m = metadata ?? .init()
            m[Self.chainKey] = .stringConvertible(id)
            m[Self.chainIndexKey] = .stringConvertible(i + 1)
            self.log(level: level, msg, metadata: m, source: source)
        }
    }
}
