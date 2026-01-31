//
//  Dweller.swift
//  GameLogic
//
//  Core dweller model representing vault inhabitants
//

import Foundation

/// A vault dweller with stats, equipment, and state.
///
/// Dwellers are the core inhabitants of the vault. They can be assigned to rooms
/// for production, sent on exploration, or participate in quests.
public struct Dweller: Identifiable, Codable, Sendable, Equatable {
    /// Unique identifier
    public let id: UUID

    /// First name
    public var firstName: String

    /// Last name
    public var lastName: String

    /// Dweller gender (affects breeding)
    public let gender: Gender

    /// Dweller rarity (affects base SPECIAL total)
    public let rarity: DwellerRarity

    /// Base S.P.E.C.I.A.L. stats (without equipment bonuses)
    public var baseStats: AbilityScores

    /// Current level (1-50)
    public private(set) var level: Int

    /// Current experience points
    public private(set) var experience: Int

    /// Current hit points
    public var currentHP: Double

    /// Maximum hit points (calculated based on Endurance during leveling)
    public private(set) var maxHP: Double

    /// Radiation damage (reduces effective max HP)
    public var radiation: Double

    /// Happiness percentage (0-100)
    public var happiness: Double

    /// Whether the dweller is currently alive
    public var isAlive: Bool {
        currentHP > 0
    }

    /// Effective max HP after radiation
    public var effectiveMaxHP: Double {
        max(0, maxHP - radiation)
    }

    /// Full display name
    public var fullName: String {
        NameGenerator.fullName(firstName: firstName, lastName: lastName)
    }

    // MARK: - Initialization

    /// Create a new dweller with specified properties
    public init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        gender: Gender,
        rarity: DwellerRarity,
        baseStats: AbilityScores,
        level: Int = 1,
        experience: Int = 0,
        currentHP: Double? = nil,
        maxHP: Double? = nil,
        radiation: Double = 0,
        happiness: Double = 50
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.gender = gender
        self.rarity = rarity
        self.baseStats = baseStats
        self.level = max(1, min(Self.maxLevel, level))
        self.experience = max(0, experience)
        self.maxHP = maxHP ?? Self.baseStartingHP
        self.currentHP = currentHP ?? self.maxHP
        self.radiation = max(0, radiation)
        self.happiness = max(0, min(100, happiness))
    }

    // MARK: - Factory Methods

    /// Create a random common dweller
    public static func randomCommon(gender: Gender? = nil, locale: String = "en") -> Dweller {
        let dwellerGender = gender ?? Gender.random
        let name = NameGenerator.randomName(gender: dwellerGender, locale: locale)
        return Dweller(
            firstName: name.firstName,
            lastName: name.lastName,
            gender: dwellerGender,
            rarity: .common,
            baseStats: .randomCommon()
        )
    }

    /// Create a random rare dweller
    public static func randomRare(gender: Gender? = nil, locale: String = "en") -> Dweller {
        let dwellerGender = gender ?? Gender.random
        let name = NameGenerator.randomName(gender: dwellerGender, locale: locale)
        return Dweller(
            firstName: name.firstName,
            lastName: name.lastName,
            gender: dwellerGender,
            rarity: .rare,
            baseStats: .randomRare()
        )
    }

    /// Create a random legendary dweller (legendary names are international)
    public static func randomLegendary() -> Dweller {
        let legendary = NameGenerator.randomLegendaryName()
        return Dweller(
            firstName: legendary.firstName,
            lastName: legendary.lastName,
            gender: legendary.gender,
            rarity: .legendary,
            baseStats: .randomLegendary()
        )
    }
}

// MARK: - Leveling System

public extension Dweller {
    /// Maximum dweller level
    static let maxLevel: Int = 50

    /// Base starting HP for all dwellers
    static let baseStartingHP: Double = 105

    /// Calculate HP gained per level based on Endurance at time of level-up
    ///
    /// Formula: HP per level = 2.5 + (Endurance × 0.5)
    /// - E1: 3.0 HP/level → 252 HP at level 50
    /// - E10: 7.5 HP/level → 472.5 HP at level 50
    /// - E17: 11.0 HP/level → 644 HP at level 50 (maximum)
    static func hpPerLevel(endurance: Int) -> Double {
        2.5 + (Double(endurance) * 0.5)
    }

    /// Maximum possible HP (E17 throughout all leveling)
    static let maxPossibleHP: Double = 644

    /// XP required to reach a specific level
    static func xpForLevel(_ level: Int) -> Int {
        guard level > 1 else { return 0 }
        // Simple exponential curve
        return Int(pow(Double(level - 1), 2) * 100)
    }

    /// Check if dweller can level up
    var canLevelUp: Bool {
        level < Self.maxLevel && experience >= Self.xpForLevel(level + 1)
    }

    /// Level up the dweller (if possible)
    ///
    /// - Parameter effectiveEndurance: The dweller's current effective Endurance (base + outfit)
    /// - Returns: true if level up occurred
    @discardableResult
    mutating func levelUp(effectiveEndurance: Int) -> Bool {
        guard canLevelUp else { return false }

        level += 1
        let hpGain = Self.hpPerLevel(endurance: effectiveEndurance)
        maxHP += hpGain
        currentHP = min(currentHP + hpGain, effectiveMaxHP)

        return true
    }

    /// Add experience points
    mutating func addExperience(_ amount: Int) {
        experience += amount
    }
}

// MARK: - Health System

public extension Dweller {
    /// Heal the dweller by a percentage of max HP
    mutating func heal(percent: Double) {
        let healAmount = effectiveMaxHP * (percent / 100)
        currentHP = min(currentHP + healAmount, effectiveMaxHP)
    }

    /// Heal the dweller by a flat amount
    mutating func heal(amount: Double) {
        currentHP = min(currentHP + amount, effectiveMaxHP)
    }

    /// Take damage
    mutating func takeDamage(_ amount: Double) {
        currentHP = max(0, currentHP - amount)
    }

    /// Add radiation damage
    mutating func addRadiation(_ amount: Double) {
        radiation = min(radiation + amount, maxHP)
        // Radiation reduces effective max HP, so current HP might need adjustment
        if currentHP > effectiveMaxHP {
            currentHP = effectiveMaxHP
        }
    }

    /// Remove radiation damage (RadAway effect)
    mutating func removeRadiation(_ amount: Double) {
        radiation = max(0, radiation - amount)
    }

    /// Full heal and remove all radiation
    mutating func fullHeal() {
        radiation = 0
        currentHP = maxHP
    }
}

// MARK: - Revival System

public extension Dweller {
    /// Cost to revive this dweller in caps
    ///
    /// Formula: 100 + (Level - 1) × 20
    var revivalCost: Int {
        100 + (level - 1) * 20
    }

    /// Revive the dweller with full health
    mutating func revive() {
        guard !isAlive else { return }
        currentHP = effectiveMaxHP
    }
}

// MARK: - Happiness System

public extension Dweller {
    /// Happiness thresholds
    static let happinessMin: Double = 0
    static let happinessMax: Double = 100
    static let happinessWrongRoom: Double = 50
    static let happinessRightRoom: Double = 75

    /// Adjust happiness by an amount (clamped to 0-100)
    mutating func adjustHappiness(_ delta: Double) {
        happiness = max(Self.happinessMin, min(Self.happinessMax, happiness + delta))
    }

    /// Set happiness to specific value (clamped to 0-100)
    mutating func setHappiness(_ value: Double) {
        happiness = max(Self.happinessMin, min(Self.happinessMax, value))
    }
}

// MARK: - Display

public extension Dweller {
    /// Short status description for Telegram
    var statusDescription: String {
        let healthPercent = Int((currentHP / maxHP) * 100)
        let hpBar = healthBar(segments: 5)
        return "\(rarity.emoji) \(fullName) Lv.\(level) \(hpBar) \(healthPercent)%"
    }

    /// Generate a simple health bar
    func healthBar(segments: Int) -> String {
        let filledCount = Int((currentHP / maxHP) * Double(segments))
        let filled = String(repeating: "█", count: filledCount)
        let empty = String(repeating: "░", count: segments - filledCount)
        return "[\(filled)\(empty)]"
    }

    /// Detailed stats display for Telegram
    var detailedDescription: String {
        """
        \(rarity.emoji) \(fullName) \(gender.emoji)
        Level: \(level)/\(Self.maxLevel)
        HP: \(Int(currentHP))/\(Int(maxHP)) \(radiation > 0 ? "(☢️\(Int(radiation)))" : "")
        Happiness: \(Int(happiness))%

        \(baseStats.emojiDescription)
        Total SPECIAL: \(baseStats.total)
        """
    }
}
