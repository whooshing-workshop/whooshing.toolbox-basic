import Crypto
import Foundation
import ErrorHandle
import DataConvertable

public extension Crypto {
    
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
    enum Asym {
        
        public enum Errcase: String, ErrList {
            case keyEncapsulateFailed = "密钥协商失败"
        }

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
        public static func keyEncapsulate<T, G>(
            key: CPrivateKey,
            partyPublic: CPublicKey,
            salt: T,
            info: G
        ) -> Res<Symm.Key, Errcase> where T: DecodingThrowableDataConvertable, G: DecodingThrowableDataConvertable {
            Result (throws: .keyEncapsulateFailed, "密钥协商失败") {
                try key.sharedSecretFromKeyAgreement(with: partyPublic)
            }.flatMap { sharedKey in
                do {
                    return .success(
                        try sharedKey.hkdfDerivedSymmetricKey(
                            using: HashFunction.self,
                            salt: salt.dataRes.get(),
                            sharedInfo: info.dataRes.get(),
                            outputByteCount: symmetricKeySize.bitCount / 8
                        )
                    )
                } catch {
                    return .failure(.keyEncapsulateFailed, "密钥派生失败", subErr: error)
                }
            }
        }

        /// 数字签名，可实现非对称加密，使用 Curve25519 进行签名和验证
        public enum Sign {
            
            public enum Errcase: String, ErrList {
                case signMakeFailed = "签名生成失败"
                case unknown = "验证失败，未知原因"
            }

            /// 使用私钥创建签名
            ///
            /// - Parameters:
            ///     - data: 要签名的数据
            ///     - key: 己方的私钥
            /// - Returns: 该数据的签名
            public static func make<T>(_ data: T, key: SPrivateKey) -> Res<Data, Errcase> where T: DecodingThrowableDataConvertable {
                .init(throws: .signMakeFailed) {
                    try key.signature(for: data.dataRes.get())
                }
            }

            /// 使用公钥验证签名
            ///
            /// - Parameters:
            ///     - data: 数据本体，需要被验证是否完整的数据
            ///     - key: 己方的公钥
            /// - Returns: 验证是否匹配，是 则返回 true，否 则返回 false
            public static func validate<T>(_ data: T, sign: Data, key: SPublicKey) -> Bool where T: DecodingSafeDataConvertable {
                try! __validate(data, sign: sign, key: key).get()
            }
            
            public static func validate<T>(_ data: T, sign: Data, key: SPublicKey) -> Res<Bool, Errcase> where T: DecodingThrowableDataConvertable {
                __validate(data, sign: sign, key: key)
            }
            
            static func __validate<T>(_ data: T, sign: Data, key: SPublicKey) -> Res<Bool, Errcase> where T: DecodingThrowableDataConvertable {
                .init(throws: .unknown, "验证未成功") {
                    try key.isValidSignature(sign, for: data.dataRes.get())
                }
            }
        }
    }
}
