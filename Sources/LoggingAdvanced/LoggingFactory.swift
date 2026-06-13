import Puppy
import Foundation

/// 日志工厂，用于配置和初始化日志系统。
public struct LoggingFactory: Sendable {
    @usableFromInline
    let strategies: [LoggerStrategy]
    
    // 允许从外部（如主程序入口）注入你自定义的全局元数据提供者
    @usableFromInline
    let metadataProvider: Logger.MetadataProvider?
    
    /// 初始化一个新的日志工厂。
    @inlinable
    public init(
        strategies: [LoggerStrategy],
        metadataProvider: Logger.MetadataProvider? = nil
    ) {
        self.strategies = strategies
        self.metadataProvider = metadataProvider
    }
    
    /// 组合多个日志工厂。
    /// 如果没有显式指定新的全局大总管，自动继承数组里第一个非空的 provider 跑包底
    @inlinable
    public init(
        factories: [Self],
        metadataProvider: Logger.MetadataProvider? = nil
    ) {
        self.strategies = factories.flatMap { $0.strategies }
        self.metadataProvider = metadataProvider ?? factories.first(where: { $0.metadataProvider != nil })?.metadataProvider
    }
    
    /// 启动日志系统。
    ///
    /// 调用此方法后，SwiftLog 的 `LoggingSystem` 将被初始化。
    @inlinable
    public func bootstrap() {
        let strategies = self.strategies
        
        LoggingSystem.bootstrap(
            { label, provider in
                var logStrategies: [LoggerStrategy] = []
                for strategy in strategies {
                    guard strategy.conform(to: label) else { continue }
                    logStrategies.append(strategy)
                }
                return LoggerHandler(label: label, strategies: logStrategies, metadataProvider: provider)
            },
            metadataProvider: metadataProvider
        )
    }
    
    /// 创建新工厂，增加日志策略
    /// 新衍生出来的结构体，应该无缝继承当前已配好的元数据提供者
    @inlinable
    public func append(strategies: [LoggerStrategy]) -> Self {
        .init(strategies: self.strategies + strategies, metadataProvider: self.metadataProvider)
    }
    
    /// 合并日志工厂，增加日志策略
    /// 把当前调用者 [self] 放在最前面，防止自身策略蒸发；同时完美继承 provider
    @inlinable
    public func combine(factories: [Self]) -> Self {
        .init(factories: [self] + factories, metadataProvider: self.metadataProvider)
    }
}
