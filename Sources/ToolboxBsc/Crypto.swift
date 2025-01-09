import Crypto
import Foundation

enum CryptoErrorLists: String, ErrList {
    var domain: String { "Crypto.Error" }
    case dataConversionFailed = "数据转换失败"
    case encryptFailed = "加密失败"
}

typealias CptErr = CryptoErrorLists

public class Crypto {

    static func symmetricKey() -> SymmetricKey { SymmetricKey(size: .bits256) }

    static func symmetricEncrypt(_ data: DataConvertable, key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data.data(), using: key)
        guard let cipher = sealedBox.combined else {
            throw CptErr.encryptFailed.d("未成功生成加密数据", 6, (#file, #line))
        }
        return cipher
    }

    static func symmetricDecrypt<D: DataConvertable>(_ cipher: Data, key: SymmetricKey) throws -> D {
        let sealedBox = try CptErr.cv(
            { try AES.GCM.SealedBox(combined: cipher) }, 
            CptErr.dataConversionFailed.d("将密文转换为 SealedBox 时出错", 7, (#file, #line))
        )
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return try D(data: decryptedData)
    }

}

protocol DataConvertable { 
    init(data: Data) throws
    func data() throws -> Data 
}

extension String: DataConvertable {
    init(data: Data) throws {
        guard let s = String(data: data, encoding: .utf8) else { throw CptErr.dataConversionFailed.d("将 Data 转换为 String 时出错", 2, (#file, #line)) }
        self = s
    }

    func data() throws -> Data {
        guard let d = self.data(using: .utf8) else { throw CptErr.dataConversionFailed.d("将 String 转换为 Data 时出错", 1, (#file, #line)) }
        return d
    }
}

extension Data: DataConvertable {
    init(data: Data) throws { self = data }
    func data() throws -> Data { self }
}

extension DataConvertable where Self: ExpressibleByIntegerLiteral {
    init(data: Data) throws {
        var value: Self = 0
        guard data.count >= MemoryLayout.size(ofValue: value) else { throw CptErr.dataConversionFailed.d("将 Data 转换为 Number 时出错", 5, (#file, #line)) }
        _ = Swift.withUnsafeMutableBytes(of: &value, { data.copyBytes(to: $0)} )
        self = value
    }

    func data() -> Data { Swift.withUnsafeBytes(of: self) { Data($0) } }
}

extension Array: DataConvertable where Element: DataConvertable {
    init(data: Data) throws{
        var elements = [Element]()
        var remainingData = data
        while !remainingData.isEmpty {
            let element = try Element(data: remainingData)
            elements.append(element)
            remainingData = remainingData.advanced(by: try element.data().count)
        }
        self = elements
    }
    func data() throws -> Data {
        var combinedData = Data()
        for element in self {
            combinedData.append(try element.data())
        }
        return combinedData
    }
}

extension Array where Element: DataConvertable & ExpressibleByIntegerLiteral {
    init(data: Data) throws{
        var array = Array<Element>(repeating: 0, count: data.count/MemoryLayout<Element>.stride)
        _ = array.withUnsafeMutableBytes { data.copyBytes(to: $0) }
        self = array
    }

    func data() throws -> Data { self.withUnsafeBytes { Data($0) } }
}

extension Int: DataConvertable {}
extension Int8: DataConvertable {}
extension Int16: DataConvertable {}
extension Int32: DataConvertable {}
extension Int64: DataConvertable {}
extension UInt: DataConvertable {}
extension UInt8: DataConvertable {}
extension UInt16: DataConvertable {}
extension UInt32: DataConvertable {}
extension UInt64: DataConvertable {}
extension Float: DataConvertable {}
extension Double: DataConvertable {}
extension Decimal: DataConvertable {}