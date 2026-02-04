import Logging
import Foundation

public protocol Loggerable {
    var logDescription: String { get }
}

public extension Loggerable where Self: CustomStringConvertible {
    @inlinable
    var logDescription: String { description }
}

public extension Logger.MetadataValue {
    @inlinable
    static func data<T>(_ loggerable: T) -> Self where T: Loggerable {
        .string(loggerable.logDescription)
    }
    
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
    @inlinable
    public var logDescription: String { "count: \(self.count)" }
}

extension Range: Loggerable {}
extension ClosedRange: Loggerable {}

extension Array: Loggerable {}
extension Dictionary: Loggerable {}

extension ObjectIdentifier: Loggerable {
    @inlinable
    public var logDescription: String {
        let rawDescription = String(describing: self)
        if let range = rawDescription.range(of: "0x") {
            return String(rawDescription[range.lowerBound..<rawDescription.index(before: rawDescription.endIndex)])
        }
        return rawDescription
    }
}

public extension Optional where Wrapped: Loggerable {
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
    public var logDescription: String {
        switch self {
        case .some(let wrapped):
            return "\(wrapped)?"
        case .none:
            return "nil"
        }
    }
}
