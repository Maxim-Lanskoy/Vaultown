//
//  CreateDweller.swift
//  Vaultown
//
//  Migration to create dwellers table
//
//  Created by Maxim Lanskoy on 31.01.2026.
//

import Fluent

struct CreateDweller: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("dwellers")
            .id()
            .field("vault_id", .uuid, .required, .references("vaults", "id", onDelete: .cascade))
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .field("gender", .string, .required)
            .field("rarity", .string, .required)
            .field("level", .int, .required, .sql(.default(1)))
            .field("experience", .int, .required, .sql(.default(0)))
            .field("current_hp", .double, .required, .sql(.default(105)))
            .field("max_hp", .double, .required, .sql(.default(105)))
            .field("radiation", .double, .required, .sql(.default(0)))
            .field("happiness", .double, .required, .sql(.default(50)))
            // SPECIAL stats
            .field("strength", .int, .required, .sql(.default(1)))
            .field("perception", .int, .required, .sql(.default(1)))
            .field("endurance", .int, .required, .sql(.default(1)))
            .field("charisma", .int, .required, .sql(.default(1)))
            .field("intelligence", .int, .required, .sql(.default(1)))
            .field("agility", .int, .required, .sql(.default(1)))
            .field("luck", .int, .required, .sql(.default(1)))
            // Room assignment (optional foreign key to rooms)
            .field("assigned_room_id", .uuid, .references("rooms", "id", onDelete: .setNull))
            // Equipment (stored as UUIDs, will be separate tables later)
            .field("weapon_id", .uuid)
            .field("outfit_id", .uuid)
            .field("pet_id", .uuid)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("dwellers").delete()
    }
}
