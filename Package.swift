// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "whooshing.toolbox-basic",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v14),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library( name: "ErrorHandle", targets: ["ErrorHandle"] ),
        .library( name: "DataConvertable", targets: ["DataConvertable"] ),
        .library( name: "Cryptos", targets: ["Cryptos"] ),
        .library( name: "NIOAdvanced", targets: ["NIOAdvanced"] )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "4.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
    ],
    targets: [
        .target( 
            name: "ErrorHandle"
        ),
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
        .target(
            name: "NIOAdvanced",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio")
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
