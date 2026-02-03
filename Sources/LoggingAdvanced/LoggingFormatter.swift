import Puppy
import Foundation

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
