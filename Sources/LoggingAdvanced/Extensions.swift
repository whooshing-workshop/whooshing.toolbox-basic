import Logging
import ErrorHandle
import Foundation

public extension Logger {
    /// 用于标记日志链的 Key
    static let chainKey = "<chain>"
    /// 用于标记日志在链中序号的 Key
    static let chainIndexKey = "<Index>"
    
    /// 创建一个派生的 Logger，可以附加子 ID 和元数据。
    ///
    /// - Parameters:
    ///   - subId: 子 ID，会附加到 label 后。如果为空，则不附加。
    ///   - metadata: 额外的元数据，会添加到新 Logger 中。
    /// - Returns: 一个新的 Logger 实例。
    @inlinable
    func derive(subId: String? = nil, metadata: Metadata? = nil) -> Self {
        var logger = Logger(
            label: label + (subId == nil ? "" : (label == "" ? subId! : ("." + subId!))),
            metadataProvider: metadataProvider ?? .init { .init() }
        )
        
        logger.logLevel = logLevel
        
        if let metadata = metadata {
            for (k, v) in metadata {
                logger[metadataKey: k] = v
            }
        }
        
        return logger
    }
    
    /// 记录并返回一个标准的 Error。
    ///
    /// - Parameters:
    ///   - error: 要记录的错误对象。
    ///   - metadata: 额外的元数据。
    /// - Returns: 传入的错误对象。
    @inlinable
    func error<T: Error>(_ error: T, metadata: Logger.Metadata? = nil) -> T {
        self.error("\(String(describing: error))", metadata: metadata)
        return error
    }
    
    /// 记录并返回一个 Err 类型的错误，支持结构化日志记录。
    ///
    /// 此方法会递归处理错误的子错误，并将错误的上下文信息（如文件、行号、元数据等）记录到日志中。
    ///
    /// - Parameters:
    ///   - e: 要记录的 Err 类型错误。
    ///   - metadata: 额外的元数据。
    /// - Returns: 传入的错误对象。
    @inlinable
    func errThrow<T: Err>(_ e: T, metadata: Logger.Metadata? = nil) -> T {
        var m = metadata ?? .init()
        return __errThrow(e, metadata: &m, index: 1)
    }
    
    @usableFromInline
    internal func __errThrow<T: Err>(_ e: T, metadata: inout Logger.Metadata, index: Int) -> T {
        if let m = e.metadata {
            for (k, v) in m {
                metadata[k] = v
            }
        }
        
        if let category = e.category {
            metadata["category"] = .string("\(category)")
        } else {
            metadata["category"] = nil
        }
        
        if e.subError != nil {
            metadata[Self.chainIndexKey] = .stringConvertible(index)
            if metadata[Self.chainKey] == nil {
                metadata[Self.chainKey] = .stringConvertible(UUID())
            }
        }
        
        self.error(
            .init(stringLiteral: e.msg),
            metadata: metadata,
            file: e.file,
            function: e.function,
            line: UInt(e.line)
        )
        
        if let subError = e.subError {
            if let er = subError as? any Err {
                _ = __errThrow(er, metadata: &metadata, index: index + 1)
            } else {
                metadata[Self.chainIndexKey] = .stringConvertible(index + 1)
                _ = error(subError, metadata: metadata)
            }
        }
        
        return e
    }
}

public extension Logger {
    /// 执行一个抛出错误的闭包，如果发生错误，将其包装为指定的 ErrType 并抛出。
    ///
    /// - Parameters:
    ///   - to: 错误列表类型，用于指定抛出的错误类型。
    ///   - explain: 错误的解释说明。
    ///   - metadata: 额外的元数据。
    ///   - category: 错误分类。
    ///   - file: 调用所在的文件名。
    ///   - line: 调用所在的行号。
    ///   - function: 调用所在的函数名。
    ///   - performing: 要执行的闭包。
    /// - Returns: 闭包的返回值。
    /// - Throws: 包装后的 G.ErrType 错误。
    @inlinable
    func required<G, T>(
        throws to: G,
        _ explain: String? = nil,
        metadata: Logger.Metadata? = nil,
        category: G.ErrType.Category? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function,
        _ performing: () throws -> T
    ) throws(G.ErrType) -> T where G: ErrList {
        do {
            let res = try performing()
            return res
        } catch let err {
            let e = G.ErrType(to, explain, category: category, file: file, line: line, function: function).subErr(err).metadata(metadata)
            throw self.errThrow(e)
        }
    }
    
    /// 执行一个异步抛出错误的闭包，如果发生错误，将其包装为指定的 ErrType 并抛出。
    ///
    /// - Parameters:
    ///   - to: 错误列表类型，用于指定抛出的错误类型。
    ///   - explain: 错误的解释说明。
    ///   - metadata: 额外的元数据。
    ///   - category: 错误分类。
    ///   - file: 调用所在的文件名。
    ///   - line: 调用所在的行号。
    ///   - function: 调用所在的函数名。
    ///   - performing: 要执行的异步闭包。
    /// - Returns: 闭包的返回值。
    /// - Throws: 包装后的 G.ErrType 错误。
    @inlinable
    func required<G, T>(
        throws to: G,
        _ explain: String? = nil,
        metadata: Logger.Metadata? = nil,
        category: G.ErrType.Category? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function,
        _ performing: () async throws -> T
    ) async throws(G.ErrType) -> T where G: ErrList {
        do {
            let res = try await performing()
            return res
        } catch let err {
            let e = G.ErrType(to, explain, category: category, file: file, line: line, function: function).subErr(err).metadata(metadata)
            throw self.errThrow(e)
        }
    }
}

public extension Logger {
    /// 执行一个抛出错误的闭包，并将其结果转换为 Result 类型。
    ///
    /// 如果闭包成功，返回 .success；如果闭包抛出错误，记录错误并返回 .failure。
    ///
    /// - Parameters:
    ///   - error: 错误列表类型，用于指定失败时的错误类型。
    ///   - explain: 错误的解释说明。
    ///   - metadata: 额外的元数据。
    ///   - category: 错误分类。
    ///   - file: 调用所在的文件名。
    ///   - line: 调用所在的行号。
    ///   - function: 调用所在的函数名。
    ///   - body: 要执行的闭包。
    /// - Returns: 指示成功或失败的 Result。
    @inlinable
    func result<T, V>(
        throws error: T.ErrorList,
        _ explain: String? = nil,
        metadata: Logger.Metadata? = nil,
        category: T.Category? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function,
        catching body: () throws -> V
    ) -> Result<V, T> where T: Err {
        do {
            return .success(try body())
        } catch let originErr {
            let e = T.init(error, explain, category: category, file: file, line: line, function: function).subErr(originErr).metadata(metadata)
            return .failure(self.errThrow(e))
        }
    }
    
    /// 执行一个异步抛出错误的闭包，并将其结果转换为 Result 类型。
    ///
    /// 如果闭包成功，返回 .success；如果闭包抛出错误，记录错误并返回 .failure。
    ///
    /// - Parameters:
    ///   - error: 错误列表类型，用于指定失败时的错误类型。
    ///   - explain: 错误的解释说明。
    ///   - metadata: 额外的元数据。
    ///   - category: 错误分类。
    ///   - file: 调用所在的文件名。
    ///   - line: 调用所在的行号。
    ///   - function: 调用所在的函数名。
    ///   - body: 要执行的异步闭包。
    /// - Returns: 指示成功或失败的 Result。
    @inlinable
    func async<T, V>(
        throws error: T.ErrorList,
        _ explain: String? = nil,
        metadata: Logger.Metadata? = nil,
        category: T.Category? = nil,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function,
        catching body: () async throws -> V
    ) async -> Result<V, T> where T: Err {
        do {
            return .success(try await body())
        } catch let originErr {
            let e = T.init(error, explain, category: category, file: file, line: line, function: function).subErr(originErr).metadata(metadata)
            return .failure(self.errThrow(e))
        }
    }
}
