//
//  ItemRarity.swift
//  GameLogic
//
//  Rarity levels for equipment items
//

import Foundation

/// Rarity classification for equipment (weapons, outfits, pets).
public enum ItemRarity: String, CaseIterable, Codable, Sendable, Comparable {
    case common
    case rare
    case legendary

    /// Display name
    public var name: String {
        rawValue.capitalized
    }

    /// Emoji indicator
    public var emoji: String {
        switch self {
        case .common: return "⚪"
        case .rare: return "🔵"
        case .legendary: return "⭐"
        }
    }

    /// Workshop level required to craft this rarity
    public var requiredWorkshopLevel: Int {
        switch self {
        case .common: return 1
        case .rare: return 2
        case .legendary: return 3
        }
    }

    /// Comparable conformance for sorting
    public static func < (lhs: ItemRarity, rhs: ItemRarity) -> Bool {
        let order: [ItemRarity] = [.common, .rare, .legendary]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}
