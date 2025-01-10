import Foundation

public enum ConvertionErrorTypes: String, ErrList {
    public var domain: String { "Convertion.Error" }
    case conversionFailed = "数据转换失败"
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
        guard let s = String(data: data, encoding: .utf8) else { throw CvtErr.conversionFailed.d("将 Data 转换为 String 时出错", 1002, (#file, #line)) }
        self = s
    }

    public func data() throws -> Data {
        guard let d = self.data(using: .utf8) else { throw CvtErr.conversionFailed.d("将 String 转换为 Data 时出错", 1001, (#file, #line)) }
        return d
    }
}

extension SafeDataConvertable where Self: ExpressibleByIntegerLiteral {
    public init(data: Data) {
        var value: Self = 0
        if data.count < MemoryLayout.size(ofValue: value) { 
            print(CvtErr.conversionFailed.d("将 Data 转换为 Number 时出错，将以 0 处理", 1005, (#file, #line)))
            self = 0
        }
        _ = Swift.withUnsafeMutableBytes(of: &value, { data.copyBytes(to: $0)} )
        self = value
    }

    public func data() -> Data { Swift.withUnsafeBytes(of: self) { Data($0) } }
}

extension Array: ThrowableDataConvertable where Element: ThrowableDataConvertable {
    public init(data: Data) throws{
        var elements = [Element]()
        var remainingData = data
        while !remainingData.isEmpty {
            let element = try Element(data: remainingData)
            elements.append(element)
            remainingData = remainingData.advanced(by: try element.data().count)
        }
        self = elements
    }

    public func data() throws -> Data {
        var combinedData = Data()
        for element in self {
            combinedData.append(try element.data())
        }
        return combinedData
    }
}

extension Array: SafeDataConvertable where Element: SafeDataConvertable {
    public init(data: Data) {
        var elements = [Element]()
        var remainingData = data
        while !remainingData.isEmpty {
            let element = Element(data: remainingData)
            elements.append(element)
            remainingData = remainingData.advanced(by: element.data().count)
        }
        self = elements
    }
    
    public func data() -> Data {
        var combinedData = Data()
        for element in self {
            combinedData.append(element.data())
        }
        return combinedData
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
