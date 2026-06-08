import Foundation

public extension UUID {
    @inlinable
    var hexString: String {
        let uuid = self.uuid
        return String(format: "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                      uuid.0, uuid.1, uuid.2, uuid.3, uuid.4, uuid.5, uuid.6, uuid.7,
                      uuid.8, uuid.9, uuid.10, uuid.11, uuid.12, uuid.13, uuid.14, uuid.15)
    }
    
    /// 返回 UUID 前 8 位的 id 全大写作为字符串
    @inlinable
    var shortString: String {
        // uuidString 的格式通常是 "E621E1F8-C27C-44A7-975B-3D2E8B99CCCD"
        // 截取第一个 "-" 之前的内容
        return String(self.uuidString.prefix(8))
    }
}
