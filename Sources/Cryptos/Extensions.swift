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

public struct SendableSymmKey: Sendable, SafeDataConvertable {
    public let key: Crypto.Symm.Key
    
    @inlinable
    public init(key: Crypto.Symm.Key) {
        self.key = key
    }
    
    @inlinable
    public static func new(data: Data) -> SendableSymmKey {
        .init(key: .init(data: data))
    }
    
    @inlinable
    public var data: Data { key.data }
}

public struct SendableAsymCPrivateKey: Sendable, EncodingThrowableDataConvertable, DecodingSafeDataConvertable {
    public let key: Crypto.Asym.CPrivateKey
    
    @inlinable
    public init(key: Crypto.Asym.CPrivateKey) {
        self.key = key
    }
    
    @inlinable
    public static func make(data: Data) -> Result<Self, Crypto.Asym.CPrivateKey.EncodeErrcase.ErrType> {
        .init { () throws(Crypto.Asym.CPrivateKey.EncodeErrcase.ErrType) in
            try Self.init(key: .make(data: data).get())
        }
    }
    
    @inlinable
    public var data: Data { key.data }
}

public struct SendableAsymCPublicKey: Sendable, EncodingThrowableDataConvertable, DecodingSafeDataConvertable {
    public let key: Crypto.Asym.CPublicKey
    
    @inlinable
    public init(key: Crypto.Asym.CPublicKey) {
        self.key = key
    }
    
    @inlinable
    public static func make(data: Data) -> Result<Self, Crypto.Asym.CPublicKey.EncodeErrcase.ErrType> {
        .init { () throws(Crypto.Asym.CPublicKey.EncodeErrcase.ErrType) in
            try Self.init(key: .make(data: data).get())
        }
    }
    
    @inlinable
    public var data: Data { key.data }
}

public struct SendableAsymSPrivateKey: Sendable, EncodingThrowableDataConvertable, DecodingSafeDataConvertable {
    public let key: Crypto.Asym.SPrivateKey
    
    @inlinable
    public init(key: Crypto.Asym.SPrivateKey) {
        self.key = key
    }
    
    @inlinable
    public static func make(data: Data) -> Result<Self, Crypto.Asym.SPrivateKey.EncodeErrcase.ErrType> {
        .init { () throws(Crypto.Asym.SPrivateKey.EncodeErrcase.ErrType) in
            try Self.init(key: .make(data: data).get())
        }
    }
    
    @inlinable
    public var data: Data { key.data }
}

public struct SendableAsymSPublicKey: Sendable, EncodingThrowableDataConvertable, DecodingSafeDataConvertable {
    public let key: Crypto.Asym.SPublicKey
    
    @inlinable
    public init(key: Crypto.Asym.SPublicKey) {
        self.key = key
    }
    
    @inlinable
    public static func make(data: Data) -> Result<Self, Crypto.Asym.SPublicKey.EncodeErrcase.ErrType> {
        .init { () throws(Crypto.Asym.SPublicKey.EncodeErrcase.ErrType) in
            try Self.init(key: .make(data: data).get())
        }
    }
    
    @inlinable
    public var data: Data { key.data }
}
