import Logging

/// 一个泛型的错误类型别名，结合了错误列表（ErrorList）和错误分类（BscErrCategory）。
/// 使用此类型可以构建结构化的错误信息。
public typealias BscError<ErrorList: ErrList> = ErrorBase<ErrorList, BscErrCategory>

/**
    #### 默认错误类型

    最基本的错误类型，以一个结构体的方式记录各种错误信息，包括：

    - **error**：该错误的错误枚举值
    - **explain**：该错误的附加解释
    - **file**：错误发生所在的文件位置
    - **line**：错误发生所在的行数
    - **subErr**： 该错误的子错误

    但请避免直接使用该 `struct` 的初始化方法直接产生 `BscError`，尽管这是可以的，但十分冗长。

    一般，你需要列出自己的错误列表，使用该错误列表来创建一个错误，见下面的例子：

    ---
    ## 声明和使用错误类型
    ``` swift
     // 声明一个错误列表，需要实现 ErrList 协议，并确保枚举值为 String。有关 ErrList 协议，请详见它的解释。
     enum NormalErrorTypes: String, ErrList {
         // 表示该错误列表中的错误，都是 BscError 类型的。
         typealias ErrType = BscError
         case error1 = "Error 1 summary"
         case error2 = "Error 2 summary"
     }

     // 可以设置类型别名，看起来更简洁。这一步非必须。
     typealias A = NormalErrorTypes

     func demo() throws {
         ...
         // 使用错误列表提供的方法来创建错误并抛出
         // 这几个参数依次是上面列出的 explain, file, line
         throw A.error1.d("一些错误解释，即 explain", 1001)
         ...
     }

     // 运行该函数触发错误
     do {
         try demo(...)
     } catch let err {   // 捕获该错误
         print(err)      // 打印： NormalErrorTypes.error1("Error 1 summary", "一些错误解释", #1001, At "Error.swift:36 -> demo()")
     }
    ```

    如果愿意，你可以自定自己的错误类型。见 `protocol Err`
*/
@frozen
public struct ErrorBase<ErrorList, ErrorCategory>: Err, AnyBscError, Sendable where ErrorList: ErrList & Sendable, ErrorCategory: ErrCategory {
    /// 该错误的错误枚举值。
    public var error: ErrorList!
    /// 该错误的类型
    public var category: ErrorCategory?
    /// 每次发生错误时，可以自行阐述一些附加说明。
    public var explain: String?
    /// 发生错误的文件名称。
    public var file: String!
    /// 发生错误的行数。
    public var line: Int!
    /// 发生错误的函数。
    public var function: String!
    /// 该错误的子错误
    public var subError: Error?
    /// 该错误的元数据(可用于 logger)
    public var metadata: Logger.Metadata?
    
    /// 创建一个错误类型实例。
    ///
    /// - Warning: 请尽量避免直接使用此初始化方法，建议通过 `ErrList` 枚举来创建错误。
    @inlinable
    public init() {}
}

/// 任何遵循此协议的类型都被视为 Bsc 错误。
/// 需要同时遵循 `Error` 和 `Sendable` 协议。
public protocol AnyBscError: Error, Sendable {}

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
