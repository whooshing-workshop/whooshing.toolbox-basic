import Testing
@testable import Cryptos
import Foundation
import Crypto
import NIO

@Suite("加密模块-测试")
struct CryptoTest {

    @Test("测试对称加密-解密")
    func testSymmetricEncryptionDecryption() {
        let key = Crypto.Symm.makeKey()
        let originalData = "Hello, World!".data(using: .utf8)!
        
        do {
            let encryptedData = try Crypto.Symm.encrypt(originalData, key: key)
            let decryptedData: Data = try Crypto.Symm.decrypt(encryptedData, key: key)
            #expect(decryptedData == originalData, "解密后的数据与原始数据不匹配")
        } catch {
            #expect(Bool(false), "对称加密-解密测试失败: \(error)")
        }
    }

    @Test("测试HMAC 生成与验证")
    func testHMAC() {
        let key = Crypto.Symm.makeKey()
        let data = "Hello, HMAC!".data(using: .utf8)!
        let hmac = Crypto.Symm.Sign.make(data, key: key)
        let isValid = Crypto.Symm.Sign.validate(data, authCode: hmac, key: key)
        #expect(isValid, "HMAC 验证失败")
    }

    @Test("测试非对称密钥生成与密钥协商")
    func testAsymmetricKeyGenerationAndKeyEncapsulation() {
        let keyPair1 = Crypto.Asym.makeCryptoKeyPair()
        let keyPair2 = Crypto.Asym.makeCryptoKeyPair()
        let salt = "some_salt".data(using: .utf8)!
        let info = "some_info".data(using: .utf8)!
        
        do {
            let symmKey1 = try Crypto.Asym.keyEncapsulate(key: keyPair1.private, partyPublic: keyPair2.public, salt: salt, info: info)
            let symmKey2 = try Crypto.Asym.keyEncapsulate(key: keyPair2.private, partyPublic: keyPair1.public, salt: salt, info: info)
            #expect(symmKey1 == symmKey2, "密钥协商失败，生成的对称密钥不匹配")
            #expect(symmKey1.bitCount == SymmetricKeySize.bits256.bitCount)
        } catch {
            #expect(Bool(false), "非对称密钥生成与密钥协商测试失败: \(error)")
        }
    }

    @Test("测试签名与验证")
    func testSigningAndValidation() {
        let keyPair = Crypto.Asym.makeSignKeyPair()
        let data = "Hello, Signing!".data(using: .utf8)!
        
        do {
            let signature = try Crypto.Asym.Sign.make(data, key: keyPair.private)
            let isValid = try Crypto.Asym.Sign.validate(data, sign: signature, key: keyPair.public)
            #expect(isValid, "签名验证失败")
        } catch {
            #expect(Bool(false), "签名与验证测试失败: \(error)")
        }
    }

    @Test("测试哈希生成")
    func testHashGeneration() {
        let data = "Hello, Hash!".data(using: .utf8)!
        let hash = Crypto.hash(data)
        #expect(!hash.isEmpty, "哈希生成失败")
    }
    
    @Test("测试对对称加密密钥进行加解密")
    func testSymmKeyCrypto() {
        let key = Crypto.Symm.makeKey()
        let cKey = Crypto.Symm.makeKey()
        do {
            let cipher = try Crypto.Symm.encrypt(key, key: cKey)
            let cipher_bytes = ByteBuffer(data: cipher)
            let cipher_data = cipher_bytes.data()
            let res: Crypto.Symm.Key = try Crypto.Symm.decrypt(cipher_data, key: cKey)
            #expect(key == res)
        } catch {
            #expect(Bool(false), "对对称加密加解密失败: \(error)")
        }
    }

    @Test("测试混合加密情况")
    func testMixedEncryptionAlgorithms() {
        let symmKey = Crypto.Symm.makeKey()
        let asymKeyPair = Crypto.Asym.makeCryptoKeyPair()
        let signKeyPair = Crypto.Asym.makeSignKeyPair()
        let originalData = "Hello, Mixed Encryption!".data(using: .utf8)!
        let salt = "mixed_salt".data(using: .utf8)!
        let info = "mixed_info".data(using: .utf8)!

        do {
            // 对称加密
            let encryptedData = try Crypto.Symm.encrypt(originalData, key: symmKey)
            // 非对称密钥封装
            let encapsulatedKey = try Crypto.Asym.keyEncapsulate(key: asymKeyPair.private, partyPublic: asymKeyPair.public, salt: salt, info: info)
            // HMAC 生成
            let hmac = Crypto.Symm.Sign.make(encryptedData, key: symmKey)
            // 使用协调密钥进行加密
            let cipherHmac = try Crypto.Symm.encrypt(hmac, key: encapsulatedKey)
            // 签名
            let signature = try Crypto.Asym.Sign.make(encryptedData, key: signKeyPair.private)
            // 解密
            let decryptedData: Data = try Crypto.Symm.decrypt(encryptedData, key: symmKey)
            // HMAC 验证
            let isHMACValid = Crypto.Symm.Sign.validate(encryptedData, authCode: hmac, key: symmKey)
            // 使用协调密钥解开 HMAC
            let plainHmac: Data = try Crypto.Symm.decrypt(cipherHmac, key: encapsulatedKey)
            // HMAC 验证解开后的 HMAC
            let isHMACValid2 = Crypto.Symm.Sign.validate(encryptedData, authCode: plainHmac, key: symmKey)
            // 签名验证
            let isSignatureValid = try Crypto.Asym.Sign.validate(encryptedData, sign: signature, key: signKeyPair.public)
            // 断言
            #expect(decryptedData == originalData)
            #expect(isHMACValid, "HMAC 验证失败")
            #expect(isHMACValid2, "协调密钥不正确")
            #expect(isSignatureValid, "签名验证失败")
            #expect(encapsulatedKey.bitCount == SymmetricKeySize.bits256.bitCount, "密钥封装失败")
        } catch {
            #expect(Bool(false), "混合加密算法测试失败: \(error)")
        }
    }
}
