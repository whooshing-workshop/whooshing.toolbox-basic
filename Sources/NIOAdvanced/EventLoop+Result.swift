import NIOCore

extension EventLoopGroup {
    public func future<Error>() -> EventLoopResult<Void, Error> {
        return self.any().makeSucceededResult(())
    }

    public func future<T: Sendable, Error>(_ value: T) -> EventLoopResult<T, Error> {
        return self.any().makeSucceededResult(value)
    }
    
    public func future<T, Error>(error: Error) -> EventLoopResult<T, Error> {
        return self.any().makeFailedResult(error)
    }
    
    public func future<T: Sendable, Error>(result: Result<T, Error>) -> EventLoopResult<T, Error> {
        let promise: EventLoopTarget<T, Error> = self.any().makeTarget()
        promise.completeWith(result)
        return promise.futureResult
    }
}
