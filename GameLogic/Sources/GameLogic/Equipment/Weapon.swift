//
//  Weapon.swift
//  GameLogic
//
//  Weapon equipment for dwellers
//

import Foundation

/// Type of weapon
public enum WeaponType: String, CaseIterable, Codable, Sendable {
    case pistol
    case rifle
    case shotgun
    case energy
    case heavy
    case melee

    /// Display name
    public var name: String {
        rawValue.capitalized
    }

    /// Emoji representation
    public var emoji: String {
        switch self {
        case .pistol: return "🔫"
        case .rifle: return "🎯"
        case .shotgun: return "💥"
        case .energy: return "⚡"
        case .heavy: return "💣"
        case .melee: return "🗡️"
        }
    }
}

/// Weapon behavior in combat
public enum WeaponBehavior: String, Codable, Sendable {
    /// Hits single target, overkill damage wasted
    case singleShot
    /// Excess damage transfers to next target
    case multiShot
    /// Damage split among all enemies
    case aoe

    /// Display description
    public var description: String {
        switch self {
        case .singleShot: return "Single target"
        case .multiShot: return "Multi-shot (damage carries over)"
        case .aoe: return "Area of effect"
        }
    }
}

/// A weapon that can be equipped by a dweller.
public struct Weapon: Identifiable, Codable, Sendable, Equatable {
    /// Unique identifier
    public let id: UUID

    /// Weapon name
    public let name: String

    /// Weapon type
    public let type: WeaponType

    /// Rarity level
    public let rarity: ItemRarity

    /// Minimum damage
    public let minDamage: Int

    /// Maximum damage
    public let maxDamage: Int

    /// Combat behavior
    public let behavior: WeaponBehavior

    /// Average damage
    public var averageDamage: Double {
        Double(minDamage + maxDamage) / 2.0
    }

    /// Damage range string for display
    public var damageRange: String {
        "\(minDamage)-\(maxDamage)"
    }

    /// Create a new weapon
    public init(
        id: UUID = UUID(),
        name: String,
        type: WeaponType,
        rarity: ItemRarity,
        minDamage: Int,
        maxDamage: Int,
        behavior: WeaponBehavior = .singleShot
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.rarity = rarity
        self.minDamage = minDamage
        self.maxDamage = maxDamage
        self.behavior = behavior
    }

    /// Roll damage for an attack
    public func rollDamage() -> Int {
        Int.random(in: minDamage...maxDamage)
    }

    /// Display description
    public var description: String {
        "\(rarity.emoji) \(name) (\(damageRange) \(type.emoji))"
    }
}

// MARK: - Weapon Database

public extension Weapon {
    /// Common weapons (0-7 damage range)
    static let commonWeapons: [Weapon] = [
        Weapon(name: "Rusty BB Gun", type: .pistol, rarity: .common, minDamage: 0, maxDamage: 1),
        Weapon(name: "BB Gun", type: .pistol, rarity: .common, minDamage: 0, maxDamage: 2),
        Weapon(name: "Rusty .32 Pistol", type: .pistol, rarity: .common, minDamage: 1, maxDamage: 2),
        Weapon(name: ".32 Pistol", type: .pistol, rarity: .common, minDamage: 2, maxDamage: 3),
        Weapon(name: "Rusty Laser Pistol", type: .energy, rarity: .common, minDamage: 2, maxDamage: 3),
        Weapon(name: "Laser Pistol", type: .energy, rarity: .common, minDamage: 3, maxDamage: 4),
        Weapon(name: "Rusty 10mm Pistol", type: .pistol, rarity: .common, minDamage: 3, maxDamage: 4),
        Weapon(name: "10mm Pistol", type: .pistol, rarity: .common, minDamage: 4, maxDamage: 5),
        Weapon(name: "Rusty Hunting Rifle", type: .rifle, rarity: .common, minDamage: 4, maxDamage: 5),
        Weapon(name: "Hunting Rifle", type: .rifle, rarity: .common, minDamage: 5, maxDamage: 6),
        Weapon(name: "Rusty Sawed-Off Shotgun", type: .shotgun, rarity: .common, minDamage: 5, maxDamage: 6),
        Weapon(name: "Sawed-Off Shotgun", type: .shotgun, rarity: .common, minDamage: 6, maxDamage: 7),
    ]

    /// Rare weapons (7-18 damage range)
    static let rareWeapons: [Weapon] = [
        Weapon(name: "Enhanced .32 Pistol", type: .pistol, rarity: .rare, minDamage: 7, maxDamage: 8),
        Weapon(name: "Enhanced Laser Pistol", type: .energy, rarity: .rare, minDamage: 8, maxDamage: 9),
        Weapon(name: "Enhanced 10mm Pistol", type: .pistol, rarity: .rare, minDamage: 9, maxDamage: 10),
        Weapon(name: "Enhanced Hunting Rifle", type: .rifle, rarity: .rare, minDamage: 10, maxDamage: 11),
        Weapon(name: "Plasma Pistol", type: .energy, rarity: .rare, minDamage: 10, maxDamage: 11),
        Weapon(name: "Enhanced Sawed-Off Shotgun", type: .shotgun, rarity: .rare, minDamage: 11, maxDamage: 12),
        Weapon(name: "Enhanced Plasma Pistol", type: .energy, rarity: .rare, minDamage: 11, maxDamage: 12),
        Weapon(name: "Laser Rifle", type: .energy, rarity: .rare, minDamage: 12, maxDamage: 13),
        Weapon(name: "Combat Shotgun", type: .shotgun, rarity: .rare, minDamage: 13, maxDamage: 14),
        Weapon(name: "Assault Rifle", type: .rifle, rarity: .rare, minDamage: 13, maxDamage: 14),
        Weapon(name: "Enhanced Laser Rifle", type: .energy, rarity: .rare, minDamage: 14, maxDamage: 15),
        Weapon(name: "Minigun", type: .heavy, rarity: .rare, minDamage: 14, maxDamage: 15, behavior: .multiShot),
        Weapon(name: "Flamer", type: .heavy, rarity: .rare, minDamage: 15, maxDamage: 17),
        Weapon(name: "Gatling Laser", type: .energy, rarity: .rare, minDamage: 16, maxDamage: 17, behavior: .multiShot),
        Weapon(name: "Plasma Rifle", type: .energy, rarity: .rare, minDamage: 17, maxDamage: 18),
    ]

    /// Legendary weapons (high damage range)
    static let legendaryWeapons: [Weapon] = [
        Weapon(name: "Blackhawk", type: .pistol, rarity: .legendary, minDamage: 3, maxDamage: 8),
        Weapon(name: "Wild Bill's Sidearm", type: .pistol, rarity: .legendary, minDamage: 5, maxDamage: 11),
        Weapon(name: "Ol' Painless", type: .rifle, rarity: .legendary, minDamage: 8, maxDamage: 13),
        Weapon(name: "Lincoln's Repeater", type: .rifle, rarity: .legendary, minDamage: 10, maxDamage: 15),
        Weapon(name: "Miss Launcher", type: .heavy, rarity: .legendary, minDamage: 13, maxDamage: 18, behavior: .aoe),
        Weapon(name: "Burnmaster", type: .heavy, rarity: .legendary, minDamage: 14, maxDamage: 19),
        Weapon(name: "Virgil's Rifle", type: .energy, rarity: .legendary, minDamage: 15, maxDamage: 21),
        Weapon(name: "Destabilizer", type: .energy, rarity: .legendary, minDamage: 17, maxDamage: 22),
        Weapon(name: "Wazer Wifle", type: .energy, rarity: .legendary, minDamage: 17, maxDamage: 22),
        Weapon(name: "Mean Green Monster", type: .heavy, rarity: .legendary, minDamage: 17, maxDamage: 23, behavior: .multiShot),
        Weapon(name: "Lead Belcher", type: .heavy, rarity: .legendary, minDamage: 18, maxDamage: 25, behavior: .multiShot),
        Weapon(name: "Technician's Revenge", type: .energy, rarity: .legendary, minDamage: 19, maxDamage: 24),
        Weapon(name: "Hardened Fatman", type: .heavy, rarity: .legendary, minDamage: 19, maxDamage: 24, behavior: .aoe),
        Weapon(name: "Fire Hydrant Bat", type: .melee, rarity: .legendary, minDamage: 19, maxDamage: 31),
        Weapon(name: "Relentless Raider Sword", type: .melee, rarity: .legendary, minDamage: 19, maxDamage: 25),
        Weapon(name: "Vengeance", type: .heavy, rarity: .legendary, minDamage: 21, maxDamage: 26, behavior: .multiShot),
        Weapon(name: "MIRV", type: .heavy, rarity: .legendary, minDamage: 22, maxDamage: 27, behavior: .aoe),
        Weapon(name: "Plasma Thrower", type: .energy, rarity: .legendary, minDamage: 21, maxDamage: 27),
        Weapon(name: "Dragon's Maw", type: .heavy, rarity: .legendary, minDamage: 22, maxDamage: 29),
    ]

    /// All weapons
    static let allWeapons: [Weapon] = commonWeapons + rareWeapons + legendaryWeapons

    /// Get a random weapon of specific rarity
    static func random(rarity: ItemRarity) -> Weapon? {
        switch rarity {
        case .common: return commonWeapons.randomElement()
        case .rare: return rareWeapons.randomElement()
        case .legendary: return legendaryWeapons.randomElement()
        }
    }
}
