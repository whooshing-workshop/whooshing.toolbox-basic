import ErrorHandle
import Logging
import LoggingAdvanced

public extension EventLoopResult {
    @inlinable
    func logIfFail(logger: Logger, metadata: Logger.Metadata? = nil) -> EventLoopResult<Value, ErrorType> {
        self.flatMapErrorThrowing { error throws(ErrorType) in
            throw logger.error(error, metadata: metadata)
        }
    }
    
    @inlinable
    func logIfFailAndExist(logger: Logger?, metadata: Logger.Metadata? = nil) -> EventLoopResult<Value, ErrorType> {
        logger != nil ? logIfFail(logger: logger!) : self
    }
}

public extension EventLoopResult where ErrorType: Err {
    @inlinable
    func logIfFail(logger: Logger, metadata: Logger.Metadata? = nil) -> EventLoopResult<Value, ErrorType> {
        self.flatMapErrorThrowing { error throws(ErrorType) in
            throw logger.errThrow(error, metadata: metadata)
        }
    }
    
    @inlinable
    func logIfFailAndExist(logger: Logger?, metadata: Logger.Metadata? = nil) -> EventLoopResult<Value, ErrorType> {
        logger != nil ? logIfFail(logger: logger!) : self
    }
}
