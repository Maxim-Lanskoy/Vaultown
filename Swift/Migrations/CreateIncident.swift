//
//  CreateIncident.swift
//  Vaultown
//
//  Migration to create the incidents table
//
//  Created by Maxim Lanskoy on 02.02.2026.
//

import Fluent

struct CreateIncident: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("incidents")
            .id()
            .field("vault_id", .uuid, .required, .references("vaults", "id", onDelete: .cascade))
            .field("room_id", .uuid, .required)
            .field("type", .string, .required)
            .field("is_active", .bool, .required)
            .field("current_hp", .int, .required)
            .field("max_hp", .int, .required)
            .field("caps_stolen", .int, .required)
            .field("spread_room_ids", .string, .required)
            .field("combat_log", .string, .required)
            .field("started_at", .datetime)
            .field("resolved_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("incidents").delete()
    }
}
