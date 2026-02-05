//
//  AddNicknameAndVaultNumber.swift
//  Vaultown
//
//  Migration for adding nickname to users and vault_number to vaults
//
//  Created by Maxim Lanskoy on 31.01.2026.
//

import Fluent

struct AddNicknameAndVaultNumber: AsyncMigration {
    func prepare(on database: any Database) async throws {
        // Add nickname to users
        try await database.schema("users")
            .field("nickname", .string)
            .update()

        // Add vault_number to vaults
        try await database.schema("vaults")
            .field("vault_number", .int64)
            .unique(on: "vault_number")
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("users")
            .deleteField("nickname")
            .update()

        try await database.schema("vaults")
            .deleteField("vault_number")
            .update()
    }
}
