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
    static let mainController           = MainController            (routerName: "main")
    static let settingsController       = SettingsController        (routerName: "settings")

    static let all: [TGControllerBase] = [
        registration,
        mainController,
        settingsController
    ]

    static func attachAllHandlers(for bot: TGBot, lingo: Lingo) async {
        for controller in all {
            await controller.attachHandlers(to: bot, lingo: lingo)
        }
    }
}
