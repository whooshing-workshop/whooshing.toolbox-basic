import NIOCore
import ErrorHandle
import Logging
import LoggingAdvanced

#if canImport(Dispatch)
import Dispatch
#endif

extension EventLoopFuture {
    @inlinable
    @preconcurrency
    public func withError<T>(logger: Logger? = nil) -> EventLoopResult<Value, T> where T: Error {
        if let logger = logger {
            return EventLoopResult<Value, T>(self).flatMapErrorThrowing { error throws(T) in
                throw logger.error(error)
            }
        } else {
            return .init(self)
        }
    }
    
    @inlinable
    @preconcurrency
    public func withError<T>(logger: Logger? = nil, _ callback: @Sendable @escaping (Error) -> T) -> EventLoopResult<Value, T> {
        self.flatMapErrorThrowing { error in
            throw callback(error)
        }.withError(logger: logger)
    }
    
    @inlinable
    @preconcurrency
    public func withError<T>(
        _ error: T,
        _ explain: String? = nil,
        metadata: Logger.Metadata? = nil,
        category: T.ErrType.Category? = nil,
        logger: Logger? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) -> EventLoopResult<Value, T.ErrType> where T: ErrList, Value: Sendable {
        self.flatMapError { err in
            let e = T.ErrType(error, explain, category: category, file: file, line: line, function: function).subErr(err).metadata(metadata)
            return self.eventLoop.makeFailedFuture(logger == nil ? e : logger!.errThrow(e))
        }.withError()
    }
}

public typealias EventLoopRes<Value, T> = EventLoopResult<Value, T.ErrType> where T: ErrList

public final class EventLoopResult<Value, ErrorType> where ErrorType: Error {
    
    @inlinable
    public var eventLoop: EventLoop { wrapped.eventLoop }
    
    public let wrapped: EventLoopFuture<Value>
    
    @inlinable
    internal init(_ wrapped: EventLoopFuture<Value>) where ErrorType: Error {
        self.wrapped = wrapped
    }
}

extension EventLoopResult: Equatable {
    @inlinable
    public static func == (lhs: EventLoopResult<Value, ErrorType>, rhs: EventLoopResult<Value, ErrorType>) -> Bool {
        lhs.wrapped == rhs.wrapped
    }
}

// MARK: flatMap and map

extension EventLoopResult {
    
    @inlinable
    @preconcurrency
    public func flatMap<NewValue: Sendable>(
        _ callback: @escaping @Sendable (Value) -> EventLoopResult<NewValue, ErrorType>
    ) -> EventLoopResult<NewValue, ErrorType> {
        self.wrapped.flatMap { value in
            callback(value).wrapped
        }.withError()
    }
    
    @inlinable
    @preconcurrency
    public func flatMapThrowing<NewValue>(
        _ callback: @escaping @Sendable (Value) throws(ErrorType) -> NewValue
    ) -> EventLoopResult<NewValue, ErrorType> {
        self.wrapped.flatMapThrowing { value in
            try callback(value)
        }.withError()
    }
    
    @inlinable
    @preconcurrency
    public func flatMapErrorThrowing<NewError>(
        _ callback: @escaping @Sendable (ErrorType) throws(NewError) -> Value
    ) -> EventLoopResult<Value, NewError> {
        self.wrapped.flatMapErrorThrowing { error in
            try callback(error as! ErrorType)
        }.withError()
    }
    
    @inlinable
    @preconcurrency
    public func map<NewValue>(
        _ callback: @escaping @Sendable (Value) -> (NewValue)
    ) -> EventLoopResult<NewValue, ErrorType> {
        self.wrapped.map { value in
            callback(value)
        }.withError()
    }
    
    @inlinable
    @preconcurrency
    public func flatMapError<NewError>(
        throws: NewError.Type = NewError.self,
        _ callback: @escaping @Sendable (ErrorType) -> EventLoopResult<Value, NewError>
    ) -> EventLoopResult<Value, NewError> where Value: Sendable {
        self.wrapped.flatMapError { error in
            callback(error as! ErrorType).wrapped
        }.withError()
    }
    
    @inlinable
    @preconcurrency
    public func flatMapResult<NewValue, NewError>(
        throws: NewError.Type = NewError.self,
        _ body: @escaping @Sendable (Value) -> Result<NewValue, NewError>
    ) -> EventLoopResult<NewValue, NewError> {
        self.wrapped.flatMapResult { value in
            body(value)
        }.withError()
    }
    
    @inlinable
    @preconcurrency
    public func recover(
        _ callback: @escaping @Sendable (ErrorType) -> Value
    ) -> EventLoopResult<Value, ErrorType> {
        self.wrapped.recover { error in
            callback(error as! ErrorType)
        }.withError()
    }
    
    @inlinable
    @preconcurrency
    public func whenSuccess(
        _ callback: @escaping @Sendable (Value) -> Void
    ) {
        self.wrapped.whenSuccess(callback)
    }
    
    @inlinable
    @preconcurrency
    public func whenFailure(
        _ callback: @escaping @Sendable (ErrorType) -> Void
    ) {
        self.wrapped.whenFailure { error in
            callback(error as! ErrorType)
        }
    }
    
    @inlinable
    @preconcurrency
    public func whenComplete(
        _ callback: @escaping @Sendable (Result<Value, ErrorType>) -> Void
    ) {
        self.wrapped.whenComplete { result in
            switch result {
            case .success(let value): callback(.success(value))
            case .failure(let error): callback(.failure(error as! ErrorType))
            }
        }
    }
}

extension EventLoopResult {
    @inlinable
    @preconcurrency
    public func flatCast<NewValue: Sendable, NewError>(
        throws: NewError.Type = NewError.self,
        _ callback: @escaping @Sendable (Value) -> EventLoopResult<NewValue, NewError>
    ) -> EventLoopResult<NewValue, NewError> {
        self.wrapped.flatMap { value in
            callback(value).wrapped
        }.withError()
    }
    
    @inlinable
    @preconcurrency
    public func flatCastThrowing<NewValue, NewError>(
        _ callback: @escaping @Sendable (Value) throws(NewError) -> NewValue
    ) -> EventLoopResult<NewValue, NewError> {
        self.wrapped.flatMapThrowing { value in
            try callback(value)
        }.withError()
    }
    
    @inlinable
    @preconcurrency
    public func forceErrorCast<NewError>(
        _ errorType: NewError.Type = NewError.self
    ) -> EventLoopResult<Value, NewError> {
        self.wrapped.withError()
    }
    
    @inlinable
    @preconcurrency
    public func errorCast<NewError>(
        throws: NewError.Type = NewError.self,
        _ callback: @Sendable @escaping (ErrorType) -> NewError
    ) -> EventLoopResult<Value, NewError> where Value: Sendable {
        self.flatMapErrorThrowing { error throws(NewError) in
            throw callback(error)
        }
    }
    
    @inlinable
    @preconcurrency
    public func errCast<NewError>(
        _ error: NewError,
        _ explain: String? = nil,
        metadata: Logger.Metadata? = nil,
        category: NewError.ErrType.Category? = nil,
        logger: Logger? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) -> EventLoopResult<Value, NewError.ErrType> where NewError: ErrList {
        self.flatMapErrorThrowing { err throws(NewError.ErrType) in
            let e = NewError.ErrType(error, explain, category: category, file: file, line: line, function: function).subErr(err).metadata(metadata)
            throw logger == nil ? e : logger!.errThrow(e)
        }
    }
}

// MARK: and

extension EventLoopResult {
    @preconcurrency
    @inlinable
    public func and<OtherValue: Sendable>(
        _ other: EventLoopResult<OtherValue, ErrorType>
    ) -> EventLoopResult<(Value, OtherValue), ErrorType> {
        self.wrapped.and(other.wrapped).withError()
    }
}

// MARK: cascade

extension EventLoopResult {
    @preconcurrency
    @inlinable
    public func cascade(
        to promise: EventLoopTarget<Value, ErrorType>?
    ) where Value: Sendable {
        self.wrapped.cascade(to: promise?.wrapped)
    }
    
    @preconcurrency
    @inlinable
    public func cascadeSuccess(
        to promise: EventLoopTarget<Value, ErrorType>?
    ) where Value: Sendable {
        self.wrapped.cascadeSuccess(to: promise?.wrapped)
    }
    
    @inlinable
    public func cascadeFailure<NewValue>(
        to promise: EventLoopTarget<NewValue, ErrorType>?
    ) {
        self.wrapped.cascadeFailure(to: promise?.wrapped)
    }
}

// MARK: wait

extension EventLoopResult {
    @available(*, noasync, message: "wait() can block indefinitely, prefer get()", renamed: "get()")
    @preconcurrency
    @inlinable
    public func wait(
        file: StaticString = #fileID,
        line: UInt = #line
    ) throws(ErrorType) -> Value where Value: Sendable {
        try flatError(as: ErrorType.self) {
            try self.wrapped.wait(file: file, line: line)
        }
    }
}

// MARK: fold

extension EventLoopResult {
    @inlinable
    @preconcurrency
    public func fold<OtherValue: Sendable, NewError>(
        _ futures: [EventLoopResult<OtherValue, ErrorType>],
        throws: NewError.Type = NewError.self,
        with combiningFunction: @escaping @Sendable (Value, OtherValue) -> EventLoopResult<Value, NewError>
    ) -> EventLoopResult<Value, NewError> where Value: Sendable {
        self.wrapped.fold(futures.map { $0.wrapped }) { value, otherValue in
            combiningFunction(value, otherValue).wrapped
        }.withError()
    }
}

// MARK: reduce

extension EventLoopResult {
    @preconcurrency
    @inlinable
    public static func reduce<InputValue: Sendable>(
        _ initialResult: Value,
        _ futures: [EventLoopResult<InputValue, ErrorType>],
        on eventLoop: EventLoop,
        _ nextPartialResult: @escaping @Sendable (Value, InputValue) -> Value
    ) -> EventLoopResult<Value, ErrorType> where Value: Sendable {
        EventLoopFuture<Value>.reduce(
            initialResult,
            futures.map { $0.wrapped },
            on: eventLoop,
            nextPartialResult
        ).withError()
    }
    
    @inlinable
    @preconcurrency
    public static func reduce<InputValue: Sendable>(
        into initialResult: Value,
        _ futures: [EventLoopResult<InputValue, ErrorType>],
        on eventLoop: EventLoop,
        _ updateAccumulatingResult: @escaping @Sendable (inout Value, InputValue) -> Void
    ) -> EventLoopResult<Value, ErrorType> where Value: Sendable {
        EventLoopFuture<Value>.reduce(
            into: initialResult,
            futures.map { $0.wrapped },
            on: eventLoop,
            updateAccumulatingResult
        ).withError()
    }
}

// MARK: "fail fast" reduce

extension EventLoopResult {
    @inlinable
    public static func andAllSucceed(
        _ futures: [EventLoopResult<Value, ErrorType>],
        on eventLoop: EventLoop
    ) -> EventLoopResult<Void, ErrorType> {
        EventLoopFuture<Value>.andAllSucceed(
            futures.map { $0.wrapped },
            on: eventLoop
        ).withError()
    }
    
    @inlinable
    public static func andAllSucceed(
        _ futures: [EventLoopResult<Value, ErrorType>],
        promise: EventLoopTarget<Void, ErrorType>
    ) {
        EventLoopFuture<Value>.andAllSucceed(
            futures.map { $0.wrapped },
            promise: promise.wrapped
        )
    }
    
    @preconcurrency
    public static func whenAllSucceed(
        _ futures: [EventLoopResult<Value, ErrorType>],
        on eventLoop: EventLoop
    ) -> EventLoopResult<[Value], ErrorType> where Value: Sendable {
        EventLoopFuture<Value>.whenAllSucceed(
            futures.map { $0.wrapped },
            on: eventLoop
        ).withError()
    }
    
    @preconcurrency
    public static func whenAllSucceed(
        _ futures: [EventLoopResult<Value, ErrorType>],
        promise: EventLoopTarget<[Value], ErrorType>
    ) where Value: Sendable {
        EventLoopFuture<Value>.whenAllSucceed(
            futures.map { $0.wrapped },
            promise: promise.wrapped
        )
    }
}

// MARK: "fail slow" reduce

extension EventLoopResult {
    @inlinable
    public static func andAllComplete(
        _ futures: [EventLoopResult<Value, ErrorType>],
        on eventLoop: EventLoop
    ) -> EventLoopResult<Void, ErrorType> {
        EventLoopFuture<Value>.andAllComplete(
            futures.map { $0.wrapped },
            on: eventLoop
        ).withError()
    }
    
    @inlinable
    public static func andAllComplete(
        _ futures: [EventLoopResult<Value, ErrorType>],
        promise: EventLoopTarget<Void, ErrorType>
    ) {
        EventLoopFuture<Value>.andAllSucceed(
            futures.map { $0.wrapped },
            promise: promise.wrapped
        )
    }
    
    @preconcurrency
    @inlinable
    public static func whenAllComplete(
        _ futures: [EventLoopResult<Value, ErrorType>],
        on eventLoop: EventLoop
    ) -> EventLoopResult<[Result<Value, ErrorType>], Never> where Value: Sendable {
        EventLoopFuture<Value>.whenAllComplete(
            futures.map { $0.wrapped },
            on: eventLoop
        ).map { $0.map { $0.mapError { $0 as! ErrorType } } }.withError()
    }
    
    @preconcurrency
    @inlinable
    public static func whenAllComplete(
        _ futures: [EventLoopResult<Value, ErrorType>],
        promise: EventLoopTarget<[Result<Value, ErrorType>], Never>
    ) where Value: Sendable {
        let result = promise.wrapped.futureResult.eventLoop.makePromise(of: [Result<Value, Error>].self)
        promise.wrapped.futureResult.map { $0.map { $0.mapError { $0 as Error } } }.cascade(to: result)
        
        EventLoopFuture<Value>.whenAllComplete(
            futures.map { $0.wrapped },
            promise: result
        )
    }
}

// MARK: hop

extension EventLoopResult {
    @preconcurrency
    @inlinable
    public func hop(
        to target: EventLoop
    ) -> EventLoopResult<Value, ErrorType> where Value: Sendable {
        self.wrapped.hop(to: eventLoop).withError()
    }
}

// MARK: always

extension EventLoopResult {
    @inlinable
    @preconcurrency
    public func always(
        _ callback: @escaping @Sendable (Result<Value, ErrorType>) -> Void
    ) -> EventLoopResult<Value, ErrorType> {
        self.wrapped.always { result in
            callback(result.mapError { $0 as! ErrorType })
        }.withError()
    }
}

// MARK: unwrap

extension EventLoopResult {
    @inlinable
    public func unwrap<NewValue>(
        orError: ErrorType
    ) -> EventLoopResult<NewValue, ErrorType> where Value == NewValue? {
        self.wrapped.unwrap(orError: orError).withError()
    }
    
    @preconcurrency
    @inlinable
    public func unwrap<NewValue: Sendable>(
        orReplace replacement: NewValue
    ) -> EventLoopResult<NewValue, ErrorType> where Value == NewValue? {
        self.wrapped.unwrap(orReplace: replacement).withError()
    }
    
    @inlinable
    @preconcurrency
    public func unwrap<NewValue>(
        orElse callback: @escaping @Sendable () -> NewValue
    ) -> EventLoopResult<NewValue, ErrorType> where Value == NewValue? {
        self.wrapped.unwrap(orElse: callback).withError()
    }
}

// MARK: may block

#if canImport(Dispatch)
extension EventLoopResult {
    @inlinable
    @preconcurrency
    public func flatMapBlocking<NewValue: Sendable>(
        onto queue: DispatchQueue,
        _ callbackMayBlock: @escaping @Sendable (Value) throws(ErrorType) -> NewValue
    ) -> EventLoopResult<NewValue, ErrorType> where Value: Sendable {
        self.wrapped.flatMapBlocking(
            onto: queue,
            callbackMayBlock
        ).withError()
    }
    
    @preconcurrency
    @inlinable
    public func whenSuccessBlocking(
        onto queue: DispatchQueue,
        _ callbackMayBlock: @escaping @Sendable (Value) -> Void
    ) where Value: Sendable {
        self.wrapped.whenSuccessBlocking(
            onto: queue,
            callbackMayBlock
        )
    }
    
    @inlinable
    @preconcurrency
    public func whenFailureBlocking(
        onto queue: DispatchQueue,
        _ callbackMayBlock: @escaping @Sendable (ErrorType) -> Void
    ) {
        self.wrapped.whenFailureBlocking(
            onto: queue,
            { callbackMayBlock($0 as! ErrorType) }
        )
    }
    
    @inlinable
    @preconcurrency
    public func whenCompleteBlocking(
        onto queue: DispatchQueue,
        _ callbackMayBlock: @escaping @Sendable (Result<Value, ErrorType>) -> Void
    ) where Value: Sendable {
        self.wrapped.whenCompleteBlocking(
            onto: queue,
            { callbackMayBlock($0.mapError { $0 as! ErrorType }) }
        )
    }
}
#endif

// MARK: assertion

extension EventLoopResult {
    @inlinable
    public func assertSuccess(
        file: StaticString = #fileID,
        line: UInt = #line
    ) -> EventLoopResult<Value, ErrorType> {
        self.wrapped.assertSuccess(
            file: file,
            line: line
        ).withError()
    }
    
    @inlinable
    public func assertFailure(
        file: StaticString = #fileID,
        line: UInt = #line
    ) -> EventLoopResult<Value, ErrorType> {
        self.wrapped.assertFailure(
            file: file,
            line: line
        ).withError()
    }
    
    @inlinable
    public func preconditionSuccess(
        file: StaticString = #fileID,
        line: UInt = #line
    ) -> EventLoopResult<Value, ErrorType> {
        self.wrapped.preconditionSuccess(
            file: file,
            line: line
        ).withError()
    }
    
    @inlinable
    public func preconditionFailure(
        file: StaticString = #fileID,
        line: UInt = #line
    ) -> EventLoopResult<Value, ErrorType> {
        self.wrapped.preconditionFailure(
            file: file,
            line: line
        ).withError()
    }
}

// MARK: fit for errorhandle

extension EventLoopResult {
    @inlinable
    @preconcurrency
    public func flatMapErrThrowing<NewError>(
        _ callback: @escaping @Sendable (ErrorType) throws(NewError) -> Value,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) -> EventLoopResult<Value, NewError.ErrType> where NewError: ErrList {
        self.flatMapErrorThrowing { error throws(NewError.ErrType) in
            do {
                return try callback(error)
            } catch let err {
                throw .init(err as! NewError, file: file, line: line, function: function).subErr(err)
            }
        }
    }
    
    @inlinable
    @preconcurrency
    public func flatMapErr<NewError>(
        _ callback: @escaping @Sendable (ErrorType) -> EventLoopResult<Value, NewError>,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) -> EventLoopResult<Value, NewError.ErrType> where Value: Sendable, NewError: ErrList {
        self.flatMapError { error in
            callback(error).flatMapErrorThrowing { err throws(NewError.ErrType) in
                throw .init(err, file: file, line: line, function: function).subErr(err)
            }
        }
    }
}

extension EventLoopResult {
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    @preconcurrency
    @inlinable
    public func get() async throws(ErrorType) -> Value where Value: Sendable {
        try await flatError(as: ErrorType.self) {
            try await self.wrapped.get()
        }
    }
}

extension EventLoopResult: Sendable {}

extension Optional {
    @preconcurrency
    public mutating func setOrCascade<Value: Sendable, ErrorType>(
        to promise: EventLoopTarget<Value, ErrorType>?
    ) where Wrapped == EventLoopTarget<Value, ErrorType> {
        var p = self?.wrapped
        p.setOrCascade(to: promise?.wrapped)
    }
}


