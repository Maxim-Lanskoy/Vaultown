//
//  DwellerRarity.swift
//  GameLogic
//
//  Dweller rarity levels and their properties
//

import Foundation

/// Rarity classification for dwellers.
///
/// Rarity determines the total S.P.E.C.I.A.L. points a dweller has
/// and affects starting equipment for legendary dwellers.
public enum DwellerRarity: String, CaseIterable, Codable, Sendable {
    case common
    case rare
    case legendary

    /// Total S.P.E.C.I.A.L. points for this rarity
    public var specialTotal: Int {
        switch self {
        case .common: return 12
        case .rare: return 28
        case .legendary: return 40
        }
    }

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

    /// Color name for display
    public var colorName: String {
        switch self {
        case .common: return "white"
        case .rare: return "blue"
        case .legendary: return "gold"
        }
    }
}

// MARK: - Breeding Rarity Calculation

public extension DwellerRarity {
    /// Calculate child rarity based on parents' total SPECIAL.
    ///
    /// Formula from GDD:
    /// ```
    /// max = (parent1_total + parent2_total - 14) / 126
    /// random = random(max/4, max)
    /// if random > 0.95: LEGENDARY
    /// if random > 0.85: RARE
    /// else: COMMON
    /// ```
    ///
    /// With both parents at 70 total (all 10s): ~6.6% legendary, ~13.3% rare
    static func forChild(parent1Total: Int, parent2Total: Int) -> DwellerRarity {
        let combinedTotal = parent1Total + parent2Total
        let maxValue = Double(combinedTotal - 14) / 126.0
        let minValue = maxValue / 4.0
        let roll = Double.random(in: minValue...max(minValue, maxValue))

        if roll > 0.95 {
            return .legendary
        } else if roll > 0.85 {
            return .rare
        } else {
            return .common
        }
    }
}
