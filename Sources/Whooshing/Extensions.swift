import Vapor
import DataConvertable
import Cryptos

extension Data: @retroactive AsyncResponseEncodable {}
extension Data: @retroactive AsyncRequestDecodable {}
extension Data: @retroactive ResponseEncodable {}
extension Data: @retroactive RequestDecodable {}
extension Data: @retroactive Content {}

extension Crypto.Symm.Key: @retroactive @unchecked Sendable {}
extension Crypto.Symm.Key: @retroactive AsyncResponseEncodable {}
extension Crypto.Symm.Key: @retroactive AsyncRequestDecodable {}
extension Crypto.Symm.Key: @retroactive ResponseEncodable {}
extension Crypto.Symm.Key: @retroactive RequestDecodable {}
extension Crypto.Symm.Key: @retroactive Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let data = withUnsafeBytes { Data($0) }
        try container.encode(data)
    }
}
extension Crypto.Symm.Key: @retroactive Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        self.init(data: data)
    }
}
extension Crypto.Symm.Key: @retroactive Content {}


extension Crypto.Asym.CPrivateKey: @retroactive @unchecked Sendable {}
extension Crypto.Asym.CPrivateKey: @retroactive AsyncResponseEncodable {}
extension Crypto.Asym.CPrivateKey: @retroactive AsyncRequestDecodable {}
extension Crypto.Asym.CPrivateKey: @retroactive ResponseEncodable {}
extension Crypto.Asym.CPrivateKey: @retroactive RequestDecodable {}
extension Crypto.Asym.CPrivateKey: @retroactive Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawRepresentation)
    }
}
extension Crypto.Asym.CPrivateKey: @retroactive Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        try self.init(rawRepresentation: data)
    }
}
extension Crypto.Asym.CPrivateKey: @retroactive Content {}


extension Crypto.Asym.CPublicKey: @retroactive @unchecked Sendable {}
extension Crypto.Asym.CPublicKey: @retroactive AsyncResponseEncodable {}
extension Crypto.Asym.CPublicKey: @retroactive AsyncRequestDecodable {}
extension Crypto.Asym.CPublicKey: @retroactive ResponseEncodable {}
extension Crypto.Asym.CPublicKey: @retroactive RequestDecodable {}
extension Crypto.Asym.CPublicKey: @retroactive Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawRepresentation)
    }
}
extension Crypto.Asym.CPublicKey: @retroactive Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        try self.init(rawRepresentation: data)
    }
}
extension Crypto.Asym.CPublicKey: @retroactive Content {}


extension Crypto.Asym.SPrivateKey: @retroactive @unchecked Sendable {}
extension Crypto.Asym.SPrivateKey: @retroactive AsyncResponseEncodable {}
extension Crypto.Asym.SPrivateKey: @retroactive AsyncRequestDecodable {}
extension Crypto.Asym.SPrivateKey: @retroactive ResponseEncodable {}
extension Crypto.Asym.SPrivateKey: @retroactive RequestDecodable {}
extension Crypto.Asym.SPrivateKey: @retroactive Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawRepresentation)
    }
}
extension Crypto.Asym.SPrivateKey: @retroactive Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        try self.init(rawRepresentation: data)
    }
}
extension Crypto.Asym.SPrivateKey: @retroactive Content {}


extension Crypto.Asym.SPublicKey: @retroactive @unchecked Sendable {}
extension Crypto.Asym.SPublicKey: @retroactive AsyncResponseEncodable {}
extension Crypto.Asym.SPublicKey: @retroactive AsyncRequestDecodable {}
extension Crypto.Asym.SPublicKey: @retroactive ResponseEncodable {}
extension Crypto.Asym.SPublicKey: @retroactive RequestDecodable {}
extension Crypto.Asym.SPublicKey: @retroactive Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawRepresentation)
    }
}
extension Crypto.Asym.SPublicKey: @retroactive Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        try self.init(rawRepresentation: data)
    }
}
extension Crypto.Asym.SPublicKey: @retroactive Content {}
