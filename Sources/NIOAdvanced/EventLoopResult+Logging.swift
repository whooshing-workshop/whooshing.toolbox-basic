import ErrorHandle
import Logging
import LoggingAdvanced

public extension EventLoopResult {
    @inlinable
    func logIfFail(logger: Logger) -> EventLoopResult<Value, ErrorType> {
        self.flatMapErrorThrowing { error throws(ErrorType) in
            throw logger.error(error)
        }
    }
}

public extension EventLoopResult where ErrorType: Err {
    @inlinable
    func logIfFail(logger: Logger) -> EventLoopResult<Value, ErrorType> {
        self.flatMapErrorThrowing { error throws(ErrorType) in
            throw logger.errThrow(error)
        }
    }
}
