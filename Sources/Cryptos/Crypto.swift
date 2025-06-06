import Crypto
import Foundation
import ErrorHandle
import DataConvertable

/// 加解密 Crypto 模块可能出现的所有错误
public enum CryptoErrorLists: String, ErrList {
    public var domain: String { "ToolboxBsc.Crypto" }
    case encryptFailed = "加密失败"
    case decryptFailed = "解密失败"
    case signFailed = "签名失败"
    case validateFailed = "签名验证失败"
    case keyEncapsulateFailed = "密钥协商失败"
    case saltGenerateFailed = "盐值生成失败"
    case keyInvalid = "密钥不合法"
}

public typealias CptErr = CryptoErrorLists

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
public enum Crypto {
    
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
    public static func hash(_ data: any SafeDataConvertable) -> Data { try! hash(data as (any ThrowableDataConvertable)) }
    public static func hash(_ data: any ThrowableDataConvertable) throws -> Data { .init(try HashFunction.hash(data: data.data())) }
    
    /**
        #### 哈希摘要算法，加盐哈希
     
        该函数使用 SHA512 进行哈希摘要。
        
        - Parameters:
            - data: 需要进行加密的数据，该数据必须为 `Safe/Throwable DataConvertable` 的实例，详见 `DataConvertable.swift`
            - salt: 盐值，该参数为 inout 参数，若输入非空的 salt 值，则该哈希会使用此盐值。否则，将会生成新值取代原 salt 值
        - Returns: 哈希摘要，只提供 Data 类型。
    */
    public static func saltyHash(_ data: any ThrowableDataConvertable, salt: inout Data?) throws -> Data {
        if salt == nil { salt = randomDataGenerate(length: 32) }
        return .init(try HashFunction.hash(data: HashFunction.hash(data: data.data()) + salt!))
    }
    
    /// 随机数据生成函数，可指定长度以生成随机数据
    public static func randomDataGenerate(length: Int = 32) -> Data {
        let randomBytes = SymmetricKey(size: .init(bitCount: length * 8)).withUnsafeBytes { Data($0) }
        return randomBytes
    }

    /**
        #### 对称加密算法

        对称加密是指加解密必须使用用同一个密钥才能完成加解密算法。

        使用 AES 进行数据加密，其中提供
        
        - 对称加解密
        - 身份验证函数(即 Sign 声明块中所定义的)

        -----
        ### 对称加解密

        AES 加密，因其高效且安全，因此通常用于进行数据流加密，适用于加密大数据，但密钥需要妥善管理并安全交换。

        使用 `makeKey()` 生成密钥，并使用 `encrypt(_, key)` 加密数据，`decrypt(_, key)` 解密数据。

        ``` swift
        let plain = "Hello World!"
        // 生成对称密钥
        let key = Crypto.Symm.makeKey()
        // plain 的数据类型为 String，为 ThrowableDataConvertable，所以需要捕获并处理错误
        do {
            // 加密数据
            let cipher = try Crypto.Symm.encrypt(plain, key: key)
            // 解密数据
            let new: String = try Crypto.Symm.decrypt(cipher, key: key)

            print(new == plain)     // true
        } catch let err {
            // AES 加解密出现错误！
            print(err)
        }
        ```
        -----
        ### HMAC 消息来源验证(即 Sign 声明块中所定义的)

        HMAC 并不负责加密数据，仅负责进行身份验证，即便消息为明文，仍可以保证消息不被篡改(或说，可以判断是否被篡改从而采取行动)。但它并不负责数据是否被窃取，仅用做验证数据完整性和可靠性。

        依然使用 `makeKey()` 生成密钥，`make(_, key)` 创建签名，`validate(_, authCode, key)` 验证签名

        ``` swift
        let plain = "Hello World!"
        let key = Crypto.Symm.makeKey()
        do {
            // 创建签名
            let hmacCode = try Crypto.Symm.Sign.make(plain, key: key)
            // 验证签名
            let isValid = try Crypto.Symm.Sign.validate(plain, authCode: hmacCode, key: key)

            print(isValid ? "验证有效，消息\"\(plain)\"未被篡改" : "验证失败，消息被篡改")  // 验证有效，消息"Hello World!"未被篡改
        } catch let err {
            print(err)
        }
        ```
    */
    public enum Symm{
        public typealias Key = SymmetricKey

        /// 创建一个对称加密密钥
        public static func makeKey() -> Key { Key(size: symmetricKeySize) }

        /// 对数据进行加密
        /// 
        /// - Parameters:
        ///     - data: 待加密的数据
        ///     - key: 用于加密的密钥，可以由 `makeKey()` 函数生成
        /// - 返回值: 加密过后的密文，只提供 Data 形式
        public static func encrypt(_ data: any ThrowableDataConvertable, key: Key) throws -> Data { try aesEncrypt(data, key: key) }

        /// 对数据进行解密
        /// 
        /// - Parameters:
        ///     - cipher: 待解密的密文
        ///     - key:  用于解密的密钥，与加密密钥使用同一个密钥
        /// - 返回值: 解密后的明文，返回的数据类型取决于目标类型
        /// 
        /// ``` swift 
        /// let plain: String = try Crypto.symm.decrypt(..., key: ...)
        /// ```
        public static func decrypt<D>(_ cipher: Data, key: Key) throws -> D where D: ThrowableDataConvertable { try aesDecrypt(cipher, key: key) }
        
        /**
            #### 数据流加解密
         
            设计来用于对流式数据进行加解密，对于这类数据，AES.GCM 无需生产随机的 nonce，转为使用每个数据块的索引代替
            且使用 AAD 进行完整性验证。
         
            每个密文的长度固定，为 明文大小 + cipherExtraLength。这保证了文件流加密时无需记录文件的加密块边界
         */
        public enum Stream {
            
            /// 数据块加密的密文额外大小，即 `cipher.count = plain.count + cipherExtraLength`
            static var cipherExtraLength: Int { Crypto.Symm.cipherExtraLength }
            
            /// 对数据流进行加密，十分适用于文件流加密这类有记忆的流式传输加密
            ///
            /// - Parameters:
            ///     - data: 待加密的数据
            ///     - key: 用于加密的密钥，可以由 `makeKey()` 函数生成
            ///     - chunkTag: 数据流的标记，一般是该数据块的索引值
            /// - Returns: 加密过后的数据密文
            ///
            /// - warning: 对于无记忆的流式传输，比如 websocket，除非你自己建立索引计数，否则应当使用普通的 `Symm.encrypt` 代替
            static func encrypt(_ data: any ThrowableDataConvertable, key: Key, chunkTag: Int) throws -> Data {
                try chunkEncrypt(data, key: key, chunkTag: chunkTag)
            }
            
            /// 对数据流密文进行解密，十分适用于文件流加密这类有记忆的流式传输加密
            ///
            /// - Parameters:
            ///     - cipher: 待解密的密文
            ///     - key:  用于解密的密钥，与加密密钥使用同一个密钥
            ///     - chunkTag: 数据流的标记，一般是该数据块的索引值
            /// - Returns: 解密后的数据明文
            ///
            /// - warning: 对于无记忆的流式传输，比如 websocket，除非你自己建立索引计数，否则应当使用普通的 `Symm.decrypt` 代替
            static func decrypt(_ cipher: Data, key: Key, chunkTag: Int) throws -> Data {
                try chunkDecrypt(cipher, key: key, chunkTag: chunkTag)
            }
            
        }
        
        /// 消息来源验证块，实现 HMAC 的签名和认证
        public enum Sign {

            /// 创建签名
            /// 
            /// - Parameters:
            ///     - data: 待签名的数据
            ///     - key: 用于签名的密钥，可共用加解密密钥
            /// - Returns: MAC 消息验证码，发送至对方用于验证消息是否被篡改
            /// ``` swift
            /// let mac = try Crypto.Symm.Sign.make(data, key)
            /// ```
            public static func make(_ data: any SafeDataConvertable, key: Key) -> Data { try! make(data as (any ThrowableDataConvertable), key: key) }
            public static func make(_ data: any ThrowableDataConvertable, key: Key) throws -> Data { .init(try HMAC<HashFunction>.authenticationCode(for: data.data(), using: key)) }
            
            /// 验证签名
            /// 
            /// - Parameters:
            ///     - data: 数据本体，需要被验证是否完整的数据
            ///     - authCode: MAC 消息验证码，由 ```Crypto.Symm.Sign.make(..., key)``` 生成
            ///     - key: 用于解密的密钥，需与加密密钥一致方可进行验证
            /// - Returns: 验证是否匹配，是 则返回 true，否 则返回 false
            public static func validate(_ data: any SafeDataConvertable, authCode: Data, key: Key) -> Bool { try! validate(data as (any ThrowableDataConvertable), authCode: authCode, key: key) }
            public static func validate(_ data: any ThrowableDataConvertable, authCode: Data, key: Key) throws -> Bool { try HMAC<HashFunction>.isValidAuthenticationCode(authCode, authenticating: data.data(), using: key) }
        }
    }

    /**
        #### 非对称加密算法

        非对称加密是指加解密使用不同的密钥完成加解密的算法，由于其加密密钥和解密密钥分开的缘故，在数据加密上更加灵活。但由于其通常较对称加密更低效，被用做密钥交换，或数字签名等等。

        使用 EdDSA(Curve25519) 进行密钥协商，并使用协商得到的私钥进行通讯加密。

        - 创建公私密钥
        - 加解密
        - 签名和验证

        -----
        ### 非对称加解密 (EdDSA)

        使用 `makeCryptoKeyPair()` 生成加解密密钥对(公钥和私钥)，调用 `keyEncapsulate(key, partyPublic, salt)` 进行密钥协商，至此得到对称加密密钥。
        ``` swift
        // 对方的公钥，用于协商共享对称密钥
        let partyPublicKey = ...
        // 盐，用于协商共享对称密钥，一般为随机值，但需要保证双方的盐值都一致
        let salt = ...
        // 上下文信息，用于协商共享对称密钥，一些附加的自定义信息，可以指定为加密的用途，机制等等都可
        let info = ...
        // 创建加密非对称密钥对，包括公钥和私钥
        let keyPair = Crypto.Asym.makeCryptoKeyPair()
        do {
            // 协商密钥，需要我方的私钥与对方的公钥，并加盐和上下文信息
            let symmKey = try Crypto.Asym.keyEncapsulate(key: keyPair.private, partyPublic: partyPublicKey, salt: salt, info: info)
            // 之后便可开始使用 symmKey 进行对称加密
            // let cipher = Crypto.Symm. ...
        } catch let err {
            // 协商失败，处理错误
            print(err)
        }
        ```

        -----
        ### 数字签名 (Curve25519)

        非对称加密创建数字签名，并不负责加密数据，仅负责进行身份验证，即便消息为明文，仍可以保证消息不被篡改(或说，可以判断是否被篡改从而采取行动)。但它并不负责数据是否可被窃取，仅用做验证完整性和可靠性。

        使用 `makeSignKeyPair()` 生成签名密钥对(公钥和私钥)，调用 `make(_, key)` 创建签名，`validate(_, sign, key)` 验证签名

        ``` swift
        let plain = "Hello World!"
        // 创建签名非对称密钥对，包括公钥和私钥
        let keyPair = makeSignKeyPair()
        do {
            // 创建签名，使用你的私钥进行签名
            let sign = try Crypto.Asym.Sign.make(plain, key: keyPair.private)
            // 使用公钥验证所签名的密文
            let isValid = try Crypto.Asym.Sign.validate(plain, sign: sign, key: keyPair.public)
            print(isValid ? "验证有效，消息\"\(plain)\"未被篡改" : "验证失败，消息被篡改")  // 验证有效，消息"Hello World!"未被篡改
        } catch let err {
            // 签名出现错误，需要处理
            print(err)
        }
        ```

        需要注意，该对称加密的加解密密钥对与签名密钥对不可混用，因此有 `makeCryptoKeyPair()` 与 `makeSignKeyPair()` 方法之别
    */
    public enum Asym {

        /// 加解密密钥对 - 公钥
        public typealias CPublicKey = Curve25519.KeyAgreement.PublicKey
        /// 加解密密钥对 - 私钥
        public typealias CPrivateKey = Curve25519.KeyAgreement.PrivateKey
        /// 签名密钥对 - 公钥
        public typealias SPublicKey = Curve25519.Signing.PublicKey
        /// 签名密钥对 - 私钥
        public typealias SPrivateKey = Curve25519.Signing.PrivateKey

        /// 加解密密钥对
        public typealias CKeyPair = (public: CPublicKey, private: CPrivateKey)
        /// 签名密钥对
        public typealias SKeyPair = (public: SPublicKey, private: SPrivateKey)

        /// 创建加解密密钥对，包括公钥和私钥
        public static func makeCryptoKeyPair() -> CKeyPair { let privateKey = CPrivateKey(); return (privateKey.publicKey, privateKey) }
        /// 创建签名密钥对，包括公钥和私钥
        public static func makeSignKeyPair() -> SKeyPair { let privateKey = SPrivateKey(); return (privateKey.publicKey, privateKey) }
        
        /// 密钥协商，成功完成后会协商出一个对称密钥
        /// 
        /// - Parameters:
        ///     - key: 己方的私钥
        ///     - partyPublic: 对方的公钥
        ///     - salt: 盐值，双方需要保持一致
        ///     - info: 上下文信息，双方需要保持一致。该参数可以自定设置为任意值，只是需要双方一致
        /// - Returns: 协商完成的对称密钥
        public static func keyEncapsulate(key: CPrivateKey, partyPublic: CPublicKey, salt: any ThrowableDataConvertable, info: any ThrowableDataConvertable) throws -> Symm.Key { 
            let sharedKey = try Guard({ try key.sharedSecretFromKeyAgreement(with: partyPublic) }, throw: CptErr.keyEncapsulateFailed.d(1012))
            return try sharedKey.hkdfDerivedSymmetricKey(using: HashFunction.self, salt: salt.data(), sharedInfo: info.data(), outputByteCount: symmetricKeySize.bitCount / 8)
        }

        /// 数字签名，可实现非对称加密，使用 Curve25519 进行签名和验证
        public enum Sign {

            /// 使用私钥创建签名
            /// 
            /// - Parameters:
            ///     - data: 要签名的数据
            ///     - key: 己方的私钥
            /// - Returns: 该数据的签名
            public static func make(_ data: any ThrowableDataConvertable, key: SPrivateKey) throws -> Data { try key.signature(for: data.data()) }

            /// 使用公钥验证签名
            /// 
            /// - Parameters:
            ///     - data: 数据本体，需要被验证是否完整的数据
            ///     - key: 己方的公钥
            /// - Returns: 验证是否匹配，是 则返回 true，否 则返回 false
            public static func validate(_ data: any SafeDataConvertable, sign: Data, key: SPublicKey) throws -> Bool { try! validate(data as (any ThrowableDataConvertable), sign: sign, key: key) }
            public static func validate(_ data: any ThrowableDataConvertable, sign: Data, key: SPublicKey) throws -> Bool { try key.isValidSignature(sign, for: data.data()) }
        }
    }
}

// MARK: - 以下为私有实现

private extension Crypto {
    typealias HashFunction = SHA512
    static var symmetricKeySize: SymmetricKeySize { SymmetricKeySize.bits256 }
}

private extension Crypto.Symm {
    static func aesEncrypt(_ data: any ThrowableDataConvertable, key: Key) throws -> Data {
        // print("正在进行加密: \(try data.data().count), key: \(key.data().base64String()))")
        precondition(key.bitCount == Crypto.symmetricKeySize.bitCount, "密钥长度不正确，应当为 \(Crypto.symmetricKeySize.bitCount) 位，却得到 \(key.bitCount) 位")
        let sealedBox = try Guard({ try AES.GCM.seal(data.data(), using: key, nonce: .init()) }, throw: CptErr.encryptFailed.d("AES 加密未能成功封印明文数据", 1009))
        guard let cipher = sealedBox.combined else {
            throw CptErr.encryptFailed.d("AES 加密-未知错误，密文不存在", 1006)
        }
        // print("加密得到: \(cipher.count)")
        return cipher
    }

    static func aesDecrypt<D>(_ cipher: Data, key: Key) throws -> D where D: ThrowableDataConvertable {
        // print("正在进行解密: \(cipher.count), key: \(key.data().base64String()))")
        precondition(key.bitCount == Crypto.symmetricKeySize.bitCount, "密钥长度不正确，应当为 \(Crypto.symmetricKeySize.bitCount) 位，却得到 \(key.bitCount) 位")
        let sealedBox = try AES.GCM.SealedBox(combined: cipher)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        // print("解密得到: \(decryptedData.count)")
        return try D(data: decryptedData)
    }

    static func aesKey(key: Data) -> Key { normalKey(key: key) }
}

private extension Crypto.Symm {
    static var cipherExtraLength: Int { 16 }
    
    static func chunkEncrypt(_ data: any ThrowableDataConvertable, key: Key, chunkTag: Int) throws -> Data {
        precondition(key.bitCount == Crypto.symmetricKeySize.bitCount, "密钥长度不正确，应当为 \(Crypto.symmetricKeySize.bitCount) 位，却得到 \(key.bitCount) 位")
        
        let chunkTagData = chunkTagToData(chunkTag)
        
        let sealedBox = try AES.GCM.seal(
            data.data(),
            using: key,
            nonce: .init(data: chunkTagData),
            authenticating: chunkTagData
        )
        
        // 密文总长度为 plain.count + 16 bytes
        return sealedBox.ciphertext + sealedBox.tag
    }
    
    static func chunkDecrypt(_ cipher: Data, key: Key, chunkTag: Int) throws -> Data {
        precondition(key.bitCount == Crypto.symmetricKeySize.bitCount, "密钥长度不正确，应当为 \(Crypto.symmetricKeySize.bitCount) 位，却得到 \(key.bitCount) 位")
        precondition(cipher.count >= cipherExtraLength, "密文过短，格式不正确，无法解密，至少超过 \(cipherExtraLength)，却得到 \(cipher.count) 字节")
        
        let chunkTagData = chunkTagToData(chunkTag)
        
        let sealedBox = try AES.GCM.SealedBox(
            nonce: .init(data: chunkTagData),
            ciphertext: cipher.subdata(in: 0..<(cipher.count - cipherExtraLength)),
            tag: cipher.subdata(in: (cipher.count - cipherExtraLength)..<cipher.count),
        )
        let plain = try AES.GCM.open(sealedBox, using: key, authenticating: chunkTagData)
        
        return plain
    }
    
    static func chunkTagToData(_ chunkTag: Int, length: Int = 12) -> Data {
        precondition(length >= 8, "Nonce 的长度必须至少为 8 bytes 以存储块标记，得到的长度为: \(length)")
        
        var bytes = [UInt8](repeating: 0, count: length)
        withUnsafeBytes(of: chunkTag.bigEndian) { ptr in
            bytes.replaceSubrange((length - 8)..<length, with: ptr) // 把 chunkTag 填入后8字节
        }
        return .init(bytes)
    }
}

private extension Crypto.Symm {
    static func normalKey(key: Data) -> Key { Key(data: key) }
}
