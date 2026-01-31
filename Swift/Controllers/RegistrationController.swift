//
//  RegistrationController.swift
//  Vaultown
//
//  Created by Maxim Lanskoy on 13.06.2025.
//

import Foundation
import Lingo
import SwiftTelegramBot

/// Registration state for multi-step registration
enum RegistrationState: String {
    case selectLanguage = "select_language"
    case enterNickname = "enter_nickname"
}

// MARK: - Registration Controller Logic
final class Registration: TGControllerBase, @unchecked Sendable {
    typealias T = Registration

    /// Validate nickname: only latin and cyrillic letters, 1-2 words, no symbols/emojis/numbers
    /// Pattern: one or two words with only letters (latin a-z, A-Z or cyrillic а-яА-ЯіІїЇєЄґҐёЁ)
    static let nicknamePattern = "^[a-zA-Zа-яА-ЯіІїЇєЄґҐёЁ]+( [a-zA-Zа-яА-ЯіІїЇєЄґҐёЁ]+)?$"

    static func isValidNickname(_ nickname: String) -> Bool {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count >= 2, trimmed.count <= 32 else {
            return false
        }
        guard let regex = try? NSRegularExpression(pattern: nicknamePattern, options: []) else {
            return false
        }
        let range = NSRange(location: 0, length: trimmed.utf16.count)
        return regex.firstMatch(in: trimmed, options: [], range: range) != nil
    }

    // MARK: - Controller Lifecycle
    override public func attachHandlers(to bot: TGBot, lingo: Lingo) async {
        let router = Router(bot: bot) { router in
            router[Commands.start.command()] = onStart
            router.unmatched = onNicknameInput
            router[.callback_query(data: nil)] = Registration.onCallbackQuery
        }
        await processRouterForEachName(router)
    }

    public func onStart(context: Context) async throws -> Bool {
        // Check if user already has nickname - go directly to vault
        if let nickname = context.session.nickname, !nickname.isEmpty {
            let vaultController = Controllers.vaultController
            try await vaultController.showVaultMenu(context: context)
            context.session.routerName = vaultController.routerName
            try await context.session.saveAndCache(in: context.db)
            return true
        }

        // Show language selection
        try await showLanguageSelection(context: context)
        return true
    }

    private func showLanguageSelection(context: Context) async throws {
        let greeting = context.lingo.localize("registration.welcome", locale: "en")
        var message = "👋 \(greeting)\n"

        var inlineKeyboard: [[TGInlineKeyboardButton]] = []
        for locale in SupportedLocale.allCases {
            message.append("\n- \(context.lingo.localize("registration.select.language", locale: locale.rawValue))")
            let langName = context.lingo.localize("lang.name", locale: locale.rawValue)
            let button = TGInlineKeyboardButton(
                text: "\(locale.flag()) \(langName)",
                callbackData: "set_lang:\(locale.rawValue)"
            )
            inlineKeyboard.append([button])
        }

        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: message, parseMode: .html, replyMarkup: markup)
    }

    private func showNicknamePrompt(context: Context) async throws {
        let prompt = context.lingo.localize("registration.nickname.prompt", locale: context.session.locale)
        let rules = context.lingo.localize("registration.nickname.rules", locale: context.session.locale)

        let text = """
        📝 <b>\(prompt)</b>

        \(rules)
        """

        let markup = TGReplyMarkup.replyKeyboardRemove(TGReplyKeyboardRemove(removeKeyboard: true))
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }

    private func onNicknameInput(context: Context) async throws -> Bool {
        // Check if we're expecting nickname input
        guard context.session.nickname == nil || context.session.nickname?.isEmpty == true else {
            return try await onStart(context: context)
        }

        guard let messageText = context.update.message?.text else {
            try await showNicknamePrompt(context: context)
            return true
        }

        let nickname = messageText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate nickname
        guard Registration.isValidNickname(nickname) else {
            let error = context.lingo.localize("registration.nickname.invalid", locale: context.session.locale)
            try await context.bot.sendMessage(session: context.session, text: "❌ \(error)", parseMode: .html)
            try await showNicknamePrompt(context: context)
            return true
        }

        // Save nickname and complete registration
        context.session.nickname = nickname
        let vaultController = Controllers.vaultController
        context.session.routerName = vaultController.routerName
        try await context.session.saveAndCache(in: context.db)

        // Show success message and vault menu
        let success = context.lingo.localize("registration.nickname.success", locale: context.session.locale, interpolations: [
            "nickname": nickname
        ])
        try await context.bot.sendMessage(session: context.session, text: "✅ \(success)", parseMode: .html)
        try await vaultController.showVaultMenu(context: context)

        return true
    }

    override public func generateControllerKB(session: User, lingo: Lingo) -> TGReplyMarkup? {
        return TGReplyMarkup.replyKeyboardRemove(TGReplyKeyboardRemove(removeKeyboard: true))
    }
}

// MARK: - Callback Queries Processing
extension Registration {
    static func onCallbackQuery(context: Context) async throws -> Bool {
        guard let query = context.update.callbackQuery else { return false }
        guard let message = query.message else { return false }

        let chatId = TGChatId.chat(message.chat.id)
        let deleteParams = TGDeleteMessageParams(chatId: chatId, messageId: message.messageId)
        try await context.bot.deleteMessage(params: deleteParams)

        guard let data = query.data, data.starts(with: "set_lang:") else { return false }

        let locale = data.replacingOccurrences(of: "set_lang:", with: "")
        context.session.locale = locale
        try await context.session.saveAndCache(in: context.db)

        // Show nickname prompt
        let prompt = context.lingo.localize("registration.nickname.prompt", locale: context.session.locale)
        let rules = context.lingo.localize("registration.nickname.rules", locale: context.session.locale)

        let text = """
        📝 <b>\(prompt)</b>

        \(rules)
        """

        let markup = TGReplyMarkup.replyKeyboardRemove(TGReplyKeyboardRemove(removeKeyboard: true))
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)

        return true
    }
}
