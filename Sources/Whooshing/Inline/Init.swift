import Vapor
import Cryptos
import ErrorHandle
import DataConvertable
import NIO
import Logging

/// 实现该协议以进行服务间模块的通讯
public protocol InlineHandler: Sendable {
    /// 当收到合法的服务模块的连线时，调用此方法
    ///
    /// - 参数
    ///     - ws: WebSocket 实例，可以进行发送，关闭等等操作
    ///     - data: 对方的请求数据
    func onData(ws: WebSocket, data: Data) throws
}

public extension Application {
    /// 注册一个 `InlineHandler`，用于处理模块间连线
    func use(inlineHandler: InlineHandler) { self.storage[Inline.Init.HandlerStorageKey.self] = inlineHandler }
}

// MARK: - 以下为私有实现

fileprivate extension Application {
    var serviceData: Inline.Init.ServiceData! { self.storage[Inline.Init.ServiceData.self] }
}

enum Inline {
    enum Init {
        fileprivate enum Err: String, ErrList {
            var domain: String { "woo.api.sys.init.err" }
            case initializeFailed = "服务初始化失败"
            case serviceIdNotValid = "服务模块不可信，ID 验证失败"
            case keyExchangeFailed = "与服务模块通讯时密钥交换失败"
            case serviceValidateFailed = "与服务模块通讯时验证失败"
        }
        
        static func config(_ app: Application) async throws {
            // 创建非对称公私钥
            let keyPair = Crypto.Asym.makeCryptoKeyPair()
            // 向模块管理器请求取得服务模块信息，首先将自己的公钥发出
            let res = try await app.client.post(app.project.managerUrl.toUri(with: "/params/init")) { postRequest in
                try postRequest.content.encode(["pub": keyPair.private], as: .json)
            }
            guard res.status == .ok else { throw Err.initializeFailed.d("请求模块管理器的结果为: \(res.status)", 10010, (#file, #line)) }
            // 解包服务器回复
            let paras = try res.content.decode(InitParaRes.self)
            // 生成共享密钥
            let sharedKey = try Crypto.Asym.keyEncapsulate(key: keyPair.private, partyPublic: paras.pub, salt: Crypto.hash("manager.shared.key"), info: "")
            // 保存到上下文
            app.storage[ServiceData.self] = try ServiceData(
                rootKey: Crypto.Symm.decrypt(paras.root, key: sharedKey),
                moduleDatas: paras.modules.map { try Crypto.Symm.decrypt($0, key: sharedKey) }
            )
            // 注册 HTTP IO 加密模块
            app.use(httpIOHandler: HttpIOCrypto(app: app))
            // 运行 websocket
            try websocket(app)
            
            struct InitParaRes: Content {
                let pub: Crypto.Asym.CPublicKey
                let root: Data
                let modules: [Data]
            }
        }
        
        static fileprivate func websocket(_ app: Application) throws {
            app.webSocket("inline") { req, ws in
                app.logger.info("接受到连线, id: \(req.id)")
                // 从对方收到消息
                ws.onBinary { ws, buffer in
                    do {
                        if let _ = app.serviceData.connectionValidate[req.id] {
                            // 服务模块已成功经过验证，开始处理请求
                            app.logger.info("连线验证通过, id: \(req.id)")
                            try app.storage[HandlerStorageKey.self]?.onData(ws: ws, data: .init(buffer: buffer))
                        } else {
                            if let _ = app.serviceData.connectionKeys[req.id] {
                                // 密钥交换已经完成，验证服务
                                try validateService(ws: ws, buffer: buffer)
                            } else {
                                // 首次连接，需要交换密钥
                                try keyExchange(ws: ws, buffer: buffer)
                            }
                        }
                    } catch let err {
                        app.logger.error(.init(stringLiteral: String(reflecting: err)))
                        _ = ws.close(code: .protocolError)
                    }
                }
                
                // 进行密钥交换
                @Sendable func keyExchange(ws: WebSocket, buffer: ByteBuffer) throws {
                    do {
                        // 收到对方的公钥
                        let pubKey = try Crypto.Asym.CPublicKey(data: Data(buffer: buffer))
                        let keyPair = Crypto.Asym.makeCryptoKeyPair()
                        // 发送自己的公钥
                        ws.send(keyPair.public.data())
                        // 计算共享密钥
                        let sharedKey = try Crypto.Asym.keyEncapsulate(key: keyPair.private, partyPublic: pubKey, salt: Crypto.hash("inline.shared.key"), info: "")
                        app.serviceData.connectionKeys[req.id] = sharedKey
                    } catch let err {
                        throw Err.keyExchangeFailed.d(10012, #file, #line).subErr(err)
                    }
                }
                
                // 进行服务验证，确认对方的服务 ID 是可信的
                @Sendable func validateService(ws: WebSocket, buffer: ByteBuffer) throws {
                    do {
                        let serviceId = try UUID(data: .init(buffer: buffer))
                        let res = app.serviceData.moduleDatas.contains { $0.serviceId == serviceId }
                        guard res == true else { throw Err.serviceIdNotValid.d(10011, #file, #line) }
                        app.serviceData.connectionValidate[req.id] = true
                    } catch let err {
                        throw Err.serviceValidateFailed.d(10013, #file, #line).subErr(err)
                    }
                }
            }
        }
        
        fileprivate final class ServiceData: StorageKey, Sendable {
            typealias Value = ServiceData
            let rootKey: Crypto.Symm.Key
            let moduleDatas: [ModuleData]
            let connectionValidate: SendableDictionary<String, Bool> = .init()
            let connectionKeys: SendableDictionary<String, Crypto.Symm.Key> = .init()
            
            init(rootKey: Crypto.Symm.Key, moduleDatas: [ModuleData]) {
                self.rootKey = rootKey
                self.moduleDatas = moduleDatas
            }
        }
        
        fileprivate struct ModuleData: Content, Sendable, ThrowableDataConvertable {
            let name: String
            let serviceId: UUID
            let connection: String?
            init(data: Data) throws {
                let paras = try [String: AnyThrowableDataConvertable](data: data)
                self.name = try paras["name"]!.cast(to: String.self)
                self.serviceId = try paras["serviceId"]!.cast(to: UUID.self)
                self.connection = try? paras["connection"]?.cast(to: String.self)
            }

            func data() throws -> Data {
                let d: [String: (any ThrowableDataConvertable)?] = [
                    "name": name,
                    "serviceId": serviceId,
                    "connection": connection
                ]
                return try d.filtered.anyValue.data()
            }
        }
        
        fileprivate struct HttpIOCrypto: HTTPIOHandler, Sendable {
            let app: Application
            func input(request: Data, context: ChannelHandlerContext, info: ChannelInfo) throws -> Data {
                let id = info.currentRequestID!
                let req: Data
                if let key = app.serviceData.connectionKeys[id] { req = try Crypto.Symm.decrypt(request, key: key) }
                else { req = try Crypto.Symm.decrypt(request, key: app.serviceData.rootKey) }
                return req
            }
            
            func output(response: Data, context: ChannelHandlerContext, info: ChannelInfo) throws -> Data {
                let id = info.currentRequestID!
                let res: Data
                if let key = app.serviceData.connectionKeys[id] { res = try Crypto.Symm.encrypt(response, key: key) }
                else { res = try Crypto.Symm.encrypt(response, key: app.serviceData.rootKey) }
                return res
            }
            
            func connectionEnd(context: ChannelHandlerContext, info: ChannelInfo) throws {
                app.serviceData.connectionKeys[info.currentRequestID] = nil
            }
        }
        
        struct HandlerStorageKey: StorageKey, Sendable {
            typealias Value = InlineHandler
        }
    }
}

extension URL {
    func toUri(with path: String) -> URI { .init(string: self.absoluteString + path) }
}
