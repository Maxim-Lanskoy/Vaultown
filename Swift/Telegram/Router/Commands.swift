//
//  Commands.swift
//  Vaultown
//
//  Created by Maxim Lanskoy on 13.06.2025.
//

import Foundation
import Lingo
import SwiftTelegramBot

enum Commands: String, Codable, CaseIterable {

    // Navigation
    case start = "commands.start"
    case cancel = "commands.cancel"
    case exit = "commands.exit"
    case settings = "commands.settings"
    case language = "commands.language"

    // Vault
    case vault = "commands.vault"
    case dwellers = "commands.dwellers"
    case resources = "commands.resources"
    case build = "commands.build"
    case rooms = "commands.rooms"
    case assign = "commands.assign"
    case explore = "commands.explore"
    case recall = "commands.recall"
    case incidents = "commands.incidents"
    case fight = "commands.fight"
    
    func button(for session: User, _ lingo: Lingo) -> TGKeyboardButton {
        let startText = lingo.localize(self.rawValue, locale: session.locale)
        return TGKeyboardButton(text: "\(startText)")
    }
    
    func buttonsForAllLocales(lingo: Lingo) -> [TGKeyboardButton] {
        var buttons: [TGKeyboardButton] = []
        for locale in SupportedLocale.allCases {
            let localizedText = lingo.localize(self.rawValue, locale: locale)
            buttons.append(TGKeyboardButton(text: localizedText))
        }
        return buttons
    }
    
    func command() -> String {
        return self.rawValue.replacingOccurrences(of: "commands.", with: "")
    }
    
    func defaultButton(lingo: Lingo) -> TGKeyboardButton {
        let localizedText = lingo.localize(self.rawValue, locale: "en")
        return TGKeyboardButton(text: localizedText)
    }
}
