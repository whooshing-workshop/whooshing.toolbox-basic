import Vapor
import DataConvertable
import Cryptos

extension Data: @retroactive Content {}


extension Crypto.Symm.Key: @retroactive @unchecked Sendable {}
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
