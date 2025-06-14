import Foundation
import Crypto
import DataConvertable
import ErrorHandle

extension Crypto.Symm.Key: @retroactive @unchecked Sendable {}
extension Crypto.Symm.Key: @retroactive Codable {}
extension Crypto.Symm.Key: @retroactive Hashable {}
extension Crypto.Symm.Key: SafeDataConvertable {
    public enum EncodeErrcase: String, ErrList {
        case initFromDataFailed = "从 Data 生成 Key 失败"
    }
    public func data() -> Data { self.withUnsafeBytes { Data($0) } }
}

extension Crypto.Asym.CPublicKey: @retroactive @unchecked Sendable {}
extension Crypto.Asym.CPrivateKey: @retroactive Codable {}
extension Crypto.Asym.CPrivateKey: @retroactive Hashable {}
extension Crypto.Asym.CPrivateKey: ThrowableDataConvertable {
    public enum EncodeErrcase: String, ErrList {
        case initFromDataFailed = "从 Data 生成 Key 失败"
    }
    public init(data: Data) throws(BscError<EncodeErrcase>) {
        self = try required(throws: EncodeErrcase.initFromDataFailed) {
            try Self.init(rawRepresentation: data)
        }
    }
    public func data() -> Data { self.rawRepresentation }
}

extension Crypto.Asym.CPrivateKey: @retroactive @unchecked Sendable {}
extension Crypto.Asym.CPublicKey: @retroactive Codable {}
extension Crypto.Asym.CPublicKey: @retroactive Hashable {}
extension Crypto.Asym.CPublicKey: ThrowableDataConvertable {
    public enum EncodeErrcase: String, ErrList {
        case initFromDataFailed = "从 Data 生成 Key 失败"
    }
    public init(data: Data) throws(BscError<EncodeErrcase>) {
        self = try required(throws: EncodeErrcase.initFromDataFailed) {
            try Self.init(rawRepresentation: data)
        }
    }
    public func data() -> Data { self.rawRepresentation }
}

extension Crypto.Asym.SPublicKey: @retroactive @unchecked Sendable {}
extension Crypto.Asym.SPrivateKey: @retroactive Codable {}
extension Crypto.Asym.SPrivateKey: @retroactive Hashable {}
extension Crypto.Asym.SPrivateKey: ThrowableDataConvertable {
    public enum EncodeErrcase: String, ErrList {
        case initFromDataFailed = "从 Data 生成 Key 失败"
    }
    public init(data: Data) throws(BscError<EncodeErrcase>) {
        self = try required(throws: EncodeErrcase.initFromDataFailed) {
            try Self.init(rawRepresentation: data)
        }
    }
    public func data() -> Data { self.rawRepresentation }
}

extension Crypto.Asym.SPrivateKey: @retroactive @unchecked Sendable {}
extension Crypto.Asym.SPublicKey: @retroactive Codable {}
extension Crypto.Asym.SPublicKey: @retroactive Hashable {}
extension Crypto.Asym.SPublicKey: ThrowableDataConvertable {
    public enum EncodeErrcase: String, ErrList {
        case initFromDataFailed = "从 Data 生成 Key 失败"
    }
    public init(data: Data) throws(BscError<EncodeErrcase>) {
        self = try required(throws: EncodeErrcase.initFromDataFailed) {
            try Self.init(rawRepresentation: data)
        }
    }
    public func data() -> Data { self.rawRepresentation }
}
