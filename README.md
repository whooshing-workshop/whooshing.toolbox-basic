# Whooshing 基本工具库

提供最基本的 API，包括：

- **基本的加密算法**：由 [swift-crypto](https://github.com/apple/swift-crypto) 提供加密功能
  - **对称加密(AES)**
  - **非对称加密(EdDSA)**
  - **HMAC 消息验证**
  - **Curve25529 电子签名**
- **PostgreSQL 数据模型**：由 [vapor/fluent-postgres-driver](https://github.com/vapor/fluent-postgres-driver) 提供实现
- **错误处理**
- **数据转换**
- **文件流式传送**

## **部署说明**

在你的 Package.swift 加入：

``` swift
.package(url: "https://github.com/SJJC-Team/whooshing.toolbox-basic.git", from: "1.2.0")
```

导入整个工具库：

``` swift
dependencies:[
  .product(name: "Whooshing", package: "whooshing.toolbox-basic"),
]
```

或导入不同的 Target：

``` swift
dependencies:[
  .product(name: "Crypto", package: "whooshing.toolbox-basic"),
  .product(name: "PgSQL", package: "whooshing.toolbox-basic"),
  .product(name: "DataConvertable", package: "whooshing.toolbox-basic"),
  .product(name: "ErrorHandle", package: "whooshing.toolbox-basic"),
  .product(name: "WhooshingClient", package: "whooshing.toolbox-basic")
]
```



#### 当前进度

| **模块**                                                     | **进度** | **测试**                                                     | **进度** |
| ------------------------------------------------------------ | -------- | ------------------------------------------------------------ | -------- |
| [**Whooshing 系统初始化工具链**](Sources/Whooshing/Whooshing.swift) | ✅        | [Whooshing-Tests.swift](Tests/ToolboxBsc-Tests/Whooshing-Tests.swift) | ✅        |
| [**基本的加密算法**](Sources/Cryptos/Crypto.swift)           | ✅        | [Crypto-Tests.swift](Tests/ToolboxBsc-Tests/Crypto-Tests.swift) | ✅        |
| [**错误处理**](Sources/ErrorHandle/Error.swift)              | ✅        | [Error-Tests.swift](Tests/ToolboxBsc-Tests/Error-Tests.swift) | ✅        |
| [**数据转换**](Sources/DataConvertable/DataConvertable.swift) | ✅        | [DataConvertable-Tests.swift](Tests/ToolboxBsc-Tests/DataConvertable-Tests.swift) | ✅        |
| [**PostgreSQL 数据模型**](Sources/PgSQL/PgSQL.swift)         | ✅        | [PgSQL-Tests.swift](Tests/ToolboxBsc-Tests/PgSQL-Tests.swift) | ✅        |
| [**请求访问 API**](Sources/WhooshingClient/WhooshingClient.swift) | ✅        | 无                                                           | ✅        |

## **代码提交约定**

见 [代码提交约定](https://github.com/SJJC-Team/.github-private/blob/main/profile/README.md)

## **联系方式**

* 开发者邮箱：contact@official.whooshings.space

* 项目主页：https://whooshings.space
