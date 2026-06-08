import Logging
import Foundation

/// 可记录日志的协议。
///
/// 遵循此协议的类型可以提供一个自定义的日志描述字符串。
public protocol Loggerable {
    /// 用于日志记录的描述信息。
    var logDescription: String { get }
    /// 用于日志记录的简短描述信息。
    var summaryDescription: String { get }
}

public extension Loggerable where Self: CustomStringConvertible {
    /// 默认实现：如果类型遵循 `CustomStringConvertible`，直接使用 description 作为日志描述。
    @inlinable
    var logDescription: String { description }
}

public extension Loggerable {
    @inlinable
    var summaryDescription: String { logDescription }
}

public extension Logger.MetadataValue {
    /// 从 Loggerable 对象创建 MetadataValue。
    @inlinable
    static func data<T>(_ loggerable: T) -> Self where T: Loggerable {
        .string(loggerable.logDescription)
    }
    
    /// 从 Loggerable 对象创建 MetadataValue。
    @inlinable
    static func summaryData<T>(_ loggerable: T) -> Self where T: Loggerable {
        .string(loggerable.summaryDescription)
    }
    
    /// 从对象的 ID 创建 MetadataValue。
    @inlinable
    static func id<T>(_ obj: T) -> Self where T: AnyObject {
        .data(ObjectIdentifier(obj))
    }
}

extension String: Loggerable {
    @inlinable
    public var logDescription: String {
        if self == "" {
            return "<empty>"
        } else {
            return self
        }
    }
}

extension Int: Loggerable {}
extension Int8: Loggerable {}
extension Int16: Loggerable {}
extension Int32: Loggerable {}
extension Int64: Loggerable {}
extension UInt: Loggerable {}
extension UInt8: Loggerable {}
extension UInt16: Loggerable {}
extension UInt32: Loggerable {}
extension UInt64: Loggerable {}
extension Float: Loggerable {}
extension Double: Loggerable {}
extension Decimal: Loggerable {}

extension Bool: Loggerable {}
extension UUID: Loggerable {}
extension Data: Loggerable {
    /// Data 的日志描述：显示字节数。
    @inlinable
    public var logDescription: String { "count: \(self.count)" }
}

extension Range: Loggerable {}
extension ClosedRange: Loggerable {}

extension Array: Loggerable where Element: Loggerable {
    @inlinable
    public var logDescription: String {
        guard !isEmpty else { return "(空)" }
        return enumerated()
            .map { i, r in "\(i): \(r.logDescription)" }
            .joined(separator: "\n")
    }
    
    @inlinable
    public var summaryDescription: String {
        guard !isEmpty else { return "(空)" }
        return enumerated()
            .map { i, r in "\(i): \(r.summaryDescription)" }
            .joined(separator: " | ")
    }
}

extension Dictionary: Loggerable where Key: Loggerable, Value: Loggerable {
    @inlinable
    public var logDescription: String {
        guard !isEmpty else { return "(空)" }
        return map { k, v in "  Key: \(k.logDescription) => Value: \(v.logDescription)" }
            .joined(separator: "\n")
    }
    
    @inlinable
    public var summaryDescription: String {
        guard !isEmpty else { return "(空)" }
        return map { k, v in "{\(k.summaryDescription): \(v.summaryDescription)}" }
            .joined(separator: " | ")
    }
}

extension ObjectIdentifier: Loggerable {
    /// ObjectIdentifier 的日志描述：尝试提取内存地址。
    @inlinable
    public var logDescription: String {
        let rawDescription = String(describing: self)
        if let range = rawDescription.range(of: "0x") {
            return String(rawDescription[range.lowerBound..<rawDescription.index(before: rawDescription.endIndex)])
        }
        return rawDescription
    }
    public var summaryDescription: String { logDescription }
}

public extension Optional where Wrapped: Loggerable {
    /// Optional 的日志描述：如果是 some，递归调用 wrapped.logDescription；如果是 nil，返回 "nil"。
    var logDescription: String {
        switch self {
        case .some(let wrapped):
            return "\(wrapped.logDescription)?"
        case .none:
            return "nil"
        }
    }
}

extension Optional: Loggerable {
    /// Optional 的日志描述：如果是 some，返回 wrapped 的描述；如果是 nil，返回 "nil"。
    public var logDescription: String {
        switch self {
        case .some(let wrapped):
            return "\(wrapped)?"
        case .none:
            return "nil"
        }
    }
}
