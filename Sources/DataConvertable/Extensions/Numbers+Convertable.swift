import Foundation
import ErrorHandle

public extension EncodingSafeDataConvertable where Self: ExpressibleByIntegerLiteral {
    static func new(data: Data) -> Self {
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
        return value
    }
}

public extension DecodingSafeDataConvertable where Self: ExpressibleByIntegerLiteral {
    var data: Data { Swift.withUnsafeBytes(of: self) { Data($0) } }
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
