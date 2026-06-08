import Logging
import Foundation

/**
    #### 错误类型的协议声明

    你可以自定义自己的错误类型，如果你希望扩展它，尝试覆写 `initAdds(_, new)` 方法。

    ---
    ## 创建自定义错误类型。

    许多时候 BscError 已经足够使用，若要创建自定义类型，可以像如下这般：
    ``` swift
    struct CustomError: Err {

        typealias AdditionType = [String]
        var error: (any ErrList)!
        var explain: String?
        var file: String!
        var line: Int!
        var function: String!
        var subError: Error?
        var addtionInformation: String!
        var addtionInformation2: String!
        ....
        
        // 在该函数中实现你所希望 addtion 的用法
        func initAdds(_ addtion: [String], new: inout Self) {
            ....
            new.addtionInformation = addtion[0]
            new.addtionInformation2 = addtion[1]
            ....
        }
    }
    ```
*/
public protocol Err: Error, Sendable, Equatable, CustomStringConvertible{
    /// 扩展类型，默认为 Never，即无类型。配合 `initAdditions(_)` 方法实现和扩展你的错误类型。
    associatedtype AdditionType = Never
    associatedtype ErrorList: ErrList
    associatedtype Category: ErrCategory
    
    /// 该错误的错误枚举值
    var error: ErrorList! { get set }
    /// 该错误的类别
    var category: Category? { get set }
    /// 该错误的附加解释
    var explain: String? { get set }
    /// 错误发生所在的文件位置
    var file: String! { get set }
    /// 错误发生所在的行数
    var line: Int! { get set }
    /// 错误发生所在的函数
    var function: String! { get set }
    /// 该错误的子错误
    var subError: Error? { get set }
    /// 该错误的元数据(可用于 logger)
    var metadata: Logger.Metadata? { get set }
    
    /// 初始化方法，你需要在你的自定义错误类型中实现该构建函数。
    init()

    /// 错误的初始化方法，默认实现会自动为 ```summary, explain, category, file, line, function``` 赋值。
    init(_ error: ErrorList, _ explain: String?, category: Category?, file: String, line: Int, function: String)

    /// 判断该错误是否与其他错误同类型。
    ///
    /// 仅检查两者的 domain 以及 error，若这两者相同，则认为同类型。
    func isSameType(of err: any Err) -> Bool

    /// 用于设置 subError 参数
    ///
    /// 用法：
    /// ``` swift
    /// ErrorTypes.aError.d("Some Explain").subErr(yourSubErr)
    /// ```
    func subErr(_ err: Error?) -> Self
    
    /// 用于设置 metadata 参数
    ///
    /// 用法：
    /// ``` swift
    /// ErrorTypes.aError.d("Some Explain").metadata(yourMetadata)
    /// ````
    func metadata(_ meta: Logger.Metadata?) -> Self

    /// 为错误设置一个附加数据
    ///
    /// 用法：
    /// ``` swift
    /// ErrorTypes.aError.d("Some Explain").adds(yourAddtionDatas)
    /// ```
    ///
    /// 关于附加数据自定义，见 ```protocol Err``` 的解释
    func adds(_ addtion: AdditionType) -> Self
    
    /// 覆写该方法，以实现自定义附加数据的行为
    ///
    /// - 参数
    ///     - addition：所附加的数据
    ///     - new：新的 Err 实例，以 inout 形式传入，因此你可以修改其内容实现你的目的
    ///
    /// 该函数被 ```adds(_) -> Self``` 函数调用，用于自定义附加数据的行为
    ///
    /// 默认实现为：
    /// ``` swift
    /// func initAdds(_ addtion: AdditionType) { }
    /// ```
    mutating func initAdds(_ addtion: AdditionType)
}

public extension Err {
    @inlinable
    init(_ error: ErrorList, _ explain: String? = nil, category: Category? = nil, file: String = #fileID, line: Int = #line, function: String = #function) {
        self.init()
        self.error = error
        self.explain = explain
        self.category = category
        self.file = file
        self.line = line
        self.function = function
    }

    @inlinable
    func subErr(_ err: Error?) -> Self {
        var new = self
        new.subError = err
        return new
    }
    
    @inlinable
    func metadata(_ meta: Logger.Metadata?) -> Self {
        var new = self
        new.metadata = meta
        return new
    }
    
    @inlinable
    func adds(_ addtion: AdditionType) -> Self {
        var new = self
        new.initAdds(addtion)
        return new
    }
}

public extension Err {
    @inlinable
    static func == (lhs: Self, rhs: Self) -> Bool {
        type(of: lhs.error) == type(of: rhs.error) &&
        lhs.explain == rhs.explain &&
        lhs.file == rhs.file &&
        lhs.line == rhs.line
    }
    
    @inlinable
    func isSameType(of err: any Err) -> Bool {
        type(of: self) == type(of: err)
    }
}

public extension Err {
    @inlinable
    var msg: String {
        "\(error!.rawValue)" + (explain == nil ? ""  : " - \(explain!)")
    }
    
    @inlinable
    var description: String {
        descriptionString(withHead: true)
    }
    
    @inlinable
    func descriptionString(withHead: Bool) -> String {
        var res = ""
        
        if withHead && subError != nil {
            res += "Error Chains:\n"
            res += "\t"
        }
        
        if !withHead {
            res += "\t"
        }
        
        let prefix = category != nil ? "[\(category!.rawValue)]\(error!.rawValue)" : "\(error!.rawValue)"
        
        res += "\(String(describing: type(of: error!))).\(error!.self)("
        let preds = ["\"", "\"", "At \""]
        let appes = ["\"", "\"", "\""]
        var resArr: [String] = []
        for (i, curData) in ([
            prefix,
            explain,
            self.file + ":" + String(self.line) + " -> " + self.function] as [String?]
        ).enumerated() {
            if let d = curData { resArr.append(preds[i] + d + appes[i]) }
        }
        res += resArr.joined(separator: ", ") + ")"
        
        if let subErr = subError {
            if let bscErr = subErr as? (any Err) {
                res += "\n" + bscErr.descriptionString(withHead: false)
            } else if let err = subErr as? CustomStringConvertible {
                res += "\n\t\(err) {\n" + ("\(String(describing: type(of: subErr))).\(String(describing: subErr)): \(String(reflecting: subErr))".indented(by: 4) + "\n}").indented(by: 4)
            } else {
                res += "\n\t\(String(describing: type(of: subErr))).\(String(describing: subErr)): \(String(reflecting: subErr))"
            }
            
            if withHead {
                res += "\nError Chains Ended"
            }
        }
        
        return res
    }
}

public extension Err where AdditionType == Never {
    @inlinable
    mutating func initAdds(_ addtion: AdditionType) { }
}

extension String {
    /// 为字符串的每一行添加缩进
    /// - Parameter spaces: 缩进的空格数
    /// - Returns: 缩进后的字符串
    @usableFromInline
    func indented(by spaces: Int) -> String {
        let indentation = String(repeating: " ", count: spaces)
        return self.components(separatedBy: .newlines)
            .map { line in
                // 如果是空行，通常不添加缩进空格以保持简洁
                line.isEmpty ? "" : "\(indentation)\(line)"
            }
            .joined(separator: "\n")
    }
}
