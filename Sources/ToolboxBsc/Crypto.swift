import Crypto
import Foundation

enum EncryptionError: Error {
    case conversionFailed
    case unsupportedType
}

class Crypto {
    func symmetricEncrypt<DataType: DataProtocol>(_ data: DataType, key: SymmetricKey) throws -> DataType {
        let sealedBox = try AES.GCM.seal(data, using: key)
        let ciphertext = sealedBox.ciphertext

        if DataType.self == String.self {
            // Convert ciphertext to String if DataType is String
            guard let stringResult = String(data: ciphertext, encoding: .utf8) as? DataType else {
                throw EncryptionError.conversionFailed
            }
            return stringResult
        } else if DataType.self == Data.self {
            // Return as Data if DataType is Data
            guard let dataResult = ciphertext as? DataType else {
                throw EncryptionError.conversionFailed
            }
            return dataResult
        } else if DataType.self == [UInt8].self {
            // Convert Data to [UInt8] if DataType is [UInt8]
            guard let arrayResult = Array(ciphertext) as? DataType else {
                throw EncryptionError.conversionFailed
            }
            return arrayResult
        } else {
            throw EncryptionError.unsupportedType
        }
    }


}
