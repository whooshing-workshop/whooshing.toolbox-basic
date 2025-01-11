* # Whooshing 基本工具库

  提供最基本的 API，包括：

  - **基本的加密算法**
    - **对称加密(AES)**
    - **非对称加密(EdDSA)**
    - **HMAC 消息验证**
    - **Curve25529 电子签名**
  - **错误处理**
  - **数据转换**
  - **PostgreSQL 数据模型**

  ## **部署说明**

  在你的 Package.swift 加入：

  ``` swift
  .package(url: "https://github.com/SJJC-Team/whooshing.toolbox-basic.git", branch: "develop")
  ```

  #### 当前进度

  | **模块**                                                  | **进度** | **测试**                                                     | **进度** |
  | --------------------------------------------------------- | -------- | ------------------------------------------------------------ | -------- |
  | [**基本的加密算法**](Sources/ToolboxBsc/Crypto.swift)     | ✅        | [Crypto-Tests.swift](Tests/ToolboxBsc-Tests/Crypto-Tests.swift) | ✅        |
  | [**错误处理**](Sources/ToolboxBsc/Error.swift)            | ✅        | [Error-Tests.swift](Tests/ToolboxBsc-Tests/Error-Tests.swift) | ✅        |
  | [**数据转换**](Sources/ToolboxBsc/DataConvertable.swift)  | ✅        | [DataConvertable-Tests.swift](Tests/ToolboxBsc-Tests/DataConvertable-Tests.swift) | ✅        |
  | [**PostgreSQL 数据模型**](Sources/ToolboxBsc/PgSQL.swift) | ✅        | [PgSQL-Tests.swift](Tests/ToolboxBsc-Tests/PgSQL-Tests.swift) | ✅        |

  ## **代码提交约定**

  见 [代码提交约定](https://github.com/SJJC-Team/.github-private/blob/main/profile/README.md)

  ## **联系方式**

  * 开发者邮箱：contact@official.whooshings.space

  * 项目主页：https://whooshings.space
