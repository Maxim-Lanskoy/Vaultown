//
//  CreateGlobalCounter.swift
//  Vaultown
//
//  Migration for global counters table
//

import Fluent

struct CreateGlobalCounter: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("global_counters")
            .id()
            .field("name", .string, .required)
            .field("value", .int64, .required)
            .unique(on: "name")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("global_counters").delete()
    }
}
