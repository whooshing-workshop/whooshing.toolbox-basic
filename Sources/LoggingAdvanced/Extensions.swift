import Logging
import ErrorHandle
import Foundation

public extension Logger {
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
        var md: Logger.Metadata
        
        if let m = e.metadata {
            md = m
        } else {
            md = [:]
        }
        
        if let metadata = metadata {
            for (k, v) in metadata {
                md[k] = v
            }
        }
        
        if let category = e.category {
            md["category"] = .string("\(category)")
        }
        
        let subErrorMetadata: Logger.Metadata?
        
        if e.subError != nil {
            let id = metadata?["<chain>"] ?? Logger.MetadataValue.stringConvertible(UUID())
            subErrorMetadata = ["<chain>": id]
            md["<chain>"] = id
        } else {
            subErrorMetadata = nil
        }
        
        self.error(
            .init(stringLiteral: e.msg),
            metadata: md == [:] ? nil : md,
            file: e.file,
            function: e.function,
            line: .init(e.line)
        )
        
        if let subError = e.subError {
            if let er = subError as? any Err {
                _ = errThrow(er, metadata: subErrorMetadata)
            } else {
                _ = error(subError, metadata: subErrorMetadata)
            }
        }
        
        return e
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
