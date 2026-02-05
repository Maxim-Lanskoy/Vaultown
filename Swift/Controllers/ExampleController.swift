//
//  ExampleController.swift
//  Vaultown
//
//  Example template controller for Telegram bot interactions
//
//  Created by Maxim Lanskoy on 29.01.2026.
//

import Foundation
import Lingo
import SwiftTelegramBot

// MARK: - Main Controller Logic
final class ExampleController: TGControllerBase, @unchecked Sendable {
    typealias T = ExampleController
        
    // MARK: - Controller Lifecycle
    override public func attachHandlers(to bot: TGBot, lingo: Lingo) async {
        let router = Router(bot: bot) { router in
            router[Commands.start.command()]     = onStart
            router[Commands.settings.command()]  = onSettings
            router[Commands.vault.command()]     = onVault

            let cancelLocales = Commands.cancel.buttonsForAllLocales(lingo: lingo)
            for button in cancelLocales { router[button.text] = onCancel }

            let settingsLocales = Commands.settings.buttonsForAllLocales(lingo: lingo)
            for button in settingsLocales { router[button.text] = onSettings }

            let vaultLocales = Commands.vault.buttonsForAllLocales(lingo: lingo)
            for button in vaultLocales { router[button.text] = onVault }

            router.unmatched                     = unmatched
            router[.callback_query(data: nil)]   = ExampleController.onCallbackQuery
        }
        await processRouterForEachName(router)
    }
    
    public func onStart(context: Context) async throws -> Bool {
        try await showMainMenu(context: context)
        return true
    }
        
    private func onCancel(context: Context) async throws -> Bool {
        return try await onStart(context: context)
    }
    
    override func unmatched(context: Context) async throws -> Bool {
        guard try await super.unmatched(context: context) else { return false }
        return try await onStart(context: context)
    }
        
    private func onSettings(context: Context) async throws -> Bool {
        let settingsController = Controllers.settingsController
        try await settingsController.showSettingsMenu(context: context)
        context.session.routerName = settingsController.routerName
        try await context.session.saveAndCache(in: context.db)
        return true
    }

    private func onVault(context: Context) async throws -> Bool {
        let vaultController = Controllers.vaultController
        try await vaultController.showVaultMenu(context: context)
        context.session.routerName = vaultController.routerName
        try await context.session.saveAndCache(in: context.db)
        return true
    }
                
    public func showMainMenu(context: Context, text: String? = nil) async throws {
        let greeting = context.lingo.localize("greeting.message", locale: context.session.locale, interpolations: [
            "full-name": "\(context.session.firstName ?? context.session.name)"
        ])
        let text = text ??  """
        👋 \(greeting)!
        """
        let markup = generateControllerKB(session: context.session, lingo: context.lingo)
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }
    
    override public func generateControllerKB(session: User, lingo: Lingo) -> TGReplyMarkup? {
        let markup = TGReplyKeyboardMarkup(keyboard: [
            [ Commands.vault.button(for: session, lingo) ],
            [ Commands.settings.button(for: session, lingo) ]
        ], resizeKeyboard: true)
        return TGReplyMarkup.replyKeyboardMarkup(markup)
    }
    
    // MARK: - Custom Methods
}

// MARK: - Callback Queries Processing
extension ExampleController {
    static func onCallbackQuery(context: Context) async throws -> Bool {
        guard let query = context.update.callbackQuery else { return false }
        guard let message = query.message else { return false }
        let chatId = TGChatId.chat(message.chat.id)
        let deleteParams = TGDeleteMessageParams(chatId: chatId, messageId: message.messageId)
        try await context.bot.deleteMessage(params: deleteParams)
        return true
    }
}
