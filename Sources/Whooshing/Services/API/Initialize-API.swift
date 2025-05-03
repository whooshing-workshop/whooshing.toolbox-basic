import Vapor
import Cryptos
import ErrorHandle
import DataConvertable
import NIO
import Logging
import WhooshingClient

enum API {
    /// 配置 API 服务模块
    static func config(_ app: Application, inlineClient: InlineReqClient) async throws {
        // 从环境变量中取得该服务模块的参数
        let env = try ServicePara.parse(prefix: "WHOOSHING_API_SERVICE_PRIVATE")
        // 注册 HTTP IO 加密模块
        app.use(httpIOHandler: HttpIOCrypto(app: app, authenticationURL: env.authenticationURL))
        // 注册客户端身份验证中间件
        app.middleware.use(GuardMiddleware(authenticationURL: env.authenticationURL))
        // 初始化服务数据
        app.storage[ServiceData.self] = .init(inlineClient: inlineClient)
    }
}
