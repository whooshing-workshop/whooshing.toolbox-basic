import Puppy
import Foundation

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
            rotationConfig: .init(      // 设置：每个文件最大 10MB，保留最近 20 个备份，总共占用约 240MB 空间
                suffixExtension: .date_uuid,
                maxFileSize: 10 * 1024 * 1024,
                maxArchivedFilesCount: 20
            ),
            delegate: delegate
        ))
    }
}
