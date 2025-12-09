import NIOCore

extension EventLoop {
    public func flatten<T, Error>(_ futures: [EventLoopResult<T, Error>]) -> EventLoopResult<[T], Error> {
        return EventLoopResult<T, Error>.whenAllSucceed(futures, on: self)
    }

    public func flatten<Error>(_ futures: [EventLoopResult<Void, Error>]) -> EventLoopResult<Void, Error> {
        return EventLoopResult<Void, Error>.whenAllSucceed(futures, on: self).map { _ in () }
    }
}
