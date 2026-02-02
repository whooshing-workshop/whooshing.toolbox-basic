import Logging
import ErrorHandle
import Puppy
import Foundation

public extension Logger {
    @inlinable
    func derive(subId: String) -> Self {
        var logger = Logger(
            label: label + (label == "" ? subId : ("." + subId)),
            metadataProvider: metadataProvider ?? .init { .init() }
        )
        
        logger.logLevel = logLevel
        
        return logger
    }
    
    @inlinable
    func errorThrow(_ error: Error, metadata: Logger.Metadata? = nil) -> Error {
        self.error("\(String(describing: error))", metadata: metadata)
        return error
    }
    
    @inlinable
    func errorAndThrow<T: Err>(_ error: T, metadata: Logger.Metadata? = nil) -> T {
        var md: Logger.Metadata
        
        if let m = error.metadata {
            md = m
        } else {
            md = [:]
        }
        
        if let metadata = metadata {
            for (k, v) in metadata {
                md[k] = v
            }
        }
        
        if let category = error.category {
            md["category"] = .string("\(category)")
        }
        
        let subErrorMetadata: Logger.Metadata?
        
        if error.subError != nil {
            let id = metadata?["<chain>"] ?? Logger.MetadataValue.stringConvertible(UUID())
            subErrorMetadata = ["<chain>": id]
            md["<chain>"] = id
        } else {
            subErrorMetadata = nil
        }
        
        self.error(
            .init(stringLiteral: error.msg),
            metadata: md == [:] ? nil : md,
            file: error.file,
            function: error.function,
            line: .init(error.line)
        )
        
        if let subError = error.subError {
            if let err = subError as? any Err {
                _ = errorAndThrow(err, metadata: subErrorMetadata)
            } else {
                _ = errorThrow(subError, metadata: subErrorMetadata)
            }
        }
        
        return error
    }
}

public struct LoggingFactory: Sendable {
    
    @usableFromInline
    var puppy = Puppy()
    
    @inlinable
    public func bootstrap() {
        LoggingSystem.bootstrap { label in
            PuppyLogHandler(label: label, puppy: self.puppy)
        }
    }
    
    @inlinable
    public mutating func add(
        _ label: String
    ) {
        puppy.add(ConsoleLogger(
            label,
            logLevel: .trace,
            logFormat: LoggingFormatter()
        ))
    }
    
    @inlinable
    public mutating func add(
        _ label: String,
        fileURL: URL,
        filePermission: String = "640",
        delegate: FileRotationLoggerDelegate? = nil
    ) throws {
        try puppy.add(FileRotationLogger(
            label,
            logLevel: .trace,
            logFormat: LoggingFormatter(),
            fileURL: fileURL,
            filePermission: filePermission,
            rotationConfig: .init(      // 设置：每个文件最大 10MB，保留最近 20 个备份，总共占用约 1GB 空间
                suffixExtension: .date_uuid,
                maxFileSize: 10 * 1024 * 1024,
                maxArchivedFilesCount: 100
            ),
            delegate: delegate
        ))
    }
}

@usableFromInline
struct LoggingFormatter: LogFormattable {
    
    @usableFromInline
    init() {}
    
    @usableFromInline
    func formatMessage(
        _ level: LogLevel,
        message: String,
        tag: String,
        function: String,
        file: String,
        line: UInt,
        swiftLogInfo: [String : String],
        label: String,
        date: Date,
        threadID: UInt64
    ) -> String {
        let timestamp = ISO8601DateFormatter.string(from: date, timeZone: .current, formatOptions: [.withInternetDateTime, .withFractionalSeconds])
        let levelStr = level.description.uppercased().padding(toLength: 5, withPad: " ", startingAt: 0)
        let fileName = file.components(separatedBy: "/").last ?? "Unknown"
        
        var finalLabel = label
        if let subLabel = swiftLogInfo["label"] {
            finalLabel = finalLabel + "-" + subLabel
        }
        
        var finalMetadata = ""
        if let businessMeta = swiftLogInfo["metadata"] {
            finalMetadata = businessMeta
        }
        
        let metadataStr = finalMetadata.isEmpty ? "" :  " | \(finalMetadata)"
        
        // 组装：[时间] [级别] [线程] [Label] [位置] 消息
        return "\(timestamp) [\(levelStr)] [T:\(threadID)] [\(finalLabel)] [\(fileName):\(line)] \(message)\(metadataStr)"
    }
}
