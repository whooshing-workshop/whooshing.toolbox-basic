import DataConvertable
import Foundation
import NIOCore
import NIOFoundationCompat

extension ByteBuffer: SafeDataConvertable {
    @inlinable
    public static func new(data: Data) -> ByteBuffer {
        Self.init(data: data)
    }
    
    @inlinable
    public var data: Data {
        .init(buffer: self)
    }
}
