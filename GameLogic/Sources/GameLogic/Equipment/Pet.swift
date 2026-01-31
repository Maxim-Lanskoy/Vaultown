//
//  Pet.swift
//  GameLogic
//
//  Pet companions providing passive bonuses
//

import Foundation

/// Type of pet species
public enum PetSpecies: String, CaseIterable, Codable, Sendable {
    case dog
    case cat
    case parrot
    case deathclaw  // Legendary only
    case radroach   // Exotic
    case moleRat    // Exotic

    /// Display name
    public var name: String {
        switch self {
        case .dog: return "Dog"
        case .cat: return "Cat"
        case .parrot: return "Parrot"
        case .deathclaw: return "Deathclaw"
        case .radroach: return "Radroach"
        case .moleRat: return "Mole Rat"
        }
    }

    /// Emoji representation
    public var emoji: String {
        switch self {
        case .dog: return "🐕"
        case .cat: return "🐈"
        case .parrot: return "🦜"
        case .deathclaw: return "🦎"
        case .radroach: return "🪳"
        case .moleRat: return "🐀"
        }
    }

    /// Whether this is a common species
    public var isCommon: Bool {
        self == .dog || self == .cat || self == .parrot
    }
}

/// Type of bonus a pet provides
public enum PetBonusType: String, CaseIterable, Codable, Sendable {
    case damage              // Combat damage bonus
    case hp                  // HP bonus
    case wastelandJunk       // Increased junk finds
    case wastelandCaps       // Increased caps finds
    case returnSpeed         // Faster explorer return
    case craftingTime        // Reduced crafting time
    case objectiveCompletion // Objective multiplier
    case childSpecials       // Child stat bonus
    case xpBonus             // Experience bonus
    case trainingSpeed       // Faster training
    case mysteriousStranger  // Increased stranger spawn

    /// Display name
    public var name: String {
        switch self {
        case .damage: return "Damage"
        case .hp: return "HP"
        case .wastelandJunk: return "Wasteland Junk"
        case .wastelandCaps: return "Wasteland Caps"
        case .returnSpeed: return "Return Speed"
        case .craftingTime: return "Crafting Time"
        case .objectiveCompletion: return "Objective Completion"
        case .childSpecials: return "Child SPECIALs"
        case .xpBonus: return "XP Bonus"
        case .trainingSpeed: return "Training Speed"
        case .mysteriousStranger: return "Mysterious Stranger"
        }
    }

    /// Description of the bonus effect
    public var effectDescription: String {
        switch self {
        case .damage: return "Combat damage"
        case .hp: return "Maximum HP"
        case .wastelandJunk: return "Wasteland junk finds"
        case .wastelandCaps: return "Wasteland caps finds"
        case .returnSpeed: return "Explorer return speed"
        case .craftingTime: return "Crafting time reduction"
        case .objectiveCompletion: return "Objective completion multiplier"
        case .childSpecials: return "Child SPECIAL stats"
        case .xpBonus: return "Experience points gained"
        case .trainingSpeed: return "Training time reduction"
        case .mysteriousStranger: return "Mysterious Stranger spawn rate"
        }
    }

    /// Emoji for the bonus type
    public var emoji: String {
        switch self {
        case .damage: return "⚔️"
        case .hp: return "❤️"
        case .wastelandJunk: return "🔧"
        case .wastelandCaps: return "💰"
        case .returnSpeed: return "🏃"
        case .craftingTime: return "⚙️"
        case .objectiveCompletion: return "✅"
        case .childSpecials: return "👶"
        case .xpBonus: return "📈"
        case .trainingSpeed: return "🏋️"
        case .mysteriousStranger: return "🎩"
        }
    }
}

/// Pet bonus values by rarity
public struct PetBonusValue: Codable, Sendable, Equatable {
    public let type: PetBonusType
    public let rarity: ItemRarity

    /// The actual bonus value based on type and rarity
    public var value: Double {
        switch type {
        case .damage:
            switch rarity {
            case .common: return 1
            case .rare: return 3
            case .legendary: return 6
            }
        case .hp:
            switch rarity {
            case .common: return 1
            case .rare: return 3
            case .legendary: return 6
            }
        case .wastelandJunk, .wastelandCaps:
            switch rarity {
            case .common: return 0.10  // +10%
            case .rare: return 0.50    // +50%
            case .legendary: return 1.0 // +100%
            }
        case .returnSpeed:
            switch rarity {
            case .common: return 1.25
            case .rare: return 2.0
            case .legendary: return 4.0
            }
        case .craftingTime:
            switch rarity {
            case .common: return 0.06  // -6%
            case .rare: return 0.24    // -24%
            case .legendary: return 0.45 // -45%
            }
        case .objectiveCompletion:
            switch rarity {
            case .common: return 1.5
            case .rare: return 2.0
            case .legendary: return 3.0
            }
        case .childSpecials:
            switch rarity {
            case .common: return 1
            case .rare: return 2
            case .legendary: return 3
            }
        case .xpBonus:
            switch rarity {
            case .common: return 0.10  // +10%
            case .rare: return 0.30    // +30%
            case .legendary: return 0.50 // +50%
            }
        case .trainingSpeed:
            switch rarity {
            case .common: return 0.10  // -10%
            case .rare: return 0.30    // -30%
            case .legendary: return 0.50 // -50%
            }
        case .mysteriousStranger:
            switch rarity {
            case .common: return 1.0   // +1×
            case .rare: return 4.0     // +4×
            case .legendary: return 7.5 // +7.5×
            }
        }
    }

    /// Display string for the bonus
    public var displayValue: String {
        switch type {
        case .damage, .hp, .childSpecials:
            return "+\(Int(value))"
        case .wastelandJunk, .wastelandCaps, .craftingTime, .xpBonus, .trainingSpeed:
            return "\(Int(value * 100))%"
        case .returnSpeed, .objectiveCompletion, .mysteriousStranger:
            return "×\(value)"
        }
    }

    public init(type: PetBonusType, rarity: ItemRarity) {
        self.type = type
        self.rarity = rarity
    }
}

/// A pet that provides passive bonuses to a dweller.
public struct Pet: Identifiable, Codable, Sendable, Equatable {
    /// Unique identifier
    public let id: UUID

    /// Pet name
    public var name: String

    /// Species type
    public let species: PetSpecies

    /// Rarity level
    public let rarity: ItemRarity

    /// Bonus provided
    public let bonus: PetBonusValue

    /// Create a new pet
    public init(
        id: UUID = UUID(),
        name: String,
        species: PetSpecies,
        rarity: ItemRarity,
        bonusType: PetBonusType
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.rarity = rarity
        self.bonus = PetBonusValue(type: bonusType, rarity: rarity)
    }

    /// Display description
    public var description: String {
        "\(rarity.emoji) \(name) \(species.emoji) (\(bonus.type.emoji) \(bonus.displayValue))"
    }
}

// MARK: - Pet Generation

public extension Pet {
    /// Generate a random pet of specific rarity
    static func random(rarity: ItemRarity) -> Pet {
        let species: PetSpecies
        if rarity == .legendary && Bool.random() {
            species = .deathclaw
        } else {
            let commonSpecies: [PetSpecies] = [.dog, .cat, .parrot]
            species = commonSpecies.randomElement() ?? .dog
        }

        let bonusType = PetBonusType.allCases.randomElement() ?? .damage
        let name = generatePetName(species: species)

        return Pet(name: name, species: species, rarity: rarity, bonusType: bonusType)
    }

    /// Generate a name for a pet
    private static func generatePetName(species: PetSpecies) -> String {
        let dogNames = ["Rex", "Max", "Buddy", "Duke", "Rocky", "Bear", "Tucker", "Jack", "Dogmeat", "Fido"]
        let catNames = ["Whiskers", "Shadow", "Luna", "Mittens", "Tiger", "Smokey", "Patches", "Felix"]
        let parrotNames = ["Polly", "Rio", "Mango", "Kiwi", "Sky", "Sunny", "Pepper", "Tweety"]
        let exoticNames = ["Spike", "Nibbles", "Chomps", "Tiny", "Fang", "Scales", "Claw"]

        switch species {
        case .dog: return dogNames.randomElement() ?? "Dog"
        case .cat: return catNames.randomElement() ?? "Cat"
        case .parrot: return parrotNames.randomElement() ?? "Bird"
        case .deathclaw, .radroach, .moleRat: return exoticNames.randomElement() ?? "Pet"
        }
    }
}
