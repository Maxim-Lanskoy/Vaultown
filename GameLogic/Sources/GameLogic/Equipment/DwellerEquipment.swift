//
//  DwellerEquipment.swift
//  GameLogic
//
//  Equipment loadout for a dweller
//

import Foundation

/// Complete equipment loadout for a dweller.
///
/// Each dweller has three equipment slots:
/// - Weapon: Provides combat damage
/// - Outfit: Provides SPECIAL stat bonuses
/// - Pet: Provides passive bonuses
public struct DwellerEquipment: Codable, Sendable, Equatable {
    /// Equipped weapon (optional)
    public var weapon: Weapon?

    /// Equipped outfit (optional)
    public var outfit: Outfit?

    /// Equipped pet (optional)
    public var pet: Pet?

    /// Create empty equipment
    public init(weapon: Weapon? = nil, outfit: Outfit? = nil, pet: Pet? = nil) {
        self.weapon = weapon
        self.outfit = outfit
        self.pet = pet
    }

    /// Total SPECIAL bonuses from outfit
    public var statBonuses: StatBonuses {
        outfit?.bonuses ?? .none
    }

    /// Get effective stat (base + equipment bonus)
    public func effectiveStat(_ stat: SPECIAL, base: Int) -> Int {
        let bonus = statBonuses.bonus(for: stat)
        return min(base + bonus, SPECIAL.maxTotalValue)
    }

    /// Weapon damage range, or unarmed (0-0)
    public var damageRange: (min: Int, max: Int) {
        if let weapon = weapon {
            return (weapon.minDamage, weapon.maxDamage)
        }
        return (0, 0) // Unarmed
    }

    /// Roll weapon damage plus pet bonus
    public func rollDamage() -> Int {
        let weaponDamage = weapon?.rollDamage() ?? 0
        let petBonus: Int
        if let pet = pet, pet.bonus.type == .damage {
            petBonus = Int(pet.bonus.value)
        } else {
            petBonus = 0
        }
        return weaponDamage + petBonus
    }

    /// Check if any equipment is present
    public var hasEquipment: Bool {
        weapon != nil || outfit != nil || pet != nil
    }

    /// Number of equipped items
    public var equippedCount: Int {
        var count = 0
        if weapon != nil { count += 1 }
        if outfit != nil { count += 1 }
        if pet != nil { count += 1 }
        return count
    }
}

// MARK: - Display

public extension DwellerEquipment {
    /// Short equipment summary for Telegram
    var summary: String {
        var parts: [String] = []

        if let weapon = weapon {
            parts.append("🔫 \(weapon.name) (\(weapon.damageRange))")
        }
        if let outfit = outfit {
            parts.append("👔 \(outfit.name) (\(outfit.bonuses.shortDescription))")
        }
        if let pet = pet {
            parts.append("\(pet.species.emoji) \(pet.name)")
        }

        return parts.isEmpty ? "No equipment" : parts.joined(separator: "\n")
    }
}
