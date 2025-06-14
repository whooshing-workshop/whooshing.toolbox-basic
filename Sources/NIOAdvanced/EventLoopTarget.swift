import NIOCore

extension EventLoopPromise {
    public func withError<T>() -> EventLoopTarget<Value, T> {
        .init(self)
    }
}

public struct EventLoopTarget<Value, ErrorType> where ErrorType: Error {
    
    public var futureResult: EventLoopResult<Value, ErrorType> {
        .init(self.wrapped.futureResult)
    }
    
    @usableFromInline
    internal let wrapped: EventLoopPromise<Value>
    
    @inlinable
    internal init(_ wrapped: EventLoopPromise<Value>) {
        self.wrapped = wrapped
    }
    
    @preconcurrency
    @inlinable
    public func succeed(_ value: Value) where Value: Sendable {
        self.wrapped.succeed(value)
    }
    
    @inlinable
    public func fail(_ error: ErrorType) {
        self.wrapped.fail(error)
    }
    
    @preconcurrency
    @inlinable
    public func completeWith(_ future: EventLoopResult<Value, ErrorType>) where Value: Sendable {
        future.cascade(to: self)
    }
    
    @preconcurrency
    @inlinable
    public func completeWith(_ result: Result<Value, ErrorType>) where Value: Sendable {
        self.wrapped.completeWith(result.mapError { $0 as Error })
    }
}

extension EventLoopTarget: Equatable {}

extension EventLoopTarget: Sendable {}

extension EventLoopTarget where Value == Void {
    @inlinable
    public func succeed() {
        succeed(Void())
    }
}
