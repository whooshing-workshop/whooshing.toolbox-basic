/// 私有，您永远不应当使用
protocol __ErrList_Base where Self.ErrType: Err, Self.RawValue == String {
    associatedtype ErrType
    associatedtype RawValue
    var rawValue: RawValue { get }
}

extension __ErrList_Base {
    fileprivate func detail(explain: String? = nil, mark: Int? = nil, addition: ErrType.AdditionType, loc: (file: String, line: Int)) -> ErrType { ErrType(summary: self.rawValue, explain: explain, mark: mark, addition: addition, file: loc.file, line: loc.line) }
}

/// 私有，您永远不应当使用
protocol __ErrList_WithAddition: __ErrList_Base {
    func d(_ addition: ErrType.AdditionType, _ file: String, _ line: Int) -> ErrType
    func d(_ mark: Int, _ addition: ErrType.AdditionType, _ file: String, _ line: Int) -> ErrType
    func d(_ explain: String, _ addition: ErrType.AdditionType, _ loc: (String, Int)) -> ErrType
    func d(_ explain: String, _ mark: Int, _ addition: ErrType.AdditionType, _ loc: (String, Int)) -> ErrType
}

extension __ErrList_WithAddition {
    func d(_ addition: ErrType.AdditionType, _ file: String, _ line: Int) -> ErrType { detail(addition: addition, loc: (file, line)) }
    func d(_ mark: Int, _ addition: ErrType.AdditionType, _ file: String, _ line: Int) -> ErrType { detail(mark: mark, addition: addition, loc: (file, line)) }
    func d(_ explain: String, _ addition: ErrType.AdditionType, _ loc: (String, Int)) -> ErrType { detail(explain: explain, addition: addition, loc: loc) }
    func d(_ explain: String, _ mark: Int, _ addition: ErrType.AdditionType, _ loc: (String, Int)) -> ErrType { detail(explain: explain, mark: mark, addition: addition, loc: loc) }
}

/// 私有，您永远不应当使用
protocol __ErrList_WithoutAddtion: __ErrList_Base {
    func d(_ file: String, _ line: Int) -> ErrType
    func d(_ explain: String, _ file: String, _ line: Int) -> ErrType
    func d(_ mark: Int, _ file: String, _ line: Int) -> ErrType
    func d(_ explain: String, _ loc: (String, Int)) -> ErrType
    func d(_ explain: String, _ mark: Int, _ loc: (String, Int)) -> ErrType
}

extension __ErrList_WithoutAddtion where ErrType.AdditionType: ExpressibleByNilLiteral {
    func d(_ file: String, _ line: Int) -> ErrType { detail(addition: nil, loc: (file, line)) }
    func d(_ explain: String, _ file: String, _ line: Int) -> ErrType { detail(explain: explain, addition: nil, loc: (file, line)) }
    func d(_ mark: Int, _ file: String, _ line: Int) -> ErrType { detail(mark: mark, addition: nil, loc: (file, line)) }
    func d(_ explain: String, _ loc: (String, Int)) -> ErrType { detail(explain: explain, addition: nil, loc: loc) }
    func d(_ explain: String, _ mark: Int, _ loc: (String, Int)) -> ErrType { detail(explain: explain, mark: mark, addition: nil, loc: loc) }
}

/**
    #### 错误列表的协议声明
    
    该协议定义了错误生成方法的默认实现。你只需要在你的错误列表枚举中实现该协议，列出所有的错误即可，但需注意一些细节。例如：

    ---
    ## 实现该协议以创建自己的错误列表。
    ``` swift
    enum NormalErrorTypes: String, ErrList {
        // 表示该错误列表中的错误，都是 BscError 类型的。
        typealias ErrType = BscError
        case error1 = "Error 1 summary"
        case error2 = "Error 2 summary"
    }
    
    // 如果愿意，可以设置类型别名，看起来更简洁。
    typealias A = NormalErrorTypes

    func demo() throws {
        ...
        // 创建错误并抛出
        throw let err = A.error1.d("一些错误解释，即 explain", 1, (#file, #line))
        ...
    }
    ```

    #### 若你创建了自定义错误类 ```ErrType```，并对其进行了扩展
    - ```ErrListWithIndeedAddition```，当你的 ErrType 的 AdditionType 不为可选值时，请代为实现该协议
    - ```ErrListWithOptionAddition```，当你的 ErrType 的 AdditionType 为可选值时，请代为实现该协议

    ---
    ## 实现 ErrListWithIndeedAddition 和 ErrListWithOptionAddition 以使用你的自定义错误类型
    ```
    // 实现 ErrListWithIndeedAddition，因为该错误类型的 AdditionType 为 [Int]
    // 未使用 ErrListWithOptionAddition，因为该 AdditionType 并非可选值
    enum NormalErrorTypes: String, ErrListWithIndeedAddition {
        // 表示该错误列表中的错误，都是 CustomError 类型的。
        typealias ErrType = CustomError
        case error1 = "Error 1 summary"
        case error2 = "Error 2 summary"
    }

    // 自定义错误类型并进行扩展
    struct CustomError: Err {
        typealias AdditionType = [Int]
        var summary: String!
        var explain: String?
        var file: String!
        var line: Int!
        var mark: Int?
        // 自定义字段 1
        var addtionInformation: Int!
        // 自定义字段 2
        var addtionInformation2: Int!
        ...

        // 自定义扩展类型赋值。
        mutating func initAddtions(_ data: [Int]) {
            self.addtionInformation = data[0]
            self.addtionInformation2 = data[1]
            ...
        }
    }

    typealias B = NormalErrorTypes

    func xxx() throws {
        ...
        // 其中 [1, 3] 则是为自定义扩展数据类型赋值
        let err = B.error1.d("错误的解释", 2, [1, 3], (#file, #line))
        print(err.addtionInformation) // 1
        print(err.addtionInformation2) // 3
        throw err
        ...
    }
    ```

    当然，你也可以在自定义错误类型和错误列表中定义和实现任何方法等等，但这通常是不必要的。
*/
protocol ErrList: __ErrList_WithoutAddtion {}
/// #### 见协议 ```ErrList```
protocol ErrListWithIndeedAddition: __ErrList_WithAddition {}
/// #### 见协议 ```ErrList```
protocol ErrListWithOptionAddition: __ErrList_WithoutAddtion, __ErrList_WithAddition {}

class ErrorAdditionTypeNull {}

/**
    #### 错误类型的协议声明

    你可以自定义自己的错误类型，如果你希望扩展它，尝试覆写 ```initAdditions(_)``` 方法。

    ---
    ## 实现该协议以创建自己的错误类型。
    ``` swift
    struct CustomError: Err {
        typealias AdditionType = [String]
        var summary: String!
        var explain: String?
        var file: String!
        var line: Int!
        var mark: Int?
        var addtionInformation: String!
        var addtionInformation2: String!
        ....

        mutating func initAddtions(_ data: [String]) {
            self.addtionInformation = data[0]
            self.addtionInformation2 = data[1]
            ....
        }
    }
    ```
*/
protocol Err: Error, CustomStringConvertible {
    /// 扩展类型，默认为 ErrorAdditionTypeNull，即空类。配合 ```initAdditions(_)``` 方法实现和扩展你的错误类型。
    associatedtype AdditionType = ErrorAdditionTypeNull?
    
    var summary: String! { get set }
    var explain: String? { get set }
    var mark: Int? { get set }
    var file: String! { get set }
    var line: Int! { get set }

    init()

    /// #### 错误的初始化方法，默认实现会自动为 ```summary, explain, mark, file, line``` 赋值。
    /// 尽管该方法是开放的，但也避免直接使用该方法生成错误。尽管这是可以的，但十分冗长。
    /// 尽量不要覆写此方法，除非你知道你在做什么。
    init(summary: String, explain: String?, mark: Int?, addition: AdditionType, file: String, line: Int)

    /// #### 扩展数据初始化，默认不进行任何动作。
    /// 若你需要扩展你的错误类型，覆写该方法。
    mutating func initAddtions(_ data: AdditionType)
}

extension Err {
    init(summary: String, explain: String?, mark: Int?, addition: AdditionType, file: String, line: Int) {
        self.init()
        self.summary = summary
        self.explain = explain
        self.mark = mark
        self.file = file
        self.line = line
        initAddtions(addition)
    }
    
    var description: String {
        var res = String(describing: type(of: self)) + "("
        let preds = ["\"", "\"", "#", "At \""]
        let appes = ["\"", "\"", "", "\""]
        var resArr: [String] = []
        for (i, curData) in ([summary, explain, mark != nil ? String(mark!) : nil, self.file + ":" + String(self.line)] as [String?]).enumerated() {
            if let d = curData { resArr.append(preds[i] + d + appes[i]) }
        }
        res += resArr.joined(separator: ", ") + ")"
        return res
    }
}

extension Err where AdditionType == ErrorAdditionTypeNull? {
    mutating func initAddtions(_ data: AdditionType) {}
}

/**
    #### 默认错误类型

    如果愿意，你可以自定自己的错误类型。见 ```protocol Err```

    另外，避免直接使用该 struct 的初始化方法直接产生 BscError，尽管这是可以的，但十分冗长。
    
    一般情况下，这个默认错误类型已经足够，但你可能希望实现你自己的错误类型。为此，你需要先创建 ErrorList，其中定义了所有可能出现的错误，并给予 summary。以下是一个例子：

    ---
    ## 声明和使用错误类型
    ``` swift
    enum NormalErrorTypes: String, ErrList {
        // 表示该错误列表中的错误，都是 BscError 类型的。
        typealias ErrType = BscError
        case error1 = "Error 1 summary"
        case error2 = "Error 2 summary"
    }
    
    // 如果愿意，可以设置类型别名，看起来更简洁。
    typealias A = NormalErrorTypes

    func demo() throws {
        ...
        // 创建错误并抛出
        throw let err = A.error1.d("一些错误解释，即 explain", 1, (#file, #line))
        ...
    }
    ```
*/
struct BscError: Err {
    /// 描述该错误。
    var summary: String!
    /// 每次发生错误时，可以自行阐述一些附加说明。
    var explain: String?
    /// 每次发生错误，可以为其指定一个标记，方便排错。
    var mark: Int?
    /// 发生错误的文件名称。
    var file: String!
    /// 发生错误的行数。
    var line: Int!
}