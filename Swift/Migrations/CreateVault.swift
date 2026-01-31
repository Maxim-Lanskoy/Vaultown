//
//  CreateVault.swift
//  Vaultown
//
//  Migration to create vaults table
//

import Fluent

struct CreateVault: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("vaults")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("name", .string, .required)
            .field("power", .double, .required, .sql(.default(50)))
            .field("max_power", .double, .required, .sql(.default(100)))
            .field("food", .double, .required, .sql(.default(50)))
            .field("max_food", .double, .required, .sql(.default(100)))
            .field("water", .double, .required, .sql(.default(50)))
            .field("max_water", .double, .required, .sql(.default(100)))
            .field("caps", .int, .required, .sql(.default(500)))
            .field("stimpaks", .int, .required, .sql(.default(2)))
            .field("radaway", .int, .required, .sql(.default(2)))
            .field("population_cap", .int, .required, .sql(.default(8)))
            .field("last_update", .datetime, .required)
            .field("created_at", .datetime)
            .unique(on: "user_id")  // One vault per user
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("vaults").delete()
    }
}
