// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "whooshing.toolbox-basic",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library( name: "ErrorHandle", targets: ["ErrorHandle"] ),
        .library( name: "DataConvertable", targets: ["DataConvertable"] ),
        .library( name: "Cryptos", targets: ["Cryptos"] ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "4.0.0"),
    ],
    targets: [
        .target( name: "ErrorHandle" ),
        .target(
            name: "Cryptos",
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
        .testTarget(
            name: "toolbox-basic-Tests",
            dependencies: [
                .target(name: "ErrorHandle"),
                .target(name: "DataConvertable"),
                .target(name: "Cryptos"),
            ]
        ),
    ]
)
