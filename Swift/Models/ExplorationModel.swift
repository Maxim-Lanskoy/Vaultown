//
//  ExplorationModel.swift
//  Vaultown
//
//  Fluent model for active/completed explorations
//

import Fluent
import Foundation
import GameLogic

/// Database model for wasteland exploration
final public class ExplorationModel: Model, @unchecked Sendable {
    public static let schema = "explorations"

    @ID(key: .id)
    public var id: UUID?

    /// Reference to the owning vault
    @Parent(key: "vault_id")
    var vault: Vault

    /// Reference to the exploring dweller
    @Parent(key: "dweller_id")
    var dweller: DwellerModel

    /// Dweller name (cached for display even after dweller might be deleted)
    @Field(key: "dweller_name")
    var dwellerName: String

    /// Status: exploring, returning, completed, dead
    @Field(key: "status")
    var status: String

    /// Exploration start time
    @Field(key: "start_time")
    var startTime: Date

    /// Time when return was initiated (nil if still exploring)
    @OptionalField(key: "return_start_time")
    var returnStartTime: Date?

    /// Current HP during exploration
    @Field(key: "current_hp")
    var currentHP: Double

    /// Max HP of explorer
    @Field(key: "max_hp")
    var maxHP: Double

    /// Current radiation level
    @Field(key: "radiation")
    var radiation: Double

    /// Whether explorer has radiation immunity (E11+)
    @Field(key: "has_radiation_immunity")
    var hasRadiationImmunity: Bool

    /// Stimpaks carried
    @Field(key: "stimpaks")
    var stimpaks: Int

    /// RadAway carried
    @Field(key: "rad_away")
    var radAway: Int

    /// Caps collected during exploration
    @Field(key: "caps_collected")
    var capsCollected: Int

    /// Items collected count
    @Field(key: "items_collected")
    var itemsCollected: Int

    /// Current dweller level (may increase during exploration)
    @Field(key: "dweller_level")
    var dwellerLevel: Int

    /// Current dweller XP
    @Field(key: "dweller_xp")
    var dwellerXP: Int

    /// Dweller's Luck stat
    @Field(key: "luck")
    var luck: Int

    /// Dweller's Perception stat
    @Field(key: "perception")
    var perception: Int

    /// Dweller's Charisma stat
    @Field(key: "charisma")
    var charisma: Int

    /// Dweller's Endurance stat (for level-up HP calculation)
    @Field(key: "endurance")
    var endurance: Int

    /// Return speed multiplier from pet (1.0 = normal, 4.0 = max)
    @Field(key: "return_speed_multiplier")
    var returnSpeedMultiplier: Double

    /// Event log stored as JSON
    @Field(key: "events_json")
    var eventsJSON: String

    /// Last event generation timestamp (minutes)
    @Field(key: "last_event_minute")
    var lastEventMinute: Int

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    public init() {}

    /// Create from GameLogic Exploration
    init(vaultID: Vault.IDValue, dwellerID: DwellerModel.IDValue, exploration: Exploration) {
        self.$vault.id = vaultID
        self.$dweller.id = dwellerID
        self.dwellerName = exploration.dwellerName
        self.status = exploration.status.rawValue
        self.startTime = exploration.startTime
        self.returnStartTime = exploration.returnStartTime
        self.currentHP = exploration.currentHP
        self.maxHP = exploration.maxHP
        self.radiation = exploration.radiation
        self.hasRadiationImmunity = exploration.hasRadiationImmunity
        self.stimpaks = exploration.stimpaks
        self.radAway = exploration.radAway
        self.capsCollected = exploration.capsCollected
        self.itemsCollected = exploration.itemsCollected
        self.dwellerLevel = exploration.dwellerLevel
        self.dwellerXP = exploration.dwellerXP
        self.luck = exploration.luck
        self.perception = exploration.perception
        self.charisma = exploration.charisma
        self.endurance = 10 // Default, should be set from dweller
        self.returnSpeedMultiplier = exploration.returnSpeedMultiplier
        self.lastEventMinute = 0

        // Encode events as JSON
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(exploration.events) {
            self.eventsJSON = String(data: data, encoding: .utf8) ?? "[]"
        } else {
            self.eventsJSON = "[]"
        }
    }
}

// MARK: - GameLogic Integration

extension ExplorationModel {
    /// Convert to GameLogic Exploration struct
    func toExploration() -> Exploration {
        let statusEnum = ExplorationStatus(rawValue: status) ?? .exploring

        // Decode events from JSON
        var events: [ExplorationEvent] = []
        if let data = eventsJSON.data(using: .utf8) {
            let decoder = JSONDecoder()
            events = (try? decoder.decode([ExplorationEvent].self, from: data)) ?? []
        }

        var exploration = Exploration(
            id: id ?? UUID(),
            dwellerID: $dweller.id,
            dwellerName: dwellerName,
            startTime: startTime,
            currentHP: currentHP,
            maxHP: maxHP,
            radiation: radiation,
            hasRadiationImmunity: hasRadiationImmunity,
            stimpaks: stimpaks,
            radAway: radAway,
            dwellerLevel: dwellerLevel,
            dwellerXP: dwellerXP,
            luck: luck,
            perception: perception,
            charisma: charisma,
            returnSpeedMultiplier: returnSpeedMultiplier
        )

        // Override with stored values
        exploration.returnStartTime = returnStartTime
        exploration.status = statusEnum
        exploration.capsCollected = capsCollected
        exploration.itemsCollected = itemsCollected
        exploration.events = events

        return exploration
    }

    /// Update from GameLogic Exploration struct
    func update(from exploration: Exploration) {
        self.status = exploration.status.rawValue
        self.returnStartTime = exploration.returnStartTime
        self.currentHP = exploration.currentHP
        self.radiation = exploration.radiation
        self.stimpaks = exploration.stimpaks
        self.radAway = exploration.radAway
        self.capsCollected = exploration.capsCollected
        self.itemsCollected = exploration.itemsCollected
        self.dwellerLevel = exploration.dwellerLevel
        self.dwellerXP = exploration.dwellerXP

        // Encode events as JSON
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(exploration.events) {
            self.eventsJSON = String(data: data, encoding: .utf8) ?? "[]"
        }
    }

    /// Create a new exploration for a dweller
    static func create(
        vaultID: Vault.IDValue,
        dweller: DwellerModel,
        stimpaks: Int,
        radAway: Int,
        returnSpeedMultiplier: Double = 1.0
    ) -> ExplorationModel {
        guard let dwellerID = dweller.id else {
            fatalError("Dweller must have an ID")
        }

        // Calculate radiation immunity (E11+)
        let hasImmunity = dweller.endurance >= 11

        let exploration = Exploration(
            dwellerID: dwellerID,
            dwellerName: dweller.fullName,
            currentHP: dweller.currentHP,
            maxHP: dweller.maxHP,
            radiation: dweller.radiation,
            hasRadiationImmunity: hasImmunity,
            stimpaks: stimpaks,
            radAway: radAway,
            dwellerLevel: dweller.level,
            dwellerXP: dweller.experience,
            luck: dweller.luck,
            perception: dweller.perception,
            charisma: dweller.charisma,
            returnSpeedMultiplier: returnSpeedMultiplier
        )

        let model = ExplorationModel(vaultID: vaultID, dwellerID: dwellerID, exploration: exploration)
        model.endurance = dweller.endurance

        return model
    }
}

// MARK: - Display

extension ExplorationModel {
    /// Status enum
    var statusEnum: ExplorationStatus {
        ExplorationStatus(rawValue: status) ?? .exploring
    }

    /// Status emoji
    var statusEmoji: String {
        switch statusEnum {
        case .exploring: return "🏃"
        case .returning: return "🔙"
        case .completed: return "✅"
        case .dead: return "💀"
        }
    }

    /// Exploration time in minutes
    var explorationMinutes: Int {
        let endTime = returnStartTime ?? Date()
        return Int(endTime.timeIntervalSince(startTime) / 60)
    }

    /// Formatted exploration time
    var explorationTimeFormatted: String {
        let hours = explorationMinutes / 60
        let mins = explorationMinutes % 60
        return "\(hours)h \(mins)m"
    }

    /// Expected return duration in minutes
    var expectedReturnDuration: Int {
        let baseReturn = Double(explorationMinutes) * 0.5
        return Int(baseReturn / returnSpeedMultiplier)
    }

    /// Return progress (0.0 to 1.0)
    var returnProgress: Double {
        guard statusEnum == .returning, let returnStart = returnStartTime else { return 0 }
        let elapsed = Int(Date().timeIntervalSince(returnStart) / 60)
        guard expectedReturnDuration > 0 else { return 1.0 }
        return min(1.0, Double(elapsed) / Double(expectedReturnDuration))
    }

    /// Short summary for list display
    var summary: String {
        let loot = "💰\(capsCollected) 📦\(itemsCollected)"
        switch statusEnum {
        case .exploring:
            return "\(statusEmoji) \(dwellerName) - Exploring (\(explorationTimeFormatted)) | \(loot)"
        case .returning:
            let progress = Int(returnProgress * 100)
            return "\(statusEmoji) \(dwellerName) - Returning (\(progress)%) | \(loot)"
        case .completed:
            return "\(statusEmoji) \(dwellerName) - Ready to collect | \(loot)"
        case .dead:
            return "\(statusEmoji) \(dwellerName) - Deceased | \(loot)"
        }
    }

    /// Health bar
    func healthBar(segments: Int = 5) -> String {
        let effectiveMax = max(0.01, maxHP - radiation)
        let pct = currentHP / effectiveMax
        let filled = Int(pct * Double(segments))
        return "[" + String(repeating: "█", count: filled) + String(repeating: "░", count: segments - filled) + "]"
    }

    /// Get recent events for display
    func recentEvents(count: Int = 5) -> [ExplorationEvent] {
        let exploration = toExploration()
        return Array(exploration.events.suffix(count))
    }
}
