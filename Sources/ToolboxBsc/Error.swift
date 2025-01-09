/**
    #### 默认错误类型

    最基本的错误类型，以一个结构体的方式记录各种错误信息，包括：

    - **domain**：该错误的错误域，仅用做展示和区分，无其他作用
    - **summary**：该错误的描述
    - **explain**：该错误的附加解释
    - **mark**：该错误的标记，仅用做展示和区分，无其他作用
    - **file**：错误发生所在的文件位置
    - **line**：错误发生所在的行数

    但请避免直接使用该 ```struct``` 的初始化方法直接产生 ```BscError```，尽管这是可以的，但十分冗长。

    一般，你需要列出自己的错误列表，使用该错误列表来创建一个错误，见下面的例子：

    ---
    ## 声明和使用错误类型
    ``` swift
    // 声明一个错误列表，需要实现 ErrList 协议，并确保枚举值为 String。有关 ErrList 协议，请详见它的解释。
    enum NormalErrorTypes: String, ErrList {
        // 表示该错误列表中的错误，都是 BscError 类型的。
        typealias ErrType = BscError
        var domain: String { "错误3.domain" }
        case error1 = "Error 1 summary"
        case error2 = "Error 2 summary"
    }
    
    // 可以设置类型别名，看起来更简洁。这一步非必须。
    typealias A = NormalErrorTypes

    func demo() throws {
        ...
        // 使用错误列表提供的方法来创建错误并抛出
        // 这几个参数依次是上面列出的 explain, mark, file, line
        throw let err = A.error1.d("一些错误解释，即 explain", 1001, (#file, #line))
        ...
    }

    // 运行该函数触发错误
    do {
        try demo(...)
    } catch let err {   // 捕获该错误
        print(err)      // 打印： 错误3.domain("Error 1 summary", "一些错误解释", #1001, At "Error.swift:36")
    }
    ```

    如果愿意，你可以自定自己的错误类型。见 ```protocol Err```
*/
struct BscError: Err {
    var domain: String!
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
        // 为你的错误列表设定域名，仅仅作为展示和区分，无其他作用
        // 在这里设置错误域，这个错误域将会被设置到每一个 BscError 中，见 ```BscError.domain```。
        // 这行也非必须，那么该名称默认为 "Error"
        var domain: String { "错误" }

        // 列出所有的错误，并为其指定 summary
        case error1 = "Error 1 summary"
        case error2 = "Error 2 summary"
    }
    
    // 如果愿意，可以设置类型别名，看起来更简洁。该行非必须。
    typealias A = NormalErrorTypes

    func demo() throws {
        ...
        // 创建错误并抛出
        throw let err = A.error1.d("一些错误解释，即 explain", 1011, (#file, #line))
        ...
    }
    ```

    #### 若你创建了自定义错误类 ```ErrType```，并对其进行了扩展，详见协议 ```Err``` 创建自定义错误类型。
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
        var domain: String { "错误2" }
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
protocol ErrList: ErrListBasicInterface { 
    /**
        #### 为一个错误设置细节信息

        此函数簇 d(...) 是细节 detail 的缩写，你可以为此为你错误列表中的错误设置细节信息。

        参数解释：

        - **explain**：为该错误设置一个解释，通常是比较细节的内容。
        - **mark**：为该错误设置一个标记，便于排错(仅仅是用于展示以及比对，该库不用它做任何其他用处)。
        - **file**：该错误发生的文件。
        - **line**：该错误发生的行数。

        例如：

        ``` swift
        ErrorList.error1.d("一些解释", 1004, (#file, #line))
        ```

        这些细节信息通常不是恒定不变的，例如：systemError，它的描述 (summary) 可能为 “系统发生错误”。
        而你可以为其添加更详细的解释 (explain)，可能为 “数据库认证用户 XXX 时失败”。

        表现在代码中，它可以如此定义和使用：

        ``` swift
        enum MyErrorTypes: ErrList {
            // 为你的错误列表设定域名，仅仅作为展示和区分，无其他作用
            var domain: String { "我的自定义错误.domain" }
            case systemError = "系统发生错误"
        }

        // 这一步非必须
        typealias A = MyErrorTypes

        func databaseAction(...) throws {
            ...
            throws A.systemError.d("数据库认证用户 XXX 时失败", 1006, (#file, #line))
            ...
        }

        // 运行该函数触发错误
        do {
            try databaseAction(...)
        } catch let err {   // 捕获该错误
            print(err) // 打印： 我的自定义错误.domain("系统发生错误", "数据库认证用户 XXX 时失败", #1006, At "Error.swift:128")
        }
        ```
    */
    func d(_ file: String, _ line: Int) -> ErrType
    func d(_ explain: String, _ file: String, _ line: Int) -> ErrType
    func d(_ mark: Int, _ file: String, _ line: Int) -> ErrType
    func d(_ explain: String, _ loc: (String, Int)) -> ErrType
    func d(_ explain: String, _ mark: Int, _ loc: (String, Int)) -> ErrType
}

/// #### 见协议 ```ErrList```
protocol ErrListWithIndeedAddition: ErrListBasicInterface { 
    func d(_ addition: ErrType.AdditionType, _ file: String, _ line: Int) -> ErrType
    func d(_ mark: Int, _ addition: ErrType.AdditionType, _ file: String, _ line: Int) -> ErrType
    func d(_ explain: String, _ addition: ErrType.AdditionType, _ loc: (String, Int)) -> ErrType
    func d(_ explain: String, _ mark: Int, _ addition: ErrType.AdditionType, _ loc: (String, Int)) -> ErrType
}

/// #### 见协议 ```ErrList```
protocol ErrListWithOptionAddition: ErrList, ErrListWithIndeedAddition { }

/**
    #### 错误列表的基本协议

    **永远不要直接实现该协议，除非你想自己实现所有的接口！**
    
    该协议中定义了你自定自己错误列表时所需要实现的所有基本内容。
    
    要自定义自己的错误列表，应当实现协议 ```ErrList``` 或 ```ErrListWithIndeedAddition``` 或 ```ErrListWithOptionAddition```
    它们的接口都有默认实现，因此你只需要列出错误列表，而不需要实现其他接口。请详见它们的解释。
*/
protocol ErrListBasicInterface where Self.ErrType: Err, Self.RawValue == String {
    associatedtype ErrType = BscError
    associatedtype RawValue
    /// 该错误列表的错误域名，仅作为展示和与其他错误列表做区分，无其他用途。
    var domain: String { get }
    /**
        #### 描述错误的键值(枚举值)

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

        try throwError() // 抛出错误为 SomeError.err，并不是我想要的，而我希望它若发生错误便抛出 A.error1.d("错误的解释...", #3, (#file, #line)) 以适应 Whooshing 的错误处理系统。
        ```
        你可以使用传统的 ```do - catch``` 结构来完成，像下面这样：

        ``` swift
        do {
            try throwError()
        } catch {   // 当 throwError() 方法发生错误并抛出错误后，捕获该错误，并改为 throw 另一个。
            throw A.error1.d("错误的解释...", #3, (#file, #line))
        }
        ```

        也可以使用所提供的 cv(_, _) 方法：

        ``` swift
        try A.cv({ throwError() }, .error1.d("错误的解释...", #3, (#file, #line)))  // 当 throwError() 发生错误时，会抛出所期望的错误。
        ```

        事实上这两种方式的实现方法是一致的，但后者更简洁。
    */
    static func cv<T>(_ cmd: () throws -> T, _ to: Self.ErrType) throws -> T
}

/**
    #### 错误类型的协议声明

    你可以自定义自己的错误类型，如果你希望扩展它，尝试覆写 ```initAdditions(_)``` 方法。

    ---
    ## 创建自定义错误类型。

    许多时候 BscError 已经足够使用，若要创建自定义类型，可以像如下这般：
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

    /// #### 该错误类型的错误域，
    /// 仅仅只是用作区分展示，无其他作用。使用该错误域区分可以更方便排错。例如 加密错误 可以用 crypto.error 作为域名，而 数据库错误 可以用 database.error 做域名。
    /// 这个错误名称仅仅展示在 error.summary 中，当然你也可以在代码逻辑中使用该参数。
    var domain: String! { get set }
    /// 该错误的描述
    var summary: String! { get set }
    /// 该错误的附加解释
    var explain: String? { get set }
    /// 该错误的标记，仅用做展示和区分，无其他作用
    var mark: Int? { get set }
    /// 错误发生所在的文件位置
    var file: String! { get set }
    /// 错误发生所在的行数
    var line: Int! { get set }

    init()

    /// #### 错误的初始化方法，默认实现会自动为 ```summary, explain, mark, file, line``` 赋值。
    /// 尽管该方法是开放的，但也避免直接使用该方法生成错误。尽管这是可以的，但十分冗长。
    /// 尽量不要覆写此方法，除非你知道你在做什么。
    init(domain: String, summary: String, explain: String?, mark: Int?, addition: AdditionType, file: String, line: Int)

    /// #### 扩展数据初始化，默认不进行任何动作。
    /// 若你需要扩展你的错误类型，覆写该方法。
    mutating func initAddtions(_ data: AdditionType)
}

// MARK: - 以下包括一些协议的默认实现

class ErrorAdditionTypeNull {}

extension ErrList where ErrType.AdditionType: ExpressibleByNilLiteral {
    func d(_ file: String, _ line: Int) -> ErrType { detail(addition: nil, loc: (file, line)) }
    func d(_ explain: String, _ file: String, _ line: Int) -> ErrType { detail(explain: explain, addition: nil, loc: (file, line)) }
    func d(_ mark: Int, _ file: String, _ line: Int) -> ErrType { detail(mark: mark, addition: nil, loc: (file, line)) }
    func d(_ explain: String, _ loc: (String, Int)) -> ErrType { detail(explain: explain, addition: nil, loc: loc) }
    func d(_ explain: String, _ mark: Int, _ loc: (String, Int)) -> ErrType { detail(explain: explain, mark: mark, addition: nil, loc: loc) }
}

extension ErrListWithIndeedAddition {
    func d(_ addition: ErrType.AdditionType, _ file: String, _ line: Int) -> ErrType { detail(addition: addition, loc: (file, line)) }
    func d(_ mark: Int, _ addition: ErrType.AdditionType, _ file: String, _ line: Int) -> ErrType { detail(mark: mark, addition: addition, loc: (file, line)) }
    func d(_ explain: String, _ addition: ErrType.AdditionType, _ loc: (String, Int)) -> ErrType { detail(explain: explain, addition: addition, loc: loc) }
    func d(_ explain: String, _ mark: Int, _ addition: ErrType.AdditionType, _ loc: (String, Int)) -> ErrType { detail(explain: explain, mark: mark, addition: addition, loc: loc) }
}

extension ErrListBasicInterface {
    var domain: String { "Error" }
    fileprivate func detail(explain: String? = nil, mark: Int? = nil, addition: ErrType.AdditionType, loc: (file: String, line: Int)) -> ErrType { ErrType(domain: self.domain, summary: self.rawValue, explain: explain, mark: mark, addition: addition, file: loc.file, line: loc.line) }
    static func cv<T>(_ cmd: () throws -> T, _ to: Self.ErrType) throws -> T {
        do { let res = try cmd(); return res }
        catch { throw to }
    }
}

extension Err {
    init(domain: String, summary: String, explain: String?, mark: Int?, addition: AdditionType, file: String, line: Int) {
        self.init()
        self.domain = domain
        self.summary = summary
        self.explain = explain
        self.mark = mark
        self.file = file
        self.line = line
        initAddtions(addition)
    }
    
    var description: String {
        var res = self.domain + "("
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