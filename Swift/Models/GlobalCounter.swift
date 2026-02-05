//
//  GlobalCounter.swift
//  Vaultown
//
//  Global counters for unique sequences (vault numbers, etc.)
//
//  Created by Maxim Lanskoy on 31.01.2026.
//

import Fluent
import Foundation

/// Database model for global counters (vault numbers, etc.)
final public class GlobalCounter: Model, @unchecked Sendable {
    public static let schema = "global_counters"

    @ID(key: .id)
    public var id: UUID?

    /// Counter name (e.g., "vault_number")
    @Field(key: "name")
    var name: String

    /// Current counter value (next available number)
    @Field(key: "value")
    var value: Int64

    public init() {}

    init(name: String, value: Int64 = 1) {
        self.name = name
        self.value = value
    }
}

// MARK: - Counter Operations

extension GlobalCounter {
    /// Counter names
    static let vaultNumberCounter = "vault_number"

    /// Get next vault number (atomic increment)
    static func nextVaultNumber(on db: any Database) async throws -> Int64 {
        // Try to find existing counter
        if let counter = try await GlobalCounter.query(on: db)
            .filter(\.$name == vaultNumberCounter)
            .first() {
            let nextValue = counter.value
            counter.value += 1
            try await counter.save(on: db)
            return nextValue
        }

        // Create new counter starting at 1
        let counter = GlobalCounter(name: vaultNumberCounter, value: 2)
        try await counter.save(on: db)
        return 1
    }
}
