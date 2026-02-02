//
//  ExplorationEvent.swift
//  GameLogic
//
//  Event types that occur during wasteland exploration
//

import Foundation

/// Types of events that can occur during exploration
public enum ExplorationEventType: String, Codable, Sendable, CaseIterable {
    /// Combat encounter with enemies
    case combat
    /// Found items (weapons, outfits)
    case lootDiscovery
    /// Collected junk for crafting
    case junkScavenging
    /// Found caps
    case capsFound
    /// Discovered a quest location
    case locationFound
    /// Met a friendly NPC
    case npcEncounter
    /// Entered a radiation zone
    case radiationZone
    /// Found a crafting recipe
    case recipeFound
    /// Dweller leveled up
    case levelUp
    /// Dweller used a stimpak
    case stimpakUsed
    /// Dweller used RadAway
    case radAwayUsed
    /// Dweller died
    case death

    /// Emoji for display
    public var emoji: String {
        switch self {
        case .combat: return "⚔️"
        case .lootDiscovery: return "🎁"
        case .junkScavenging: return "🔧"
        case .capsFound: return "💰"
        case .locationFound: return "📍"
        case .npcEncounter: return "🗣️"
        case .radiationZone: return "☢️"
        case .recipeFound: return "📜"
        case .levelUp: return "⬆️"
        case .stimpakUsed: return "💊"
        case .radAwayUsed: return "💉"
        case .death: return "💀"
        }
    }
}

/// Enemy types encountered during exploration
public enum ExplorationEnemy: String, Codable, Sendable, CaseIterable {
    case radroach
    case bloatfly
    case moleRat
    case feralGhoul
    case raider
    case wildDog
    case radscorpion
    case supermutant
    case deathclaw

    /// Display name
    public var name: String {
        switch self {
        case .radroach: return "Radroach"
        case .bloatfly: return "Bloatfly"
        case .moleRat: return "Mole Rat"
        case .feralGhoul: return "Feral Ghoul"
        case .raider: return "Raider"
        case .wildDog: return "Wild Dog"
        case .radscorpion: return "Radscorpion"
        case .supermutant: return "Super Mutant"
        case .deathclaw: return "Deathclaw"
        }
    }

    /// Emoji for display
    public var emoji: String {
        switch self {
        case .radroach: return "🪳"
        case .bloatfly: return "🪰"
        case .moleRat: return "🐀"
        case .feralGhoul: return "🧟"
        case .raider: return "🏴‍☠️"
        case .wildDog: return "🐕"
        case .radscorpion: return "🦂"
        case .supermutant: return "👹"
        case .deathclaw: return "🦎"
        }
    }

    /// Base damage range
    public var damageRange: ClosedRange<Int> {
        switch self {
        case .radroach: return 2...4
        case .bloatfly: return 2...5
        case .moleRat: return 4...8
        case .feralGhoul: return 8...12
        case .raider: return 6...15
        case .wildDog: return 5...10
        case .radscorpion: return 10...18
        case .supermutant: return 12...20
        case .deathclaw: return 20...35
        }
    }

    /// Base HP
    public var baseHP: Int {
        switch self {
        case .radroach: return 10
        case .bloatfly: return 15
        case .moleRat: return 25
        case .feralGhoul: return 40
        case .raider: return 50
        case .wildDog: return 30
        case .radscorpion: return 60
        case .supermutant: return 80
        case .deathclaw: return 150
        }
    }

    /// Whether this enemy deals radiation damage
    public var dealsRadiation: Bool {
        switch self {
        case .feralGhoul, .radscorpion: return true
        default: return false
        }
    }

    /// XP reward for killing this enemy
    public var xpReward: Int {
        switch self {
        case .radroach: return 5
        case .bloatfly: return 8
        case .moleRat: return 15
        case .feralGhoul: return 25
        case .raider: return 30
        case .wildDog: return 20
        case .radscorpion: return 40
        case .supermutant: return 50
        case .deathclaw: return 100
        }
    }

    /// Random enemy based on exploration time (stronger enemies appear later)
    public static func random(explorationMinutes: Int) -> ExplorationEnemy {
        let hours = Double(explorationMinutes) / 60.0

        // Weighted selection based on exploration time
        if hours < 1 {
            // Early exploration: weak enemies only
            return [.radroach, .bloatfly, .moleRat].randomElement()!
        } else if hours < 3 {
            // Mid exploration
            return [.radroach, .moleRat, .feralGhoul, .raider, .wildDog].randomElement()!
        } else if hours < 6 {
            // Late exploration
            return [.feralGhoul, .raider, .radscorpion, .supermutant].randomElement()!
        } else {
            // Extended exploration: any enemy including deathclaws
            return allCases.randomElement()!
        }
    }
}

/// A single exploration event with all its data
public struct ExplorationEvent: Identifiable, Codable, Sendable, Equatable {
    /// Unique identifier
    public let id: UUID

    /// Type of event
    public let type: ExplorationEventType

    /// Timestamp (minutes since exploration started)
    public let timestamp: Int

    /// Event description for the log
    public let description: String

    /// Associated data depending on event type
    public var capsGained: Int?
    public var damageReceived: Double?
    public var radiationReceived: Double?
    public var xpGained: Int?
    public var itemFound: String?
    public var enemyDefeated: String?
    public var locationName: String?

    /// Create a new exploration event
    public init(
        id: UUID = UUID(),
        type: ExplorationEventType,
        timestamp: Int,
        description: String,
        capsGained: Int? = nil,
        damageReceived: Double? = nil,
        radiationReceived: Double? = nil,
        xpGained: Int? = nil,
        itemFound: String? = nil,
        enemyDefeated: String? = nil,
        locationName: String? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.description = description
        self.capsGained = capsGained
        self.damageReceived = damageReceived
        self.radiationReceived = radiationReceived
        self.xpGained = xpGained
        self.itemFound = itemFound
        self.enemyDefeated = enemyDefeated
        self.locationName = locationName
    }

    /// Formatted timestamp for display (HH:MM)
    public var formattedTimestamp: String {
        let hours = timestamp / 60
        let minutes = timestamp % 60
        return String(format: "%d:%02d", hours, minutes)
    }

    /// Full log line for display
    public var logLine: String {
        "[\(formattedTimestamp)] \(type.emoji) \(description)"
    }
}
