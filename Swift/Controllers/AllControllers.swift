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
    static let registration             = Registration              (routerName: "registration")
    static let settingsController       = SettingsController        (routerName: "settings")
    static let vaultController          = VaultController           (routerName: "vault")
    static let buildController          = BuildController           (routerName: "build")

    static let all: [TGControllerBase] = [
        registration,
        settingsController,
        vaultController,
        buildController
    ]

    static func attachAllHandlers(for bot: TGBot, lingo: Lingo) async {
        for controller in all {
            await controller.attachHandlers(to: bot, lingo: lingo)
        }
    }
}
