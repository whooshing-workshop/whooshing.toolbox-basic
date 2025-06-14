/**
    #### 默认错误类型

    最基本的错误类型，以一个结构体的方式记录各种错误信息，包括：

    - **error**：该错误的错误枚举值
    - **explain**：该错误的附加解释
    - **mark**：该错误的标记，仅用做展示和区分，无其他作用
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
         // 这几个参数依次是上面列出的 explain, mark, file, line
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

public struct BscError: Err, Sendable {
    /// 该错误的错误枚举值。
    public var error: (any ErrList)!
    /// 每次发生错误时，可以自行阐述一些附加说明。
    public var explain: String?
    /// 每次发生错误，可以为其指定一个标记，方便排错。
    public var mark: Int?
    /// 发生错误的文件名称。
    public var file: String!
    /// 发生错误的行数。
    public var line: Int!
    /// 发生错误的函数。
    public var function: String!
    /// 该错误的子错误
    public var subError: Error?
    
    /// 创建一个错误类型，但请尽量避免使用，尽管这是可行的。
    public init() {}
}

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
public protocol ErrList: Sendable where Self.ErrType: Err, Self.RawValue == String {
    associatedtype ErrType = BscError
    associatedtype RawValue
    
    /**
        描述错误的键值(枚举值)

        每个错误枚举都当有一个 rawValue 属性，且该 rawValue 必须为 String 类型。
        
        一般使用 enum 声明一个错误列表，并将其键值设为 String 即可。
        ``` swift
        enum MyErrorList: String, ErrList {
            case error1 = "该错误 1 的解释"
            case error2 = "该错误 2 的解释"
            ...
        }
        ```
    */
    var rawValue: RawValue { get }
    /**
        为一个错误设置细节信息

        此函数簇 d(...) 的名称是细节 detail 的缩写，你可以为此为你错误列表中的错误设置细节信息。

        参数解释：

        - **explain**：为该错误设置一个解释，通常是比较细节的内容。
        - **mark**：为该错误设置一个标记，便于排错(仅仅是用于展示以及比对，该库不用它做任何其他用处)。
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
    func d(file: String, line: Int, function: String) -> ErrType
    func d(_ explain: String, file: String, line: Int, function: String) -> ErrType
    func d(_ mark: Int, file: String, line: Int, function: String) -> ErrType
    func d(_ explain: String, _ mark: Int, file: String, line: Int, function: String) -> ErrType
}

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
        var mark: Int?
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
    
    /// 该错误的错误枚举值
    var error: (any ErrList)! { get set }
    /// 该错误的附加解释
    var explain: String? { get set }
    /// 该错误的标记，仅用做展示和区分，无其他作用
    var mark: Int? { get set }
    /// 错误发生所在的文件位置
    var file: String! { get set }
    /// 错误发生所在的行数
    var line: Int! { get set }
    /// 错误发生所在的函数
    var function: String! { get set }
    /// 该错误的子错误
    var subError: Error? { get set }
    
    /// 初始化方法，你需要在你的自定义错误类型中实现该构建函数。
    init()

    /// 错误的初始化方法，默认实现会自动为 ```summary, explain, mark, file, line, function``` 赋值。
    ///
    /// 尽管该方法是开放的，但也避免直接使用该方法生成错误。尽管这是可以的，但十分冗长。
    /// 尽量不要覆写此方法，除非你知道你在做什么。
    init(error: any ErrList, explain: String?, mark: Int?, file: String, line: Int, function: String)

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
    /// func initAdds(_ addtion: AdditionType, new: inout Self) { }
    /// ```
    func initAdds(_ addtion: AdditionType, new: inout Self)
}

/**
    #### 错误转换函数
    
    当某个 api 的 throw 抛出的错误，并非你所希望的错误类型，你可以转换其抛出的错误。例如：

    -----
    ### 转换抛出错误

    以下模拟了一个函数，并且抛出了一个错误。但是有时，你可能并不希望该函数抛出这样的错误。且该函数由于某些原因你无法修改(例如，该函数来自其他第三方库)
    ``` swift
    func throwError() throws {
        ... do something ...
        // 抛出 SomeError.err
        throw SomeError.err
    }

    enum WanttedErrorTypes: String, ErrList {
        case error1 = "错误 1"
        case error2 = "错误 2"
        case error3 = "错误 3"
        ...
    }

    typealias A = WanttedErrorTypes

    try throwError() // 抛出错误为 SomeError.err，并不是我想要的，而我希望它若发生错误便抛出 A.error1.d("错误的解释...", 3) 以适应 Whooshing 的错误处理系统。
    ```
    你可以使用传统的 `do - catch` 结构来完成，像下面这样：

    ``` swift
    do {
        try throwError()
    } catch {   // 当 throwError() 方法发生错误并抛出错误后，捕获该错误，并改为 throw 另一个。
        throw A.error1.d("错误的解释...", 3)
    }
    ```

    也可以使用所提供的 cv(_, _) 方法：

    ``` swift
    try Guard({ throwError() }, throw: A.error1.d("错误的解释...", 3))  // 当 throwError() 发生错误时，会抛出所期望的错误。
    ```

    事实上这两种方式的实现方法是一致的，但后者更简洁。
*/
public func Guard<T>(_ cmd: () throws -> T, throw to: any Err) throws -> T {
    do { let res = try cmd(); return res }
    catch let err { throw to.subErr(err) }
}

// MARK: - 以下包括一些协议的默认实现

public extension ErrList {
    func d(file: String = #file, line: Int = #line, function: String = #function) -> ErrType { detail(loc: (file, line, function)) }
    func d(_ explain: String, file: String = #file, line: Int = #line, function: String = #function) -> ErrType { detail(explain: explain, loc: (file, line, function)) }
    func d(_ mark: Int, file: String = #file, line: Int = #line, function: String = #function) -> ErrType { detail(mark: mark, loc: (file, line, function)) }
    func d(_ explain: String, _ mark: Int, file: String = #file, line: Int = #line, function: String = #function) -> ErrType { detail(explain: explain, mark: mark, loc: (file, line, function)) }
}

private extension ErrList {
    func detail(explain: String? = nil, mark: Int? = nil, loc: (file: String, line: Int, function: String)) -> ErrType { ErrType(error: self, explain: explain, mark: mark, file: loc.file, line: loc.line, function: loc.function) }
}

public extension Err {
    init(error: any ErrList, explain: String?, mark: Int?, file: String, line: Int, function: String) {
        self.init()
        self.error = error
        self.explain = explain
        self.mark = mark
        self.file = file
        self.line = line
        self.function = function
    }

    func subErr(_ err: Error?) -> Self {
        var new = self
        new.subError = err
        return new
    }
    
    func adds(_ addtion: AdditionType) -> Self {
        var new = self
        initAdds(addtion, new: &new)
        return new
    }
}

public extension Err {
    static func == (lhs: Self, rhs: Self) -> Bool {
        type(of: lhs.error) == type(of: rhs.error) &&
        lhs.error.rawValue == rhs.error.rawValue &&
        lhs.explain == rhs.explain &&
        lhs.mark == rhs.mark &&
        lhs.file == rhs.file &&
        lhs.line == rhs.line
    }
    
    func isSameType(of err: any Err) -> Bool {
        type(of: self) == type(of: err) &&
        self.error.rawValue == err.error.rawValue
    }
}

public extension Err {
    var description: String {
        descriptionString(withHead: true)
    }
    
    func descriptionString(withHead: Bool) -> String {
        var res = ""
        
        if withHead && subError != nil {
            res += "Error Chains:\n"
            res += "\t"
        }
        
        if !withHead {
            res += "\t"
        }
        
        res += "\(String(describing: type(of: error!))).\(error!.self)("
        let preds = ["\"", "\"", "#", "At \""]
        let appes = ["\"", "\"", "", "\""]
        var resArr: [String] = []
        for (i, curData) in (["\(error.rawValue)", explain, mark != nil ? String(mark!) : nil, self.file + ":" + String(self.line) + " -> " + self.function] as [String?]).enumerated() {
            if let d = curData { resArr.append(preds[i] + d + appes[i]) }
        }
        res += resArr.joined(separator: ", ") + ")"
        
        if let subErr = subError {
            if let bscErr = subErr as? (any Err) {
                res += "\n" + bscErr.descriptionString(withHead: false)
            } else {
                res += "\n\t\(String(describing: type(of: subErr))).\(subErr.self)"
            }
            
            if withHead {
                res += "\nError Chains Ended"
            }
        }
        
        return res
    }
}

public extension Err where AdditionType == Never {
    func initAdds(_ addtion: AdditionType, new: inout Self) { }
}

public struct StringError: Error, CustomStringConvertible, ExpressibleByStringLiteral {
    public let reason: String
    
    public init(_ reason: String) {
        self.reason = reason
    }
    
    public init(stringLiteral value: StringLiteralType) {
        self.reason = value
    }
    
    public var description: String { self.reason }
}
