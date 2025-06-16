import Testing
@testable import Cryptos
import Foundation
import Crypto

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
            let isValid = Crypto.Asym.Sign.validate(data, sign: signature, key: keyPair.public)
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
    
    @Test("测试加盐哈希")
    func testSaltyHash() {
        let data = "Hello, Hash!".data(using: .utf8)!
        do {
            var salt: Data? = Crypto.randomDataGenerate()
            let hash = try Crypto.saltyHash(data, salt: &salt)
            #expect(!hash.isEmpty, "加盐哈希生成失败")
            var salt2: Data? = Crypto.randomDataGenerate()
            let hash2 = try Crypto.saltyHash(data, salt: &salt2)
            #expect(!hash2.isEmpty, "加盐哈希 2 生成失败")
            #expect(salt != salt2, "加盐哈希验证失败，生成了相同的盐值")
            #expect(hash != hash2, "加盐哈希验证失败，不同盐值却生成了相同的哈希值")
        } catch {
            #expect(Bool(false), "加盐哈希测试失败: \(error)")
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
            let isSignatureValid = Crypto.Asym.Sign.validate(encryptedData, sign: signature, key: signKeyPair.public)
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
    
    @Test("密钥派生测试")
    func testKeyDerive() throws {
        let key = Crypto.Symm.makeKey()
        
        let key2 = try key.derive("Salt2", info: "Key2")
        let key3 = try key.derive("Salt3", info: "Key3")
        let key4 = try key.derive("Salt2", info: "Key2")
        let key5 = key.derive(nil)
        let key6 = try key.derive("Salt2", info: nil)
        
        #expect(key2.bitCount == key.bitCount)
        #expect(key3.bitCount == key.bitCount)
        
        #expect(key != key2)
        #expect(key != key3)
        #expect(key2 != key3)
        #expect(key2 == key4)
        #expect(key == key5)
        #expect(key6 != key)
        #expect(key6 != key2)
        
        let origin = "Hello World!"
        
        let cipher = try Crypto.Symm.encrypt(origin, key: key)
        let cipher2 = try Crypto.Symm.encrypt(origin, key: key2)
        let cipher3 = try Crypto.Symm.encrypt(origin, key: key3)
        
        #expect(throws: Error.self, performing: { let _: String = try Crypto.Symm.decrypt(cipher, key: key2) })
        #expect(throws: Error.self, performing: { let _: String = try Crypto.Symm.decrypt(cipher2, key: key) })
        #expect(throws: Error.self, performing: { let _: String = try Crypto.Symm.decrypt(cipher3, key: key2) })
        
        let plain: String = try Crypto.Symm.decrypt(cipher, key: key)
        let plain2: String = try Crypto.Symm.decrypt(cipher2, key: key2)
        let plain3: String = try Crypto.Symm.decrypt(cipher3, key: key3)
        
        #expect(plain == origin)
        #expect(plain2 == origin)
        #expect(plain3 == origin)
    }

    @Test("测试大数据加解密")
    func testLargeDataEncryption() {
        var s = ""
        for _ in 0..<100000 {
            s += "Hello"
        }
        let key = Crypto.Symm.makeKey()
        do {
            let cipher = try Crypto.Symm.encrypt(s, key: key)
            let plain: String = try Crypto.Symm.decrypt(cipher, key: key)
            #expect(s == plain)
        } catch let err {
            #expect(Bool(false), "大数据加解密测试失败: \(err)")
        }
    }
    
    @Test("测试流式加解密")
    func testStreamingDataEncryption() async throws {
        let total = 65535
        let chunkSize = 1000
        let chunkCipherSize = Crypto.Symm.Stream.cipherExtraLength + chunkSize
        
        let key = Crypto.Symm.makeKey()
        let data = Self.randomData(size: total)
        var current = 0
        
        var cipherData = Data()
        
        var i = 0
        while current < data.count {
            let endIndex = min(current + chunkSize, data.count)
            let chunkCipher = try Crypto.Symm.Stream.encrypt(data.subdata(in: current..<endIndex), key: key, chunkTag: i)
            let chunkSize = min(chunkSize, data.count - current)
            #expect(chunkCipher.count == chunkSize + Crypto.Symm.Stream.cipherExtraLength)
            cipherData += chunkCipher
            current += chunkSize
            i += 1
        }
        
        var plainData = Data()
        
        i = 0
        current = 0
        while current < cipherData.count {
            let endIndex = min(current + chunkCipherSize, cipherData.count)
            let chunkPlain: Data = try Crypto.Symm.Stream.decrypt(cipherData.subdata(in: current..<endIndex), key: key, chunkTag: i)
            let chunkSize = min(chunkCipherSize, cipherData.count - current)
            #expect(chunkPlain.count == chunkSize - Crypto.Symm.Stream.cipherExtraLength)
            plainData += chunkPlain
            current += chunkSize
            i += 1
        }
        
        #expect(plainData == data)
    }
    
    
    static func randomData(size: Int) -> Data {
        var data = Data()
        var rng = SystemRandomNumberGenerator()
        let randomBytes = (0..<size).map { _ in UInt8.random(in: 0...255, using: &rng) }
        data.append(contentsOf: randomBytes)
        return data
    }
}
