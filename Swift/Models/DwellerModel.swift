//
//  DwellerModel.swift
//  Vaultown
//
//  Fluent model for vault dwellers with SPECIAL stats
//
//  Created by Maxim Lanskoy on 31.01.2026.
//

import Fluent
import Foundation
import GameLogic

/// Database model for a vault dweller
final public class DwellerModel: Model, @unchecked Sendable {
    public static let schema = "dwellers"

    @ID(key: .id)
    public var id: UUID?

    /// Reference to the owning vault
    @Parent(key: "vault_id")
    var vault: Vault

    /// First name
    @Field(key: "first_name")
    var firstName: String

    /// Last name
    @Field(key: "last_name")
    var lastName: String

    /// Gender (male/female)
    @Field(key: "gender")
    var gender: String

    /// Rarity (common/rare/legendary)
    @Field(key: "rarity")
    var rarity: String

    /// Current level (1-50)
    @Field(key: "level")
    var level: Int

    /// Current experience points
    @Field(key: "experience")
    var experience: Int

    /// Current HP
    @Field(key: "current_hp")
    var currentHP: Double

    /// Maximum HP
    @Field(key: "max_hp")
    var maxHP: Double

    /// Radiation damage
    @Field(key: "radiation")
    var radiation: Double

    /// Happiness (0-100)
    @Field(key: "happiness")
    var happiness: Double

    // SPECIAL Stats
    @Field(key: "strength")
    var strength: Int

    @Field(key: "perception")
    var perception: Int

    @Field(key: "endurance")
    var endurance: Int

    @Field(key: "charisma")
    var charisma: Int

    @Field(key: "intelligence")
    var intelligence: Int

    @Field(key: "agility")
    var agility: Int

    @Field(key: "luck")
    var luck: Int

    /// Assigned room (optional parent relationship)
    @OptionalParent(key: "assigned_room_id")
    var assignedRoom: RoomModel?

    /// Equipped weapon ID (optional)
    @OptionalField(key: "weapon_id")
    var weaponID: UUID?

    /// Equipped outfit ID (optional)
    @OptionalField(key: "outfit_id")
    var outfitID: UUID?

    /// Equipped pet ID (optional)
    @OptionalField(key: "pet_id")
    var petID: UUID?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    public init() {}

    /// Create from GameLogic Dweller
    init(vaultID: Vault.IDValue, dweller: Dweller) {
        self.$vault.id = vaultID
        self.firstName = dweller.firstName
        self.lastName = dweller.lastName
        self.gender = dweller.gender.rawValue
        self.rarity = dweller.rarity.rawValue
        self.level = dweller.level
        self.experience = dweller.experience
        self.currentHP = dweller.currentHP
        self.maxHP = dweller.maxHP
        self.radiation = dweller.radiation
        self.happiness = dweller.happiness
        self.strength = dweller.baseStats.strength
        self.perception = dweller.baseStats.perception
        self.endurance = dweller.baseStats.endurance
        self.charisma = dweller.baseStats.charisma
        self.intelligence = dweller.baseStats.intelligence
        self.agility = dweller.baseStats.agility
        self.luck = dweller.baseStats.luck
    }
}

// MARK: - GameLogic Integration

extension DwellerModel {
    /// Convert to GameLogic Dweller struct
    func toDweller() -> Dweller {
        let genderEnum = Gender(rawValue: gender) ?? .male
        let rarityEnum = DwellerRarity(rawValue: rarity) ?? .common

        return Dweller(
            id: id ?? UUID(),
            firstName: firstName,
            lastName: lastName,
            gender: genderEnum,
            rarity: rarityEnum,
            baseStats: AbilityScores(
                strength: strength,
                perception: perception,
                endurance: endurance,
                charisma: charisma,
                intelligence: intelligence,
                agility: agility,
                luck: luck
            ),
            level: level,
            experience: experience,
            currentHP: currentHP,
            maxHP: maxHP,
            radiation: radiation,
            happiness: happiness
        )
    }

    /// Update from GameLogic Dweller struct
    func update(from dweller: Dweller) {
        self.firstName = dweller.firstName
        self.lastName = dweller.lastName
        self.level = dweller.level
        self.experience = dweller.experience
        self.currentHP = dweller.currentHP
        self.maxHP = dweller.maxHP
        self.radiation = dweller.radiation
        self.happiness = dweller.happiness
        self.strength = dweller.baseStats.strength
        self.perception = dweller.baseStats.perception
        self.endurance = dweller.baseStats.endurance
        self.charisma = dweller.baseStats.charisma
        self.intelligence = dweller.baseStats.intelligence
        self.agility = dweller.baseStats.agility
        self.luck = dweller.baseStats.luck
    }

    /// Create a random dweller for a vault
    static func createRandom(vaultID: Vault.IDValue, rarity: DwellerRarity = .common, locale: String = "en") -> DwellerModel {
        let dweller: Dweller
        switch rarity {
        case .common:
            dweller = Dweller.randomCommon(locale: locale)
        case .rare:
            dweller = Dweller.randomRare(locale: locale)
        case .legendary:
            dweller = Dweller.randomLegendary()
        }
        return DwellerModel(vaultID: vaultID, dweller: dweller)
    }

    /// Create the player's dweller with custom name (from nickname)
    static func createPlayerDweller(vaultID: Vault.IDValue, nickname: String, rarity: DwellerRarity = .common) -> DwellerModel {
        // Parse nickname into first/last name (supports 1-2 words)
        let parts = nickname.trimmingCharacters(in: .whitespaces).split(separator: " ", maxSplits: 1)
        let firstName = String(parts.first ?? "Player")
        let lastName = parts.count > 1 ? String(parts[1]) : ""

        // Create base stats for the rarity
        let baseStats: AbilityScores
        switch rarity {
        case .common:
            baseStats = .randomCommon()
        case .rare:
            baseStats = .randomRare()
        case .legendary:
            baseStats = .randomLegendary()
        }

        let dweller = Dweller(
            firstName: firstName,
            lastName: lastName,
            gender: Gender.random,
            rarity: rarity,
            baseStats: baseStats
        )
        return DwellerModel(vaultID: vaultID, dweller: dweller)
    }
}

// MARK: - Display

extension DwellerModel {
    /// Full name
    var fullName: String {
        if lastName.isEmpty {
            return firstName
        }
        return "\(firstName) \(lastName)"
    }

    /// Rarity emoji
    var rarityEmoji: String {
        (DwellerRarity(rawValue: rarity) ?? .common).emoji
    }

    /// Gender emoji
    var genderEmoji: String {
        (Gender(rawValue: gender) ?? .male).emoji
    }

    /// Short status for list display
    func shortStatus(levelLabel: String) -> String {
        let healthPct = Int((currentHP / maxHP) * 100)
        return "\(rarityEmoji) \(fullName) \(levelLabel) \(level) ❤️\(healthPct)%"
    }

    /// SPECIAL stats display
    var specialDisplay: String {
        "💪\(strength) 👁\(perception) ❤️\(endurance) 💬\(charisma) 🧠\(intelligence) ⚡\(agility) 🍀\(luck)"
    }

    /// Localized detailed display for Telegram
    func localizedDetailedDisplay(
        levelLabel: String,
        hpLabel: String,
        happinessLabel: String,
        totalLabel: String,
        rarityName: String
    ) -> String {
        let genderStr = (Gender(rawValue: gender) ?? .male).emoji

        return """
        \(rarityEmoji) \(fullName) \(genderStr)
        \(levelLabel): \(level)/50 | \(rarityName)
        \(hpLabel): \(Int(currentHP))/\(Int(maxHP))\(radiation > 0 ? " (☢️\(Int(radiation)))" : "")
        \(happinessLabel): \(Int(happiness))%

        \(specialDisplay)
        \(totalLabel): \(strength + perception + endurance + charisma + intelligence + agility + luck)
        """
    }
}
