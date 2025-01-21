import Foundation
import ErrorHandle

public struct AnySafeDataConvertable: SafeDataConvertable {
    private let _data: () -> Data
    public init<T: SafeDataConvertable>(_ data: T) { self._data = { data.data() } }
    public init(data: Data) { self._data = { data } }
    public func data() -> Data { return _data() }
    public func cast<T: SafeDataConvertable>(to type: T.Type) -> T { T(data: self.data()) }
}

public struct AnyThrowableDataConvertable: ThrowableDataConvertable {
    private let _data: () throws -> Data
    public init<T: ThrowableDataConvertable>(_ data: T) { self._data = { try data.data() } }
    public init(data: Data) { self._data = { data } }
    public func data() throws -> Data { return try _data() }
    public func cast<T: ThrowableDataConvertable>(to type: T.Type) throws -> T { try T(data: self.data()) }
}


public extension Dictionary where Key: ThrowableDataConvertable {
    var anyKey: [AnyThrowableDataConvertable: Value] { self.reduce(into: [AnyThrowableDataConvertable: Value]()) { $0[.init($1.key)] = $1.value } }
}

public extension Dictionary where Key: SafeDataConvertable {
    var anyKey: [AnySafeDataConvertable: Value] { self.reduce(into: [AnySafeDataConvertable: Value]()) { $0[.init($1.key)] = $1.value } }
}



public extension Dictionary where Value: ThrowableDataConvertable {
    var anyValue: [Key: AnyThrowableDataConvertable] { self.reduce(into: [Key: AnyThrowableDataConvertable]()) { $0[$1.key] = .init($1.value) } }
}

public extension Dictionary where Key: ThrowableDataConvertable, Value: ThrowableDataConvertable {
    var any: [AnyThrowableDataConvertable: AnyThrowableDataConvertable] { self.reduce(into: [AnyThrowableDataConvertable: AnyThrowableDataConvertable]()) { $0[.init($1.key)] = .init($1.value) } }
}

public extension Dictionary where Value: SafeDataConvertable {
    var anyValue: [Key: AnySafeDataConvertable] { self.reduce(into: [Key: AnySafeDataConvertable]()) { $0[$1.key] = .init($1.value) } }
}

public extension Dictionary where Key: SafeDataConvertable, Value: SafeDataConvertable {
    var any: [AnySafeDataConvertable: AnySafeDataConvertable] { self.reduce(into: [AnySafeDataConvertable: AnySafeDataConvertable]()) { $0[.init($1.key)] = .init($1.value) } }
}


public extension Dictionary where Value: AnyOptional {
    var filtered: [Key: Value.Wrapped] {
        return self.filter { $0.value.value != nil }.reduce(into: .init()) { $0[$1.key] = $1.value.value! }
    }
}


public protocol AnyOptional {
    associatedtype Wrapped
    var value: Wrapped? { get }
}

extension Optional: AnyOptional {
    public var value: Wrapped? {
        return self
    }
}
