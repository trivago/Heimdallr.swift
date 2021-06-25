// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Heimdallr",
    platforms: [.iOS(.v11), .macOS(.v10_10)],
    products: [
        .library(
            name: "Heimdallr",
            targets: ["Heimdallr"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", .exact("9.1.0"))
    ],
    targets: [
        .target(
            name: "Heimdallr",
            dependencies: []),
        .testTarget(
            name: "HeimdallrTests",
            dependencies: [
                "Heimdallr",
                "OHHTTPStubs",
            ],
            resources: [
                .process("./Resources/"),
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
