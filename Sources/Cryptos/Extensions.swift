import Foundation
import Crypto
import DataConvertable
import ErrorHandle

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
