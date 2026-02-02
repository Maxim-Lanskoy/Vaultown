//
//  AllControllers.swift
//  Vaultown
//
//  Created by Maxim Lanskoy on 13.06.2025.
//

import Foundation
import Lingo
import SwiftTelegramBot

struct Controllers {
    // MARK: - Controllers initialization.
    // Only 3 controllers: Registration, Settings, and Vault (main game)
    static let registration         = Registration          (routerName: "registration")
    static let settingsController   = SettingsController    (routerName: "settings")
    static let vaultController      = VaultController       (routerName: "vault")

    static let all: [TGControllerBase] = [
        registration,
        settingsController,
        vaultController
    ]

    static func attachAllHandlers(for bot: TGBot, lingo: Lingo) async {
        for controller in all {
            await controller.attachHandlers(to: bot, lingo: lingo)
        }
    }
}
