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

extension Collection where Element: Sendable {
    public func sequencedFlatMapEach<Result: Sendable, Error>(
        on eventLoop: any EventLoop,
        _ transform: @escaping @Sendable (_ element: Element) -> EventLoopResult<Result, Error>
    ) -> EventLoopResult<[Result], Error> {
        return self.reduce(eventLoop.future([])) { fut, elem in fut.flatMap { res in transform(elem).map { res + [$0] } } }
    }

    public func sequencedFlatMapEach<Error>(
        on eventLoop: any EventLoop,
        _ transform: @escaping @Sendable (_ element: Element) -> EventLoopResult<Void, Error>
    ) -> EventLoopResult<Void, Error> {
        return self.reduce(eventLoop.future()) { fut, elem in fut.flatMap { transform(elem) } }
    }

    public func sequencedFlatMapEachCompact<Result: Sendable, Error>(
        on eventLoop: any EventLoop,
        _ transform: @escaping @Sendable (_ element: Element) -> EventLoopResult<Result?, Error>
    ) -> EventLoopResult<[Result], Error> {
        return self.reduce(eventLoop.future([])) { fut, elem in fut.flatMap { res in transform(elem).map { res + [$0].compactMap { $0 } } } }
    }
}
