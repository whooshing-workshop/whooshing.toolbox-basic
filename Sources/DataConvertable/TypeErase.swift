import Foundation
import ErrorHandle

@frozen
public struct AnySafeDataConvertable: SafeDataConvertable {
    @usableFromInline let _data: () -> Data
    @inlinable init(_ data: Data) { self._data = { data } }
    @inlinable public init<T: DecodingSafeDataConvertable>(_ data: T) { self._data = { data.data } }
    @inlinable public static func new(data: Data) -> Self { .init(data) }
    @inlinable public var data: Data { return _data() }
    @inlinable public func cast<T: EncodingSafeDataConvertable>(to type: T.Type) -> T { T.new(data: self.data) }
}

@frozen
public struct AnyThrowableDataConvertable: ThrowableDataConvertable {
    @usableFromInline let _data: () throws -> Data
    @inlinable init(_ data: @escaping () throws -> Data) { self._data = data }
    @inlinable public init<T: DecodingThrowableDataConvertable>(_ data: T) { self._data = { try data.dataRes.get() } }
    @inlinable public static func make(data: Data) -> Result<Self, Error> { .success(.init { data }) }
    @inlinable public var dataRes: Result<Data, Error> { .init(catching: _data) }
    @inlinable public func cast<T: EncodingThrowableDataConvertable>(to type: T.Type) -> Result<T, Error> { .init { try T.make(data: self.dataRes.get()).get() } }
}


public extension Dictionary where Key: ThrowableDataConvertable {
    @inlinable
    var anyKey: [AnyThrowableDataConvertable: Value] { self.reduce(into: [AnyThrowableDataConvertable: Value]()) { $0[.init($1.key)] = $1.value } }
}

public extension Dictionary where Key: SafeDataConvertable {
    @inlinable
    var anyKey: [AnySafeDataConvertable: Value] { self.reduce(into: [AnySafeDataConvertable: Value]()) { $0[.init($1.key)] = $1.value } }
}



public extension Dictionary where Value == any ThrowableDataConvertable {
    @inlinable
    var anyValue: [Key: AnyThrowableDataConvertable] { self.reduce(into: [Key: AnyThrowableDataConvertable]()) { $0[$1.key] = .init($1.value) } }
}

public extension Dictionary where Key: ThrowableDataConvertable, Value == any ThrowableDataConvertable {
    @inlinable
    var any: [AnyThrowableDataConvertable: AnyThrowableDataConvertable] { self.reduce(into: [AnyThrowableDataConvertable: AnyThrowableDataConvertable]()) { $0[.init($1.key)] = .init($1.value) } }
}

public extension Dictionary where Value == any SafeDataConvertable {
    @inlinable
    var anyValue: [Key: AnySafeDataConvertable] { self.reduce(into: [Key: AnySafeDataConvertable]()) { $0[$1.key] = .init($1.value) } }
}

public extension Dictionary where Key: SafeDataConvertable, Value == any SafeDataConvertable {
    @inlinable
    var any: [AnySafeDataConvertable: AnySafeDataConvertable] { self.reduce(into: [AnySafeDataConvertable: AnySafeDataConvertable]()) { $0[.init($1.key)] = .init($1.value) } }
}


public extension Dictionary where Value: ThrowableDataConvertable {
    @inlinable
    var anyValue: [Key: AnyThrowableDataConvertable] { self.reduce(into: [Key: AnyThrowableDataConvertable]()) { $0[$1.key] = .init($1.value) } }
}

public extension Dictionary where Key: ThrowableDataConvertable, Value: ThrowableDataConvertable {
    @inlinable
    var any: [AnyThrowableDataConvertable: AnyThrowableDataConvertable] { self.reduce(into: [AnyThrowableDataConvertable: AnyThrowableDataConvertable]()) { $0[.init($1.key)] = .init($1.value) } }
}

public extension Dictionary where Value: SafeDataConvertable {
    @inlinable
    var anyValue: [Key: AnySafeDataConvertable] { self.reduce(into: [Key: AnySafeDataConvertable]()) { $0[$1.key] = .init($1.value) } }
}

public extension Dictionary where Key: SafeDataConvertable, Value: SafeDataConvertable {
    @inlinable
    var any: [AnySafeDataConvertable: AnySafeDataConvertable] { self.reduce(into: [AnySafeDataConvertable: AnySafeDataConvertable]()) { $0[.init($1.key)] = .init($1.value) } }
}


public extension Dictionary where Value: AnyOptional {
    @inlinable
    var filtered: [Key: Value.Wrapped] {
        return self.filter { $0.value.value != nil }.reduce(into: .init()) { $0[$1.key] = $1.value.value! }
    }
}


public protocol AnyOptional {
    associatedtype Wrapped
    @inlinable
    var value: Wrapped? { get }
}

extension Optional: AnyOptional {
    @inlinable
    public var value: Wrapped? {
        return self
    }
}
