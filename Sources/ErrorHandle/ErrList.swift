/**
    #### 错误列表的协议声明
    
    该协议定义了错误生成方法的默认实现。你只需要在你的错误列表枚举中实现该协议，列出所有的错误即可，但需注意一些细节。见以下例子：

    ---
    ## 创建错误列表。
    ``` swift
    // 声明一个错误列表，需要实现 ErrList 协议，并确保枚举值为 String。
    enum NormalErrorTypes: String, ErrList {
        // 表示该错误列表中的错误，都是 BscError 类型的。
        // 这行非必须，那么 ErrType 默认便是 BscError。请详见该基本错误。
        typealias ErrType = BscError
 
        // 列出所有的错误，并为其指定 summary
        case error1 = "Error 1 summary"
        case error2 = "Error 2 summary"
    }
    
    // 如果愿意，可以设置类型别名，看起来更简洁。该行非必须。
    typealias A = NormalErrorTypes

    func demo() throws {
        ...
        // 创建错误并抛出
        throw A.error1.d("一些错误解释，即 explain", 1011)
        ...
    }
    ```
 
    当然，你也可以在自定义错误类型和错误列表中定义和实现任何方法等等，但这通常是不必要的。
*/
public protocol ErrList: Sendable, RawRepresentable, CaseIterable where Self.ErrType: Err, Self.ErrType.ErrorList == Self {
    associatedtype ErrType = BasicError<Self>
    /**
        为一个错误设置细节信息

        此函数簇 d(...) 的名称是细节 detail 的缩写，你可以为此为你错误列表中的错误设置细节信息。

        参数解释：

        - **explain**：为该错误设置一个解释，通常是比较细节的内容。
        - **file**：该错误发生的文件。
        - **line**：该错误发生的行数。
        - **function**：该错误发生的函数。

        例如：

        ``` swift
        ErrorList.error1.d("一些解释", 1004)
        ```

        这些细节信息并非是恒定不变的，例如：systemError，它的描述 (summary) 可能为 “系统发生错误”。
        而你可能为其添加更详细的解释 (explain)：“数据库认证用户 XXX 时失败”。

        表现在代码中，它可以如此定义和使用：

        ``` swift
        enum MyErrorTypes: String, ErrList {
            // 在此处定义错误的 summary
            case systemError = "系统发生错误"
        }

        // 这一步非必须
        typealias A = MyErrorTypes

        func databaseAction(...) throws {
            ...
            // 此处定义这次发生错误的一些解释
            throw A.systemError.d("数据库认证用户 XXX 时失败", 1006)
            ...
        }

        // 运行该函数触发错误
        do {
            try databaseAction(...)
        } catch let err {   // 捕获该错误
            print(err) // 打印： MyErrorTypes.systemError("系统发生错误", "数据库认证用户 XXX 时失败", #1006, At "Error.swift:128 -> databaseAction()")
        }
        ```
    */
    func d(category: ErrCategory, file: String, line: Int, function: String) -> ErrType
    func d(_ explain: String, category: ErrCategory, file: String, line: Int, function: String) -> ErrType
    
    /// 用于设置 subError 参数
    ///
    /// 用法：
    /// ``` swift
    /// ErrorTypes.aError.subErr(yourSubErr)
    /// ```
    func subErr(_ error: Error?, category: ErrCategory, file: String, line: Int, function: String) -> ErrType
}

// MARK: - 内部实现

public extension ErrList {
    @inlinable
    func d(category: ErrCategory, file: String = #fileID, line: Int = #line, function: String = #function) -> ErrType { detail(category: category, loc: (file, line, function)) }
    @inlinable
    func d(_ explain: String, category: ErrCategory, file: String = #fileID, line: Int = #line, function: String = #function) -> ErrType { detail(explain: explain, category: category, loc: (file, line, function)) }
    @inlinable
    func subErr(_ error: Error?, category: ErrCategory, file: String = #fileID, line: Int = #line, function: String = #function) -> ErrType { detail(category: category, loc: (file, line, function)).subErr(error) }
    @inlinable
    var identifier: String { String(describing: Self.self) + "." + String(describing: self.rawValue) }
}

extension ErrList {
    @inlinable
    func detail(explain: String? = nil, category: ErrCategory, loc: (file: String, line: Int, function: String)) -> ErrType { ErrType(self, explain, category: category, file: loc.file, line: loc.line, function: loc.function) }
}
