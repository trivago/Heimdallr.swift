// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Heimdallr",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v9)
    ],
    products: [
        .library(
            name: "Heimdallr",
            targets: ["Heimdallr"]),
    ],
    dependencies: [
        .package(url: "https://github.com/antitypical/Result", from: "4.1.0"),
//        .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.0.0"),
//        .package(url: "https://github.com/Quick/Nimble", from: "8.0.0"),
//        .package(url: "https://github.com/Quick/Quick", from: "2.1.0")
    ],
    targets: [
        .target(
            name: "Heimdallr",
            dependencies: ["Result"],
            path: "Heimdallr",
            exclude: ["Supporting Files/Info.plist"]
        ),
//        .testTarget(
//            name: "HeimdallrTests",
//            dependencies: ["Heimdallr", "Nimble", "Quick", "OHHTTPStubs"],
//            path: "HeimdallrTests",
//            exclude: ["Info.plist"],
//            resources: [
//                .copy("JSON Responses")
//            ]
//        ),
    ]
)
