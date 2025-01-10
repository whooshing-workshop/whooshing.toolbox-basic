// import Crypto
// import Foundation

// enum CryptoErrorLists: String, ErrList {
//     var domain: String { "Crypto.Error" }
//     case dataConversionFailed = "数据转换失败"
//     case encryptFailed = "加密失败"
//     case decryptFailed = "解密失败"
// }

// typealias CptErr = CryptoErrorLists

// public enum Crypto {

//     static func hash(_ data: SafeDataConvertable) -> Data { try! hash(data as ThrowableDataConvertable) }
//     static func hash(_ data: ThrowableDataConvertable) throws -> Data { .init(try HashFunction.hash(data: data.data())) }

//     public enum Symm{
//         typealias Key = SymmetricKey
//         static func makeKey() -> Key { Key(size: symmetricKeySize) }

//         static func encrypt(_ data: ThrowableDataConvertable, key: Key) throws -> Data { try aesEncrypt(data, key: key) }
//         static func decrypt<D>(_ cipher: Data, key: Key) throws -> D where D: ThrowableDataConvertable { try aesDecrypt(cipher, key: key) }

//         public enum Hmac {
//             static func make(_ data: SafeDataConvertable, key: Key) -> Data { try! make(data as ThrowableDataConvertable, key: key) }
//             static func make(_ data: ThrowableDataConvertable, key: Key) throws -> Data { .init(try HMAC<HashFunction>.authenticationCode(for: data.data(), using: key)) }
            
//             static func validate(_ data: SafeDataConvertable, authCode: Data, key: Key) -> Bool { try! validate(data as ThrowableDataConvertable, authCode: authCode, key: key) }
//             static func validate(_ data: ThrowableDataConvertable, authCode: Data, key: Key) throws -> Bool { try HMAC<HashFunction>.isValidAuthenticationCode(data.data(), authenticating: authCode, using: key) }
//         }
//     }

//     public enum Asym {
//         typealias Key = Curve25519.KeyAgreement.PrivateKey
//         typealias PublicKey = Key.PublicKey
//         static func makeKeyPair() -> Key { Key() }
        
//         static func keyEncapsulate(key: Key, partyPublic: PublicKey, salt: ThrowableDataConvertable, info: ThrowableDataConvertable) throws -> Symm.Key { 
//             let sharedKey = try key.sharedSecretFromKeyAgreement(with: partyPublic)
//             return try sharedKey.hkdfDerivedSymmetricKey(using: HashFunction.self, salt: salt.data(), sharedInfo: info.data(), outputByteCount: symmetricKeySize.bitCount)
//         }

//         public enum Sign {
//             static func make(_ data: ThrowableDataConvertable, key: Key) throws -> Data {
//                 let k = try Curve25519.Signing.PrivateKey(rawRepresentation: key.rawRepresentation)
//                 return try k.signature(for: data.data())
//             }
//             static func validate(_ data: ThrowableDataConvertable, sign: Data, key: PublicKey) throws -> Bool {
//                 let k = try Curve25519.Signing.PublicKey(rawRepresentation: key.rawRepresentation)
//                 return try k.isValidSignature(sign, for: data.data())
//             }
//         }
//     }
// }

// private extension Crypto {
//     typealias HashFunction = SHA512
//     static var symmetricKeySize: SymmetricKeySize { SymmetricKeySize.bits256 }
// }

// private extension Crypto.Symm {
//     static func aesEncrypt(_ data: ThrowableDataConvertable, key: Key) throws -> Data {
//         let sealedBox = try AES.GCM.seal(data.data(), using: key)
//         guard let cipher = sealedBox.combined else {
//             throw CptErr.encryptFailed.d("未成功生成加密数据", 1006, (#file, #line))
//         }
//         return cipher
//     }

//     static func aesDecrypt<D>(_ cipher: Data, key: Key) throws -> D where D: ThrowableDataConvertable {
//         let sealedBox = try Guard( { try AES.GCM.SealedBox(combined: cipher) }, throw: CptErr.decryptFailed.d("将密文转换为 SealedBox 时出错", 1007, (#file, #line)))
//         let decryptedData = try Guard({ try AES.GCM.open(sealedBox, using: key) }, throw: CptErr.decryptFailed.d("解开密文时出错", 1008, (#file, #line)))
//         return try D(data: decryptedData)
//     }

//     static func aesKey(key: Data) -> Key { normalKey(key: key) }
// }

// private extension Crypto.Symm {
//     static func normalKey(key: Data) -> Key { Key(data: key) }
// }




// protocol ThrowableDataConvertable { 
//     init(data: Data) throws
//     func data() throws -> Data 
// }

// protocol SafeDataConvertable: ThrowableDataConvertable {
//     init(data: Data)
//     func data() -> Data 
// }

// extension Data: SafeDataConvertable {
//     init(data: Data) { self = data }
//     func data() -> Data { self }
// }

// extension String: ThrowableDataConvertable {
//     init(data: Data) throws {
//         guard let s = String(data: data, encoding: .utf8) else { throw CptErr.dataConversionFailed.d("将 Data 转换为 String 时出错", 1002, (#file, #line)) }
//         self = s
//     }

//     func data() throws -> Data {
//         guard let d = self.data(using: .utf8) else { throw CptErr.dataConversionFailed.d("将 String 转换为 Data 时出错", 1001, (#file, #line)) }
//         return d
//     }
// }

// extension SafeDataConvertable where Self: ExpressibleByIntegerLiteral {
//     init(data: Data) {
//         var value: Self = 0
//         if data.count < MemoryLayout.size(ofValue: value) { 
//             print(CptErr.dataConversionFailed.d("将 Data 转换为 Number 时出错，将以 0 处理", 1005, (#file, #line)))
//             self = 0
//         }
//         _ = Swift.withUnsafeMutableBytes(of: &value, { data.copyBytes(to: $0)} )
//         self = value
//     }

//     func data() -> Data { Swift.withUnsafeBytes(of: self) { Data($0) } }
// }

// extension Array: ThrowableDataConvertable where Element: ThrowableDataConvertable {
//     init(data: Data) throws{
//         var elements = [Element]()
//         var remainingData = data
//         while !remainingData.isEmpty {
//             let element = try Element(data: remainingData)
//             elements.append(element)
//             remainingData = remainingData.advanced(by: try element.data().count)
//         }
//         self = elements
//     }

//     func data() throws -> Data {
//         var combinedData = Data()
//         for element in self {
//             combinedData.append(try element.data())
//         }
//         return combinedData
//     }
// }

// extension Array: SafeDataConvertable where Element: SafeDataConvertable {
//     init(data: Data) {
//         var elements = [Element]()
//         var remainingData = data
//         while !remainingData.isEmpty {
//             let element = Element(data: remainingData)
//             elements.append(element)
//             remainingData = remainingData.advanced(by: element.data().count)
//         }
//         self = elements
//     }
    
//     func data() -> Data {
//         var combinedData = Data()
//         for element in self {
//             combinedData.append(element.data())
//         }
//         return combinedData
//     }
// }

// extension Array where Element: ExpressibleByIntegerLiteral {
//     init(data: Data) {
//         var array = Array<Element>(repeating: 0, count: data.count / MemoryLayout<Element>.stride)
//         _ = array.withUnsafeMutableBytes { data.copyBytes(to: $0) }
//         self = array
//     }

//     func data() -> Data { self.withUnsafeBytes { Data($0) } }
// }

// extension Int: SafeDataConvertable {}
// extension Int8: SafeDataConvertable {}
// extension Int16: SafeDataConvertable {}
// extension Int32: SafeDataConvertable {}
// extension Int64: SafeDataConvertable {}
// extension UInt: SafeDataConvertable {}
// extension UInt8: SafeDataConvertable {}
// extension UInt16: SafeDataConvertable {}
// extension UInt32: SafeDataConvertable {}
// extension UInt64: SafeDataConvertable {}
// extension Float: SafeDataConvertable {}
// extension Double: SafeDataConvertable {}
// extension Decimal: SafeDataConvertable {}
