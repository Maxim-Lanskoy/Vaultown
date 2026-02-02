//
//  CreateExploration.swift
//  Vaultown
//
//  Migration to create explorations table
//

import Fluent

struct CreateExploration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("explorations")
            .id()
            .field("vault_id", .uuid, .required, .references("vaults", "id", onDelete: .cascade))
            .field("dweller_id", .uuid, .required, .references("dwellers", "id", onDelete: .cascade))
            .field("dweller_name", .string, .required)
            .field("status", .string, .required, .sql(.default("exploring")))
            .field("start_time", .datetime, .required)
            .field("return_start_time", .datetime)
            .field("current_hp", .double, .required)
            .field("max_hp", .double, .required)
            .field("radiation", .double, .required, .sql(.default(0)))
            .field("has_radiation_immunity", .bool, .required, .sql(.default(false)))
            .field("stimpaks", .int, .required, .sql(.default(0)))
            .field("rad_away", .int, .required, .sql(.default(0)))
            .field("caps_collected", .int, .required, .sql(.default(0)))
            .field("items_collected", .int, .required, .sql(.default(0)))
            .field("dweller_level", .int, .required, .sql(.default(1)))
            .field("dweller_xp", .int, .required, .sql(.default(0)))
            .field("luck", .int, .required, .sql(.default(1)))
            .field("perception", .int, .required, .sql(.default(1)))
            .field("charisma", .int, .required, .sql(.default(1)))
            .field("endurance", .int, .required, .sql(.default(1)))
            .field("return_speed_multiplier", .double, .required, .sql(.default(1.0)))
            .field("events_json", .string, .required, .sql(.default("[]")))
            .field("last_event_minute", .int, .required, .sql(.default(0)))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("explorations").delete()
    }
}
