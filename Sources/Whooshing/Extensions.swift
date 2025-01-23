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
extension Crypto.Symm.Key: @retroactive Content {}


extension Crypto.Asym.CPrivateKey: @retroactive @unchecked Sendable {}
extension Crypto.Asym.CPrivateKey: @retroactive AsyncResponseEncodable {}
extension Crypto.Asym.CPrivateKey: @retroactive AsyncRequestDecodable {}
extension Crypto.Asym.CPrivateKey: @retroactive ResponseEncodable {}
extension Crypto.Asym.CPrivateKey: @retroactive RequestDecodable {}
extension Crypto.Asym.CPrivateKey: @retroactive Content {}


extension Crypto.Asym.CPublicKey: @retroactive @unchecked Sendable {}
extension Crypto.Asym.CPublicKey: @retroactive AsyncResponseEncodable {}
extension Crypto.Asym.CPublicKey: @retroactive AsyncRequestDecodable {}
extension Crypto.Asym.CPublicKey: @retroactive ResponseEncodable {}
extension Crypto.Asym.CPublicKey: @retroactive RequestDecodable {}
extension Crypto.Asym.CPublicKey: @retroactive Content {}


extension Crypto.Asym.SPrivateKey: @retroactive @unchecked Sendable {}
extension Crypto.Asym.SPrivateKey: @retroactive AsyncResponseEncodable {}
extension Crypto.Asym.SPrivateKey: @retroactive AsyncRequestDecodable {}
extension Crypto.Asym.SPrivateKey: @retroactive ResponseEncodable {}
extension Crypto.Asym.SPrivateKey: @retroactive RequestDecodable {}
extension Crypto.Asym.SPrivateKey: @retroactive Content {}


extension Crypto.Asym.SPublicKey: @retroactive @unchecked Sendable {}
extension Crypto.Asym.SPublicKey: @retroactive AsyncResponseEncodable {}
extension Crypto.Asym.SPublicKey: @retroactive AsyncRequestDecodable {}
extension Crypto.Asym.SPublicKey: @retroactive ResponseEncodable {}
extension Crypto.Asym.SPublicKey: @retroactive RequestDecodable {}
extension Crypto.Asym.SPublicKey: @retroactive Content {}

public final class SendableDictionary<Key, Value>: @unchecked Sendable where Key: Sendable & Hashable, Value: Sendable {
    public var allKey: [Key: Value].Keys { lock.sync { wrapped.keys } }
    public var allValue: [Key: Value].Values { lock.sync { wrapped.values } }
    private var wrapped: [Key: Value]
    private let lock: DispatchQueue
    public init(wrapped: [Key: Value] = [:], lockLabel: String = String(Int.random())) {
        self.wrapped = wrapped
        self.lock = DispatchQueue(label: "woo.SendableDictionary.lock.\(lockLabel)")
    }
    public subscript(key: Key) -> Value? {
        get { lock.sync { wrapped[key] } }
        set {
            if let v = newValue { lock.sync { wrapped[key] = v } }
            else { lock.sync { _ = wrapped.removeValue(forKey: key) } }
        }
    }
    
    public func forEach(closure: @escaping ((key: Key, value: Value)) -> ()) {
        lock.sync { wrapped.forEach { closure($0) } }
    }
}

public extension URL {
    func toUri(with path: String) -> URI { .init(string: self.absoluteString + path) }
}
