//
//  VaultController.swift
//  Vaultown
//
//  Controller for vault management and display
//

import Foundation
import Fluent
import Lingo
import SwiftTelegramBot
import GameLogic

// MARK: - Vault Controller Logic
final class VaultController: TGControllerBase, @unchecked Sendable {
    typealias T = VaultController

    // MARK: - Controller Lifecycle
    override public func attachHandlers(to bot: TGBot, lingo: Lingo) async {
        let router = Router(bot: bot) { router in
            router[Commands.start.command()] = onStart
            router[Commands.vault.command()] = onVault

            // Vault button locales
            let vaultLocales = Commands.vault.buttonsForAllLocales(lingo: lingo)
            for button in vaultLocales { router[button.text] = onVault }

            // Dwellers button locales
            let dwellersLocales = Commands.dwellers.buttonsForAllLocales(lingo: lingo)
            for button in dwellersLocales { router[button.text] = onDwellers }

            // Resources button locales
            let resourcesLocales = Commands.resources.buttonsForAllLocales(lingo: lingo)
            for button in resourcesLocales { router[button.text] = onResources }

            // Build button locales
            let buildLocales = Commands.build.buttonsForAllLocales(lingo: lingo)
            for button in buildLocales { router[button.text] = onBuild }

            // Rooms button locales
            let roomsLocales = Commands.rooms.buttonsForAllLocales(lingo: lingo)
            for button in roomsLocales { router[button.text] = onRooms }

            // Settings navigation
            let settingsLocales = Commands.settings.buttonsForAllLocales(lingo: lingo)
            for button in settingsLocales { router[button.text] = onSettings }

            router.unmatched = unmatched
            router[.callback_query(data: nil)] = VaultController.onCallbackQuery
        }
        await processRouterForEachName(router)
    }

    public func onStart(context: Context) async throws -> Bool {
        try await showVaultMenu(context: context)
        return true
    }

    private func onBack(context: Context) async throws -> Bool {
        // Vault is the main hub - just refresh the vault menu
        try await showVaultMenu(context: context)
        return true
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

    // MARK: - Vault Actions

    private func onVault(context: Context) async throws -> Bool {
        try await showVaultStatus(context: context)
        return true
    }

    private func onDwellers(context: Context) async throws -> Bool {
        try await showDwellersList(context: context)
        return true
    }

    private func onResources(context: Context) async throws -> Bool {
        try await showResourcesDetail(context: context)
        return true
    }

    private func onBuild(context: Context) async throws -> Bool {
        let buildController = Controllers.buildController
        try await buildController.showBuildMenu(context: context)
        context.session.routerName = buildController.routerName
        try await context.session.saveAndCache(in: context.db)
        return true
    }

    private func onRooms(context: Context) async throws -> Bool {
        let buildController = Controllers.buildController
        try await buildController.showRoomsList(context: context)
        context.session.routerName = buildController.routerName
        try await context.session.saveAndCache(in: context.db)
        return true
    }

    // MARK: - Display Methods

    public func showVaultMenu(context: Context, text: String? = nil) async throws {
        // Get or create vault for user
        let vault = try await Vault.forUser(context.session, on: context.db)
        let dwellerCount = try await vault.dwellerCount(on: context.db)

        let locale = context.session.locale
        let title = context.lingo.localize("vault.title", locale: locale)
        let welcome = context.lingo.localize("vault.welcome", locale: locale)

        let vaultStatus = vault.localizedStatusDisplay(
            dwellerCount: dwellerCount,
            vaultName: context.lingo.localize("vault.name", locale: locale),
            population: context.lingo.localize("vault.population", locale: locale),
            power: context.lingo.localize("resources.power", locale: locale),
            food: context.lingo.localize("resources.food", locale: locale),
            water: context.lingo.localize("resources.water", locale: locale),
            caps: context.lingo.localize("resources.caps", locale: locale),
            stimpaksLabel: context.lingo.localize("resources.stimpaks", locale: locale),
            radawayLabel: context.lingo.localize("resources.radaway", locale: locale)
        )

        let text = text ?? """
        🏠 <b>\(title)</b>

        \(welcome)

        \(vaultStatus)
        """

        let markup = generateControllerKB(session: context.session, lingo: context.lingo)
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }

    public func showVaultStatus(context: Context) async throws {
        let vault = try await Vault.forUser(context.session, on: context.db)
        let dwellerCount = try await vault.dwellerCount(on: context.db)

        let locale = context.session.locale
        let statusTitle = context.lingo.localize("vault.status", locale: locale)

        let vaultStatus = vault.localizedStatusDisplay(
            dwellerCount: dwellerCount,
            vaultName: context.lingo.localize("vault.name", locale: locale),
            population: context.lingo.localize("vault.population", locale: locale),
            power: context.lingo.localize("resources.power", locale: locale),
            food: context.lingo.localize("resources.food", locale: locale),
            water: context.lingo.localize("resources.water", locale: locale),
            caps: context.lingo.localize("resources.caps", locale: locale),
            stimpaksLabel: context.lingo.localize("resources.stimpaks", locale: locale),
            radawayLabel: context.lingo.localize("resources.radaway", locale: locale)
        )

        let text = """
        📊 <b>\(statusTitle)</b>

        \(vaultStatus)
        """

        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html)
    }

    public func showDwellersList(context: Context) async throws {
        let vault = try await Vault.forUser(context.session, on: context.db)
        let locale = context.session.locale
        let title = context.lingo.localize("dwellers.title", locale: locale)
        let levelLabel = context.lingo.localize("dwellers.level", locale: locale)

        guard let vaultID = vault.id else {
            let empty = context.lingo.localize("dwellers.empty", locale: locale)
            let text = "👥 <b>\(title)</b>\n\n\(empty)"
            try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html)
            return
        }

        let dwellers = try await DwellerModel.query(on: context.db)
            .filter(\.$vault.$id, .equal, vaultID)
            .with(\.$assignedRoom)
            .all()

        if dwellers.isEmpty {
            let empty = context.lingo.localize("dwellers.empty", locale: locale)
            let text = "👥 <b>\(title)</b>\n\n\(empty)"
            try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html)
            return
        }

        let listTitle = context.lingo.localize("dwellers.list", locale: locale)
        let idleEmoji = context.lingo.localize("dwellers.idle", locale: locale)
        var text = "👥 <b>\(title)</b>\n\n\(listTitle)\n\n"

        for (index, dweller) in dwellers.enumerated() {
            // Show room emoji or idle indicator
            let workEmoji: String
            if let room = dweller.assignedRoom, let roomType = room.roomType {
                workEmoji = roomType.emoji
            } else {
                workEmoji = idleEmoji
            }
            text += "\(index + 1). \(workEmoji) \(dweller.shortStatus(levelLabel: levelLabel))\n"
        }

        // Create inline keyboard for dweller selection
        var inlineKeyboard: [[TGInlineKeyboardButton]] = []
        for dweller in dwellers {
            // Show room emoji or idle indicator in button (room first, then rarity)
            let workEmoji: String
            if let room = dweller.assignedRoom, let roomType = room.roomType {
                workEmoji = roomType.emoji
            } else {
                workEmoji = idleEmoji
            }
            let button = TGInlineKeyboardButton(
                text: "\(workEmoji) \(dweller.rarityEmoji) \(dweller.fullName)",
                callbackData: "dweller:\(dweller.id?.uuidString ?? "")"
            )
            inlineKeyboard.append([button])
        }

        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }

    public func showResourcesDetail(context: Context) async throws {
        let vault = try await Vault.forUser(context.session, on: context.db)
        let locale = context.session.locale

        let resourcesTitle = context.lingo.localize("resources.title", locale: locale)
        let powerLabel = context.lingo.localize("resources.power", locale: locale)
        let foodLabel = context.lingo.localize("resources.food", locale: locale)
        let waterLabel = context.lingo.localize("resources.water", locale: locale)
        let capsLabel = context.lingo.localize("resources.caps", locale: locale)
        let stimpaksLabel = context.lingo.localize("resources.stimpaks", locale: locale)
        let radawayLabel = context.lingo.localize("resources.radaway", locale: locale)
        let consumptionTitle = context.lingo.localize("resources.consumption", locale: locale)
        let foodRate = context.lingo.localize("resources.food.rate", locale: locale)
        let waterRate = context.lingo.localize("resources.water.rate", locale: locale)

        let text = """
        📊 <b>\(resourcesTitle)</b>

        ⚡ \(powerLabel): \(vault.resources.resourceBar(.power)) \(Int(vault.power))/\(Int(vault.maxPower))
        🍲 \(foodLabel): \(vault.resources.resourceBar(.food)) \(Int(vault.food))/\(Int(vault.maxFood))
        💧 \(waterLabel): \(vault.resources.resourceBar(.water)) \(Int(vault.water))/\(Int(vault.maxWater))
        💰 \(capsLabel): \(vault.caps)

        💊 \(stimpaksLabel): \(vault.stimpaks)
        ☢️ \(radawayLabel): \(vault.radaway)

        📈 <b>\(consumptionTitle)</b>
        🍲 \(foodRate)
        💧 \(waterRate)
        """

        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html)
    }

    public func showDwellerDetail(context: Context, dwellerID: UUID) async throws {
        guard let dweller = try await DwellerModel.query(on: context.db)
            .filter(\DwellerModel.$id, .equal, dwellerID)
            .with(\.$assignedRoom)
            .first() else {
            let notFound = context.lingo.localize("dwellers.empty", locale: context.session.locale)
            try await context.bot.sendMessage(session: context.session, text: notFound, parseMode: .html)
            return
        }

        let locale = context.session.locale
        let title = context.lingo.localize("dwellers.detail.title", locale: locale)

        // Get localized rarity name
        let rarityKey = "rarity.\(dweller.rarity)"
        let rarityName = context.lingo.localize(rarityKey, locale: locale)

        let detailedDisplay = dweller.localizedDetailedDisplay(
            levelLabel: context.lingo.localize("dwellers.level", locale: locale),
            hpLabel: context.lingo.localize("dwellers.hp", locale: locale),
            happinessLabel: context.lingo.localize("dwellers.happiness", locale: locale),
            totalLabel: context.lingo.localize("dwellers.total", locale: locale),
            rarityName: rarityName
        )

        // Get assignment info
        let assignmentLabel = context.lingo.localize("dwellers.assigned", locale: locale)
        let unassignedLabel = context.lingo.localize("dwellers.unassigned", locale: locale)

        let assignmentText: String
        if let room = dweller.assignedRoom, let roomType = room.roomType {
            let roomKey = "room.\(roomType.rawValue)"
            let roomName = context.lingo.localize(roomKey, locale: locale)
            assignmentText = "🔧 \(assignmentLabel): \(roomType.emoji) \(roomName)"
        } else {
            assignmentText = unassignedLabel
        }

        let text = """
        📋 <b>\(title)</b>

        \(detailedDisplay)

        \(assignmentText)
        """

        // Create inline keyboard with unassign button if dweller is assigned
        var inlineKeyboard: [[TGInlineKeyboardButton]] = []

        if dweller.assignedRoom != nil {
            let shortDwellerID = String(dweller.id?.uuidString.prefix(8) ?? "")
            let unassignText = context.lingo.localize("button.unassign.dweller", locale: locale)
            let unassignButton = TGInlineKeyboardButton(
                text: unassignText,
                callbackData: "d.un:\(shortDwellerID)"
            )
            inlineKeyboard.append([unassignButton])
        }

        // Back button
        let backText = context.lingo.localize("button.back", locale: locale)
        let backButton = TGInlineKeyboardButton(text: backText, callbackData: "d.list")
        inlineKeyboard.append([backButton])

        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }

    override public func generateControllerKB(session: User, lingo: Lingo) -> TGReplyMarkup? {
        let markup = TGReplyKeyboardMarkup(keyboard: [
            [
                Commands.dwellers.button(for: session, lingo),
                Commands.resources.button(for: session, lingo)
            ],
            [
                Commands.build.button(for: session, lingo),
                Commands.rooms.button(for: session, lingo)
            ],
            [
                Commands.settings.button(for: session, lingo)
            ]
        ], resizeKeyboard: true)
        return TGReplyMarkup.replyKeyboardMarkup(markup)
    }
}

// MARK: - Callback Queries Processing
extension VaultController {
    static func onCallbackQuery(context: Context) async throws -> Bool {
        guard let query = context.update.callbackQuery else { return false }
        guard let data = query.data else { return false }

        let controller = Controllers.vaultController

        // Answer callback to remove loading state
        let answerParams = TGAnswerCallbackQueryParams(callbackQueryId: query.id)
        try await context.bot.answerCallbackQuery(params: answerParams)

        // Delete the message with inline keyboard to keep chat clean
        if let message = query.message {
            let chatId = TGChatId.chat(message.chat.id)
            let deleteParams = TGDeleteMessageParams(chatId: chatId, messageId: message.messageId)
            _ = try? await context.bot.deleteMessage(params: deleteParams)
        }

        // Handle dweller selection (full UUID format)
        if data.starts(with: "dweller:") {
            let dwellerIDString = data.replacingOccurrences(of: "dweller:", with: "")
            if let dwellerID = UUID(uuidString: dwellerIDString) {
                try await controller.showDwellerDetail(context: context, dwellerID: dwellerID)
            }
            return true
        }

        // Handle back to dwellers list
        if data == "d.list" {
            try await controller.showDwellersList(context: context)
            return true
        }

        // Handle unassign dweller (short ID format: d.un:SHORTID)
        if data.starts(with: "d.un:") {
            let shortID = data.replacingOccurrences(of: "d.un:", with: "")
            try await controller.unassignDweller(context: context, shortID: shortID)
            return true
        }

        return false
    }

    /// Find dweller by short ID (first 8 chars of UUID)
    func findDwellerByShortID(_ shortID: String, on db: any Database) async throws -> DwellerModel? {
        let dwellers = try await DwellerModel.query(on: db).all()
        return dwellers.first { dweller in
            guard let id = dweller.id?.uuidString else { return false }
            return id.prefix(8).lowercased() == shortID.lowercased()
        }
    }

    /// Unassign a dweller from their current room
    func unassignDweller(context: Context, shortID: String) async throws {
        guard let dweller = try await findDwellerByShortID(shortID, on: context.db) else {
            return
        }

        let locale = context.session.locale

        // Check if dweller is actually assigned
        guard dweller.$assignedRoom.id != nil else {
            let notAssigned = context.lingo.localize("unassign.not.assigned", locale: locale, interpolations: [
                "dweller": dweller.fullName
            ])
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(notAssigned)", parseMode: .html)
            return
        }

        // Unassign the dweller
        dweller.$assignedRoom.id = nil
        try await dweller.save(on: context.db)

        let successText = context.lingo.localize("unassign.success", locale: locale, interpolations: [
            "dweller": dweller.fullName,
            "room": ""
        ])

        try await context.bot.sendMessage(session: context.session, text: "✅ \(successText)", parseMode: .html)

        // Show updated dweller detail
        if let dwellerID = dweller.id {
            try await showDwellerDetail(context: context, dwellerID: dwellerID)
        }
    }
}
