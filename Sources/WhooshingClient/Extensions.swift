import Vapor
import DataConvertable
import Cryptos

extension Crypto.Symm.Key: @retroactive @unchecked Sendable {}
extension Crypto.Asym.CPrivateKey: @retroactive @unchecked Sendable {}
extension Crypto.Asym.CPublicKey: @retroactive @unchecked Sendable {}
extension Crypto.Asym.SPrivateKey: @retroactive @unchecked Sendable {}
extension Crypto.Asym.SPublicKey: @retroactive @unchecked Sendable {}

extension ByteBuffer: SafeDataConvertable {
    public func data() -> Data { .init(buffer: self) }
}


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
