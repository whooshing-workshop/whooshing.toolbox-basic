import Testing
@testable import ToolboxBsc
import Crypto

@Suite("加密模块测试") struct CryptoTests {

    @Test func testEncryptionDecryption() async throws {
        let key = Crypto.symmetricKey()
        let plain: String = "Hello World!"

        let cipher = try Crypto.symmetricEncrypt(plain, key: key)
        let decrypted: String = try Crypto.symmetricDecrypt(cipher, key: key)

        #expect(decrypted == plain)
    }

    @Test func testEncryptionWithDifferentKeys() async throws {
        let key1 = Crypto.symmetricKey()
        let key2 = Crypto.symmetricKey()
        let plain: String = "Hello World!"

        let cipher = try Crypto.symmetricEncrypt(plain, key: key1)

        do {
            let _ = try Crypto.symmetricDecrypt(cipher, key: key2) as String
            assert(false, "Decryption should have failed with a different key")
        } catch {
            // Expected error
        }
    }

    @Test func testEmptyStringEncryption() async throws {
        let key = Crypto.symmetricKey()
        let plain: String = ""

        let cipher = try Crypto.symmetricEncrypt(plain, key: key)
        let decrypted: String = try Crypto.symmetricDecrypt(cipher, key: key)

        #expect(decrypted == plain)
    }

    @Test func testLargeStringEncryption() async throws {
        let key = Crypto.symmetricKey()
        let plain = String(repeating: "A", count: 10000)

        let cipher = try Crypto.symmetricEncrypt(plain, key: key)
        let decrypted: String = try Crypto.symmetricDecrypt(cipher, key: key)

        #expect(decrypted == plain)
    }

}
