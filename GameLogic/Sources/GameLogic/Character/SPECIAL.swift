//
//  SPECIAL.swift
//  GameLogic
//
//  S.P.E.C.I.A.L. stat system based on Fallout
//

import Foundation

/// The seven S.P.E.C.I.A.L. stats that define a dweller's abilities.
///
/// Each stat affects different aspects of gameplay:
/// - Production room efficiency
/// - Rush success chance
/// - Quest combat effectiveness
/// - Exploration bonuses
public enum SPECIAL: String, CaseIterable, Codable, Sendable {
    case strength = "S"
    case perception = "P"
    case endurance = "E"
    case charisma = "C"
    case intelligence = "I"
    case agility = "A"
    case luck = "L"

    /// Full name of the stat
    public var name: String {
        switch self {
        case .strength: return "Strength"
        case .perception: return "Perception"
        case .endurance: return "Endurance"
        case .charisma: return "Charisma"
        case .intelligence: return "Intelligence"
        case .agility: return "Agility"
        case .luck: return "Luck"
        }
    }

    /// Emoji representation for Telegram display
    public var emoji: String {
        switch self {
        case .strength: return "💪"
        case .perception: return "👁"
        case .endurance: return "❤️"
        case .charisma: return "💬"
        case .intelligence: return "🧠"
        case .agility: return "⚡"
        case .luck: return "🍀"
        }
    }

    /// Production rooms that benefit from this stat
    public var productionRooms: [String] {
        switch self {
        case .strength: return ["Power Generator", "Nuclear Reactor"]
        case .perception: return ["Water Treatment", "Water Purification"]
        case .endurance: return ["Nuka-Cola Bottler"]
        case .charisma: return ["Living Quarters", "Radio Studio"]
        case .intelligence: return ["Medbay", "Science Lab"]
        case .agility: return ["Diner", "Garden"]
        case .luck: return [] // Luck provides caps bonus in all rooms
        }
    }

    /// Training room that improves this stat
    public var trainingRoom: String? {
        switch self {
        case .strength: return "Weight Room"
        case .perception: return "Armory"
        case .endurance: return "Fitness Room"
        case .charisma: return "Lounge"
        case .intelligence: return "Classroom"
        case .agility: return "Athletics Room"
        case .luck: return "Game Room"
        }
    }
}

// MARK: - Stat Limits

public extension SPECIAL {
    /// Minimum base stat value
    static let minValue: Int = 1

    /// Maximum base stat value (trainable)
    static let maxBaseValue: Int = 10

    /// Maximum total stat value with outfit bonus (+7)
    static let maxTotalValue: Int = 17

    /// Maximum outfit bonus
    static let maxOutfitBonus: Int = 7
}
