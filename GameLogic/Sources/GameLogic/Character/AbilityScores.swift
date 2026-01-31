//
//  AbilityScores.swift
//  GameLogic
//
//  Container for all S.P.E.C.I.A.L. stats
//

import Foundation

/// Container for all seven S.P.E.C.I.A.L. stats.
///
/// Base stats are capped at 10 (trainable maximum).
/// With outfit bonuses, effective stats can reach 17.
public struct AbilityScores: Codable, Sendable, Equatable {
    /// Base stat values (1-10)
    public private(set) var strength: Int
    public private(set) var perception: Int
    public private(set) var endurance: Int
    public private(set) var charisma: Int
    public private(set) var intelligence: Int
    public private(set) var agility: Int
    public private(set) var luck: Int

    /// Creates ability scores with specified values.
    /// Values are clamped to valid range (1-10).
    public init(
        strength: Int = 1,
        perception: Int = 1,
        endurance: Int = 1,
        charisma: Int = 1,
        intelligence: Int = 1,
        agility: Int = 1,
        luck: Int = 1
    ) {
        self.strength = Self.clampBase(strength)
        self.perception = Self.clampBase(perception)
        self.endurance = Self.clampBase(endurance)
        self.charisma = Self.clampBase(charisma)
        self.intelligence = Self.clampBase(intelligence)
        self.agility = Self.clampBase(agility)
        self.luck = Self.clampBase(luck)
    }

    /// Clamp a value to valid base stat range
    private static func clampBase(_ value: Int) -> Int {
        max(SPECIAL.minValue, min(SPECIAL.maxBaseValue, value))
    }

    /// Get base stat value for a specific SPECIAL
    public func base(_ stat: SPECIAL) -> Int {
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

    /// Set base stat value for a specific SPECIAL
    public mutating func setBase(_ stat: SPECIAL, value: Int) {
        let clamped = Self.clampBase(value)
        switch stat {
        case .strength: strength = clamped
        case .perception: perception = clamped
        case .endurance: endurance = clamped
        case .charisma: charisma = clamped
        case .intelligence: intelligence = clamped
        case .agility: agility = clamped
        case .luck: luck = clamped
        }
    }

    /// Increase a stat by 1 (for training completion)
    /// Returns true if stat was increased, false if already at max
    @discardableResult
    public mutating func train(_ stat: SPECIAL) -> Bool {
        let current = base(stat)
        if current < SPECIAL.maxBaseValue {
            setBase(stat, value: current + 1)
            return true
        }
        return false
    }

    /// Total of all base stats
    public var total: Int {
        strength + perception + endurance + charisma + intelligence + agility + luck
    }

    /// Check if all stats are at maximum base value
    public var isMaxed: Bool {
        SPECIAL.allCases.allSatisfy { base($0) == SPECIAL.maxBaseValue }
    }
}

// MARK: - Factory Methods

public extension AbilityScores {
    /// Creates random ability scores for a common dweller (total ~12 points)
    static func randomCommon() -> AbilityScores {
        generateRandom(targetTotal: DwellerRarity.common.specialTotal)
    }

    /// Creates random ability scores for a rare dweller (total 28 points)
    static func randomRare() -> AbilityScores {
        generateRandom(targetTotal: DwellerRarity.rare.specialTotal)
    }

    /// Creates random ability scores for a legendary dweller (total 40 points)
    static func randomLegendary() -> AbilityScores {
        generateRandom(targetTotal: DwellerRarity.legendary.specialTotal)
    }

    /// Generate random stats with approximate target total
    private static func generateRandom(targetTotal: Int) -> AbilityScores {
        let statCount = SPECIAL.allCases.count
        let basePerStat = targetTotal / statCount
        let remainder = targetTotal % statCount

        var stats: [Int] = Array(repeating: basePerStat, count: statCount)

        // Distribute remainder randomly
        var remainingPoints = remainder
        while remainingPoints > 0 {
            let index = Int.random(in: 0..<statCount)
            if stats[index] < SPECIAL.maxBaseValue {
                stats[index] += 1
                remainingPoints -= 1
            }
        }

        // Add some variance (shift points between stats)
        for _ in 0..<3 {
            let from = Int.random(in: 0..<statCount)
            let to = Int.random(in: 0..<statCount)
            if from != to && stats[from] > SPECIAL.minValue && stats[to] < SPECIAL.maxBaseValue {
                stats[from] -= 1
                stats[to] += 1
            }
        }

        return AbilityScores(
            strength: stats[0],
            perception: stats[1],
            endurance: stats[2],
            charisma: stats[3],
            intelligence: stats[4],
            agility: stats[5],
            luck: stats[6]
        )
    }

    /// Creates all stats at minimum value
    static var minimum: AbilityScores {
        AbilityScores()
    }

    /// Creates all stats at maximum base value
    static var maximum: AbilityScores {
        AbilityScores(
            strength: SPECIAL.maxBaseValue,
            perception: SPECIAL.maxBaseValue,
            endurance: SPECIAL.maxBaseValue,
            charisma: SPECIAL.maxBaseValue,
            intelligence: SPECIAL.maxBaseValue,
            agility: SPECIAL.maxBaseValue,
            luck: SPECIAL.maxBaseValue
        )
    }
}

// MARK: - Display

public extension AbilityScores {
    /// Short format: S1 P2 E3 C4 I5 A6 L7
    var shortDescription: String {
        SPECIAL.allCases.map { "\($0.rawValue)\(base($0))" }.joined(separator: " ")
    }

    /// Emoji format for Telegram: 💪1 👁2 ❤️3 💬4 🧠5 ⚡6 🍀7
    var emojiDescription: String {
        SPECIAL.allCases.map { "\($0.emoji)\(base($0))" }.joined(separator: " ")
    }
}
