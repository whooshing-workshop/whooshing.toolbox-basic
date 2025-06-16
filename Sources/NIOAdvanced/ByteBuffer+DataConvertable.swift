import DataConvertable
import Foundation
import NIOCore
import NIOFoundationCompat

extension ByteBuffer: SafeDataConvertable {
    public func data() -> Data {
        .init(buffer: self)
    }
}
