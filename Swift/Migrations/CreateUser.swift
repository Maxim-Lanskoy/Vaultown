//
//  CreateUser.swift
//  Vaultown
//
//  Created by Maxim Lanskoy on 13.06.2025.
//

import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("users")
            .id()
            .field("telegram_id", .int64, .required)
            .field("created_at", .datetime)
            .field("first_name", .string)
            .field("last_name", .string)
            .field("user_name", .string)
            .field("router_name", .string, .required, .sql(.default("main")))
            .field("locale", .string)
            .unique(on: "telegram_id")
            .ignoreExisting()
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("users").delete()
    }
} 
