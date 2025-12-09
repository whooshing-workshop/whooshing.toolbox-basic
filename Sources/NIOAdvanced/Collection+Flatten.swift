import NIOCore

extension Collection {
    public func flatten<Value: Sendable, Error>(on eventLoop: any EventLoop) -> EventLoopResult<[Value], Error>
        where Element == EventLoopResult<Value, Error>
    {
        return eventLoop.flatten(Array(self))
    }
}

extension Array {
    public func flatten<Error>(on eventLoop: any EventLoop) -> EventLoopResult<Void, Error>
        where Element == EventLoopResult<Void, Error>
    {
        return .andAllSucceed(self, on: eventLoop)
    }
}

extension Collection {
    public func sequencedFlatMapEach<Result: Sendable, Error, T>(
        on eventLoop: any EventLoop,
        _ transform: @escaping @Sendable (_ element: T) -> EventLoopResult<Result, Error>
    ) -> EventLoopResult<[Result], Error> where T == Element, T: Sendable {
        return self.reduce(eventLoop.future([])) { fut, elem in fut.flatMap { res in transform(elem).map { res + [$0] } } }
    }

    public func sequencedFlatMapEach<Error, T>(
        on eventLoop: any EventLoop,
        _ transform: @escaping @Sendable (_ element: T) -> EventLoopResult<Void, Error>
    ) -> EventLoopResult<Void, Error> where T == Element, T: Sendable {
        return self.reduce(eventLoop.future()) { fut, elem in fut.flatMap { transform(elem) } }
    }

    public func sequencedFlatMapEachCompact<Result: Sendable, Error, T>(
        on eventLoop: any EventLoop,
        _ transform: @escaping @Sendable (_ element: T) -> EventLoopResult<Result?, Error>
    ) -> EventLoopResult<[Result], Error> where T == Element, T: Sendable {
        return self.reduce(eventLoop.future([])) { fut, elem in fut.flatMap { res in transform(elem).map { res + [$0].compactMap { $0 } } } }
    }
}
