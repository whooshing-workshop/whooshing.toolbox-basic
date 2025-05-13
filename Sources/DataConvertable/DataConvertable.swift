import Foundation
import ErrorHandle

/// 数据转换模块可能出现的所有错误
public enum ConvertionErrorTypes: String, ErrList, Sendable {
    public var domain: String { "ToolboxBsc.Convertion" }
    case dataToString = "将 Data 转换为 String 时出错"
    case StringtoData = "将 String 转换为 Data 时出错"
    case dataToBase64String = "将 Data 转换为 Base64String 时出错"
    case base64StringtoData = "将 Base64String 转换为 Data 时出错"
    case dataToNum = "将 Data 转换为 Number 时出错"
    case numToData = "将 Number 转换为 Data 时出错"
    case dataToArray = "将 Data 转换为 Array 时出错"
    case arrayToData = "将 Array 转换为 Data 时出错"
    case dataToDictionary = "将 Data 转换为 Dictionary 时出错"
    case dictionaryToData = "将 Dictionary 转换为 Data 时出错"
    case uuidToData = "将 UUID 转换为 Data 时出错"
    case dataToUuid = "将 Data 转换为 UUID 时出错"
    case typeEraseCastFailed = "类型擦除转换失败"
}

public typealias CvtErr = ConvertionErrorTypes

/**
    #### 实现该协议的类型，即表示其转换可能失败，引发 throw

    例如 `String` 类型默认实现了该协议，因此它可以：
    ``` swift 
    do {
        // 声明一个字符串
        let string = "Hello World!"
        // 将字符串转为 Data
        let data = try string.data()
        // 重新将 Data 转为字符串
        let newString = try String(data: data)

        print(string == newString)      // true
    } catch let err {
        // 数据转换时出现了错误，需要处理错误
        print(err)
    }
    ```

    无论是转为 Data 或是从 Data 转回，都需要使用 try 修饰，以处理其错误，当然若你十分确定不会出错，可以强制执行：
    ``` swift 
    // 声明一个字符串
    let string = "Hello World!"
    // 将字符串转为 Data
    let data = try! string.data()
    // 重新将 Data 转为字符串
    let newString = try! String(data: data)

    print(string == newString)      // true
    ```

    另外一个协议 `SafeDataConvertable`，表示该类型执行转换时是安全的，不会抛出错误
    
    -----
    ### 数组 与 Data 互转

    数组是否为 Safe 的转换类型，取决于其中的类型，若其中的类型是 Throwable 的，那么该 Array 便为 Throwable；
    若其中类型为 Safe，则该 Array 为 Safe：

    ``` swift
    // Int 类型是 Safe 的
    let arr = [1, 2, 3]
    let arrData = arr.data()
    let newArr = [Int](data: arrData)

    print(arr == newArr)        // true
    ```

    而若使用 ```[String]``` 类型，则 Array 变为 Throwable：

    ``` swift
    do {
        let arr = ["1", "2", "3"]
        let arrData = try arr.data()
        let newArr = try [String](data: arrData)
        print(arr == newArr)            // true
    } catch let err {
        print(err)
    }
    ```
    -----
    ### 字典类型与 Data 互转

    字典是 Throwable 的转换类型，无论 Key 和 Value 如何

    ``` swift
    do {
        let dic = [1: "One", 2: "Two", 3: "Three"]
        let data = try dic.data()
        let newDic = try [Int: String](data: data)

        print(dic == newDic)        // true
    } catch let err {
        print(err)
    }
    ```
    -----
    ### 目前所有实现该协议的类型：

    - `SafeDataConvertable`
        - `Data`
        - `Int`
        - `Int8`
        - `Int16`
        - `Int32`
        - `Int64`
        - `UInt`
        - `UInt8`
        - `UInt16`
        - `UInt32`
        - `UInt64`
        - `Float`
        - `Double`
        - `Decimal`
        - `Date`
        - `Dictionary<SafeDataConvertable: SafeDataConvertable>`
        - `Range<SafeDataConvertable>`
        - `ClosedRange<SafeDataConvertable>`
        - `Array<SafeDataConvertable>`

    - `ThrowableDataConvertable`
        - `String`
        - `Base64String`
        - `UUID`
        - `Dictionary<key == ThrowableDataConvertable or value == ThrowableDataConvertable>`
        - `Range<ThrowableDataConvertable>`
        - `ClosedRange<ThrowableDataConvertable>`
        - `Array<ThrowableDataConvertable>`

    你也可以自己实现该协议，以创建转换类型
*/
public protocol ThrowableDataConvertable: Codable, Hashable { 
    init(data: Data) throws
    func data() throws -> Data 
}

/**
    #### 实现该协议的类型，即表示其进行类型转换一定成功

    例如，```Int``` 类型(包括所有数字类型)，默认实现了该协议，因此它可以：
    ``` swift
    let int = 100
    let data = int.data()
    let newInt = Int(data: data)
    ```
    另见协议 `ThrowableDataConvertable`
*/
public protocol SafeDataConvertable: ThrowableDataConvertable {
    /// 从 Data 初始化该类型，无错误抛出
    init(data: Data)
    /// 转换为 Data，无错误抛出
    func data() -> Data 
}

public extension ThrowableDataConvertable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        try self.init(data: data)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.data())
    }
    
    func hash(into hasher: inout Hasher) { try! hasher.combine(self.data()) }
    static func == (lhs: Self, rhs: Self) -> Bool { (try? lhs.data() == rhs.data()) ?? false }
}

public extension SafeDataConvertable {
    func hash(into hasher: inout Hasher) { hasher.combine(self.data()) }
}

/// Base64 编码的字符串，用于加解密时进行数据传输时使用。对于有特殊字符的字符串进行数据转换会出错。
public struct Base64String: ThrowableDataConvertable, CustomStringConvertible, Equatable, Sendable {
    public let string: String
    public var description: String { string }
    public init(_ string: String) { self.string = string }
    public init(data: Data) { self.string = data.base64EncodedString() }
    public func data() throws -> Data {
        guard let d = Data(base64Encoded: string) else { throw CvtErr.base64StringtoData.d(1030, (#file, #line)) }
        return d
    }
    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.string == rhs.string }
}

// MARK: - 以下为各协议的默认实现

extension Data: SafeDataConvertable {
    /// 从 Data 初始化该类型，有错误抛出
    public init(data: Data) { self = data }
    /// 转换为 Data，有错误抛出
    public func data() -> Data { self }
}

extension String: ThrowableDataConvertable {
    public init(data: Data) throws {
        guard let s = String(data: data, encoding: .utf8) else { throw CvtErr.dataToString.d(1002, (#file, #line)) }
        self = s
    }

    public func data() throws -> Data {
        guard let d = self.data(using: .utf8) else { throw CvtErr.StringtoData.d(1001, (#file, #line)) }
        return d
    }
}

public extension SafeDataConvertable where Self: ExpressibleByIntegerLiteral {
    init(data: Data) {
        var value: Self = 0
        if data.count < MemoryLayout.size(ofValue: value) { 
            print(CvtErr.dataToNum.d("将把数字以 0 处理", 1005, (#file, #line)))
            self = 0
        }
        _ = Swift.withUnsafeMutableBytes(of: &value, { data.copyBytes(to: $0)} )
        self = value
    }

    func data() -> Data { Swift.withUnsafeBytes(of: self) { Data($0) } }
}

extension Array: ThrowableDataConvertable where Element: ThrowableDataConvertable {
    public init(data: Data) throws{ self = try Self.createSelf(data: data) }
    public func data() throws -> Data { try self.toData() }

    private static func createSelf(data: Data) throws -> Self {
        var elements = [Element]()
        var remainingData = data
        while !remainingData.isEmpty {
            let element = try Element(data: remainingData)
            elements.append(element)
            remainingData = remainingData.advanced(by: try element.data().count)
        }
        return elements
    } 

    private func toData() throws -> Data {
        var combinedData = Data()
        for element in self {
            combinedData.append(try element.data())
        }
        return combinedData
    }
}

extension Array: SafeDataConvertable where Element: SafeDataConvertable {
    public init(data: Data) { self = try! Self.createSelf(data: data) }
    public func data() -> Data { try! self.toData() }
}

extension Dictionary: SafeDataConvertable where Key: SafeDataConvertable, Value: SafeDataConvertable {
    public init(data: Data) {
        let d = try! [AnyThrowableDataConvertable: AnyThrowableDataConvertable](data: data)
        let res = d.reduce(into: [Key: Value]()) { try! $0[$1.key.cast(to: Key.self)] = $1.value.cast(to: Value.self) }
        self = res
    }
    public func data() -> Data { try! (self as (any ThrowableDataConvertable)).data() }
}

extension Dictionary: ThrowableDataConvertable where Key: ThrowableDataConvertable, Value: ThrowableDataConvertable {
    public init(data: Data) throws {
        let lsize = MemoryLayout.size(ofValue: Int.self)
        var curLength = 0
        var res: [Key: Value] = [:]
        while (curLength < data.count) {
            let kLength = Int(data: data.subdata(in: curLength..<(curLength + lsize))); curLength += lsize
            let vLength = Int(data: data.subdata(in: curLength..<(curLength + lsize))); curLength += lsize
            let k = try Key(data: data.subdata(in: curLength..<(curLength + kLength))); curLength += kLength
            let v = try Value(data: data.subdata(in: curLength..<(curLength + vLength))); curLength += vLength
            res[k] = v
        }
        self = res
    }

    public func data() throws -> Data { 
        var res = Data()
        for (key, value) in self {
            let kData = try key.data()
            let vData = try value.data()
            res += kData.count.data() + vData.count.data() + kData + vData
        }
        return res
    }
}

extension UUID: ThrowableDataConvertable {
    public init(data: Data) throws {
        guard let v = try UUID(uuidString: String(data: data)) else { throw CvtErr.dataToUuid.d(1050, (#file, #line)) }
        self = v
    }
    
    public func data() -> Data { try! self.uuidString.data() }
}

extension Date: SafeDataConvertable {
    public init(data: Data) { self = Date(timeIntervalSince1970: TimeInterval(data: data)) }
    public func data() -> Data { self.timeIntervalSince1970.data() }
}

extension Range: SafeDataConvertable where Bound: SafeDataConvertable {
    public init(data: Data) {
        let size = MemoryLayout.size(ofValue: Int.self)
        let lowerBoundSize = Int(data: data.prefix(size))
        let upperBoundSize = Int(data: data.subdata(in: size..<(size + size)))
        let lowerBound = Bound(data: data.subdata(in: (size * 2)..<(size * 2 + lowerBoundSize)))
        let upperBound = Bound(data: data.suffix(upperBoundSize))
        self = Self(uncheckedBounds: (lower: lowerBound, upper: upperBound))
    }
    public func data() -> Data { try! (self as (any ThrowableDataConvertable)).data() }
}

extension Range: ThrowableDataConvertable where Bound: ThrowableDataConvertable {
    public init(data: Data) throws {
        let size = MemoryLayout.size(ofValue: Int.self)
        let lowerBoundSize = Int(data: data.prefix(size))
        let upperBoundSize = Int(data: data.subdata(in: size..<(size + size)))
        let lowerBound = try Bound(data: data.subdata(in: (size * 2)..<(size * 2 + lowerBoundSize)))
        let upperBound = try Bound(data: data.suffix(upperBoundSize))
        self = Self(uncheckedBounds: (lower: lowerBound, upper: upperBound))
    }
    public func data() throws -> Data {
        let lowerData = try self.lowerBound.data()
        let upperData = try self.upperBound.data()
        return lowerData.count.data() + upperData.count.data() + lowerData + upperData
    }
}

extension ClosedRange: SafeDataConvertable where Bound: SafeDataConvertable {
    public init(data: Data) {
        let size = MemoryLayout.size(ofValue: Int.self)
        let lowerBoundSize = Int(data: data.prefix(size))
        let upperBoundSize = Int(data: data.subdata(in: size..<(size + size)))
        let lowerBound = Bound(data: data.subdata(in: (size * 2)..<(size * 2 + lowerBoundSize)))
        let upperBound = Bound(data: data.suffix(upperBoundSize))
        self = Self(uncheckedBounds: (lower: lowerBound, upper: upperBound))
    }
    public func data() -> Data { try! (self as (any ThrowableDataConvertable)).data() }
}

extension ClosedRange: ThrowableDataConvertable where Bound: ThrowableDataConvertable {
    public init(data: Data) throws {
        let size = MemoryLayout.size(ofValue: Int.self)
        let lowerBoundSize = Int(data: data.prefix(size))
        let upperBoundSize = Int(data: data.subdata(in: size..<(size + size)))
        let lowerBound = try Bound(data: data.subdata(in: (size * 2)..<(size * 2 + lowerBoundSize)))
        let upperBound = try Bound(data: data.suffix(upperBoundSize))
        self = Self(uncheckedBounds: (lower: lowerBound, upper: upperBound))
    }
    public func data() throws -> Data {
        let lowerData = try self.lowerBound.data()
        let upperData = try self.upperBound.data()
        return lowerData.count.data() + upperData.count.data() + lowerData + upperData
    }
}

extension Int: SafeDataConvertable {}
extension Int8: SafeDataConvertable {}
extension Int16: SafeDataConvertable {}
extension Int32: SafeDataConvertable {}
extension Int64: SafeDataConvertable {}
extension UInt: SafeDataConvertable {}
extension UInt8: SafeDataConvertable {}
extension UInt16: SafeDataConvertable {}
extension UInt32: SafeDataConvertable {}
extension UInt64: SafeDataConvertable {}
extension Float: SafeDataConvertable {}
extension Double: SafeDataConvertable {}
extension Decimal: SafeDataConvertable {}
