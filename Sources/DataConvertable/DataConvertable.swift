import Foundation
import ErrorHandle

/// 数据转换模块可能出现的所有错误
//public enum ConvertionErrorTypes: String, ErrList, Sendable {
//    case dataToString = "将 Data 转换为 String 时出错"
//    case StringtoData = "将 String 转换为 Data 时出错"
//    case dataToBase64String = "将 Data 转换为 Base64String 时出错"
//    case base64StringtoData = "将 Base64String 转换为 Data 时出错"
//    case dataToNum = "将 Data 转换为 Number 时出错"
//    case numToData = "将 Number 转换为 Data 时出错"
//    case dataToArray = "将 Data 转换为 Array 时出错"
//    case arrayToData = "将 Array 转换为 Data 时出错"
//    case dataToDictionary = "将 Data 转换为 Dictionary 时出错"
//    case dictionaryToData = "将 Dictionary 转换为 Data 时出错"
//    case uuidToData = "将 UUID 转换为 Data 时出错"
//    case dataToUuid = "将 Data 转换为 UUID 时出错"
//    case typeEraseCastFailed = "类型擦除转换失败"
//}

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
    associatedtype EncodeErrType: Error
    associatedtype DecodeErrType: Error
    init(data: Data) throws(EncodeErrType)
    func data() throws(DecodeErrType) -> Data
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
    associatedtype EncodeErrType = Never
    associatedtype DecodeErrType = Never
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
    
    public enum Errcase: String, ErrList {
        case stringToDataBase64Failed = "将 String 解码为 Base64 Data 失败"
    }
    
    public let string: String
    public var description: String { string }
    public init(_ string: String) { self.string = string }
    public init(data: Data) { self.string = data.base64EncodedString() }
    public func data() throws(BscError<Errcase>) -> Data {
        guard let d = Data(base64Encoded: string) else { throw .init(.stringToDataBase64Failed) }
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
    
    public enum EncodeErrcase: String, ErrList {
        case dataToStringFailed = "将 Data 编码为 UTF8 String 失败"
    }
    
    public enum DecodeErrcase: String, ErrList {
        case stringToDataFailed = "将 String 解码为 Data 失败"
    }
    
    public init(data: Data) throws(BscError<EncodeErrcase>) {
        guard let s = String(data: data, encoding: .utf8) else { throw .init(.dataToStringFailed) }
        self = s
    }

    public func data() throws(BscError<DecodeErrcase>) -> Data {
        guard let d = self.data(using: .utf8) else { throw .init(.stringToDataFailed) }
        return d
    }
}

extension Array: SafeDataConvertable where Element: SafeDataConvertable {
    public init(data: Data) {
        let d = [AnyThrowableDataConvertable](data: data)
        let res = d.map { try! $0.cast(to: Element.self) }
        self = res
    }
    public func data() -> Data { try! (self as (any ThrowableDataConvertable)).data() }
}

public extension SafeDataConvertable where Self: ExpressibleByIntegerLiteral {
    init(data: Data) {
        var value: Self = 0
        let size = MemoryLayout<Self>.size
        let input: Data

        if data.count > size {
            input = data.prefix(size) // 截取多余部分
        } else if data.count < size {
            input = Data(repeating: 0, count: size - data.count) + data // 前面补零
        } else {
            input = data
        }

        input.withUnsafeBytes { rawBuffer in
            Swift.withUnsafeMutableBytes(of: &value) { valueBuffer in
                valueBuffer.copyMemory(from: rawBuffer)
            }
        }

        self = value
    }

    func data() -> Data { Swift.withUnsafeBytes(of: self) { Data($0) } }
}

extension Array: ThrowableDataConvertable where Element: ThrowableDataConvertable {
    public init(data: Data) throws(Element.EncodeErrType) {
        let lsize = MemoryLayout.size(ofValue: Int.self)
        var curLength = 0
        var res: [Element] = []
        while (curLength < data.count) {
            let kLength = Int(data: data.subdata(in: curLength..<(curLength + lsize))); curLength += lsize
            let value = try Element(data: data.subdata(in: curLength..<(curLength + kLength))); curLength += kLength
            res.append(value)
        }
        self = res
    }
    
    public func data() throws(Element.DecodeErrType) -> Data {
        var res = Data()
        for element in self {
            let data = try element.data()
            res += data.count.data() + data
        }
        return res
    }
}

extension Dictionary: SafeDataConvertable where Key: SafeDataConvertable, Value: SafeDataConvertable {
    public init(data: Data) {
        let d = try! [AnyThrowableDataConvertable: AnyThrowableDataConvertable](data: data)
        let res = d.reduce(into: [Key: Value]()) { try! $0[$1.key.cast(to: Key.self)] = $1.value.cast(to: Value.self) }
        self = res
    }
    public func data() -> Data { try! (self as (any ThrowableDataConvertable)).data() }
}

public enum DictionaryEncodeErrcase: String, ErrList {
    case keyFailed = "字典 Key 编码失败"
    case valueFailed = "字典 Value 编码失败"
}

public enum DictionaryDecodeErrcase: String, ErrList {
    case keyFailed = "字典 Key 解码失败"
    case valueFailed = "字典 Value 解码失败"
}

extension Dictionary: ThrowableDataConvertable where Key: ThrowableDataConvertable, Value: ThrowableDataConvertable {
    
    public init(data: Data) throws(BscError<DictionaryEncodeErrcase>) {
        let lsize = MemoryLayout.size(ofValue: Int.self)
        var curLength = 0
        var res: [Key: Value] = [:]
        while (curLength < data.count) {
            let kLength = Int(data: data.subdata(in: curLength..<(curLength + lsize))); curLength += lsize
            let vLength = Int(data: data.subdata(in: curLength..<(curLength + lsize))); curLength += lsize
            let k = try required(throws: DictionaryEncodeErrcase.keyFailed) {
                try Key(data: data.subdata(in: curLength..<(curLength + kLength)))
            }
            curLength += kLength
            let v = try required(throws: DictionaryEncodeErrcase.valueFailed) {
                try Value(data: data.subdata(in: curLength..<(curLength + vLength)))
            }
            curLength += vLength
            res[k] = v
        }
        self = res
    }

    public func data() throws(BscError<DictionaryDecodeErrcase>) -> Data {
        var res = Data()
        for (key, value) in self {
            let kData = try required(throws: DictionaryDecodeErrcase.keyFailed) {
                try key.data()
            }
            let vData = try required(throws: DictionaryDecodeErrcase.valueFailed) {
                try value.data()
            }
            res += kData.count.data() + vData.count.data() + kData + vData
        }
        return res
    }
}

extension UUID: ThrowableDataConvertable {
    public enum Errcase: String, ErrList {
        case uuidFailed = "Data 到 UUID 编码失败"
    }
    
    public init(data: Data) throws(BscError<Errcase>) {
        guard let v = try required(throws: Errcase.uuidFailed.d("Data 格式不正确"), {
            try UUID(uuidString: String(data: data))
        }) else {
            throw .init(.uuidFailed, "Data 编码后得到空字符串")
        }
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

public enum RangeEncodeErrcase: String, ErrList {
    case lowerBoundFailed = "Range 低边界编码失败"
    case upperBoundFailed = "Range 高边界编码失败"
}

public enum RangeDecodeErrcase: String, ErrList {
    case lowerBoundFailed = "Range 低边界解码失败"
    case upperBoundFailed = "Range 高边界解码失败"
}

extension Range: ThrowableDataConvertable where Bound: ThrowableDataConvertable {
    
    public init(data: Data) throws(BscError<RangeEncodeErrcase>) {
        let size = MemoryLayout.size(ofValue: Int.self)
        let lowerBoundSize = Int(data: data.prefix(size))
        let upperBoundSize = Int(data: data.subdata(in: size..<(size + size)))
        let lowerBound = try required(throws: RangeEncodeErrcase.lowerBoundFailed) {
            try Bound(data: data.subdata(in: (size * 2)..<(size * 2 + lowerBoundSize)))
        }
        let upperBound = try required(throws: RangeEncodeErrcase.upperBoundFailed) {
            try Bound(data: data.suffix(upperBoundSize))
        }
        self = Self(uncheckedBounds: (lower: lowerBound, upper: upperBound))
    }
    public func data() throws(BscError<RangeDecodeErrcase>) -> Data {
        let lowerData = try required(throws: RangeDecodeErrcase.lowerBoundFailed) {
            try self.lowerBound.data()
        }
        let upperData = try required(throws: RangeDecodeErrcase.upperBoundFailed) {
            try self.upperBound.data()
        }
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

public enum ClosedRangeEncodeErrcase: String, ErrList {
    case lowerBoundFailed = "ClosedRange 低边界编码失败"
    case upperBoundFailed = "ClosedRange 高边界编码失败"
}

public enum ClosedRangeDecodeErrcase: String, ErrList {
    case lowerBoundFailed = "ClosedRange 低边界解码失败"
    case upperBoundFailed = "ClosedRange 高边界解码失败"
}

extension ClosedRange: ThrowableDataConvertable where Bound: ThrowableDataConvertable {
    
    public init(data: Data) throws(BscError<ClosedRangeEncodeErrcase>) {
        let size = MemoryLayout.size(ofValue: Int.self)
        let lowerBoundSize = Int(data: data.prefix(size))
        let upperBoundSize = Int(data: data.subdata(in: size..<(size + size)))
        let lowerBound = try required(throws: ClosedRangeEncodeErrcase.lowerBoundFailed) {
            try Bound(data: data.subdata(in: (size * 2)..<(size * 2 + lowerBoundSize)))
        }
        let upperBound = try required(throws: ClosedRangeEncodeErrcase.upperBoundFailed) {
            try Bound(data: data.suffix(upperBoundSize))
        }
        self = Self(uncheckedBounds: (lower: lowerBound, upper: upperBound))
    }
    public func data() throws(BscError<ClosedRangeDecodeErrcase>) -> Data {
        let lowerData = try required(throws: ClosedRangeDecodeErrcase.lowerBoundFailed) {
            try self.lowerBound.data()
        }
        let upperData = try required(throws: ClosedRangeDecodeErrcase.upperBoundFailed) {
            try self.upperBound.data()
        }
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
