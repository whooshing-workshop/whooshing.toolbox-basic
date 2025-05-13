import Foundation
import Crypto
import DataConvertable

extension Crypto.Symm.Key: Sendable {}
extension Crypto.Symm.Key: @retroactive Codable {}
extension Crypto.Symm.Key: @retroactive Hashable {}
extension Crypto.Symm.Key: SafeDataConvertable {
    public func data() -> Data { self.withUnsafeBytes { Data($0) } }
}

extension Crypto.Asym.CPublicKey: Sendable {}
extension Crypto.Asym.CPrivateKey: @retroactive Codable {}
extension Crypto.Asym.CPrivateKey: @retroactive Hashable {}
extension Crypto.Asym.CPrivateKey: ThrowableDataConvertable {
    public init(data: Data) throws { try self = Self.init(rawRepresentation: data) }
    public func data() -> Data { self.rawRepresentation }
}

extension Crypto.Asym.CPrivateKey: Sendable {}
extension Crypto.Asym.CPublicKey: @retroactive Codable {}
extension Crypto.Asym.CPublicKey: @retroactive Hashable {}
extension Crypto.Asym.CPublicKey: ThrowableDataConvertable {
    public init(data: Data) throws { try self = Self.init(rawRepresentation: data) }
    public func data() -> Data { self.rawRepresentation }
}

extension Crypto.Asym.SPublicKey: Sendable {}
extension Crypto.Asym.SPrivateKey: @retroactive Codable {}
extension Crypto.Asym.SPrivateKey: @retroactive Hashable {}
extension Crypto.Asym.SPrivateKey: ThrowableDataConvertable {
    public init(data: Data) throws { try self = Self.init(rawRepresentation: data) }
    public func data() -> Data { self.rawRepresentation }
}

extension Crypto.Asym.SPrivateKey: Sendable {}
extension Crypto.Asym.SPublicKey: @retroactive Codable {}
extension Crypto.Asym.SPublicKey: @retroactive Hashable {}
extension Crypto.Asym.SPublicKey: ThrowableDataConvertable {
    public init(data: Data) throws { try self = Self.init(rawRepresentation: data) }
    public func data() -> Data { self.rawRepresentation }
}
