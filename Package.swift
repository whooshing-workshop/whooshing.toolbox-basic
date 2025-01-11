// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "whooshing.toolbox-basic",
    platforms: [
       .macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ToolboxBsc",
            targets: ["ToolboxBsc"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.111.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.10.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.12.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ToolboxBsc",
            dependencies: [
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Crypto", package: "swift-crypto")
            ]
        ),
        .testTarget(
            name: "ToolboxBsc-Tests",
            dependencies: [
                .target(name: "ToolboxBsc"),
                .product(name: "Fluent", package: "fluent")
            ]
        ),
    ]
)
