import Foundation
import ErrorHandle

extension Data: SafeDataConvertable {
    /// 从 Data 初始化该类型，有错误抛出
    @inlinable
    public static func new(data: Data) -> Data { data }
    /// 转换为 Data，有错误抛出
    @inlinable
    public var data: Data { self }
}

extension UUID: EncodingThrowableDataConvertable, DecodingSafeDataConvertable {
    public enum Errcase: String, ErrList {
        case uuidFailed = "Data 到 UUID 编码失败"
    }
    
    @inlinable
    public static func make(data: Data) -> Res<Self, Errcase> {
        String.make(data: data).mapError { error in
            .init(.uuidFailed, "Data 格式不正确")
        }.flatMap { uuidString in
            guard let v = UUID(uuidString: uuidString) else {
                return .failure(.uuidFailed, "Data 编码后得到空字符串")
            }
            return .success(v)
        }
    }
    
    @inlinable
    public var data: Data { try! self.uuidString.dataRes.get() }
}

extension Date: SafeDataConvertable {
    @inlinable
    public static func new(data: Data) -> Self { Date(timeIntervalSince1970: TimeInterval.new(data: data)) }
    @inlinable
    public var data: Data { self.timeIntervalSince1970.data }
}
