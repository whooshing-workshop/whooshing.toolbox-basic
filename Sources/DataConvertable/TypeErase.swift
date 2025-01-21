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
