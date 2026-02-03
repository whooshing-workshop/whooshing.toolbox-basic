import NIOCore
import ErrorHandle
import Logging
import LoggingAdvanced

extension EventLoop {
    @inlinable
    public func makeSucceededVoidResult<ErrorType>(throws errorType: ErrorType.Type = ErrorType.self) -> EventLoopResult<Void, ErrorType> {
        self.makeSucceededVoidFuture().withError()
    }
}

extension EventLoop {
    @inlinable
    @preconcurrency
    public func submitResult<T, G>(
        throws errorType: G.Type = G.self,
        _ task: @escaping @Sendable () throws(G) -> T
    ) -> EventLoopResult<T, G> {
        self.submit {
            try task()
        }.withError()
    }
    
    @inlinable
    @preconcurrency
    public func flatSubmitResult<T: Sendable, G>(
        throws errorType: G.Type = G.self,
        _ task: @escaping @Sendable () -> EventLoopResult<T, G>
    ) -> EventLoopResult<T, G> {
        self.flatSubmit {
            task().wrapped
        }.withError()
    }
    
    @inlinable
    public func makeTarget<T, G>(
        of type: T.Type = T.self,
        file: StaticString = #fileID,
        line: UInt = #line
    ) -> EventLoopTarget<T, G> {
        self.makePromise(of: T.self, file: file, line: line).withError()
    }
    
    @inlinable
    public func makeFailedResult<T, G>(_ error: G) -> EventLoopResult<T, G> {
        self.makeFailedFuture(error).withError()
    }
    
    @inlinable
    public func makeFailedResult<T, G>(
        _ error: G,
        _ explain: String? = nil,
        metadata: Logger.Metadata? = nil,
        category: G.ErrType.Category? = nil,
        logger: Logger? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) -> EventLoopResult<T, G.ErrType> where G: ErrList {
        let e = G.ErrType(error, explain, category: category, file: file, line: line, function: function).metadata(metadata)
        return self.makeFailedResult(logger == nil ? e : logger!.errThrow(e))
    }
    
    @preconcurrency
    @inlinable
    public func makeSucceededResult<Success: Sendable, ErrorType>(
        _ value: Success,
        throws errorType: ErrorType.Type = ErrorType.self
    ) -> EventLoopResult<Success, ErrorType> {
        self.makeSucceededFuture(value).withError()
    }
}

extension EventLoopResult {
    
    public struct Isolated {
        
        public let wrapped: EventLoopFuture<Value>.Isolated
        
        @inlinable
        internal init(_ wrapped: EventLoopFuture<Value>.Isolated) {
            self.wrapped = wrapped
        }
        
        @inlinable
        @available(*, noasync)
        public func flatMap<NewValue: Sendable>(
            _ callback: @escaping (Value) -> EventLoopResult<NewValue, ErrorType>
        ) -> EventLoopResult<NewValue, ErrorType>.Isolated {
            self.wrapped.flatMap { callback($0).wrapped }.withError()
        }
        
        @inlinable
        @available(*, noasync)
        public func flatMapThrowing<NewValue>(
            _ callback: @escaping (Value) throws(ErrorType) -> NewValue
        ) -> EventLoopResult<NewValue, ErrorType>.Isolated {
            self.wrapped.flatMapThrowing { try callback($0) }.withError()
        }
        
        @inlinable
        @available(*, noasync)
        public func flatMapErrorThrowing<NewError>(
            _ callback: @escaping (ErrorType) throws(NewError) -> Value
        ) -> EventLoopResult<Value, NewError>.Isolated {
            self.wrapped.flatMapErrorThrowing { try callback($0 as! ErrorType) }.withError()
        }
        
        @inlinable
        @available(*, noasync)
        public func map<NewValue>(
            _ callback: @escaping (Value) -> (NewValue)
        ) -> EventLoopResult<NewValue, ErrorType>.Isolated {
            self.wrapped.map(callback).withError()
        }
        
        @inlinable
        @available(*, noasync)
        public func flatMapError<NewError>(
            throws: NewError.Type = NewError.self,
            _ callback: @escaping (ErrorType) -> EventLoopResult<Value, NewError>
        ) -> EventLoopResult<Value, NewError>.Isolated where Value: Sendable {
            self.wrapped.flatMapError { callback($0 as! ErrorType).wrapped }.withError()
        }
        
        @inlinable
        @available(*, noasync)
        public func flatMapError<NewError>(
            throws: NewError.Type = NewError.self,
            _ callback: @escaping (ErrorType) -> EventLoopResult<Value, NewError>.Isolated
        ) -> EventLoopResult<Value, NewError>.Isolated {
            self.wrapped.flatMapError { callback($0 as! ErrorType).wrapped }.withError()
        }
        
        @inlinable
        @available(*, noasync)
        public func flatMapResult<NewValue, NewError>(
            throws: NewError.Type = NewError.self,
            _ body: @escaping (Value) -> Result<NewValue, NewError>
        ) -> EventLoopResult<NewValue, NewError>.Isolated {
            self.wrapped.flatMapResult { body($0) }.withError()
        }
        
        @inlinable
        @available(*, noasync)
        public func recover(
            _ callback: @escaping (ErrorType) -> Value
        ) -> EventLoopResult<Value, ErrorType>.Isolated {
            self.wrapped.recover { callback($0 as! ErrorType) }.withError()
        }
        
        @inlinable
        @available(*, noasync)
        public func whenSuccess(_ callback: @escaping (Value) -> Void) {
            self.wrapped.whenSuccess(callback)
        }
        
        @inlinable
        @available(*, noasync)
        public func whenFailure(_ callback: @escaping (ErrorType) -> Void) {
            self.wrapped.whenFailure { callback($0 as! ErrorType) }
        }
        
        @inlinable
        @available(*, noasync)
        public func whenComplete(
            _ callback: @escaping (Result<Value, ErrorType>) -> Void
        ) {
            self.wrapped.whenComplete { callback($0.mapError { $0 as! ErrorType }) }
        }
        
        @inlinable
        @available(*, noasync)
        public func always(
            _ callback: @escaping (Result<Value, ErrorType>) -> Void
        ) -> EventLoopResult<Value, ErrorType>.Isolated {
            self.wrapped.always { callback($0.mapError { $0 as! ErrorType }) }.withError()
        }
        
        @inlinable
        @available(*, noasync)
        public func unwrap<NewValue>(
            orReplace replacement: NewValue
        ) -> EventLoopResult<NewValue, ErrorType>.Isolated where Value == NewValue? {
            self.wrapped.unwrap(orReplace: replacement).withError()
        }
        
        @inlinable
        @available(*, noasync)
        public func unwrap<NewValue>(
            orElse callback: @escaping () -> NewValue
        ) -> EventLoopResult<NewValue, ErrorType>.Isolated where Value == NewValue? {
            self.wrapped.unwrap(orElse: callback).withError()
        }
        
        @inlinable
        public func nonisolated() -> EventLoopResult<Value, ErrorType> {
            self.wrapped.nonisolated().withError()
        }
    }
    
    @inlinable
    @available(*, noasync)
    public func assumeIsolated() -> Isolated {
        self.wrapped.assumeIsolated().withError()
    }
    
    @inlinable
    @available(*, noasync)
    public func assumeIsolatedUnsafeUnchecked() -> Isolated {
        self.wrapped.assumeIsolatedUnsafeUnchecked().withError()
    }
}

extension EventLoopResult.Isolated {
    @inlinable
    @preconcurrency
    public func flatMapErrThrowing<NewError>(
        _ callback: @escaping @Sendable (ErrorType) throws(NewError) -> Value,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) -> EventLoopResult<Value, NewError.ErrType>.Isolated where NewError: ErrList {
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
    ) -> EventLoopResult<Value, NewError.ErrType>.Isolated where Value: Sendable, NewError: ErrList {
        self.flatMapError { error in
            callback(error).flatMapErrorThrowing { err throws(NewError.ErrType) in
                throw .init(err, file: file, line: line, function: function).subErr(err)
            }
        }
    }
}

extension EventLoopResult.Isolated {
    @inlinable
    @preconcurrency
    public func flatCast<NewValue: Sendable, NewError>(
        throws: NewError.Type = NewError.self,
        _ callback: @escaping @Sendable (Value) -> EventLoopResult<NewValue, NewError>
    ) -> EventLoopResult<NewValue, NewError>.Isolated {
        self.wrapped.flatMap { value in
            callback(value).wrapped
        }.withError()
    }
    
    @inlinable
    @preconcurrency
    public func flatCastThrowing<NewValue, NewError>(
        _ callback: @escaping @Sendable (Value) throws(NewError) -> NewValue
    ) -> EventLoopResult<NewValue, NewError>.Isolated {
        self.wrapped.flatMapThrowing { value in
            try callback(value)
        }.withError()
    }
    
    @inlinable
    @preconcurrency
    public func forceErrorCast<NewError>(
        _ errorType: NewError.Type = NewError.self
    ) -> EventLoopResult<Value, NewError>.Isolated {
        self.wrapped.withError()
    }
    
    @inlinable
    @preconcurrency
    public func errorCast<NewError>(
        throws: NewError.Type = NewError.self,
        _ callback: @Sendable @escaping (ErrorType) -> NewError
    ) -> EventLoopResult<Value, NewError>.Isolated where Value: Sendable {
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
    ) -> EventLoopResult<Value, NewError.ErrType>.Isolated where NewError: ErrList {
        self.flatMapErrorThrowing { err throws(NewError.ErrType) in
            let e = NewError.ErrType(error, explain, category: category, file: file, line: line, function: function).subErr(err).metadata(metadata)
            throw logger == nil ? e : logger!.errThrow(e)
        }
    }
}

@available(*, unavailable)
extension EventLoopResult.Isolated: Sendable {}

extension EventLoopFuture.Isolated {
    @inlinable
    @preconcurrency
    public func withError<ErrorType>() -> EventLoopResult<Value, ErrorType>.Isolated {
        .init(self)
    }
    
    @inlinable
    @preconcurrency
    public func withError<T>(_ callback: @Sendable @escaping (Error) -> T) -> EventLoopResult<Value, T>.Isolated {
        self.flatMapErrorThrowing { error in
            throw callback(error)
        }.withError()
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
    ) -> EventLoopResult<Value, T.ErrType>.Isolated where T: ErrList {
        self.flatMapErrorThrowing { err throws(T.ErrType) in
            let e = T.ErrType(error, explain, category: category, file: file, line: line, function: function).subErr(err).metadata(metadata)
            throw logger == nil ? e : logger!.errThrow(e)
        }.withError()
    }
}

extension EventLoopTarget {
    
    public struct Isolated {
        
        public let wrapped: EventLoopPromise<Value>.Isolated
        
        @inlinable
        @available(*, noasync)
        public var futureResult: EventLoopResult<Value, ErrorType>.Isolated {
            self.wrapped.futureResult.withError()
        }
        
        @inlinable
        internal init(_ wrapped: EventLoopPromise<Value>.Isolated) {
            self.wrapped = wrapped
        }
        
        @inlinable
        @available(*, noasync)
        public func succeed(_ value: Value) {
            self.wrapped.succeed(value)
        }
        
        @inlinable
        @available(*, noasync)
        public func completeWith(_ result: Result<Value, ErrorType>) {
            self.wrapped.completeWith(result.mapError { $0 as Error })
        }
        
        @inlinable
        public func nonisolated() -> EventLoopTarget<Value, ErrorType> {
            self.wrapped.nonisolated().withError()
        }
    }
    
    @inlinable
    @available(*, noasync)
    public func assumeIsolated() -> Isolated {
        self.wrapped.assumeIsolated().withError()
    }
    
    @inlinable
    public func assumeIsolatedUnsafeUnchecked() -> Isolated {
        self.wrapped.assumeIsolatedUnsafeUnchecked().withError()
    }
}

@available(*, unavailable)
extension EventLoopTarget.Isolated: Sendable {}

extension EventLoopPromise.Isolated {
    @inlinable
    @preconcurrency
    public func withError<ErrorType>() -> EventLoopTarget<Value, ErrorType>.Isolated {
        .init(self)
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension EventLoop {
    @preconcurrency
    @inlinable
    public func makeResultWithTask<Return: Sendable, NewError>(
        _ body: @Sendable @escaping () async throws(NewError) -> Return
    ) -> EventLoopResult<Return, NewError> {
        self.makeFutureWithTask { () throws(NewError) in
            try await body()
        }.withError()
    }
}
