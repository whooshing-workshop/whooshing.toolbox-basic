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
    
    /// 创建一个错误类型，但请尽量避免使用，尽管这是可行的。
    @inlinable
    public init() {}
}

public protocol AnyBscError: Error, Sendable {}

@frozen
public struct StringError: Error, CustomStringConvertible, ExpressibleByStringLiteral {
    public let reason: String
    
    @inlinable
    public init(_ reason: String) {
        self.reason = reason
    }
    
    @inlinable
    public init(stringLiteral value: StringLiteralType) {
        self.reason = value
    }
    
    @inlinable
    public var description: String { self.reason }
}
