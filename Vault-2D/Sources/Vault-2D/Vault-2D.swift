// Vault-2D.swift
// Vault-2D - SwiftGodot version of Vaultown game
// Entry point and class registration

import SwiftGodot
import GameLogic

/// GDExtension entry point
/// This registers all Swift classes with Godot
#initSwiftExtension(
    cdecl: "swift_entry_point",
    types: [
        // Core game scenes
        GameMain.self,
        GameWorld.self,
        GameUI.self,

        // TileMap with emoji labels
        EmojiTileMap.self,

        // Character creation UI
        CharacterCreationUI.self,

        // UI Components
        StatsPanel.self,
        ActionBar.self,
        MovementPad.self,
        SettingsPanel.self
    ]
)
