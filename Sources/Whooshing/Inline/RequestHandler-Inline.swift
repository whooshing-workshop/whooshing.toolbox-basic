import Vapor
import Cryptos
import ErrorHandle
import DataConvertable
import NIO
import Logging

extension ReqClient where ServiceType == Inline {
    var requestIoData: Inline.Init.RequestIOData! { self.storage[Inline.Init.RequestIOData.self] }
}

extension Inline.Init {
    final class RequestIOData: StorageKey, Sendable {
        typealias Value = RequestIOData
        let rootKey: Crypto.Symm.Key
        let module: ModuleData
        let connectionValidate: SendableDictionary<ObjectIdentifier, Bool> = .init()
        let connectionKeys: SendableDictionary<ObjectIdentifier, Crypto.Symm.Key> = .init()
        
        init(rootKey: Crypto.Symm.Key, module: ModuleData) {
            self.rootKey = rootKey
            self.module = module
        }
    }
    
    /// 实现 HTTP Request 的加解密
    struct RequestIOCrypto: RequestIOHandler, Sendable {
        let client: ReqClient<Inline>
        
        /// 发送请求时，进行编码并加密
        func send(request: ClientRequest, context: ChannelHandlerContext, allocator: ByteBufferAllocator) throws -> ByteBuffer {
            var plain = try request.data(bufferAllocator: allocator)
            let cipher: Data
            let id = ObjectIdentifier(context.channel)
            if let key = client.requestIoData.connectionKeys[id] { cipher = try Crypto.Symm.encrypt(plain, key: key) }
            else { cipher = try Crypto.Symm.encrypt(plain, key: client.requestIoData.rootKey) }
            plain.clear()
            plain.writeData(cipher)
            return plain
        }
        
        /// 收到响应时，进行解密并解码
        func get(response: ByteBuffer, context: ChannelHandlerContext) throws -> ClientResponse {
            let id = ObjectIdentifier(context.channel)
            let plain: ByteBuffer
            if let key = client.requestIoData.connectionKeys[id] { plain = try Crypto.Symm.decrypt(.init(buffer: response), key: key) }
            else { plain = try Crypto.Symm.decrypt(.init(buffer: response), key: client.requestIoData.rootKey) }
            return try .init(data: plain)
        }
    }
}
