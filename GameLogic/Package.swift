// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GameLogic",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "GameLogic",
            targets: ["GameLogic"]
        ),
    ],
    targets: [
        .target(
            name: "GameLogic",
            path: "Sources/GameLogic"
        ),
        .testTarget(
            name: "GameLogicTests",
            dependencies: ["GameLogic"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
