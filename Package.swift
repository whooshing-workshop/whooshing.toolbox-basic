// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "whooshing.toolbox-basic",
    platforms: [
       .macOS(.v11)
    ],
    products: [
        .library( name: "WhooshingInline", targets: ["WhooshingInline"] ),
        .library( name: "ErrorHandle", targets: ["ErrorHandle"] ),
        .library( name: "DataConvertable", targets: ["DataConvertable"] ),
        .library( name: "Cryptos", targets: ["Cryptos"] ),
        .library( name: "PgSQL", targets: ["PgSQL"] ),
    ],
    dependencies: [
        .package(url: "https://github.com/SJJC-Team/whooshing-vapor.git", branch: "main"),
        .package(url: "https://github.com/SJJC-Team/whooshing-fluent.git", branch: "main"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.10.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "4.0.0"),
    ],
    targets: [
        .target( name: "ErrorHandle" ),
        .target(
            name:  "Cryptos",
            dependencies: [
                .target(name: "ErrorHandle"),
                .target(name: "DataConvertable"),
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
            name: "WhooshingHttps",
            dependencies: [ .target(name: "WhooshingCore") ],
            swiftSettings: [ .define("HTTPS") ]
        ),
        .target(
            name: "WhooshingInline",
            dependencies: [ .target(name: "WhooshingCore") ],
            swiftSettings: [ .define("INLINE") ]
        ),
        .target(
            name: "WhooshingAPI",
            dependencies: [ .target(name: "WhooshingCore") ],
            swiftSettings: [ .define("API") ]
        ),
        .target(
            name: "WhooshingCore",
            dependencies: [
                .target(name: "ErrorHandle"),
                .target(name: "DataConvertable"),
                .target(name: "Cryptos"),
                .target(name: "PgSQL"),
                .product(name: "Vapor", package: "whooshing-vapor"),
                .product(name: "Fluent", package: "whooshing-fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
            ],
            swiftSettings: [ .define("INLINE") ]
        ),
        .testTarget(
            name: "ToolboxBsc-Tests",
            dependencies: [
                .target(name: "ErrorHandle"),
                .target(name: "DataConvertable"),
                .target(name: "PgSQL"),
                .target(name: "Cryptos"),
                .target(name: "WhooshingCore"),
                .product(name: "Fluent", package: "whooshing-fluent")
            ]
        ),
    ]
)
