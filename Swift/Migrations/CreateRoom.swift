//
//  CreateRoom.swift
//  Vaultown
//
//  Migration to create rooms table
//
//  Created by Maxim Lanskoy on 31.01.2026.
//

import Fluent

struct CreateRoom: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("rooms")
            .id()
            .field("vault_id", .uuid, .required, .references("vaults", "id", onDelete: .cascade))
            .field("type", .string, .required)
            .field("level", .int, .required, .sql(.default(1)))
            .field("x", .int, .required)
            .field("y", .int, .required)
            .field("width", .int, .required, .sql(.default(1)))
            .field("production_state", .string, .required, .sql(.default("idle")))
            .field("production_progress", .double, .required, .sql(.default(0)))
            .field("last_production_update", .datetime, .required)
            .field("has_power", .bool, .required, .sql(.default(true)))
            .field("created_at", .datetime)
            // Unique constraint: no two rooms can occupy the same position in a vault
            .unique(on: "vault_id", "x", "y")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("rooms").delete()
    }
}
