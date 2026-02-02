# Whooshing 基本工具库

为 Whooshing 系统提供最底层加解密，错误处理以及数据转换的基本能功能：

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
.package(url: "https://github.com/SJJC-Team/whooshing.toolbox-basic.git", .upToNextMajor(from: "1.4.7"))
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
    // NIO 扩展
    .product(name: "NIOAdvanced", package: "whooshing.toolbox-basic")
]
```

-----------

### 运行环境

* **macOS** (> 10.15)
* **iOS** (> 14.0)
* **Linux** (> 20)
* **Swift** (> 6.0)
* **watchOS** (> 6.0) **[未测试]**
* **tvOS**(> 13) **[未测试]**

----------

### 联系与反馈

如有使用问题或建议，请通过 [GitHub Issues](https://github.com/SJJC-Team/whooshing.toolbox-basic/issues) 提交反馈。

或发至邮箱 [contact@official.whooshings.space](mailto:contact@official.whooshings.space)
