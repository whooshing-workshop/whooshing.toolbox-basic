import DataConvertable
import Foundation
import NIOCore
import NIOFoundationCompat

extension ByteBuffer: SafeDataConvertable {
    public static func new(data: Data) -> ByteBuffer {
        Self.init(data: data)
    }
    
    public var data: Data {
        .init(buffer: self)
    }
}
