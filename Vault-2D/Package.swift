// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Vault-2D",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Vault-2D",
            type: .dynamic,
            targets: ["Vault-2D"]
        ),
    ],
    dependencies: [
        // SwiftGodot - Swift bindings for Godot 4
        .package(url: "https://github.com/migueldeicaza/SwiftGodot.git", branch: "main"),
        // Local GameLogic package
        .package(path: "../GameLogic")
    ],
    targets: [
        .target(
            name: "Vault-2D",
            dependencies: [
                "SwiftGodot",
                "GameLogic"
            ],
            path: "Sources/Vault-2D",
            swiftSettings: [
                .unsafeFlags(["-suppress-warnings"])
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
