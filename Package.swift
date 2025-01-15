// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "whooshing.toolbox-basic",
    platforms: [
       .macOS(.v11)
    ],
    products: [
        .library( name: "Whooshing", targets: ["Whooshing"] ),
        .library( name: "ErrorHandle", targets: ["ErrorHandle"] ),
        .library( name: "DataConvertable", targets: ["DataConvertable"] ),
        .library( name: "Cryptos", targets: ["Cryptos"] ),
        .library( name: "PgSQL", targets: ["PgSQL"] ),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.111.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.10.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.12.0"),
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
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .target(
            name: "Whooshing",
            dependencies: [
                .target(name: "ErrorHandle"),
                .target(name: "DataConvertable"),
                .target(name: "Cryptos"),
                .target(name: "PgSQL"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
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
                .product(name: "Fluent", package: "fluent")
            ]
        ),
    ]
)
