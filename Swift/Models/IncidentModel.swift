//
//  IncidentModel.swift
//  Vaultown
//
//  Fluent model for active incidents in vaults
//

import Fluent
import Foundation
import GameLogic

/// Database model for an active incident
final public class IncidentModel: Model, @unchecked Sendable {
    public static let schema = "incidents"

    @ID(key: .id)
    public var id: UUID?

    /// Reference to the vault where incident is occurring
    @Parent(key: "vault_id")
    var vault: Vault

    /// Reference to the room where incident started
    @Field(key: "room_id")
    var roomID: UUID

    /// Incident type (fire, radroach, raider, etc.)
    @Field(key: "type")
    var type: String

    /// Whether incident is still active
    @Field(key: "is_active")
    var isActive: Bool

    /// Current HP remaining
    @Field(key: "current_hp")
    var currentHP: Int

    /// Maximum HP the incident started with
    @Field(key: "max_hp")
    var maxHP: Int

    /// Caps stolen (for raiders)
    @Field(key: "caps_stolen")
    var capsStolen: Int

    /// Room IDs the incident has spread to (JSON array)
    @Field(key: "spread_room_ids")
    var spreadRoomIDsJSON: String

    /// Combat log (JSON array)
    @Field(key: "combat_log")
    var combatLogJSON: String

    /// When the incident started
    @Timestamp(key: "started_at", on: .create)
    var startedAt: Date?

    /// When the incident was resolved (defeated or evacuated)
    @Field(key: "resolved_at")
    var resolvedAt: Date?

    public init() {}

    /// Initialize from GameLogic Incident
    init(
        id: UUID? = nil,
        vaultID: Vault.IDValue,
        incident: Incident
    ) {
        self.id = id ?? incident.id
        self.$vault.id = vaultID
        self.roomID = incident.roomID
        self.type = incident.type.rawValue
        self.isActive = incident.isActive
        self.currentHP = incident.currentHP
        self.maxHP = incident.maxHP
        self.capsStolen = incident.capsStolen
        if let data = try? JSONEncoder().encode(incident.spreadRoomIDs) {
            self.spreadRoomIDsJSON = String(data: data, encoding: .utf8) ?? "[]"
        } else {
            self.spreadRoomIDsJSON = "[]"
        }
        if let data = try? JSONEncoder().encode(incident.combatLog) {
            self.combatLogJSON = String(data: data, encoding: .utf8) ?? "[]"
        } else {
            self.combatLogJSON = "[]"
        }
        self.resolvedAt = nil
    }
}

// MARK: - GameLogic Integration

public extension IncidentModel {
    /// Get the IncidentType enum value
    var incidentType: IncidentType? {
        IncidentType(rawValue: type)
    }

    /// Get spread room IDs
    var spreadRoomIDs: [UUID] {
        guard let data = spreadRoomIDsJSON.data(using: .utf8),
              let ids = try? JSONDecoder().decode([UUID].self, from: data) else {
            return []
        }
        return ids
    }

    /// Get combat log entries
    var combatLog: [IncidentCombatEntry] {
        guard let data = combatLogJSON.data(using: .utf8),
              let entries = try? JSONDecoder().decode([IncidentCombatEntry].self, from: data) else {
            return []
        }
        return entries
    }

    /// Convert to GameLogic Incident struct
    func toIncident() -> Incident? {
        guard let incidentType = incidentType else { return nil }

        var incident = Incident(
            id: id ?? UUID(),
            type: incidentType,
            roomID: roomID
        )
        incident.currentHP = currentHP
        incident.isActive = isActive
        incident.capsStolen = capsStolen
        incident.spreadRoomIDs = spreadRoomIDs
        incident.combatLog = combatLog
        return incident
    }

    /// Update from GameLogic Incident struct
    func update(from incident: Incident) {
        self.currentHP = incident.currentHP
        self.isActive = incident.isActive
        self.capsStolen = incident.capsStolen
        if let data = try? JSONEncoder().encode(incident.spreadRoomIDs) {
            self.spreadRoomIDsJSON = String(data: data, encoding: .utf8) ?? "[]"
        }
        if let data = try? JSONEncoder().encode(incident.combatLog) {
            self.combatLogJSON = String(data: data, encoding: .utf8) ?? "[]"
        }

        if !incident.isActive && resolvedAt == nil {
            resolvedAt = Date()
        }
    }

    /// Progress percentage (damage dealt)
    var progressPercent: Double {
        guard maxHP > 0 else { return 100 }
        return Double(maxHP - currentHP) / Double(maxHP) * 100
    }

    /// Short ID for callback data
    var shortID: String {
        (id?.uuidString.prefix(8)).map(String.init) ?? "unknown"
    }
}

// MARK: - Display

public extension IncidentModel {
    /// Short description for display
    var shortDescription: String {
        guard let incidentType = incidentType else { return "Unknown Incident" }
        let hp = "\(currentHP)/\(maxHP) HP"
        return "\(incidentType.emoji) \(incidentType.rawValue.capitalized) - \(hp)"
    }

    /// Status text
    var statusText: String {
        if !isActive {
            return "Defeated"
        }
        let percent = Int(progressPercent)
        return "\(percent)% damage dealt"
    }
}

// MARK: - Queries

public extension IncidentModel {
    /// Find active incidents for a vault
    static func activeIncidents(vaultID: UUID, on db: any Database) async throws -> [IncidentModel] {
        try await IncidentModel.query(on: db)
            .filter(\.$vault.$id == vaultID)
            .filter(\.$isActive == true)
            .all()
    }

    /// Find incident by short ID in a vault
    static func findByShortID(_ shortID: String, vaultID: UUID, on db: any Database) async throws -> IncidentModel? {
        let incidents = try await activeIncidents(vaultID: vaultID, on: db)
        return incidents.first { $0.shortID == shortID }
    }

    /// Count active incidents for a vault
    static func activeCount(vaultID: UUID, on db: any Database) async throws -> Int {
        try await IncidentModel.query(on: db)
            .filter(\.$vault.$id == vaultID)
            .filter(\.$isActive == true)
            .count()
    }
}
