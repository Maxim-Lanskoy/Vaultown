//
//  GameLogic.swift
//  GameLogic
//
//  Main module file - shared game mechanics for Vaultown
//  This provides a shared game logic layer for both Telegram Bot and SwiftGodot versions
//

import Foundation

// MARK: - Game Info

/// Game version
public let gameVersion = "0.1.0"

/// Game title
public let gameTitle = "Vaultown"

// MARK: - Re-exports

// Character System
// - SPECIAL: The seven stats (Strength, Perception, Endurance, Charisma, Intelligence, Agility, Luck)
// - AbilityScores: Container for all SPECIAL stats with validation
// - DwellerRarity: Common (12 pts), Rare (28 pts), Legendary (40 pts)
// - Gender: Male/Female for breeding mechanics
// - NameGenerator: Random name generation from predefined pools
