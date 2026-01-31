//
//  Outfit.swift
//  GameLogic
//
//  Outfit equipment providing SPECIAL bonuses
//

import Foundation

/// An outfit that provides SPECIAL stat bonuses when worn.
public struct Outfit: Identifiable, Codable, Sendable, Equatable {
    /// Unique identifier
    public let id: UUID

    /// Outfit name
    public let name: String

    /// Rarity level
    public let rarity: ItemRarity

    /// SPECIAL stat bonuses
    public let bonuses: StatBonuses

    /// Total bonus points
    public var totalBonus: Int {
        bonuses.total
    }

    /// Create a new outfit
    public init(
        id: UUID = UUID(),
        name: String,
        rarity: ItemRarity,
        bonuses: StatBonuses
    ) {
        self.id = id
        self.name = name
        self.rarity = rarity
        self.bonuses = bonuses
    }

    /// Create an outfit with single stat bonus
    public init(
        id: UUID = UUID(),
        name: String,
        rarity: ItemRarity,
        primaryStat: SPECIAL,
        primaryBonus: Int
    ) {
        self.id = id
        self.name = name
        self.rarity = rarity
        self.bonuses = StatBonuses(stat: primaryStat, value: primaryBonus)
    }

    /// Display description
    public var description: String {
        "\(rarity.emoji) \(name) (\(bonuses.shortDescription))"
    }
}

/// SPECIAL stat bonuses from equipment
public struct StatBonuses: Codable, Sendable, Equatable {
    public var strength: Int
    public var perception: Int
    public var endurance: Int
    public var charisma: Int
    public var intelligence: Int
    public var agility: Int
    public var luck: Int

    public init(
        strength: Int = 0,
        perception: Int = 0,
        endurance: Int = 0,
        charisma: Int = 0,
        intelligence: Int = 0,
        agility: Int = 0,
        luck: Int = 0
    ) {
        self.strength = strength
        self.perception = perception
        self.endurance = endurance
        self.charisma = charisma
        self.intelligence = intelligence
        self.agility = agility
        self.luck = luck
    }

    /// Create with single stat bonus
    public init(stat: SPECIAL, value: Int) {
        self.strength = stat == .strength ? value : 0
        self.perception = stat == .perception ? value : 0
        self.endurance = stat == .endurance ? value : 0
        self.charisma = stat == .charisma ? value : 0
        self.intelligence = stat == .intelligence ? value : 0
        self.agility = stat == .agility ? value : 0
        self.luck = stat == .luck ? value : 0
    }

    /// Get bonus for a specific stat
    public func bonus(for stat: SPECIAL) -> Int {
        switch stat {
        case .strength: return strength
        case .perception: return perception
        case .endurance: return endurance
        case .charisma: return charisma
        case .intelligence: return intelligence
        case .agility: return agility
        case .luck: return luck
        }
    }

    /// Total bonus points
    public var total: Int {
        strength + perception + endurance + charisma + intelligence + agility + luck
    }

    /// No bonuses
    public static let none = StatBonuses()

    /// Short description like "+7S" or "+4P +3I"
    public var shortDescription: String {
        var parts: [String] = []
        if strength > 0 { parts.append("+\(strength)S") }
        if perception > 0 { parts.append("+\(perception)P") }
        if endurance > 0 { parts.append("+\(endurance)E") }
        if charisma > 0 { parts.append("+\(charisma)C") }
        if intelligence > 0 { parts.append("+\(intelligence)I") }
        if agility > 0 { parts.append("+\(agility)A") }
        if luck > 0 { parts.append("+\(luck)L") }
        return parts.isEmpty ? "No bonuses" : parts.joined(separator: " ")
    }
}

// MARK: - Outfit Database

public extension Outfit {
    /// Legendary outfits with +7 to a primary stat
    static let legendaryOutfits: [Outfit] = [
        // Strength +7
        Outfit(name: "Commander Fatigues", rarity: .legendary, bonuses: StatBonuses(strength: 7)),
        Outfit(name: "Heavy Vault Suit", rarity: .legendary, bonuses: StatBonuses(strength: 6, agility: 1)),

        // Perception +7
        Outfit(name: "Expert Jumpsuit", rarity: .legendary, bonuses: StatBonuses(perception: 7)),
        Outfit(name: "Detective Outfit", rarity: .legendary, bonuses: StatBonuses(perception: 4, intelligence: 3)),

        // Endurance +7
        Outfit(name: "Heavy Wasteland Gear", rarity: .legendary, bonuses: StatBonuses(endurance: 7)),
        Outfit(name: "Wasteland Surgeon", rarity: .legendary, bonuses: StatBonuses(endurance: 4, intelligence: 3)),

        // Charisma +7
        Outfit(name: "Eulogy Jones' Suit", rarity: .legendary, bonuses: StatBonuses(charisma: 7)),
        Outfit(name: "Comedian", rarity: .legendary, bonuses: StatBonuses(charisma: 5, agility: 2)),

        // Intelligence +7
        Outfit(name: "Expert Lab Coat", rarity: .legendary, bonuses: StatBonuses(intelligence: 7)),
        Outfit(name: "Professor Outfit", rarity: .legendary, bonuses: StatBonuses(intelligence: 5, agility: 2)),

        // Agility +7
        Outfit(name: "Ninja Outfit", rarity: .legendary, bonuses: StatBonuses(agility: 7)),
        Outfit(name: "Minuteman Uniform", rarity: .legendary, bonuses: StatBonuses(perception: 3, agility: 4)),

        // Luck +7
        Outfit(name: "Lucky Formal Wear", rarity: .legendary, bonuses: StatBonuses(luck: 7)),
        Outfit(name: "Piper's Outfit", rarity: .legendary, bonuses: StatBonuses(perception: 1, luck: 6)),
    ]

    /// Quest-exclusive Horsemen outfits (+16 total)
    static let horsemenOutfits: [Outfit] = [
        Outfit(name: "War's Armor", rarity: .legendary, bonuses: StatBonuses(strength: 4, endurance: 4, agility: 4, luck: 4)),
        Outfit(name: "Famine's Vestment", rarity: .legendary, bonuses: StatBonuses(perception: 4, charisma: 4, intelligence: 4, luck: 4)),
        Outfit(name: "Pestilence's Plating", rarity: .legendary, bonuses: StatBonuses(strength: 4, perception: 4, intelligence: 4, agility: 4)),
        Outfit(name: "Death's Jacket", rarity: .legendary, bonuses: StatBonuses(perception: 4, endurance: 4, charisma: 4, luck: 4)),
    ]

    /// Rare outfits (+5 total)
    static let rareOutfits: [Outfit] = [
        Outfit(name: "Sturdy Vault Suit", rarity: .rare, bonuses: StatBonuses(strength: 5)),
        Outfit(name: "Sharpshooter Jacket", rarity: .rare, bonuses: StatBonuses(perception: 5)),
        Outfit(name: "Sturdy Wasteland Gear", rarity: .rare, bonuses: StatBonuses(endurance: 5)),
        Outfit(name: "Formal Wear", rarity: .rare, bonuses: StatBonuses(charisma: 5)),
        Outfit(name: "Lab Coat", rarity: .rare, bonuses: StatBonuses(intelligence: 5)),
        Outfit(name: "Athlete Outfit", rarity: .rare, bonuses: StatBonuses(agility: 5)),
        Outfit(name: "Gambler Suit", rarity: .rare, bonuses: StatBonuses(luck: 5)),
    ]

    /// Common outfits (+3 total)
    static let commonOutfits: [Outfit] = [
        Outfit(name: "Vault Suit", rarity: .common, bonuses: StatBonuses(strength: 3)),
        Outfit(name: "Wasteland Gear", rarity: .common, bonuses: StatBonuses(endurance: 3)),
        Outfit(name: "Casual Outfit", rarity: .common, bonuses: StatBonuses(charisma: 3)),
        Outfit(name: "Mechanic Jumpsuit", rarity: .common, bonuses: StatBonuses(intelligence: 3)),
        Outfit(name: "Athletic Wear", rarity: .common, bonuses: StatBonuses(agility: 3)),
        Outfit(name: "Sleepwear", rarity: .common, bonuses: StatBonuses(luck: 3)),
    ]

    /// All outfits
    static let allOutfits: [Outfit] = commonOutfits + rareOutfits + legendaryOutfits + horsemenOutfits

    /// Get a random outfit of specific rarity
    static func random(rarity: ItemRarity) -> Outfit? {
        switch rarity {
        case .common: return commonOutfits.randomElement()
        case .rare: return rareOutfits.randomElement()
        case .legendary: return legendaryOutfits.randomElement()
        }
    }
}
