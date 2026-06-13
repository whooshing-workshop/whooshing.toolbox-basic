import Puppy
import Foundation

/// 日志工厂，用于配置和初始化日志系统。
public struct LoggingFactory {
    @usableFromInline
    let strategies: [LoggerStrategy]
    
    /// 初始化一个新的日志工厂。
    @inlinable
    public init(strategies: [LoggerStrategy]) {
        self.strategies = strategies
    }
    
    /// 初始化一个新的日志工厂。
    @inlinable
    public init(factories: [Self]) {
        self.strategies = factories.flatMap { $0.strategies }
    }
    
    /// 启动日志系统。
    ///
    /// 调用此方法后，SwiftLog 的 `LoggingSystem` 将被初始化。
    @inlinable
    public func bootstrap() {
        let strategies = self.strategies
        LoggingSystem.bootstrap { label in
            var logStrategies: [LoggerStrategy] = []
            for strategy in strategies {
                guard strategy.conform(to: label) else { continue }
                logStrategies.append(strategy)
            }
            return LoggerHandler(label: label, strategies: logStrategies)
        }
    }
    
    /// 创建新工厂，增加日志策略
    @inlinable
    public func append(strategies: [LoggerStrategy]) -> Self {
        .init(strategies: self.strategies + strategies)
    }
    
    /// 合并日志工厂，增加日志策略
    @inlinable
    public func combine(factories: [Self]) -> Self {
        .init(factories: factories)
    }
}
