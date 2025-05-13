# Whooshing 基本工具库

提供最基本的 API，包括：

- **基本的加密算法**：由 [swift-crypto](https://github.com/apple/swift-crypto) 提供加密功能
  - **对称加密(AES)**
  - **非对称加密(EdDSA)**
  - **HMAC 消息验证**
  - **Curve25529 电子签名**
- **错误处理**
- **数据转换**

## **部署说明**

在你的 Package.swift 加入：

``` swift
.package(url: "https://github.com/SJJC-Team/whooshing.toolbox-basic.git", .upToNextMajor(from: "1.2.3"))
```

或导入不同的 Target：

``` swift
dependencies:[
    // 提供 Whooshing 基本的哈希，对称，非对称加密算法
    .product(name: "Crypto", package: "whooshing.toolbox-basic"),
    // 提供各种数据转换
    .product(name: "DataConvertable", package: "whooshing.toolbox-basic"),
    // 错误处理
    .product(name: "ErrorHandle", package: "whooshing.toolbox-basic"),
]
```



#### 当前进度

| **模块**                                                     | **进度** | **测试**                                                     | **进度** |
| ------------------------------------------------------------ | -------- | ------------------------------------------------------------ | -------- |
| [**基本的加密算法**](Sources/Cryptos/Crypto.swift)           | ✅        | [Crypto-Tests.swift](Tests/ToolboxBsc-Tests/Crypto-Tests.swift) | ✅        |
| [**错误处理**](Sources/ErrorHandle/Error.swift)              | ✅        | [Error-Tests.swift](Tests/ToolboxBsc-Tests/Error-Tests.swift) | ✅        |
| [**数据转换**](Sources/DataConvertable/DataConvertable.swift) | ✅        | [DataConvertable-Tests.swift](Tests/ToolboxBsc-Tests/DataConvertable-Tests.swift) | ✅        |

## **代码提交约定**

见 [代码提交约定](https://github.com/SJJC-Team/.github-private/blob/main/profile/README.md)

## **联系方式**

* 开发者邮箱：contact@official.whooshings.space

* 项目主页：https://whooshings.space
