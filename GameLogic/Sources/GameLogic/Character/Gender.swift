//
//  Gender.swift
//  GameLogic
//
//  Dweller gender for breeding mechanics
//

import Foundation

/// Dweller gender, used for breeding mechanics.
public enum Gender: String, CaseIterable, Codable, Sendable {
    case male
    case female

    /// Display name
    public var name: String {
        rawValue.capitalized
    }

    /// Emoji representation
    public var emoji: String {
        switch self {
        case .male: return "👨"
        case .female: return "👩"
        }
    }

    /// Random gender (50/50)
    public static var random: Gender {
        Bool.random() ? .male : .female
    }
}
