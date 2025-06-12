import Crypto
import Foundation
import ErrorHandle
import DataConvertable

public extension Crypto {
    
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
    enum Symm{
        public typealias Key = SymmetricKey

        /// 创建一个对称加密密钥
        public static func makeKey() -> Key { Key(size: symmetricKeySize) }
        
        /// 从一个父密钥派生新密钥
        ///
        /// - Parameters:
        ///     - key: 父密钥
        ///     - salt: 派生盐，应当不重复且随机
        ///     - info: 派生密钥上下文信息
        /// - Returns: 从父密钥创建的新派生密钥
        ///
        /// salt 与 info 为可缺省值，若两值都指定为 nil，则函数返回原密钥，即 key
        public static func derive(key: Key, salt: (any ThrowableDataConvertable)?, info: (any ThrowableDataConvertable)?) throws -> Key {
            if let salt = salt, let info = info {
                return try HKDF<HashFunction>.deriveKey(inputKeyMaterial: key, salt: salt.data(), info: info.data(), outputByteCount: symmetricKeySize.bitCount / 8)
            } else if let salt = salt {
                return try HKDF<HashFunction>.deriveKey(inputKeyMaterial: key, salt: salt.data(), outputByteCount: symmetricKeySize.bitCount / 8)
            } else if let info = info {
                return try HKDF<HashFunction>.deriveKey(inputKeyMaterial: key, info: info.data(), outputByteCount: symmetricKeySize.bitCount / 8)
            } else {
                return key
            }
        }
        
        /// 从一个父密钥派生新密钥
        ///
        /// - Parameters:
        ///     - key: 父密钥
        ///     - salt: 派生盐，应当不重复且随机
        ///     - info: 派生密钥上下文信息
        /// - Returns: 从父密钥创建的新派生密钥
        ///
        /// salt 与 info 为可缺省值，若两值都指定为 nil，则函数返回原密钥，即 key
        public static func derive(key: Key, salt: (any SafeDataConvertable)?, info: (any SafeDataConvertable)?) -> Key {
            if let salt = salt, let info = info {
                return HKDF<HashFunction>.deriveKey(inputKeyMaterial: key, salt: salt.data(), info: info.data(), outputByteCount: symmetricKeySize.bitCount / 8)
            } else if let salt = salt {
                return HKDF<HashFunction>.deriveKey(inputKeyMaterial: key, salt: salt.data(), outputByteCount: symmetricKeySize.bitCount / 8)
            } else if let info = info {
                return HKDF<HashFunction>.deriveKey(inputKeyMaterial: key, info: info.data(), outputByteCount: symmetricKeySize.bitCount / 8)
            } else {
                return key
            }
        }

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
            public static var cipherExtraLength: Int { Crypto.Symm.cipherExtraLength }
            
            /// 对数据流进行加密，十分适用于文件流加密这类有记忆的流式传输加密
            ///
            /// - Parameters:
            ///     - data: 待加密的数据
            ///     - key: 用于加密的密钥，可以由 `makeKey()` 函数生成
            ///     - chunkTag: 数据流的标记，一般是该数据块的索引值
            /// - Returns: 加密过后的数据密文
            ///
            /// - warning: 对于无记忆的流式传输，比如 websocket，除非你自己建立索引计数，否则应当使用普通的 `Symm.encrypt` 代替
            public static func encrypt(_ data: any ThrowableDataConvertable, key: Key, chunkTag: Int) throws -> Data {
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
            public static func decrypt(_ cipher: Data, key: Key, chunkTag: Int) throws -> Data {
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
            tag: cipher.subdata(in: (cipher.count - cipherExtraLength)..<cipher.count)
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
