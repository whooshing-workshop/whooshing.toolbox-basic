/// 一个简单的基于字符串的错误类型。
///
/// 当你只需要抛出一个简单的错误消息，而不需要复杂的结构化信息时，可以使用此类型。
/// 它支持直接使用字符串字面量初始化。
@frozen
public struct StringError: Error, CustomStringConvertible, ExpressibleByStringLiteral {
    /// 错误的具体原因。
    public let reason: String
    
    /// 使用描述错误原因的字符串初始化。
    /// - Parameter reason: 错误原因。
    @inlinable
    public init(_ reason: String) {
        self.reason = reason
    }
    
    /// 使用字符串字面量初始化。
    /// - Parameter value: 字符串字面量。
    @inlinable
    public init(stringLiteral value: StringLiteralType) {
        self.reason = value
    }
    
    /// 错误的文本描述。
    @inlinable
    public var description: String { self.reason }
}
