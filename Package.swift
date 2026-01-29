//  swift-tools-version: 6.2
//
//  Package.swift
//  Vaultown
//
//  Created by Maxim Lanskoy on 13.06.2025.
//

import PackageDescription

let package = Package(
    name: "Vaultown",
    platforms: [
       .macOS(.v14)
    ],
    dependencies: [
        // 🪽 Lightweight, flexible HTTP server framework written in Swift.
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.10.0"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.13.0"),
        // 🐘 Fluent driver for PostgreSQL.
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.10.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.92.0"),
        // 🌐 Async HTTP client for Swift.
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.25.0"),
        // ✈ A Swift wrapper for the Telegram API.
        .package(url: "https://github.com/nerzh/swift-telegram-sdk", from: "4.2.2"),
        // 🔑 A dotenv library for Swift.
        .package(url: "https://github.com/thebarndog/swift-dotenv.git", from: "2.1.0"),
        // 🗺️ Lingo: A Swift package for localization.
        .package(url: "https://github.com/miroslavkovac/Lingo.git", from: "4.0.0"),
        // 🎮 Shared game logic for Vaultown (local package)
        .package(path: "GameLogic"),
    ],
    targets: [
        .executableTarget(
            name: "Vaultown",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "SwiftTelegramBot", package: "swift-telegram-sdk"),
                .product(name: "SwiftDotenv", package: "swift-dotenv"),
                .product(name: "Lingo", package: "Lingo"), "gd",
                .product(name: "GameLogic", package: "GameLogic"),
            ],
            path: "Swift", swiftSettings: swiftSettings
        ),
        .systemLibrary(
            name: "gd",
            pkgConfig: "gdlib",
            providers: [
                .apt(["libgd-dev"]),
                .brew(["gd"])
            ]
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
