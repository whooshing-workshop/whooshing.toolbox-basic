import Logging
import ErrorHandle
import Foundation

public extension Logger {
    static let chainKey = "<chain>"
    static let chainIndexKey = "<Index>"
    
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
    
    @inlinable
    func error<T: Error>(_ error: T, metadata: Logger.Metadata? = nil) -> T {
        self.error("\(String(describing: error))", metadata: metadata)
        return error
    }
    
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
