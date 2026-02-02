//
//  IncidentType.swift
//  GameLogic
//
//  Incident types and their behaviors for vault defense
//

import Foundation

/// Types of incidents that can occur in a vault
public enum IncidentType: String, Codable, Sendable, CaseIterable {
    case fire
    case radroach
    case moleRat
    case raider
    case feralGhoul
    case radscorpion
    case deathclaw

    /// Emoji for display
    public var emoji: String {
        switch self {
        case .fire: return "🔥"
        case .radroach: return "🪳"
        case .moleRat: return "🐀"
        case .raider: return "🏴‍☠️"
        case .feralGhoul: return "🧟"
        case .radscorpion: return "🦂"
        case .deathclaw: return "🦖"
        }
    }

    /// Minimum population required for this incident type
    public var minimumPopulation: Int {
        switch self {
        case .fire: return 2
        case .radroach: return 9
        case .raider: return 14
        case .moleRat: return 31
        case .feralGhoul: return 41
        case .radscorpion: return 51
        case .deathclaw: return 61
        }
    }

    /// Base damage range (min, max) for this incident type
    public var baseDamageRange: (min: Int, max: Int) {
        switch self {
        case .fire: return (1, 3)
        case .radroach: return (2, 4)
        case .moleRat: return (2, 5)
        case .raider: return (6, 15)
        case .feralGhoul: return (4, 8)
        case .radscorpion: return (8, 12)
        case .deathclaw: return (15, 30)
        }
    }

    /// Base HP of incident enemies (per unit)
    public var baseHP: Int {
        switch self {
        case .fire: return 50  // Fire has "HP" representing how long it takes to extinguish
        case .radroach: return 20
        case .moleRat: return 30
        case .raider: return 50
        case .feralGhoul: return 60
        case .radscorpion: return 80
        case .deathclaw: return 150
        }
    }

    /// Whether this incident deals radiation damage
    public var dealsRadiation: Bool {
        switch self {
        case .feralGhoul, .radscorpion: return true
        default: return false
        }
    }

    /// Radiation damage per hit (if applicable)
    public var radiationDamage: Int {
        switch self {
        case .feralGhoul: return 10
        case .radscorpion: return 15
        default: return 0
        }
    }

    /// Whether this incident spreads to adjacent empty rooms
    public var spreadsToEmptyRooms: Bool {
        switch self {
        case .fire, .radroach, .moleRat: return true
        default: return false
        }
    }

    /// Whether this incident ignores vault door (enters instantly)
    public var ignoresVaultDoor: Bool {
        switch self {
        case .deathclaw: return true
        default: return false
        }
    }

    /// Whether this incident can steal caps
    public var stealsCaps: Bool {
        switch self {
        case .raider: return true
        default: return false
        }
    }

    /// Caps stolen per second (if applicable)
    public var capsStealRate: Int {
        switch self {
        case .raider: return 5
        default: return 0
        }
    }

    /// Number of enemies that spawn (base, scales with room level/width)
    public var baseEnemyCount: Int {
        switch self {
        case .fire: return 1  // Fire doesn't have "count"
        case .radroach: return 3
        case .moleRat: return 2
        case .raider: return 3
        case .feralGhoul: return 2
        case .radscorpion: return 2
        case .deathclaw: return 2
        }
    }

    /// XP reward for defeating this incident (per enemy)
    public var xpReward: Int {
        switch self {
        case .fire: return 5
        case .radroach: return 10
        case .moleRat: return 15
        case .raider: return 25
        case .feralGhoul: return 30
        case .radscorpion: return 40
        case .deathclaw: return 100
        }
    }

    /// Caps reward for defeating (raiders drop their stolen caps)
    public var capsReward: Int {
        switch self {
        case .raider: return 50
        default: return 0
        }
    }

    /// Get available incident types for a given population
    public static func availableTypes(forPopulation population: Int) -> [IncidentType] {
        return IncidentType.allCases.filter { $0.minimumPopulation <= population }
    }

    /// Get rush failure incident types for a given population
    public static func rushFailureTypes(forPopulation population: Int) -> [IncidentType] {
        // Rush failures have specific rules
        switch population {
        case 2...8:
            return [.fire]
        case 9...13:
            return [.fire, .radroach]
        case 14...30:
            return [.fire, .radroach, .raider]
        case 31...40:
            return [.fire, .radroach, .moleRat]
        case 41...50:
            return [.fire, .radroach, .moleRat, .feralGhoul]
        case 51...60:
            return [.fire, .radroach, .moleRat, .feralGhoul, .radscorpion]
        default:
            if population >= 61 {
                return IncidentType.allCases
            }
            return []
        }
    }
}

/// Incident behavior flags
public struct IncidentBehavior: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let spreads = IncidentBehavior(rawValue: 1 << 0)
    public static let steals = IncidentBehavior(rawValue: 1 << 1)
    public static let radiates = IncidentBehavior(rawValue: 1 << 2)
    public static let ignoresDoors = IncidentBehavior(rawValue: 1 << 3)
    public static let teleports = IncidentBehavior(rawValue: 1 << 4)  // Radscorpions
}
