import Logging
import Foundation

public protocol LoggerProvider {
    var logMessage: Logger.Message { get }
    var metadata: Logger.Metadata? { get }
    var source: String? { get }
}

public extension Logger {
    @inlinable
    func traces(
        _ msg: Logger.Message,
        paras: [(metadata: Logger.Metadata, source: String?)],
        id: UUID = UUID()
    ) {
        chain(msg, paras: paras, level: .trace, id: id)
    }
    
    @inlinable
    func debugs(
        _ msg: Logger.Message,
        paras: [(metadata: Logger.Metadata, source: String?)],
        id: UUID = UUID()
    ) {
        chain(msg, paras: paras, level: .debug, id: id)
    }
    
    @inlinable
    func infos(
        _ msg: Logger.Message,
        paras: [(metadata: Logger.Metadata, source: String?)],
        id: UUID = UUID()
    ) {
        chain(msg, paras: paras, level: .info, id: id)
    }
    
    @inlinable
    func notices(
        _ msg: Logger.Message,
        paras: [(metadata: Logger.Metadata, source: String?)],
        id: UUID = UUID()
    ) {
        chain(msg, paras: paras, level: .notice, id: id)
    }
    
    @inlinable
    func warnings(
        _ msg: Logger.Message,
        paras: [(metadata: Logger.Metadata, source: String?)],
        id: UUID = UUID()
    ) {
        chain(msg, paras: paras, level: .warning, id: id)
    }
    
    @inlinable
    func errors(
        _ msg: Logger.Message,
        paras: [(metadata: Logger.Metadata, source: String?)],
        id: UUID = UUID()
    ) {
        chain(msg, paras: paras, level: .error, id: id)
    }
    
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
    typealias LoggerBlock = (msg: Logger.Message, metadata: Metadata?, source: String?)
    
    @inlinable
    func traces(_ logs: LoggerBlock..., id: UUID = UUID()) {
        chain(logs, level: .trace, id: id)
    }
    
    @inlinable
    func debugs(_ logs: LoggerBlock..., id: UUID = UUID()) {
        chain(logs, level: .debug, id: id)
    }
    
    @inlinable
    func infos(_ logs: LoggerBlock..., id: UUID = UUID()) {
        chain(logs, level: .info, id: id)
    }
    
    @inlinable
    func notices(_ logs: LoggerBlock..., id: UUID = UUID()) {
        chain(logs, level: .notice, id: id)
    }
    
    @inlinable
    func warnings(_ logs: LoggerBlock..., id: UUID = UUID()) {
        chain(logs, level: .warning, id: id)
    }
    
    @inlinable
    func errors(_ logs: LoggerBlock..., id: UUID = UUID()) {
        chain(logs, level: .error, id: id)
    }
    
    @inlinable
    func criticals(_ logs: LoggerBlock..., id: UUID = UUID()) {
        chain(logs, level: .critical, id: id)
    }
}

public extension Logger {
    @inlinable
    func traces(_ logs: LoggerProvider..., id: UUID = UUID()) {
        chain(logs, level: .trace, id: id)
    }
    
    @inlinable
    func debugs(_ logs: LoggerProvider..., id: UUID = UUID()) {
        chain(logs, level: .debug, id: id)
    }
    
    @inlinable
    func infos(_ logs: LoggerProvider..., id: UUID = UUID()) {
        chain(logs, level: .info, id: id)
    }
    
    @inlinable
    func notices(_ logs: LoggerProvider..., id: UUID = UUID()) {
        chain(logs, level: .notice, id: id)
    }
    
    @inlinable
    func warnings(_ logs: LoggerProvider..., id: UUID = UUID()) {
        chain(logs, level: .warning, id: id)
    }
    
    @inlinable
    func errors(_ logs: LoggerProvider..., id: UUID = UUID()) {
        chain(logs, level: .error, id: id)
    }
    
    @inlinable
    func criticals(_ logs: LoggerProvider..., id: UUID = UUID()) {
        chain(logs, level: .critical, id: id)
    }
}

public extension Logger {
    @inlinable
    func traces(_ logs: [LoggerProvider], id: UUID = UUID()) {
        chain(logs, level: .trace, id: id)
    }
    
    @inlinable
    func debugs(_ logs: [LoggerProvider], id: UUID = UUID()) {
        chain(logs, level: .debug, id: id)
    }
    
    @inlinable
    func infos(_ logs: [LoggerProvider], id: UUID = UUID()) {
        chain(logs, level: .info, id: id)
    }
    
    @inlinable
    func notices(_ logs: [LoggerProvider], id: UUID = UUID()) {
        chain(logs, level: .notice, id: id)
    }
    
    @inlinable
    func warnings(_ logs: [LoggerProvider], id: UUID = UUID()) {
        chain(logs, level: .warning, id: id)
    }
    
    @inlinable
    func errors(_ logs: [LoggerProvider], id: UUID = UUID()) {
        chain(logs, level: .error, id: id)
    }
    
    @inlinable
    func criticals(_ logs: [LoggerProvider], id: UUID = UUID()) {
        chain(logs, level: .critical, id: id)
    }
}

public extension Logger {
    @inlinable
    func traces(_ logs: [LoggerBlock], id: UUID = UUID()) {
        chain(logs, level: .trace, id: id)
    }
    
    @inlinable
    func debugs(_ logs: [LoggerBlock], id: UUID = UUID()) {
        chain(logs, level: .debug, id: id)
    }
    
    @inlinable
    func infos(_ logs: [LoggerBlock], id: UUID = UUID()) {
        chain(logs, level: .info, id: id)
    }
    
    @inlinable
    func notices(_ logs: [LoggerBlock], id: UUID = UUID()) {
        chain(logs, level: .notice, id: id)
    }
    
    @inlinable
    func warnings(_ logs: [LoggerBlock], id: UUID = UUID()) {
        chain(logs, level: .warning, id: id)
    }
    
    @inlinable
    func errors(_ logs: [LoggerBlock], id: UUID = UUID()) {
        chain(logs, level: .error, id: id)
    }
    
    @inlinable
    func criticals(_ logs: [LoggerBlock], id: UUID = UUID()) {
        chain(logs, level: .critical, id: id)
    }
}

public extension Logger {
    @inlinable
    func chain(_ logs: [LoggerBlock], level: Logger.Level, id: UUID = UUID()) {
        for (msg, metadata, source) in logs {
            var m = metadata ?? .init()
            m[Self.chainKey] = .stringConvertible(id)
            self.log(level: level, msg, metadata: m, source: source)
        }
    }
    
    @inlinable
    func chain(_ logs: [LoggerProvider], level: Logger.Level, id: UUID = UUID()) {
        for log in logs {
            var metadata = log.metadata ?? .init()
            metadata[Self.chainKey] = .stringConvertible(id)
            self.log(level: level, log.logMessage, metadata: metadata, source: log.source)
        }
    }
    
    @inlinable
    func chain(
        _ msg: Logger.Message,
        paras: [(metadata: Metadata?, source: String?)],
        level: Logger.Level,
        id: UUID = UUID()
    ) {
        for (metadata, source) in paras {
            var m = metadata ?? .init()
            m[Self.chainKey] = .stringConvertible(id)
            self.log(level: level, msg, metadata: m, source: source)
        }
    }
}
