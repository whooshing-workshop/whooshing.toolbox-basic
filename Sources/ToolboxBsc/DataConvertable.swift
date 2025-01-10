import Foundation

public enum ConvertionErrorTypes: String, ErrList {
    public var domain: String { "Convertion.Error" }
    case dataToString = "将 Data 转换为 String 时出错"
    case StringtoData = "将 String 转换为 Data 时出错"
    case dataToNum = "将 Data 转换为 Number 时出错"
    case numToData = "将 Number 转换为 Data 时出错"
    case dataToArray = "将 Data 转换为 Array 时出错"
    case arrayToData = "将 Array 转换为 Data 时出错"
    case dataToDictionary = "将 Data 转换为 Dictionary 时出错"
    case dictionaryToData = "将 Dictionary 转换为 Data 时出错"
}

public typealias CvtErr = ConvertionErrorTypes

public protocol ThrowableDataConvertable { 
    init(data: Data) throws
    func data() throws -> Data 
}

public protocol SafeDataConvertable: ThrowableDataConvertable {
    init(data: Data)
    func data() -> Data 
}

extension Data: SafeDataConvertable {
    public init(data: Data) { self = data }
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

extension Dictionary: ThrowableDataConvertable {
    public init(data: Data) throws { 
        guard let dic = (try Guard({ try JSONSerialization.jsonObject(with: data) }, throw: CvtErr.dataToDictionary.d("JSON 解包失败", 1011, (#file, #line)))) as? Self else {
            print(CvtErr.dataToDictionary.d("转换结果为 nil，将字典以空处理", 1012, (#file, #line)))
            self = [:]
            return
        }
        self = dic
    }

    public func data() throws -> Data { 
        return try Guard({ try JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]) }, throw: CvtErr.dictionaryToData.d("JSON 封装失败", 1013, (#file, #line)))
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
