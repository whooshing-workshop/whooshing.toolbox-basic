import Crypto
import Foundation
import ErrorHandle
import DataConvertable

/**
    #### 封装了与加密相关的静态方法和功能，使用 enum 定义是只将其作为一个命名空间。

    包括: 

    - **摘要算法**: HASH(哈希)
    - **对称加密算法**: AES(高级加密标准)
    - **非对称加密算法**: EdDSA(Edward 曲线)
    - **密钥交换算法**: Diffie-Hellman 密钥交换协议
    - **签名和认证**:
        - **HMAC**: 使用对称加密和 HASH 生成信息来源验证
        - **EdDSA**: 非对称的电子签名来源验证
*/
@frozen
public enum Crypto {
    
    @frozen
    public enum Errcase: String, ErrList {
        case hashFailed = "哈希失败"
    }
    
    /**
        #### 哈希摘要算法

        哈希算法由于其不可逆且高效的优点，常用与密码加密，完整性验证等等。

        该函数使用 SHA512 进行哈希摘要。

        - Parameters:
            - data: 需要进行加密的数据，该数据必须为 `Safe/Throwable DataConvertable` 的实例，详见 `DataConvertable.swift`
        
        - Returns: 哈希摘要，只提供 Data 类型。

        例如，摘要一个字符串: 
        ``` swift
        let plain = "Hello World!"
        // 由于 String 类型是 ThrowableDataConvertable 的，因此需要处理可能的错误。若数据类型为 SafeDataConvertable，则不存在这个问题
        do {
            // digest 即为摘要结果
            let digest = try Crypto.hash(plain)
        } catch let err {
            print(err)
        }
        ```
    */
    @inlinable
    public static func hash<T>(_ data: T) -> Data where T: DecodingSafeDataConvertable {
        try! __hash(data).get()
    }
    
    @inlinable
    public static func hash<T>(_ data: T) -> Res<Data, Errcase> where T: DecodingThrowableDataConvertable {
        __hash(data)
    }
    
    @inlinable
    static func __hash<T>(_ data: T) -> Res<Data, Errcase> where T: DecodingThrowableDataConvertable {
        Result(throws: .hashFailed) {
            Data(try HashFunction.hash(data: data.dataRes.get()))
        }
    }
    
    /**
        #### 哈希摘要算法，加盐哈希
     
        该函数使用 SHA512 进行哈希摘要。
        
        - Parameters:
            - data: 需要进行加密的数据，该数据必须为 `Safe/Throwable DataConvertable` 的实例，详见 `DataConvertable.swift`
            - salt: 盐值，该参数为 inout 参数，若输入非空的 salt 值，则该哈希会使用此盐值。否则，将会生成新值取代原 salt 值
        - Returns: 哈希摘要，只提供 Data 类型。
    */
    @inlinable
    public static func saltyHash<T>(_ data: T, salt: inout Data?) -> Res<Data, Errcase> where T: DecodingThrowableDataConvertable {
        if salt == nil {
            salt = randomDataGenerate(length: 32)
        }
        return Result(throws: .hashFailed) {
            Data(try HashFunction.hash(data: HashFunction.hash(data: data.dataRes.get()) + salt!))
        }
    }
    
    /// 随机数据生成函数，可指定长度以生成随机数据
    @inlinable
    public static func randomDataGenerate(length: Int = 32) -> Data {
        let randomBytes = SymmetricKey(size: .init(bitCount: length * 8)).withUnsafeBytes { Data($0) }
        return randomBytes
    }
}

// MARK: - 以下为私有实现

extension Crypto {
    @usableFromInline
    typealias HashFunction = SHA512
    
    @inlinable
    static var symmetricKeySize: SymmetricKeySize { SymmetricKeySize.bits256 }
}
