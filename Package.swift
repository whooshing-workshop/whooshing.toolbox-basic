// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "whooshing.toolbox-basic",
    platforms: [
       .macOS(.v13)
    ],
    products: [
        .library( name: "Whooshing", targets: ["Whooshing"] ),
        .library( name: "ErrorHandle", targets: ["ErrorHandle"] ),
        .library( name: "DataConvertable", targets: ["DataConvertable"] ),
        .library( name: "Cryptos", targets: ["Cryptos"] ),
        .library( name: "PgSQL", targets: ["PgSQL"] ),
        .library( name: "WhooshingClient", targets: ["WhooshingClient"] ),
    ],
    dependencies: [
        .package(url: "https://github.com/SJJC-Team/whooshing-vapor.git", branch: "main"),
        .package(url: "https://github.com/SJJC-Team/whooshing-fluent.git", branch: "main"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.10.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "4.0.0"),
        .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.0.0"),
    ],
    targets: [
        .target( name: "ErrorHandle" ),
        .target(
            name:  "Cryptos",
            dependencies: [
                .target(name: "ErrorHandle"),
                .target(name: "DataConvertable"),
                .product(name: "Vapor", package: "whooshing-vapor"),
                .product(name: "Crypto", package: "swift-crypto")
            ]
        ),
        .target(
            name: "DataConvertable",
            dependencies: [
                .target(name: "ErrorHandle")
            ]
        ),
        .target(
            name:  "PgSQL",
            dependencies: [
                .target(name: "ErrorHandle"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
            ]
        ),
        .target(
            name: "WhooshingClient",
            dependencies: [
                .target(name: "ErrorHandle"),
                .target(name: "DataConvertable"),
                .target(name: "Cryptos"),
                .product(name: "NIOExtras", package: "swift-nio-extras"),
                .product(name: "Vapor", package: "whooshing-vapor")
            ]
        ),
        .target(
            name: "Whooshing",
            dependencies: [
                .target(name: "ErrorHandle"),
                .target(name: "DataConvertable"),
                .target(name: "Cryptos"),
                .target(name: "PgSQL"),
                .target(name: "WhooshingClient"),
                .product(name: "Vapor", package: "whooshing-vapor"),
                .product(name: "Fluent", package: "whooshing-fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
            ],
            resources: [
                .process("Services/API/3.API请求流程.png")
            ]
        ),
        .testTarget(
            name: "ToolboxBsc-Tests",
            dependencies: [
                .target(name: "ErrorHandle"),
                .target(name: "DataConvertable"),
                .target(name: "PgSQL"),
                .target(name: "Cryptos"),
                .target(name: "Whooshing"),
                .product(name: "Fluent", package: "whooshing-fluent")
            ]
        ),
    ]
)
