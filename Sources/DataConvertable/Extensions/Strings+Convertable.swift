import Foundation
import ErrorHandle

extension String: ThrowableDataConvertable {
    @frozen
    public enum EncodeErrcase: String, ErrList {
        case dataToStringFailed = "将 Data 编码为 UTF8 String 失败"
    }
    
    @frozen
    public enum DecodeErrcase: String, ErrList {
        case stringToDataFailed = "将 String 解码为 Data 失败"
    }
    
    @inlinable
    public static func make(data: Data) -> Res<String, EncodeErrcase> {
        guard let s = String(data: data, encoding: .utf8) else { return .failure(.dataToStringFailed) }
        return .success(s)
    }

    @inlinable
    public var dataRes: Res<Data, DecodeErrcase> {
        guard let d = self.data(using: .utf8) else { return .failure(.stringToDataFailed) }
        return .success(d)
    }
}


/// Base64 编码的字符串，用于加解密时进行数据传输时使用。对于有特殊字符的字符串进行数据转换会出错。
@frozen
public struct Base64String: Sendable {
    public let string: String
    
    @inlinable
    public init(_ string: String) { self.string = string }
}

extension Base64String: CustomStringConvertible {
    @inlinable
    public var description: String { string }
}

extension Base64String: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.string == rhs.string }
}

extension Base64String: EncodingSafeDataConvertable {
    @inlinable
    public static func new(data: Data) -> Base64String {
        Self.init(data.base64EncodedString())
    }
}

extension Base64String: DecodingThrowableDataConvertable {
    @frozen
    public enum Errcase: String, ErrList {
        case stringToDataBase64Failed = "将 String 解码为 Base64 Data 失败"
    }
    
    @inlinable
    public var dataRes: Res<Data, Errcase> {
        guard let d = Data(base64Encoded: string) else { return .failure(.stringToDataBase64Failed) }
        return .success(d)
    }
}
