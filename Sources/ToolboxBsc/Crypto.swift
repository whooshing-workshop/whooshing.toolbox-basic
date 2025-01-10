import Crypto
import Foundation

public enum CryptoErrorLists: String, ErrList {
    public var domain: String { "Crypto.Error" }
    case encryptFailed = "加密失败"
    case decryptFailed = "解密失败"
    case signFailed = "签名失败"
    case validateFailed = "签名验证失败"
    case keyEncapsulateFailed = "密钥协商失败"
}

public typealias CptErr = CryptoErrorLists

public enum Crypto {

    public static func hash(_ data: SafeDataConvertable) -> Data { try! hash(data as ThrowableDataConvertable) }
    public static func hash(_ data: ThrowableDataConvertable) throws -> Data { .init(try HashFunction.hash(data: data.data())) }

    public enum Symm{
        public typealias Key = SymmetricKey
        public static func makeKey() -> Key { Key(size: symmetricKeySize) }

        public static func encrypt(_ data: ThrowableDataConvertable, key: Key) throws -> Data { try aesEncrypt(data, key: key) }
        public static func decrypt<D>(_ cipher: Data, key: Key) throws -> D where D: ThrowableDataConvertable { try aesDecrypt(cipher, key: key) }

        public enum Sign {
            public static func make(_ data: SafeDataConvertable, key: Key) -> Data { try! make(data as ThrowableDataConvertable, key: key) }
            public static func make(_ data: ThrowableDataConvertable, key: Key) throws -> Data { .init(try HMAC<HashFunction>.authenticationCode(for: data.data(), using: key)) }
            
            public static func validate(_ data: SafeDataConvertable, authCode: Data, key: Key) -> Bool { try! validate(data as ThrowableDataConvertable, authCode: authCode, key: key) }
            public static func validate(_ data: ThrowableDataConvertable, authCode: Data, key: Key) throws -> Bool { try HMAC<HashFunction>.isValidAuthenticationCode(authCode, authenticating: data.data(), using: key) }
        }
    }

    public enum Asym {

        public typealias CPublicKey = Curve25519.KeyAgreement.PublicKey
        public typealias CPrivateKey = Curve25519.KeyAgreement.PrivateKey
        public typealias SPublicKey = Curve25519.Signing.PublicKey
        public typealias SPrivateKey = Curve25519.Signing.PrivateKey

        public typealias CKeyPair = (public: CPublicKey, private: CPrivateKey)
        public typealias SKeyPair = (public: SPublicKey, private: SPrivateKey)

        public static func makeCryptoKeyPair() -> CKeyPair { let privateKey = CPrivateKey(); return (privateKey.publicKey, privateKey) }
        public static func makeSignKeyPair() -> SKeyPair { let privateKey = SPrivateKey(); return (privateKey.publicKey, privateKey) }
        
        public static func keyEncapsulate(key: CPrivateKey, partyPublic: CPublicKey, salt: ThrowableDataConvertable, info: ThrowableDataConvertable) throws -> Symm.Key { 
            let sharedKey = try Guard({ try key.sharedSecretFromKeyAgreement(with: partyPublic) }, throw: CptErr.keyEncapsulateFailed.d(1012, (#file, #line)))
            return try sharedKey.hkdfDerivedSymmetricKey(using: HashFunction.self, salt: salt.data(), sharedInfo: info.data(), outputByteCount: symmetricKeySize.bitCount / 8)
        }

        public enum Sign {
            public static func make(_ data: ThrowableDataConvertable, key: SPrivateKey) throws -> Data { try key.signature(for: data.data()) }

            public static func validate(_ data: SafeDataConvertable, sign: Data, key: SPublicKey) throws -> Bool { try! validate(data as ThrowableDataConvertable, sign: sign, key: key) }
            public static func validate(_ data: ThrowableDataConvertable, sign: Data, key: SPublicKey) throws -> Bool { try key.isValidSignature(sign, for: data.data()) }
        }
    }
}

private extension Crypto {
    typealias HashFunction = SHA512
    static var symmetricKeySize: SymmetricKeySize { SymmetricKeySize.bits256 }
}

private extension Crypto.Symm {
    static func aesEncrypt(_ data: ThrowableDataConvertable, key: Key) throws -> Data {
        let sealedBox = try Guard({ try AES.GCM.seal(data.data(), using: key) }, throw: CptErr.encryptFailed.d("AES 加密未能成功封印明文数据", 1009, (#file, #line)))
        guard let cipher = sealedBox.combined else {
            throw CptErr.encryptFailed.d("AES 加密-未知错误，密文不存在", 1006, (#file, #line))
        }
        return cipher
    }

    static func aesDecrypt<D>(_ cipher: Data, key: Key) throws -> D where D: ThrowableDataConvertable {
        let sealedBox = try Guard( { try AES.GCM.SealedBox(combined: cipher) }, throw: CptErr.decryptFailed.d("AES 解密-将密文转换为 SealedBox 时出错", 1007, (#file, #line)))
        let decryptedData = try Guard({ try AES.GCM.open(sealedBox, using: key) }, throw: CptErr.decryptFailed.d("AES 解密-解开密文时出错", 1008, (#file, #line)))
        return try D(data: decryptedData)
    }

    static func aesKey(key: Data) -> Key { normalKey(key: key) }
}

private extension Crypto.Symm {
    static func normalKey(key: Data) -> Key { Key(data: key) }
}

// extension Curve25519.KeyAgreement.PublicKey: Crypto.Asym.KeyPair.PublicKey {}
// extension Curve25519.KeyAgreement.PrivateKey: Crypto.Asym.KeyPair.PrivateKey {}
// extension Curve25519.Signing.PublicKey: Crypto.Asym.KeyPair.PublicKey {}
// extension Curve25519.Signing.PrivateKey: Crypto.Asym.KeyPair.PrivateKey {}