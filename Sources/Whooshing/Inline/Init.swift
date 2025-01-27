import Vapor
import Cryptos
import ErrorHandle
import DataConvertable
import NIO
import Logging

extension Application {
    var serviceData: Inline.Init.ServiceData! { self.storage[Inline.Init.ServiceData.self] }
}

enum Inline {
    enum Init {
        fileprivate enum Err: String, ErrList {
            var domain: String { "woo.inline.sys.init.err" }
            case initializeFailed = "服务初始化失败"
            case relayParseFailed = "中继转送解析失败"
            case relaySendFailed = "中继转送失败"
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
            // 注册服务来源验证中间件
            app.middleware.use(GuardMiddleware())
            
            struct InitParaRes: Content {
                let pub: Crypto.Asym.CPublicKey
                let root: Data
                let modules: [Data]
            }
        }
        
        final class ServiceData: StorageKey, Sendable {
            typealias Value = ServiceData
            let rootKey: Crypto.Symm.Key
            let moduleDatas: [ModuleData]
            let connectionValidate: SendableDictionary<ObjectIdentifier, Bool> = .init()
            let connectionKeys: SendableDictionary<ObjectIdentifier, Crypto.Symm.Key> = .init()
            
            init(rootKey: Crypto.Symm.Key, moduleDatas: [ModuleData]) {
                self.rootKey = rootKey
                self.moduleDatas = moduleDatas
            }
        }
        
        struct ModuleData: Content, Sendable, ThrowableDataConvertable {
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
        
        /// 实现 HTTP IO 加解密处理
        fileprivate struct HttpIOCrypto: HTTPIOHandler, Sendable {
            let app: Application
            /// 有客户端请求进入
            func input(request: Data, context: ChannelHandlerContext, info: ChannelInfo) throws -> Data? {
                if let relayData = try relayDataHandle(request) {
                    // 中继请求
                    do { try context.writeAndFlush(.init(dataToByteBuffer(data: relayData))).wait() } catch let err { throw Err.relaySendFailed.d(10064, (#file, #line)) }
                    return nil
                } else {
                    // 一般请求(加密)
                    let id = ObjectIdentifier(context.channel)
                    let req: Data
                    if let key = app.serviceData.connectionKeys[id] { req = try Crypto.Symm.decrypt(request, key: key) }
                    else { req = try Crypto.Symm.decrypt(request, key: app.serviceData.rootKey) }
                    return req
                }
            }
            
            /// 将有服务器响应请求发出
            func output(response: Data, context: ChannelHandlerContext, info: ChannelInfo) throws -> Data? {
                let id = ObjectIdentifier(context.channel)
                let res: Data
                // 若 key 存在，但 validate 不存在，则仍然使用 rootKey 加密
                if let key = app.serviceData.connectionKeys[id], let _ = app.serviceData.connectionValidate[id] {
                    res = try Crypto.Symm.encrypt(response, key: key) }
                else { res = try Crypto.Symm.encrypt(response, key: app.serviceData.rootKey) }
                return res
            }
            
            private func relayDataHandle(_ request: Data) throws -> Data? {
                guard let req = String(data: request, encoding: .utf8) else { return nil }
                let relayReq = try relayRequestModify(data: req)
                return relayReq.data(using: .utf8)
            }
            
            private func relayRequestModify(data: String) throws -> String {
                // 分割请求头和主体
                let components = data.components(separatedBy: "\r\n\r\n")
                guard components.count >= 2 else { throw Err.relayParseFailed.d("非完整的中继 HTTP 请求", 10066, (#file, #line)) }
                var headers = components[0].components(separatedBy: "\r\n")
                let body = components.dropFirst().joined(separator: "\r\n\r\n")
                guard headers.count >= 1 else { throw Err.relayParseFailed.d("中继 HTTP 请求的格式不正确", 10067, (#file, #line)) }
                let separator = "/whooshing-relay"
                let requestLine = headers[0].components(separatedBy: " ")
                guard requestLine.count == 3 else { throw Err.relayParseFailed.d("中继 HTTP 请求的第一行 Header 格式不正确", 10067, (#file, #line)) }
                
                // 修改请求 URI
                let method = requestLine[0]
                let relayUri = requestLine[1].components(separatedBy: separator)
                guard relayUri.count == 2 else { throw Err.relayParseFailed.d("中继 HTTP 请求的 URI 格式不正确", 10068, (#file, #line)) }
                guard relayUri[0].count > 1 else { throw Err.relayParseFailed.d("中继 HTTP 请求的 URI 格式不正确", 10069, (#file, #line)) }
                let newHost = relayUri[0].dropFirst()
                let newURI = relayUri[1]
                let httpVersion = requestLine[2]
                headers[0] = "\(method) \(newURI) \(httpVersion)"
                
                // 修改 Header
                for (index, header) in headers.enumerated() {
                    if header.lowercased().hasPrefix("host:") {
                        headers[index] = "Host: \(newHost)"
                        break
                    }
                }
                
                // 重组请求头和主体
                let newRequest = headers.joined(separator: "\r\n") + "\r\n\r\n" + body
                return newRequest
            }
            
            private func dataToByteBuffer(data: Data) -> ByteBuffer {
                var buffer = ByteBufferAllocator().buffer(capacity: data.count)
                buffer.writeBytes(data)
                return buffer
            }
            
            /// 连线结束
            func connectionEnd(context: ChannelHandlerContext, info: ChannelInfo) throws {
                app.serviceData.connectionKeys[ObjectIdentifier(context.channel)] = nil
            }
        }
    }
}
