import Foundation
import Crypto
import DataConvertable
import ErrorHandle

extension SymmetricKey: @retroactive Encodable {}
extension SymmetricKey: @retroactive Hashable {}
extension SymmetricKey: @retroactive Decodable {}
extension Crypto.Symm.Key: SafeDataConvertable {
    @frozen
    public enum EncodeErrcase: String, ErrList {
        case initFromDataFailed = "从 Data 生成 Key 失败"
    }
    
    @inlinable
    public static func new(data: Data) -> SymmetricKey {
        Self.init(data: data)
    }
    
    @inlinable
    public var data: Data {
        self.withUnsafeBytes { Data($0) }
    }
}

extension Crypto.Asym.CPrivateKey: @retroactive Decodable {}
extension Crypto.Asym.CPrivateKey: @retroactive Hashable {}
extension Crypto.Asym.CPrivateKey: @retroactive Equatable {}
extension Crypto.Asym.CPrivateKey: @retroactive Encodable {}
extension Crypto.Asym.CPrivateKey: EncodingThrowableDataConvertable, DecodingSafeDataConvertable {
    @frozen
    public enum EncodeErrcase: String, ErrList {
        case initFromDataFailed = "从 Data 生成 Key 失败"
    }
    
    @inlinable
    public static func make(data: Data) -> Res<Self, EncodeErrcase> {
        .init(throws: .initFromDataFailed) {
            try Self.init(rawRepresentation: data)
        }
    }
    
    @inlinable
    public var data: Data {
        self.rawRepresentation
    }
}

extension Crypto.Asym.CPublicKey: @retroactive Decodable {}
extension Crypto.Asym.CPublicKey: @retroactive Hashable {}
extension Crypto.Asym.CPublicKey: @retroactive Equatable {}
extension Crypto.Asym.CPublicKey: @retroactive Encodable {}
extension Crypto.Asym.CPublicKey: EncodingThrowableDataConvertable, DecodingSafeDataConvertable {
    @frozen
    public enum EncodeErrcase: String, ErrList {
        case initFromDataFailed = "从 Data 生成 Key 失败"
    }
    
    @inlinable
    public static func make(data: Data) -> Res<Self, EncodeErrcase> {
        .init(throws: .initFromDataFailed) {
            try Self.init(rawRepresentation: data)
        }
    }
    
    @inlinable
    public var data: Data {
        self.rawRepresentation
    }
}

extension Crypto.Asym.SPrivateKey: @retroactive Decodable {}
extension Crypto.Asym.SPrivateKey: @retroactive Hashable {}
extension Crypto.Asym.SPrivateKey: @retroactive Equatable {}
extension Crypto.Asym.SPrivateKey: @retroactive Encodable {}
extension Crypto.Asym.SPrivateKey: EncodingThrowableDataConvertable, DecodingSafeDataConvertable {
    @frozen
    public enum EncodeErrcase: String, ErrList {
        case initFromDataFailed = "从 Data 生成 Key 失败"
    }
    
    @inlinable
    public static func make(data: Data) -> Res<Self, EncodeErrcase> {
        .init(throws: .initFromDataFailed) {
            try Self.init(rawRepresentation: data)
        }
    }
    
    @inlinable
    public var data: Data { self.rawRepresentation }
}

extension Crypto.Asym.SPublicKey: @retroactive Decodable {}
extension Crypto.Asym.SPublicKey: @retroactive Hashable {}
extension Crypto.Asym.SPublicKey: @retroactive Equatable {}
extension Crypto.Asym.SPublicKey: @retroactive Encodable {}
extension Crypto.Asym.SPublicKey: EncodingThrowableDataConvertable, DecodingSafeDataConvertable {
    @frozen
    public enum EncodeErrcase: String, ErrList {
        case initFromDataFailed = "从 Data 生成 Key 失败"
    }
    
    @inlinable
    public static func make(data: Data) -> Res<Self, EncodeErrcase> {
        .init(throws: .initFromDataFailed) {
            try Self.init(rawRepresentation: data)
        }
    }
    
    @inlinable
    public var data: Data {
        self.rawRepresentation
    }
}
