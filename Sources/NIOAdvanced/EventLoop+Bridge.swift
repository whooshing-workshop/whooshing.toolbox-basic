import NIOCore

public extension EventLoop {
    // 使用原生的 makeResultWithTask 或 makeFutureWithTask 可能会出现非预期的 bug
    // 可使用 bridge 替换
    @inlinable
    func bridge<R: Sendable, E>(
        throws: E.Type = E.self,
        _ action: @escaping @Sendable () async throws(E) -> R
    ) -> EventLoopResult<R, E> {
        let target = self.makeTarget(of: R.self, throws: E.self)
        
        Task {
            do {
                let r = try await action()
                target.succeed(r)
            } catch {
                target.fail(error as! E)
            }
        }
        
        return target.futureResult
    }

    @inlinable
    func bridge<R: Sendable>(
        _ action: @escaping @Sendable () async throws -> R
    ) -> EventLoopFuture<R> {
        let promise = self.makePromise(of: R.self)
        
        Task {
            do {
                let r = try await action()
                promise.succeed(r)
            } catch {
                promise.fail(error)
            }
        }
        
        return promise.futureResult
    }

}
