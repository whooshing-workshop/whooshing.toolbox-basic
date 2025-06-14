import NIOCore

extension EventLoop {
    public func makeSucceededVoidResult<ErrorType>() -> EventLoopResult<Void, ErrorType> {
        self.makeSucceededVoidFuture().withError()
    }
}

extension EventLoop {
    @inlinable
    @preconcurrency
    public func submitResult<T, G>(
        _ task: @escaping @Sendable () throws(G) -> T
    ) -> EventLoopResult<T, G> {
        self.submit {
            try task()
        }.withError()
    }
    
    @inlinable
    @preconcurrency
    public func flatSubmitResult<T: Sendable, G>(
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
    
    @preconcurrency
    @inlinable
    public func makeSucceededResult<Success: Sendable, ErrorType>(
        _ value: Success
    ) -> EventLoopResult<Success, ErrorType> {
        self.makeSucceededFuture(value).withError()
    }
}

extension EventLoopGroup {
    
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
            _ callback: @escaping (ErrorType) -> EventLoopResult<Value, NewError>
        ) -> EventLoopResult<Value, NewError>.Isolated where Value: Sendable {
            self.wrapped.flatMapError { callback($0 as! ErrorType).wrapped }.withError()
        }
        
        @inlinable
        @available(*, noasync)
        public func flatMapError<NewError>(
            _ callback: @escaping (ErrorType) -> EventLoopResult<Value, NewError>.Isolated
        ) -> EventLoopResult<Value, NewError>.Isolated {
            self.wrapped.flatMapError { callback($0 as! ErrorType).wrapped }.withError()
        }
        
        @inlinable
        @available(*, noasync)
        public func flatMapResult<NewValue, NewError>(
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

@available(*, unavailable)
extension EventLoopResult.Isolated: Sendable {}

extension EventLoopFuture.Isolated {
    @inlinable
    @preconcurrency
    public func withError<ErrorType>() -> EventLoopResult<Value, ErrorType>.Isolated {
        .init(self)
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
