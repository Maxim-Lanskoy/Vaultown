//
//  VaultController.swift
//  Vaultown
//
//  Main game controller for vault management (build, exploration, incidents, dwellers)
//
//  Created by Maxim Lanskoy on 31.01.2026.
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
            // Slash commands
            router[Commands.start.command()] = onStart
            router[Commands.vault.command()] = onVault
            router[Commands.dwellers.command()] = onDwellers
            router[Commands.resources.command()] = onResources
            router[Commands.build.command()] = onBuild
            router[Commands.rooms.command()] = onRooms
            router[Commands.explore.command()] = onExplore
            router[Commands.incidents.command()] = onIncidents
            router[Commands.settings.command()] = onSettings

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

            // Explore button locales
            let exploreLocales = Commands.explore.buttonsForAllLocales(lingo: lingo)
            for button in exploreLocales { router[button.text] = onExplore }

            // Incidents button locales
            let incidentsLocales = Commands.incidents.buttonsForAllLocales(lingo: lingo)
            for button in incidentsLocales { router[button.text] = onIncidents }

            // Fight button locales
            let fightLocales = Commands.fight.buttonsForAllLocales(lingo: lingo)
            for button in fightLocales { router[button.text] = onIncidents }

            // Cancel/back button locales
            let cancelLocales = Commands.cancel.buttonsForAllLocales(lingo: lingo)
            for button in cancelLocales { router[button.text] = onStart }

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
        try await showBuildMenu(context: context)
        return true
    }

    private func onRooms(context: Context) async throws -> Bool {
        try await showRoomsList(context: context)
        return true
    }

    private func onExplore(context: Context) async throws -> Bool {
        try await showExplorationMenu(context: context)
        return true
    }

    private func onIncidents(context: Context) async throws -> Bool {
        try await showIncidentsList(context: context)
        return true
    }

    // MARK: - Vault Display Methods

    public func showVaultMenu(context: Context, text: String? = nil) async throws {
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
            let workEmoji: String
            if let room = dweller.assignedRoom, let roomType = room.roomType {
                workEmoji = roomType.emoji
            } else {
                workEmoji = idleEmoji
            }
            text += "\(index + 1). \(workEmoji) \(dweller.shortStatus(levelLabel: levelLabel))\n"
        }

        var inlineKeyboard: [[TGInlineKeyboardButton]] = []
        for dweller in dwellers {
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
        let rarityKey = "rarity.\(dweller.rarity)"
        let rarityName = context.lingo.localize(rarityKey, locale: locale)

        let detailedDisplay = dweller.localizedDetailedDisplay(
            levelLabel: context.lingo.localize("dwellers.level", locale: locale),
            hpLabel: context.lingo.localize("dwellers.hp", locale: locale),
            happinessLabel: context.lingo.localize("dwellers.happiness", locale: locale),
            totalLabel: context.lingo.localize("dwellers.total", locale: locale),
            rarityName: rarityName
        )

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

        // Check if dweller is dead
        let isDead = dweller.currentHP <= 0
        let statusText: String
        if isDead {
            statusText = "\n\n💀 " + context.lingo.localize("dwellers.dead", locale: locale)
        } else {
            statusText = ""
        }

        let text = """
        📋 <b>\(title)</b>

        \(detailedDisplay)

        \(assignmentText)\(statusText)
        """

        var inlineKeyboard: [[TGInlineKeyboardButton]] = []
        let shortDwellerID = String(dweller.id?.uuidString.prefix(8) ?? "")

        // Revive button if dead
        if isDead {
            let reviveCost = dweller.toDweller().revivalCost
            let reviveText = "💊 " + context.lingo.localize("button.revive", locale: locale, interpolations: ["cost": "\(reviveCost)"])
            let reviveButton = TGInlineKeyboardButton(
                text: reviveText,
                callbackData: "d.rev:\(shortDwellerID)"
            )
            inlineKeyboard.append([reviveButton])
        }

        // Unassign button if assigned (and alive)
        if dweller.assignedRoom != nil && !isDead {
            let unassignText = context.lingo.localize("button.unassign.dweller", locale: locale)
            let unassignButton = TGInlineKeyboardButton(
                text: unassignText,
                callbackData: "d.un:\(shortDwellerID)"
            )
            inlineKeyboard.append([unassignButton])
        }

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
                Commands.explore.button(for: session, lingo),
                Commands.settings.button(for: session, lingo)
            ]
        ], resizeKeyboard: true)
        return TGReplyMarkup.replyKeyboardMarkup(markup)
    }
}

// MARK: - Build Methods
extension VaultController {

    public func showBuildMenu(context: Context, text: String? = nil) async throws {
        let locale = context.session.locale
        let title = context.lingo.localize("build.title", locale: locale)
        let selectCategory = context.lingo.localize("build.select.category", locale: locale)

        let text = text ?? """
        🔨 <b>\(title)</b>

        \(selectCategory)
        """

        var inlineKeyboard: [[TGInlineKeyboardButton]] = []

        let categories: [(RoomCategory, String)] = [
            (.production, context.lingo.localize("rooms.category.production", locale: locale)),
            (.training, context.lingo.localize("rooms.category.training", locale: locale)),
            (.medical, context.lingo.localize("rooms.category.medical", locale: locale)),
            (.special, context.lingo.localize("rooms.category.special", locale: locale)),
            (.crafting, context.lingo.localize("rooms.category.crafting", locale: locale)),
            (.infrastructure, context.lingo.localize("rooms.category.infrastructure", locale: locale))
        ]

        for (category, name) in categories {
            let emoji = categoryEmoji(category)
            let button = TGInlineKeyboardButton(
                text: "\(emoji) \(name)",
                callbackData: "build.category:\(category.rawValue)"
            )
            inlineKeyboard.append([button])
        }

        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }

    public func showRoomsInCategory(context: Context, category: RoomCategory) async throws {
        let vault = try await Vault.forUser(context.session, on: context.db)
        let dwellerCount = try await vault.dwellerCount(on: context.db)
        let existingRooms = try await vault.getRooms(on: context.db)
        let locale = context.session.locale

        let selectRoom = context.lingo.localize("build.select.room", locale: locale)
        let costLabel = context.lingo.localize("build.cost", locale: locale)

        let roomTypes = RoomType.allCases.filter { $0.category == category && $0.isBuildable }

        var text = "🔨 <b>\(selectRoom)</b>\n\n"
        var inlineKeyboard: [[TGInlineKeyboardButton]] = []

        for roomType in roomTypes {
            let roomName = localizedRoomName(roomType, locale: locale, lingo: context.lingo)
            let isUnlocked = dwellerCount >= roomType.unlockPopulation
            let cost = calculateRoomCost(roomType: roomType, existingRooms: existingRooms)

            if isUnlocked {
                text += "\(roomType.emoji) \(roomName) - \(costLabel): \(cost) 💰\n"
                let button = TGInlineKeyboardButton(
                    text: "\(roomType.emoji) \(roomName) (\(cost) 💰)",
                    callbackData: "build.select:\(roomType.rawValue)"
                )
                inlineKeyboard.append([button])
            } else {
                let unlockText = context.lingo.localize("build.unlock.population", locale: locale, interpolations: ["population": "\(roomType.unlockPopulation)"])
                text += "🔒 \(roomName) - \(unlockText)\n"
            }
        }

        let backText = context.lingo.localize("button.back", locale: locale)
        let backButton = TGInlineKeyboardButton(text: backText, callbackData: "build.back")
        inlineKeyboard.append([backButton])

        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }

    public func showPositionSelection(context: Context, roomType: RoomType) async throws {
        let vault = try await Vault.forUser(context.session, on: context.db)
        let existingRooms = try await vault.getRooms(on: context.db)
        let locale = context.session.locale

        let selectPosition = context.lingo.localize("build.select.position", locale: locale)
        let costLabel = context.lingo.localize("build.cost", locale: locale)
        let roomName = localizedRoomName(roomType, locale: locale, lingo: context.lingo)
        let cost = calculateRoomCost(roomType: roomType, existingRooms: existingRooms)

        var text = "📍 <b>\(selectPosition)</b>\n"
        text += "\(roomType.emoji) \(roomName) - \(costLabel): \(cost) 💰\n\n"
        text += renderVaultGrid(existingRooms)

        let availablePositions = findAvailablePositions(existingRooms: existingRooms, roomWidth: 1, roomType: roomType)

        var inlineKeyboard: [[TGInlineKeyboardButton]] = []

        for position in availablePositions.prefix(10) {
            let button = TGInlineKeyboardButton(
                text: "[\(position.x),\(position.y)]",
                callbackData: "build.position:\(roomType.rawValue):\(position.x):\(position.y)"
            )
            inlineKeyboard.append([button])
        }

        let backText = context.lingo.localize("button.back", locale: locale)
        let backButton = TGInlineKeyboardButton(text: backText, callbackData: "build.category:\(roomType.category.rawValue)")
        inlineKeyboard.append([backButton])

        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }

    public func confirmBuild(context: Context, roomType: RoomType, x: Int, y: Int) async throws {
        let vault = try await Vault.forUser(context.session, on: context.db)
        let existingRooms = try await vault.getRooms(on: context.db)
        let locale = context.session.locale

        let roomName = localizedRoomName(roomType, locale: locale, lingo: context.lingo)
        let cost = calculateRoomCost(roomType: roomType, existingRooms: existingRooms)

        let confirmText = context.lingo.localize("build.confirm", locale: locale, interpolations: [
            "room": roomName,
            "cost": "\(cost)"
        ])

        var inlineKeyboard: [[TGInlineKeyboardButton]] = []

        if vault.caps >= cost {
            let yesButton = TGInlineKeyboardButton(
                text: "✅ \(context.lingo.localize("yes", locale: locale))",
                callbackData: "build.confirm:\(roomType.rawValue):\(x):\(y)"
            )
            let noButton = TGInlineKeyboardButton(
                text: "❌ \(context.lingo.localize("no", locale: locale))",
                callbackData: "build.back"
            )
            inlineKeyboard.append([yesButton, noButton])
        } else {
            let insufficientText = context.lingo.localize("build.insufficient.caps", locale: locale, interpolations: [
                "have": "\(vault.caps)",
                "need": "\(cost)"
            ])
            let text = "\(confirmText)\n\n⚠️ \(insufficientText)"
            try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html)
            return
        }

        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: confirmText, parseMode: .html, replyMarkup: markup)
    }

    public func executeBuild(context: Context, roomType: RoomType, x: Int, y: Int) async throws {
        let vault = try await Vault.forUser(context.session, on: context.db)
        let existingRooms = try await vault.getRooms(on: context.db)
        let locale = context.session.locale

        let roomName = localizedRoomName(roomType, locale: locale, lingo: context.lingo)
        let cost = calculateRoomCost(roomType: roomType, existingRooms: existingRooms)

        guard RoomModel.isValidPosition(x: x, y: y, width: 1, existingRooms: existingRooms) else {
            let errorText = context.lingo.localize("build.invalid.position", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "❌ \(errorText)", parseMode: .html)
            return
        }

        if existingRooms.count >= 3 && !RoomModel.isConnected(x: x, y: y, width: 1, existingRooms: existingRooms, roomType: roomType) {
            let errorText = context.lingo.localize("build.not.connected", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "❌ \(errorText)", parseMode: .html)
            return
        }

        guard vault.caps >= cost else {
            let errorText = context.lingo.localize("build.insufficient.caps", locale: locale, interpolations: [
                "have": "\(vault.caps)",
                "need": "\(cost)"
            ])
            try await context.bot.sendMessage(session: context.session, text: "❌ \(errorText)", parseMode: .html)
            return
        }

        vault.caps -= cost
        try await vault.save(on: context.db)

        let room = RoomModel(vaultID: vault.id!, type: roomType, x: x, y: y)
        try await room.save(on: context.db)

        let successText = context.lingo.localize("build.success", locale: locale, interpolations: [
            "room": roomName
        ])

        try await context.bot.sendMessage(session: context.session, text: "✅ \(successText)", parseMode: .html)

        try await tryMergeRooms(context: context, newRoom: room)
        try await showVaultMenu(context: context)
    }

    public func showRoomsList(context: Context) async throws {
        let vault = try await Vault.forUser(context.session, on: context.db)
        let rooms = try await vault.getRooms(on: context.db)
        let locale = context.session.locale

        let title = context.lingo.localize("rooms.title", locale: locale)

        if rooms.isEmpty {
            let empty = context.lingo.localize("rooms.empty", locale: locale)
            let text = "🚪 <b>\(title)</b>\n\n\(empty)"
            try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html)
            return
        }

        var text = "🚪 <b>\(title)</b>\n\n"
        text += renderVaultGrid(rooms)

        var inlineKeyboard: [[TGInlineKeyboardButton]] = []

        for room in rooms.sorted(by: { ($0.y, $0.x) < ($1.y, $1.x) }) {
            guard let roomType = room.roomType else { continue }
            let roomName = localizedRoomName(roomType, locale: locale, lingo: context.lingo)
            let assignedCount = try await room.assignedCount(on: context.db)
            let widthEmojis = String(repeating: roomType.emoji, count: room.width)
            let shortRoomID = String(room.id?.uuidString.prefix(8) ?? "")
            let button = TGInlineKeyboardButton(
                text: "\(widthEmojis) \(roomName) L\(room.level) 👥\(assignedCount)/\(room.capacity)",
                callbackData: "r.d:\(shortRoomID)"
            )
            inlineKeyboard.append([button])
        }

        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }

    public func showRoomDetail(context: Context, roomID: UUID) async throws {
        guard let room = try await RoomModel.find(roomID, on: context.db),
              let roomType = room.roomType else {
            return
        }

        let locale = context.session.locale
        let title = context.lingo.localize("rooms.detail.title", locale: locale)
        let roomName = localizedRoomName(roomType, locale: locale, lingo: context.lingo)
        let levelLabel = context.lingo.localize("rooms.level", locale: locale)
        let positionLabel = context.lingo.localize("rooms.position", locale: locale)
        let capacityLabel = context.lingo.localize("rooms.capacity", locale: locale)
        let powerLabel = context.lingo.localize("rooms.power.consumption", locale: locale)
        let assignedLabel = context.lingo.localize("rooms.assigned.dwellers", locale: locale)

        let assignedCount = try await room.assignedCount(on: context.db)
        let assignedDwellers = try await DwellerModel.query(on: context.db)
            .filter(\DwellerModel.$assignedRoom.$id, .equal, room.id)
            .all()

        let widthEmojis = String(repeating: roomType.emoji, count: room.width)

        var text = """
        📋 <b>\(title)</b>

        \(widthEmojis) <b>\(roomName)</b>
        \(levelLabel): \(room.level)/3
        \(positionLabel): [\(room.x), \(room.y)] (width: \(room.width))
        \(capacityLabel): 👥 \(assignedCount)/\(room.capacity)
        \(powerLabel): ⚡ \(room.powerConsumption)
        """

        if roomType.isProductionRoom, let resource = roomType.producesResource {
            let productionLabel = context.lingo.localize("rooms.production", locale: locale)
            let resourceKey = "resources.\(resource.rawValue)"
            let resourceName = context.lingo.localize(resourceKey, locale: locale)
            text += "\n\(productionLabel): \(resource.emoji) \(resourceName)"
        }

        text += "\n\n<b>\(assignedLabel):</b>\n"
        if assignedDwellers.isEmpty {
            let noDwellers = context.lingo.localize("rooms.no.dwellers", locale: locale)
            text += "\(noDwellers)"
        } else {
            let primaryStat = roomType.primaryStat
            for dweller in assignedDwellers {
                let statInfo: String
                if let stat = primaryStat {
                    let statValue = dweller.toDweller().baseStats.base(stat)
                    statInfo = " \(stat.emoji)\(statValue)"
                } else {
                    statInfo = ""
                }
                text += "• \(dweller.rarityEmoji) \(dweller.fullName)\(statInfo)\n"
            }
        }

        var inlineKeyboard: [[TGInlineKeyboardButton]] = []
        let shortRoomID = String(room.id?.uuidString.prefix(8) ?? "")

        if let upgradeCost = room.upgradeCost {
            let upgradeText = context.lingo.localize("button.upgrade", locale: locale, interpolations: [
                "level": "\(room.level + 1)",
                "cost": "\(upgradeCost)"
            ])
            let upgradeButton = TGInlineKeyboardButton(
                text: upgradeText,
                callbackData: "r.up:\(shortRoomID)"
            )
            inlineKeyboard.append([upgradeButton])
        }

        if assignedCount < room.capacity {
            let assignText = context.lingo.localize("button.assign.dweller", locale: locale)
            let assignButton = TGInlineKeyboardButton(
                text: assignText,
                callbackData: "r.as:\(shortRoomID)"
            )
            inlineKeyboard.append([assignButton])
        }

        let backText = context.lingo.localize("button.back", locale: locale)
        let backButton = TGInlineKeyboardButton(text: backText, callbackData: "r.list")
        inlineKeyboard.append([backButton])

        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }

    func upgradeRoom(context: Context, roomID: UUID) async throws {
        guard let room = try await RoomModel.find(roomID, on: context.db),
              let roomType = room.roomType else {
            return
        }

        let vault = try await Vault.forUser(context.session, on: context.db)
        let locale = context.session.locale
        let roomName = localizedRoomName(roomType, locale: locale, lingo: context.lingo)

        guard let upgradeCost = room.upgradeCost else {
            let maxLevel = context.lingo.localize("upgrade.max.level", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(maxLevel)", parseMode: .html)
            return
        }

        let population = try await vault.dwellerCount(on: context.db)
        guard room.toRoom()?.canUpgrade(currentPopulation: population) ?? false else {
            let popRequired = context.lingo.localize("upgrade.population.required", locale: locale, interpolations: ["population": "?"])
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(popRequired)", parseMode: .html)
            return
        }

        guard vault.caps >= upgradeCost else {
            let insufficientText = context.lingo.localize("build.insufficient.caps", locale: locale, interpolations: [
                "have": "\(vault.caps)",
                "need": "\(upgradeCost)"
            ])
            try await context.bot.sendMessage(session: context.session, text: "❌ \(insufficientText)", parseMode: .html)
            return
        }

        vault.caps -= upgradeCost
        room.level += 1
        try await vault.save(on: context.db)
        try await room.save(on: context.db)

        let successText = context.lingo.localize("upgrade.success", locale: locale, interpolations: [
            "room": roomName,
            "level": "\(room.level)"
        ])

        try await context.bot.sendMessage(session: context.session, text: "✅ \(successText)", parseMode: .html)
        try await showRoomDetail(context: context, roomID: roomID)
    }

    func showAssignDwellerToRoom(context: Context, roomID: UUID) async throws {
        guard let room = try await RoomModel.find(roomID, on: context.db),
              let roomType = room.roomType else {
            return
        }

        let vault = try await Vault.forUser(context.session, on: context.db)
        let locale = context.session.locale

        let title = context.lingo.localize("assign.title", locale: locale)
        let selectDweller = context.lingo.localize("assign.select.dweller", locale: locale)
        let roomName = localizedRoomName(roomType, locale: locale, lingo: context.lingo)

        let unassignedDwellers = try await DwellerModel.query(on: context.db)
            .filter(\DwellerModel.$vault.$id, .equal, vault.id!)
            .filter(\DwellerModel.$assignedRoom.$id, .equal, .none)
            .all()

        var text = """
        👥 <b>\(title)</b>

        \(roomType.emoji) \(roomName)

        \(selectDweller)
        """

        let shortRoomID = String(room.id?.uuidString.prefix(8) ?? "")

        if unassignedDwellers.isEmpty {
            let noUnassigned = context.lingo.localize("assign.no.unassigned", locale: locale)
            text += "\n\n\(noUnassigned)"

            var inlineKeyboard: [[TGInlineKeyboardButton]] = []
            let backText = context.lingo.localize("button.back", locale: locale)
            let backButton = TGInlineKeyboardButton(text: backText, callbackData: "r.d:\(shortRoomID)")
            inlineKeyboard.append([backButton])

            let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
            try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
            return
        }

        var inlineKeyboard: [[TGInlineKeyboardButton]] = []

        for dweller in unassignedDwellers {
            let statInfo: String
            if let primaryStat = roomType.primaryStat {
                let statValue = dweller.toDweller().baseStats.base(primaryStat)
                statInfo = " (\(primaryStat.emoji)\(statValue))"
            } else {
                statInfo = ""
            }

            let shortDwellerID = String(dweller.id?.uuidString.prefix(8) ?? "")
            let button = TGInlineKeyboardButton(
                text: "\(dweller.rarityEmoji) \(dweller.fullName)\(statInfo)",
                callbackData: "a.d:\(shortRoomID):\(shortDwellerID)"
            )
            inlineKeyboard.append([button])
        }

        let backText = context.lingo.localize("button.back", locale: locale)
        let backButton = TGInlineKeyboardButton(text: backText, callbackData: "r.d:\(shortRoomID)")
        inlineKeyboard.append([backButton])

        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }

    func assignDwellerToRoom(context: Context, roomID: UUID, dwellerID: UUID) async throws {
        guard let room = try await RoomModel.find(roomID, on: context.db),
              let roomType = room.roomType,
              let dweller = try await DwellerModel.find(dwellerID, on: context.db) else {
            return
        }

        let locale = context.session.locale
        let roomName = localizedRoomName(roomType, locale: locale, lingo: context.lingo)

        let assignedCount = try await room.assignedCount(on: context.db)
        guard assignedCount < room.capacity else {
            let roomFull = context.lingo.localize("assign.room.full", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(roomFull)", parseMode: .html)
            return
        }

        dweller.$assignedRoom.id = roomID
        try await dweller.save(on: context.db)

        let successText = context.lingo.localize("assign.success", locale: locale, interpolations: [
            "dweller": dweller.fullName,
            "room": roomName
        ])

        try await context.bot.sendMessage(session: context.session, text: "✅ \(successText)", parseMode: .html)
        try await showRoomDetail(context: context, roomID: roomID)
    }

    // MARK: - Build Helpers

    private func categoryEmoji(_ category: RoomCategory) -> String {
        switch category {
        case .production: return "⚡"
        case .training: return "💪"
        case .medical: return "💊"
        case .crafting: return "🔧"
        case .special: return "🏠"
        case .infrastructure: return "🛗"
        }
    }

    private func localizedRoomName(_ roomType: RoomType, locale: String, lingo: Lingo) -> String {
        let key = "room.\(roomType.rawValue)"
        return lingo.localize(key, locale: locale)
    }

    private func calculateRoomCost(roomType: RoomType, existingRooms: [RoomModel]) -> Int {
        let existingCount = existingRooms.filter { $0.type == roomType.rawValue }.count
        return roomType.baseBuildCost * (existingCount + 1)
    }

    private func renderVaultGrid(_ rooms: [RoomModel]) -> String {
        guard !rooms.isEmpty else { return "" }

        let maxY = rooms.map { $0.y }.max() ?? 0
        let maxX = rooms.map { $0.x + $0.width - 1 }.max() ?? 0

        var grid = ""

        for y in 0...maxY {
            var row = ""
            for x in 0...maxX {
                if let room = rooms.first(where: { $0.y == y && $0.x <= x && x < $0.x + $0.width }),
                   let roomType = room.roomType {
                    row += roomType.emoji
                } else {
                    row += "⬛"
                }
            }
            grid += row + "\n"
        }

        return "<code>\(grid)</code>\n"
    }

    private func findAvailablePositions(existingRooms: [RoomModel], roomWidth: Int, roomType: RoomType) -> [(x: Int, y: Int)] {
        var positions: [(x: Int, y: Int)] = []

        let maxY: Int
        if roomType == .elevator {
            let deepestElevator = existingRooms.filter { $0.roomType == .elevator }.map { $0.y }.max() ?? 0
            maxY = deepestElevator + 1
        } else {
            maxY = existingRooms.map { $0.y }.max() ?? 0
        }
        let maxX = 10

        for y in 0...min(maxY, 24) {
            for x in 0..<maxX {
                if RoomModel.isValidPosition(x: x, y: y, width: roomWidth, existingRooms: existingRooms) {
                    if existingRooms.isEmpty || RoomModel.isConnected(x: x, y: y, width: roomWidth, existingRooms: existingRooms, roomType: roomType) {
                        positions.append((x: x, y: y))
                    }
                }
            }
        }

        return positions
    }

    private func tryMergeRooms(context: Context, newRoom: RoomModel) async throws {
        guard let roomType = newRoom.roomType,
              roomType.canMerge else {
            return
        }

        let vault = try await Vault.forUser(context.session, on: context.db)
        let allRooms = try await vault.getRooms(on: context.db)
        let locale = context.session.locale

        let adjacentRooms = allRooms.filter { room in
            guard room.id != newRoom.id,
                  room.y == newRoom.y,
                  room.type == newRoom.type,
                  room.level == newRoom.level else {
                return false
            }

            let roomEndX = room.x + room.width
            let newRoomEndX = newRoom.x + newRoom.width

            if roomEndX == newRoom.x { return true }
            if newRoomEndX == room.x { return true }

            return false
        }

        guard !adjacentRooms.isEmpty else { return }

        var roomsToMerge: [RoomModel] = [newRoom]
        roomsToMerge.append(contentsOf: adjacentRooms)
        roomsToMerge.sort { $0.x < $1.x }

        let totalWidth = roomsToMerge.reduce(0) { $0 + $1.width }

        guard totalWidth <= 3 else {
            if roomsToMerge.count >= 2 {
                let firstTwo = Array(roomsToMerge.prefix(2))
                let width = firstTwo.reduce(0) { $0 + $1.width }
                if width <= 3 {
                    try await performMerge(context: context, rooms: firstTwo, locale: locale)
                }
            }
            return
        }

        try await performMerge(context: context, rooms: roomsToMerge, locale: locale)
    }

    private func performMerge(context: Context, rooms: [RoomModel], locale: String) async throws {
        guard rooms.count >= 2,
              let keepRoom = rooms.first,
              let roomType = keepRoom.roomType else {
            return
        }

        let newWidth = rooms.reduce(0) { $0 + $1.width }
        guard newWidth <= 3 else { return }

        let leftmostX = rooms.map { $0.x }.min() ?? keepRoom.x

        var allDwellerIDs: [UUID] = []
        for room in rooms where room.id != keepRoom.id {
            let dwellers = try await DwellerModel.query(on: context.db)
                .filter(\DwellerModel.$assignedRoom.$id, .equal, room.id)
                .all()
            allDwellerIDs.append(contentsOf: dwellers.compactMap { $0.id })
        }

        keepRoom.x = leftmostX
        keepRoom.width = newWidth
        try await keepRoom.save(on: context.db)

        for dwellerID in allDwellerIDs {
            if let dweller = try await DwellerModel.find(dwellerID, on: context.db) {
                dweller.$assignedRoom.id = keepRoom.id
                try await dweller.save(on: context.db)
            }
        }

        for room in rooms where room.id != keepRoom.id {
            try await room.delete(on: context.db)
        }

        let roomName = localizedRoomName(roomType, locale: locale, lingo: context.lingo)
        let widthKey = "merge.width.\(RoomWidth(rawValue: newWidth)?.name.lowercased() ?? "single")"
        let widthName = context.lingo.localize(widthKey, locale: locale)

        let mergeText = context.lingo.localize("merge.success", locale: locale, interpolations: [
            "width": widthName,
            "room": roomName
        ])

        try await context.bot.sendMessage(session: context.session, text: "🔗 \(mergeText)", parseMode: .html)
    }
}

// MARK: - Exploration Methods
extension VaultController {

    public func showExplorationMenu(context: Context) async throws {
        let vault = try await Vault.forUser(context.session, on: context.db)
        guard let vaultID = vault.id else { return }

        let locale = context.session.locale
        let title = context.lingo.localize("explore.title", locale: locale)

        let explorations = try await ExplorationModel.query(on: context.db)
            .filter(\ExplorationModel.$vault.$id, .equal, vaultID)
            .filter(\ExplorationModel.$status, .notEqual, "completed")
            .all()

        let dwellers = try await DwellerModel.query(on: context.db)
            .filter(\DwellerModel.$vault.$id, .equal, vaultID)
            .with(\.$assignedRoom)
            .all()

        let exploringDwellerIDs = Set(explorations.map { $0.$dweller.id })
        let availableDwellers = dwellers.filter { dweller in
            guard let id = dweller.id else { return false }
            return !exploringDwellerIDs.contains(id)
        }

        var text = "🗺️ <b>\(title)</b>\n\n"

        if explorations.isEmpty {
            let noExplorers = context.lingo.localize("explore.no.active", locale: locale)
            text += "\(noExplorers)\n\n"
        } else {
            let activeTitle = context.lingo.localize("explore.active", locale: locale)
            text += "📡 <b>\(activeTitle)</b>\n"
            for exploration in explorations {
                text += "  • \(exploration.summary)\n"
            }
            text += "\n"
        }

        let availableTitle = context.lingo.localize("explore.available.dwellers", locale: locale)
        text += "👥 <b>\(availableTitle):</b> \(availableDwellers.count)/\(Exploration.maxExplorers)\n"
        text += "💊 \(context.lingo.localize("resources.stimpaks", locale: locale)): \(vault.stimpaks)\n"
        text += "☢️ \(context.lingo.localize("resources.radaway", locale: locale)): \(vault.radaway)\n"

        var inlineKeyboard: [[TGInlineKeyboardButton]] = []

        for exploration in explorations {
            let shortID = String(exploration.id?.uuidString.prefix(8) ?? "")
            let buttonText = "\(exploration.statusEmoji) \(exploration.dwellerName)"
            let button = TGInlineKeyboardButton(
                text: buttonText,
                callbackData: "exp.det:\(shortID)"
            )
            inlineKeyboard.append([button])
        }

        if !availableDwellers.isEmpty && explorations.count < Exploration.maxExplorers {
            let sendText = context.lingo.localize("explore.send", locale: locale)
            let sendButton = TGInlineKeyboardButton(
                text: "🚀 \(sendText)",
                callbackData: "exp.send"
            )
            inlineKeyboard.append([sendButton])
        }

        let backText = context.lingo.localize("button.back", locale: locale)
        let backButton = TGInlineKeyboardButton(text: backText, callbackData: "exp.back")
        inlineKeyboard.append([backButton])

        let inlineMarkup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))

        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: inlineMarkup)
    }

    public func showDwellerSelectionForExploration(context: Context) async throws {
        let vault = try await Vault.forUser(context.session, on: context.db)
        guard let vaultID = vault.id else { return }

        let locale = context.session.locale

        let explorations = try await ExplorationModel.query(on: context.db)
            .filter(\ExplorationModel.$vault.$id, .equal, vaultID)
            .filter(\ExplorationModel.$status, .notEqual, "completed")
            .all()

        let dwellers = try await DwellerModel.query(on: context.db)
            .filter(\DwellerModel.$vault.$id, .equal, vaultID)
            .all()

        let exploringDwellerIDs = Set(explorations.map { $0.$dweller.id })
        let availableDwellers = dwellers.filter { dweller in
            guard let id = dweller.id else { return false }
            return !exploringDwellerIDs.contains(id)
        }

        if availableDwellers.isEmpty {
            let noAvailable = context.lingo.localize("explore.no.available", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(noAvailable)", parseMode: .html)
            try await showExplorationMenu(context: context)
            return
        }

        let title = context.lingo.localize("explore.select.dweller", locale: locale)
        let text = "👥 <b>\(title)</b>\n\n"

        var inlineKeyboard: [[TGInlineKeyboardButton]] = []

        for dweller in availableDwellers {
            let shortID = String(dweller.id?.uuidString.prefix(8) ?? "")
            let healthPct = Int((dweller.currentHP / dweller.maxHP) * 100)
            let buttonText = "\(dweller.rarityEmoji) \(dweller.fullName) L\(dweller.level) ❤️\(healthPct)%"
            let button = TGInlineKeyboardButton(
                text: buttonText,
                callbackData: "exp.sel:\(shortID)"
            )
            inlineKeyboard.append([button])
        }

        let backText = context.lingo.localize("button.back", locale: locale)
        let backButton = TGInlineKeyboardButton(text: backText, callbackData: "exp.menu")
        inlineKeyboard.append([backButton])

        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }

    public func showSupplySelection(context: Context, dwellerShortID: String, stimpaks: Int = 0, radaway: Int = 0) async throws {
        let vault = try await Vault.forUser(context.session, on: context.db)
        let locale = context.session.locale

        guard let dweller = try await findDwellerByShortID(dwellerShortID, on: context.db) else {
            try await showDwellerSelectionForExploration(context: context)
            return
        }

        let currentStimpaks = min(stimpaks, vault.stimpaks)
        let currentRadaway = min(radaway, vault.radaway)

        let title = context.lingo.localize("explore.supplies", locale: locale)
        let stimpaksLabel = context.lingo.localize("resources.stimpaks", locale: locale)
        let radawayLabel = context.lingo.localize("resources.radaway", locale: locale)

        let immuneText = dweller.endurance >= 11 ? " (☢️ Immune!)" : ""

        let text = """
        🎒 <b>\(title)</b>

        \(dweller.rarityEmoji) <b>\(dweller.fullName)</b>
        ❤️ HP: \(Int(dweller.currentHP))/\(Int(dweller.maxHP))
        🍀 L: \(dweller.luck) | 👁 P: \(dweller.perception) | 💬 C: \(dweller.charisma)
        ❤️ E: \(dweller.endurance)\(immuneText)

        💊 \(stimpaksLabel): \(vault.stimpaks) available
        ☢️ \(radawayLabel): \(vault.radaway) available

        <b>Selected:</b> 💊 \(currentStimpaks) | ☢️ \(currentRadaway)
        """

        var inlineKeyboard: [[TGInlineKeyboardButton]] = []

        let stimpakMinus = TGInlineKeyboardButton(
            text: "➖",
            callbackData: "exp.sup:\(dwellerShortID):\(max(0, currentStimpaks - 1)):\(currentRadaway)"
        )
        let stimpakDisplay = TGInlineKeyboardButton(
            text: "💊 \(currentStimpaks)",
            callbackData: "exp.nop"
        )
        let stimpakPlus = TGInlineKeyboardButton(
            text: "➕",
            callbackData: "exp.sup:\(dwellerShortID):\(min(Exploration.maxStimpaks, min(vault.stimpaks, currentStimpaks + 1))):\(currentRadaway)"
        )
        inlineKeyboard.append([stimpakMinus, stimpakDisplay, stimpakPlus])

        let radawayMinus = TGInlineKeyboardButton(
            text: "➖",
            callbackData: "exp.sup:\(dwellerShortID):\(currentStimpaks):\(max(0, currentRadaway - 1))"
        )
        let radawayDisplay = TGInlineKeyboardButton(
            text: "☢️ \(currentRadaway)",
            callbackData: "exp.nop"
        )
        let radawayPlus = TGInlineKeyboardButton(
            text: "➕",
            callbackData: "exp.sup:\(dwellerShortID):\(currentStimpaks):\(min(Exploration.maxRadAway, min(vault.radaway, currentRadaway + 1)))"
        )
        inlineKeyboard.append([radawayMinus, radawayDisplay, radawayPlus])

        let maxButton = TGInlineKeyboardButton(
            text: "⬆️ Max",
            callbackData: "exp.sup:\(dwellerShortID):\(min(Exploration.maxStimpaks, vault.stimpaks)):\(min(Exploration.maxRadAway, vault.radaway))"
        )
        let noneButton = TGInlineKeyboardButton(
            text: "⬇️ None",
            callbackData: "exp.sup:\(dwellerShortID):0:0"
        )
        inlineKeyboard.append([noneButton, maxButton])

        let sendText = context.lingo.localize("explore.send", locale: locale)
        let sendButton = TGInlineKeyboardButton(
            text: "🚀 \(sendText)",
            callbackData: "exp.go:\(dwellerShortID):\(currentStimpaks):\(currentRadaway)"
        )
        inlineKeyboard.append([sendButton])

        let backText = context.lingo.localize("button.back", locale: locale)
        let backButton = TGInlineKeyboardButton(text: backText, callbackData: "exp.send")
        inlineKeyboard.append([backButton])

        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }

    public func sendExplorer(context: Context, dwellerShortID: String, stimpaks: Int, radaway: Int) async throws {
        let vault = try await Vault.forUser(context.session, on: context.db)
        guard let vaultID = vault.id else { return }

        let locale = context.session.locale

        guard let dweller = try await findDwellerByShortID(dwellerShortID, on: context.db) else {
            try await showDwellerSelectionForExploration(context: context)
            return
        }

        guard vault.stimpaks >= stimpaks && vault.radaway >= radaway else {
            let notEnough = context.lingo.localize("explore.not.enough.supplies", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(notEnough)", parseMode: .html)
            try await showSupplySelection(context: context, dwellerShortID: dwellerShortID)
            return
        }

        vault.stimpaks -= stimpaks
        vault.radaway -= radaway
        try await vault.save(on: context.db)

        if dweller.$assignedRoom.id != nil {
            dweller.$assignedRoom.id = nil
            try await dweller.save(on: context.db)
        }

        let exploration = ExplorationModel.create(
            vaultID: vaultID,
            dweller: dweller,
            stimpaks: stimpaks,
            radAway: radaway,
            returnSpeedMultiplier: 1.0
        )
        try await exploration.save(on: context.db)

        let successText = context.lingo.localize("explore.sent", locale: locale, interpolations: [
            "dweller": dweller.fullName,
            "stimpaks": "\(stimpaks)",
            "radaway": "\(radaway)"
        ])

        try await context.bot.sendMessage(session: context.session, text: "🚀 \(successText)", parseMode: .html)
        try await showExplorationMenu(context: context)
    }

    public func showExplorationDetail(context: Context, explorationShortID: String) async throws {
        guard let exploration = try await findExplorationByShortID(explorationShortID, on: context.db) else {
            try await showExplorationMenu(context: context)
            return
        }

        let locale = context.session.locale
        let title = context.lingo.localize("explore.detail.title", locale: locale)

        let recentEvents = exploration.recentEvents(count: 5)
        var eventLog = ""
        for event in recentEvents {
            let localizedLine = localizeEventLine(event: event, locale: locale, lingo: context.lingo)
            eventLog += "\(localizedLine)\n"
        }

        if eventLog.isEmpty {
            eventLog = context.lingo.localize("explore.no.events", locale: locale)
        }

        let hpLabel = context.lingo.localize("dwellers.hp", locale: locale)
        let stimpaksLabel = context.lingo.localize("resources.stimpaks", locale: locale)
        let radawayLabel = context.lingo.localize("resources.radaway", locale: locale)
        let statusLabel = context.lingo.localize("explore.status", locale: locale)
        let timeLabel = context.lingo.localize("explore.time", locale: locale)
        let radLabel = context.lingo.localize("explore.rad", locale: locale)
        let capsLabel = context.lingo.localize("explore.caps", locale: locale)
        let itemsLabel = context.lingo.localize("explore.items", locale: locale)
        let eventsLabel = context.lingo.localize("explore.events", locale: locale)

        let statusText = localizeStatus(exploration: exploration, locale: locale, lingo: context.lingo)

        let text = """
        📋 <b>\(title)</b>

        \(exploration.statusEmoji) <b>\(exploration.dwellerName)</b>
        📍 \(statusLabel): \(statusText)
        ⏱️ \(timeLabel): \(exploration.explorationTimeFormatted)

        \(hpLabel): \(exploration.healthBar()) \(Int(exploration.currentHP))/\(Int(exploration.maxHP))
        ☢️ \(radLabel): \(Int(exploration.radiation))%
        💊 \(stimpaksLabel): \(exploration.stimpaks)
        ☢️ \(radawayLabel): \(exploration.radAway)

        💰 \(capsLabel): \(exploration.capsCollected)
        📦 \(itemsLabel): \(exploration.itemsCollected)/\(Exploration.maxItems)

        📜 <b>\(eventsLabel):</b>
        <code>\(eventLog)</code>
        """

        var inlineKeyboard: [[TGInlineKeyboardButton]] = []

        if exploration.statusEnum == .exploring {
            let recallText = context.lingo.localize("explore.recall", locale: locale)
            let recallButton = TGInlineKeyboardButton(
                text: "🔙 \(recallText)",
                callbackData: "exp.rec:\(explorationShortID)"
            )
            inlineKeyboard.append([recallButton])
        }

        if exploration.statusEnum == .completed || exploration.statusEnum == .dead {
            let collectText = context.lingo.localize("explore.collect", locale: locale)
            let collectButton = TGInlineKeyboardButton(
                text: "✅ \(collectText)",
                callbackData: "exp.col:\(explorationShortID)"
            )
            inlineKeyboard.append([collectButton])
        }

        let refreshText = context.lingo.localize("explore.refresh", locale: locale)
        let refreshButton = TGInlineKeyboardButton(
            text: "🔄 \(refreshText)",
            callbackData: "exp.det:\(explorationShortID)"
        )
        inlineKeyboard.append([refreshButton])

        let backText = context.lingo.localize("button.back", locale: locale)
        let backButton = TGInlineKeyboardButton(text: backText, callbackData: "exp.menu")
        inlineKeyboard.append([backButton])

        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }

    public func recallExplorer(context: Context, explorationShortID: String) async throws {
        guard let exploration = try await findExplorationByShortID(explorationShortID, on: context.db) else {
            try await showExplorationMenu(context: context)
            return
        }

        let locale = context.session.locale

        guard exploration.statusEnum == .exploring else {
            let cannotRecall = context.lingo.localize("explore.cannot.recall", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(cannotRecall)", parseMode: .html)
            return
        }

        exploration.status = ExplorationStatus.returning.rawValue
        exploration.returnStartTime = Date()
        try await exploration.save(on: context.db)

        let recalledText = context.lingo.localize("explore.recalled", locale: locale, interpolations: [
            "dweller": exploration.dwellerName,
            "time": "\(exploration.expectedReturnDuration)"
        ])

        try await context.bot.sendMessage(session: context.session, text: "🔙 \(recalledText)", parseMode: .html)
        try await showExplorationDetail(context: context, explorationShortID: explorationShortID)
    }

    public func collectLoot(context: Context, explorationShortID: String) async throws {
        guard let exploration = try await findExplorationByShortID(explorationShortID, on: context.db) else {
            try await showExplorationMenu(context: context)
            return
        }

        let locale = context.session.locale

        guard exploration.statusEnum == .completed || exploration.statusEnum == .dead else {
            let cannotCollect = context.lingo.localize("explore.cannot.collect", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(cannotCollect)", parseMode: .html)
            return
        }

        let vault = try await Vault.forUser(context.session, on: context.db)
        let dweller = try await DwellerModel.query(on: context.db)
            .filter(\DwellerModel.$id, .equal, exploration.$dweller.id)
            .first()

        vault.caps += exploration.capsCollected
        try await vault.save(on: context.db)

        if let dweller = dweller, exploration.statusEnum == .completed {
            dweller.currentHP = exploration.currentHP
            dweller.radiation = exploration.radiation
            dweller.level = exploration.dwellerLevel
            dweller.experience = exploration.dwellerXP
            try await dweller.save(on: context.db)
        }

        try await exploration.delete(on: context.db)

        let collectedText = context.lingo.localize("explore.collected", locale: locale, interpolations: [
            "dweller": exploration.dwellerName,
            "caps": "\(exploration.capsCollected)",
            "items": "\(exploration.itemsCollected)"
        ])

        try await context.bot.sendMessage(session: context.session, text: "✅ \(collectedText)", parseMode: .html)
        try await showExplorationMenu(context: context)
    }

    // MARK: - Exploration Helpers

    func localizeStatus(exploration: ExplorationModel, locale: String, lingo: Lingo) -> String {
        let loot = "💰\(exploration.capsCollected) 📦\(exploration.itemsCollected)"
        switch exploration.statusEnum {
        case .exploring:
            let statusStr = lingo.localize("explore.exploring", locale: locale)
            return "\(statusStr) (\(exploration.explorationTimeFormatted)) | \(loot)"
        case .returning:
            let statusStr = lingo.localize("explore.returning", locale: locale)
            let progress = Int(exploration.returnProgress * 100)
            return "\(statusStr) (\(progress)%) | \(loot)"
        case .completed:
            let statusStr = lingo.localize("explore.completed", locale: locale)
            return "\(statusStr) | \(loot)"
        case .dead:
            let statusStr = lingo.localize("explore.dead", locale: locale)
            return "\(statusStr) | \(loot)"
        }
    }

    func localizeEventLine(event: ExplorationEvent, locale: String, lingo: Lingo) -> String {
        let timeStr = formatEventTime(event.timestamp)
        let eventEmoji = eventTypeEmoji(event.type)

        if event.description.contains("left the vault") {
            let parts = event.description.components(separatedBy: " left the vault")
            let dwellerName = parts.first ?? ""
            let localizedDesc = lingo.localize("explore.departed", locale: locale, interpolations: [
                "dweller": dwellerName
            ])
            return "[\(timeStr)] \(eventEmoji) \(localizedDesc)"
        }

        return "[\(timeStr)] \(eventEmoji) \(event.description)"
    }

    func formatEventTime(_ timestamp: Int) -> String {
        let hours = timestamp / 60
        let mins = timestamp % 60
        return String(format: "%d:%02d", hours, mins)
    }

    func eventTypeEmoji(_ type: ExplorationEventType) -> String {
        switch type {
        case .combat: return "⚔️"
        case .lootDiscovery: return "🎁"
        case .junkScavenging: return "📦"
        case .capsFound: return "💰"
        case .locationFound: return "📍"
        case .npcEncounter: return "🗣️"
        case .radiationZone: return "☢️"
        case .recipeFound: return "📜"
        case .levelUp: return "⬆️"
        case .stimpakUsed: return "💊"
        case .radAwayUsed: return "💉"
        case .death: return "💀"
        }
    }
}

// MARK: - Incident Methods
extension VaultController {

    public func showIncidentsList(context: Context) async throws {
        let vault = try await Vault.forUser(context.session, on: context.db)
        guard let vaultID = vault.id else { return }

        let locale = context.session.locale
        let title = context.lingo.localize("incidents.title", locale: locale)

        let incidents = try await IncidentModel.activeIncidents(vaultID: vaultID, on: context.db)

        if incidents.isEmpty {
            let noIncidents = context.lingo.localize("incidents.none", locale: locale)
            let text = "🚨 <b>\(title)</b>\n\n\(noIncidents)"
            try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html)
            return
        }

        var text = "🚨 <b>\(title)</b>\n\n"
        for incident in incidents {
            let progress = Int(incident.progressPercent)
            let hp = "\(incident.currentHP)/\(incident.maxHP)"
            let typeName = context.lingo.localize("incident.\(incident.type)", locale: locale)

            if let incidentType = incident.incidentType {
                text += "\(incidentType.emoji) <b>\(typeName)</b>\n"
                text += "   ❤️ \(hp) (\(progress)% damaged)\n"

                if incident.capsStolen > 0 {
                    text += "   💰 Stolen: \(incident.capsStolen) caps\n"
                }
                text += "\n"
            }
        }

        var inlineKeyboard: [[TGInlineKeyboardButton]] = []
        for incident in incidents {
            if let incidentType = incident.incidentType {
                let typeName = context.lingo.localize("incident.\(incident.type)", locale: locale)
                let button = TGInlineKeyboardButton(
                    text: "\(incidentType.emoji) \(typeName) - \(incident.currentHP) HP",
                    callbackData: "inc:\(incident.shortID)"
                )
                inlineKeyboard.append([button])
            }
        }

        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }

    public func showIncidentDetail(context: Context, incidentShortID: String) async throws {
        print("[VaultController] showIncidentDetail called with shortID: '\(incidentShortID)'")

        let vault = try await Vault.forUser(context.session, on: context.db)
        guard let vaultID = vault.id else {
            print("[VaultController] showIncidentDetail: No vault ID found")
            return
        }

        let locale = context.session.locale

        // List all active incidents for debugging
        let allIncidents = try await IncidentModel.activeIncidents(vaultID: vaultID, on: context.db)
        print("[VaultController] Active incidents: \(allIncidents.map { "id=\($0.id?.uuidString ?? "nil"), shortID=\($0.shortID)" })")

        guard let incident = try await IncidentModel.findByShortID(incidentShortID, vaultID: vaultID, on: context.db),
              let incidentType = incident.incidentType else {
            print("[VaultController] showIncidentDetail: Incident not found for shortID '\(incidentShortID)'")
            let notFound = context.lingo.localize("incidents.not.found", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(notFound)", parseMode: .html)
            return
        }

        print("[VaultController] showIncidentDetail: Found incident type=\(incidentType.rawValue)")

        let room = try await RoomModel.find(incident.roomID, on: context.db)
        let roomName: String
        if let room = room, let roomType = room.roomType {
            roomName = "\(roomType.emoji) " + context.lingo.localize("room.\(roomType.rawValue)", locale: locale)
        } else {
            roomName = context.lingo.localize("incidents.unknown.room", locale: locale)
        }

        let typeName = context.lingo.localize("incident.\(incident.type)", locale: locale)
        let progress = Int(incident.progressPercent)

        var text = "🚨 <b>\(incidentType.emoji) \(typeName)</b>\n\n"
        text += "📍 " + context.lingo.localize("incidents.location", locale: locale) + ": \(roomName)\n"
        text += "❤️ HP: \(incident.currentHP)/\(incident.maxHP) (\(progress)% damaged)\n"

        if incidentType.dealsRadiation {
            text += "☢️ " + context.lingo.localize("incidents.deals.radiation", locale: locale) + "\n"
        }

        if incident.capsStolen > 0 {
            text += "💰 " + context.lingo.localize("incidents.caps.stolen", locale: locale) + ": \(incident.capsStolen)\n"
        }

        let dwellersInRoom = try await DwellerModel.query(on: context.db)
            .filter(\.$assignedRoom.$id == incident.roomID)
            .filter(\.$currentHP > 0)
            .all()

        text += "\n👥 " + context.lingo.localize("incidents.defenders", locale: locale) + ": \(dwellersInRoom.count)\n"

        for dweller in dwellersInRoom {
            let hpBar = Self.hpBar(current: Int(dweller.currentHP), max: Int(dweller.maxHP))
            text += "   \(dweller.fullName) \(hpBar) \(Int(dweller.currentHP))/\(Int(dweller.maxHP))\n"
        }

        let log = incident.combatLog.suffix(5)
        if !log.isEmpty {
            text += "\n📜 " + context.lingo.localize("incidents.combat.log", locale: locale) + ":\n"
            for entry in log {
                text += "   • \(entry.description)\n"
            }
        }

        var inlineKeyboard: [[TGInlineKeyboardButton]] = []

        let sendText = context.lingo.localize("button.send.fighters", locale: locale)
        let sendButton = TGInlineKeyboardButton(
            text: "⚔️ \(sendText)",
            callbackData: "inc.send:\(incidentShortID)"
        )
        inlineKeyboard.append([sendButton])

        if vault.stimpaks > 0 && dwellersInRoom.contains(where: { $0.currentHP < $0.maxHP }) {
            let stimpakText = context.lingo.localize("button.use.stimpak", locale: locale)
            let stimpakButton = TGInlineKeyboardButton(
                text: "💊 \(stimpakText)",
                callbackData: "inc.stim:\(incidentShortID)"
            )
            inlineKeyboard.append([stimpakButton])
        }

        let backText = context.lingo.localize("button.back", locale: locale)
        let backButton = TGInlineKeyboardButton(text: "⬅️ \(backText)", callbackData: "inc.list")
        inlineKeyboard.append([backButton])

        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }

    public func showSendFighters(context: Context, incidentShortID: String) async throws {
        let vault = try await Vault.forUser(context.session, on: context.db)
        guard let vaultID = vault.id else { return }

        let locale = context.session.locale

        guard let incident = try await IncidentModel.findByShortID(incidentShortID, vaultID: vaultID, on: context.db) else {
            let notFound = context.lingo.localize("incidents.not.found", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(notFound)", parseMode: .html)
            return
        }

        // Get dwellers already in the incident room (they're already fighting)
        let dwellersInRoom = try await DwellerModel.query(on: context.db)
            .filter(\.$assignedRoom.$id == incident.roomID)
            .all()
        let dwellersInRoomIDs = Set(dwellersInRoom.compactMap { $0.id })

        // Get ALL dwellers in the vault with HP > 0 (even those working in other rooms)
        let allDwellers = try await DwellerModel.query(on: context.db)
            .filter(\.$vault.$id == vaultID)
            .filter(\.$currentHP > 0)
            .all()

        // Filter out dwellers already fighting this incident
        let availableDwellers = allDwellers.filter { !dwellersInRoomIDs.contains($0.id ?? UUID()) }

        print("[VaultController] showSendFighters: incidentRoom=\(incident.roomID), dwellersInRoom=\(dwellersInRoom.count), allDwellers=\(allDwellers.count), availableDwellers=\(availableDwellers.count)")

        let title = context.lingo.localize("incidents.send.title", locale: locale)
        var text = "⚔️ <b>\(title)</b>\n\n"

        if availableDwellers.isEmpty {
            if allDwellers.isEmpty {
                text += context.lingo.localize("incidents.no.available.dwellers", locale: locale)
                text += "\n\n⚠️ (No dwellers found in vault)"
            } else {
                text += context.lingo.localize("incidents.no.available.dwellers", locale: locale)
                text += "\n\n⚠️ (All \(allDwellers.count) dwellers are already fighting this incident)"
            }
            try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html)
            return
        }

        text += context.lingo.localize("incidents.select.fighter", locale: locale) + "\n"

        var inlineKeyboard: [[TGInlineKeyboardButton]] = []
        for dweller in availableDwellers.prefix(10) {
            let shortDwellerID = String(dweller.id?.uuidString.prefix(8) ?? "")
            let hpInfo = "❤️\(Int(dweller.currentHP))/\(Int(dweller.maxHP))"
            let weaponInfo = dweller.weaponID != nil ? "⚔️" : "👊"

            let button = TGInlineKeyboardButton(
                text: "\(dweller.rarityEmoji) \(dweller.fullName) \(hpInfo) \(weaponInfo)",
                callbackData: "inc.fight:\(incidentShortID):\(shortDwellerID)"
            )
            inlineKeyboard.append([button])
        }

        let backText = context.lingo.localize("button.back", locale: locale)
        let backButton = TGInlineKeyboardButton(text: "⬅️ \(backText)", callbackData: "inc:\(incidentShortID)")
        inlineKeyboard.append([backButton])

        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }

    public func sendDwellerToFight(context: Context, incidentShortID: String, dwellerShortID: String) async throws {
        let vault = try await Vault.forUser(context.session, on: context.db)
        guard let vaultID = vault.id else { return }

        let locale = context.session.locale

        guard let incident = try await IncidentModel.findByShortID(incidentShortID, vaultID: vaultID, on: context.db) else {
            let notFound = context.lingo.localize("incidents.not.found", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(notFound)", parseMode: .html)
            return
        }

        guard let dweller = try await findDwellerByShortIDAndVault(dwellerShortID, vaultID: vaultID, on: context.db) else {
            let notFound = context.lingo.localize("dwellers.empty", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(notFound)", parseMode: .html)
            return
        }

        dweller.$assignedRoom.id = incident.roomID
        try await dweller.save(on: context.db)

        let sent = context.lingo.localize("incidents.dweller.sent", locale: locale, interpolations: [
            "dweller": dweller.fullName
        ])
        try await context.bot.sendMessage(session: context.session, text: "✅ \(sent)", parseMode: .html)

        try await showIncidentDetail(context: context, incidentShortID: incidentShortID)
    }

    public func useStimpakInIncident(context: Context, incidentShortID: String) async throws {
        let vault = try await Vault.forUser(context.session, on: context.db)
        guard let vaultID = vault.id else { return }

        let locale = context.session.locale

        guard vault.stimpaks > 0 else {
            let noStimpaks = context.lingo.localize("incidents.no.stimpaks", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(noStimpaks)", parseMode: .html)
            return
        }

        guard let incident = try await IncidentModel.findByShortID(incidentShortID, vaultID: vaultID, on: context.db) else {
            let notFound = context.lingo.localize("incidents.not.found", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(notFound)", parseMode: .html)
            return
        }

        let dwellersInRoom = try await DwellerModel.query(on: context.db)
            .filter(\.$assignedRoom.$id == incident.roomID)
            .filter(\.$currentHP > 0)
            .all()

        guard let mostInjured = dwellersInRoom.min(by: {
            Double($0.currentHP) / Double($0.maxHP) < Double($1.currentHP) / Double($1.maxHP)
        }), mostInjured.currentHP < mostInjured.maxHP else {
            let noNeedHealing = context.lingo.localize("incidents.no.need.healing", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "ℹ️ \(noNeedHealing)", parseMode: .html)
            return
        }

        let healPercent = Double.random(in: 0.40...0.50)
        let healAmount = mostInjured.maxHP * healPercent
        mostInjured.currentHP = min(mostInjured.maxHP, mostInjured.currentHP + healAmount)
        try await mostInjured.save(on: context.db)

        vault.stimpaks -= 1
        try await vault.save(on: context.db)

        let healed = context.lingo.localize("incidents.stimpak.used", locale: locale, interpolations: [
            "dweller": mostInjured.fullName,
            "amount": String(Int(healAmount))
        ])
        try await context.bot.sendMessage(session: context.session, text: "💊 \(healed)", parseMode: .html)

        try await showIncidentDetail(context: context, incidentShortID: incidentShortID)
    }

    public func sendIncidentAlert(vaultID: UUID, incident: Incident, on db: any Database, bot: TGBot, lingo: Lingo) async throws {
        guard let vault = try await Vault.find(vaultID, on: db),
              let owner = try await User.find(vault.$user.id, on: db) else {
            return
        }

        let locale = owner.locale
        let typeName = lingo.localize("incident.\(incident.type.rawValue)", locale: locale)
        let alertTitle = lingo.localize("incidents.alert", locale: locale)

        let room = try await RoomModel.find(incident.roomID, on: db)
        let roomName: String
        if let room = room, let roomType = room.roomType {
            roomName = "\(roomType.emoji) " + lingo.localize("room.\(roomType.rawValue)", locale: locale)
        } else {
            roomName = lingo.localize("incidents.unknown.room", locale: locale)
        }

        let text = """
        🚨 <b>\(alertTitle)</b>

        \(incident.type.emoji) <b>\(typeName)</b>
        📍 \(roomName)
        """

        let viewText = lingo.localize("button.view.incident", locale: locale)
        let incidentShortID = incident.id.uuidString.prefix(8)
        let inlineKeyboard = [[
            TGInlineKeyboardButton(
                text: "⚔️ \(viewText)",
                callbackData: "inc:\(incidentShortID)"
            )
        ]]

        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        let chatId = TGChatId.chat(owner.telegramId)
        let params = TGSendMessageParams(chatId: chatId, text: text, parseMode: .html, replyMarkup: markup)
        _ = try? await bot.sendMessage(params: params)
    }

    static func hpBar(current: Int, max: Int) -> String {
        guard max > 0 else { return "❤️" }
        let percent = Double(current) / Double(max)
        let filled = Int(percent * 5)
        let empty = 5 - filled
        return String(repeating: "🟩", count: filled) + String(repeating: "⬛", count: empty)
    }
}

// MARK: - Helper Methods
extension VaultController {

    func findDwellerByShortID(_ shortID: String, on db: any Database) async throws -> DwellerModel? {
        let dwellers = try await DwellerModel.query(on: db).all()
        return dwellers.first { dweller in
            guard let id = dweller.id?.uuidString else { return false }
            return id.prefix(8).lowercased() == shortID.lowercased()
        }
    }

    func findDwellerByShortIDAndVault(_ shortID: String, vaultID: UUID, on db: any Database) async throws -> DwellerModel? {
        let dwellers = try await DwellerModel.query(on: db)
            .filter(\.$vault.$id == vaultID)
            .all()
        return dwellers.first { dweller in
            guard let id = dweller.id?.uuidString else { return false }
            return id.prefix(8).lowercased() == shortID.lowercased()
        }
    }

    func findExplorationByShortID(_ shortID: String, on db: any Database) async throws -> ExplorationModel? {
        let explorations = try await ExplorationModel.query(on: db).all()
        return explorations.first { exploration in
            guard let id = exploration.id?.uuidString else { return false }
            return id.prefix(8).lowercased() == shortID.lowercased()
        }
    }

    func findRoomByShortID(_ shortID: String, vault: Vault, db: any Database) async throws -> RoomModel? {
        let rooms = try await vault.getRooms(on: db)
        return rooms.first { room in
            guard let id = room.id?.uuidString else { return false }
            return id.prefix(8).lowercased() == shortID.lowercased()
        }
    }

    func unassignDweller(context: Context, shortID: String) async throws {
        guard let dweller = try await findDwellerByShortID(shortID, on: context.db) else {
            return
        }

        let locale = context.session.locale

        guard dweller.$assignedRoom.id != nil else {
            let notAssigned = context.lingo.localize("unassign.not.assigned", locale: locale, interpolations: [
                "dweller": dweller.fullName
            ])
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(notAssigned)", parseMode: .html)
            return
        }

        dweller.$assignedRoom.id = nil
        try await dweller.save(on: context.db)

        let successText = context.lingo.localize("unassign.success", locale: locale, interpolations: [
            "dweller": dweller.fullName,
            "room": ""
        ])

        try await context.bot.sendMessage(session: context.session, text: "✅ \(successText)", parseMode: .html)

        if let dwellerID = dweller.id {
            try await showDwellerDetail(context: context, dwellerID: dwellerID)
        }
    }

    func reviveDweller(context: Context, shortID: String) async throws {
        guard let dweller = try await findDwellerByShortID(shortID, on: context.db) else {
            return
        }

        let locale = context.session.locale

        // Check if dweller is actually dead
        guard dweller.currentHP <= 0 else {
            try await showDwellerDetail(context: context, dwellerID: dweller.id!)
            return
        }

        // Get vault and check caps
        let vault = try await Vault.forUser(context.session, on: context.db)
        var gameDweller = dweller.toDweller()
        let reviveCost = gameDweller.revivalCost

        guard vault.caps >= reviveCost else {
            let notEnoughCaps = context.lingo.localize("revive.insufficient.caps", locale: locale, interpolations: [
                "have": "\(vault.caps)",
                "need": "\(reviveCost)"
            ])
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(notEnoughCaps)", parseMode: .html)
            return
        }

        // Deduct caps and revive
        vault.caps -= reviveCost
        try await vault.save(on: context.db)

        // Use GameLogic's revive method
        gameDweller.revive()

        // Update dweller model
        dweller.currentHP = gameDweller.currentHP
        try await dweller.save(on: context.db)

        let successText = context.lingo.localize("revive.success", locale: locale, interpolations: [
            "dweller": dweller.fullName,
            "cost": "\(reviveCost)"
        ])
        try await context.bot.sendMessage(session: context.session, text: "✅ \(successText)", parseMode: .html)

        // Show updated dweller detail
        if let dwellerID = dweller.id {
            try await showDwellerDetail(context: context, dwellerID: dwellerID)
        }
    }
}

// MARK: - Callback Queries Processing
extension VaultController {
    static func onCallbackQuery(context: Context) async throws -> Bool {
        guard let query = context.update.callbackQuery else {
            print("[VaultController] onCallbackQuery: No callbackQuery in update")
            return false
        }
        guard let data = query.data else {
            print("[VaultController] onCallbackQuery: No data in callbackQuery")
            return false
        }

        print("[VaultController] onCallbackQuery received: '\(data)'")

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

        // MARK: - Dweller Callbacks

        if data.starts(with: "dweller:") {
            let dwellerIDString = data.replacingOccurrences(of: "dweller:", with: "")
            if let dwellerID = UUID(uuidString: dwellerIDString) {
                try await controller.showDwellerDetail(context: context, dwellerID: dwellerID)
            }
            return true
        }

        if data == "d.list" {
            try await controller.showDwellersList(context: context)
            return true
        }

        if data.starts(with: "d.un:") {
            let shortID = data.replacingOccurrences(of: "d.un:", with: "")
            try await controller.unassignDweller(context: context, shortID: shortID)
            return true
        }

        if data.starts(with: "d.rev:") {
            let shortID = data.replacingOccurrences(of: "d.rev:", with: "")
            try await controller.reviveDweller(context: context, shortID: shortID)
            return true
        }

        // MARK: - Build Callbacks

        if data.starts(with: "build.category:") {
            let categoryRaw = data.replacingOccurrences(of: "build.category:", with: "")
            if let category = RoomCategory(rawValue: categoryRaw) {
                try await controller.showRoomsInCategory(context: context, category: category)
            }
            return true
        }

        if data.starts(with: "build.select:") {
            let roomRaw = data.replacingOccurrences(of: "build.select:", with: "")
            if let roomType = RoomType(rawValue: roomRaw) {
                try await controller.showPositionSelection(context: context, roomType: roomType)
            }
            return true
        }

        if data.starts(with: "build.position:") {
            let parts = data.replacingOccurrences(of: "build.position:", with: "").split(separator: ":")
            if parts.count == 3,
               let roomType = RoomType(rawValue: String(parts[0])),
               let x = Int(parts[1]),
               let y = Int(parts[2]) {
                try await controller.confirmBuild(context: context, roomType: roomType, x: x, y: y)
            }
            return true
        }

        if data.starts(with: "build.confirm:") {
            let parts = data.replacingOccurrences(of: "build.confirm:", with: "").split(separator: ":")
            if parts.count == 3,
               let roomType = RoomType(rawValue: String(parts[0])),
               let x = Int(parts[1]),
               let y = Int(parts[2]) {
                try await controller.executeBuild(context: context, roomType: roomType, x: x, y: y)
            }
            return true
        }

        if data == "build.back" {
            try await controller.showBuildMenu(context: context)
            return true
        }

        // MARK: - Room Callbacks

        if data == "r.list" {
            try await controller.showRoomsList(context: context)
            return true
        }

        if data.starts(with: "r.d:") {
            let shortID = data.replacingOccurrences(of: "r.d:", with: "")
            let vault = try await Vault.forUser(context.session, on: context.db)
            if let room = try await controller.findRoomByShortID(shortID, vault: vault, db: context.db) {
                try await controller.showRoomDetail(context: context, roomID: room.id!)
            }
            return true
        }

        if data.starts(with: "r.up:") {
            let shortID = data.replacingOccurrences(of: "r.up:", with: "")
            let vault = try await Vault.forUser(context.session, on: context.db)
            if let room = try await controller.findRoomByShortID(shortID, vault: vault, db: context.db) {
                try await controller.upgradeRoom(context: context, roomID: room.id!)
            }
            return true
        }

        if data.starts(with: "r.as:") {
            let shortID = data.replacingOccurrences(of: "r.as:", with: "")
            let vault = try await Vault.forUser(context.session, on: context.db)
            if let room = try await controller.findRoomByShortID(shortID, vault: vault, db: context.db) {
                try await controller.showAssignDwellerToRoom(context: context, roomID: room.id!)
            }
            return true
        }

        if data.starts(with: "a.d:") {
            let parts = data.replacingOccurrences(of: "a.d:", with: "").split(separator: ":")
            if parts.count == 2 {
                let roomShortID = String(parts[0])
                let dwellerShortID = String(parts[1])
                let vault = try await Vault.forUser(context.session, on: context.db)
                if let room = try await controller.findRoomByShortID(roomShortID, vault: vault, db: context.db),
                   let dweller = try await controller.findDwellerByShortID(dwellerShortID, on: context.db) {
                    try await controller.assignDwellerToRoom(context: context, roomID: room.id!, dwellerID: dweller.id!)
                }
            }
            return true
        }

        // MARK: - Exploration Callbacks

        if data == "exp.menu" {
            try await controller.showExplorationMenu(context: context)
            return true
        }

        if data == "exp.back" {
            try await controller.showVaultMenu(context: context)
            return true
        }

        if data == "exp.send" {
            try await controller.showDwellerSelectionForExploration(context: context)
            return true
        }

        if data.starts(with: "exp.sel:") {
            let shortID = data.replacingOccurrences(of: "exp.sel:", with: "")
            try await controller.showSupplySelection(context: context, dwellerShortID: shortID, stimpaks: 0, radaway: 0)
            return true
        }

        if data.starts(with: "exp.sup:") {
            let parts = data.replacingOccurrences(of: "exp.sup:", with: "").split(separator: ":")
            if parts.count >= 3,
               let stimpaks = Int(parts[1]),
               let radaway = Int(parts[2]) {
                let dwellerShortID = String(parts[0])
                try await controller.showSupplySelection(context: context, dwellerShortID: dwellerShortID, stimpaks: stimpaks, radaway: radaway)
            }
            return true
        }

        if data == "exp.nop" {
            return true
        }

        if data.starts(with: "exp.go:") {
            let parts = data.replacingOccurrences(of: "exp.go:", with: "").split(separator: ":")
            if parts.count >= 3,
               let stimpaks = Int(parts[1]),
               let radaway = Int(parts[2]) {
                let dwellerShortID = String(parts[0])
                try await controller.sendExplorer(context: context, dwellerShortID: dwellerShortID, stimpaks: stimpaks, radaway: radaway)
            }
            return true
        }

        if data.starts(with: "exp.det:") {
            let shortID = data.replacingOccurrences(of: "exp.det:", with: "")
            try await controller.showExplorationDetail(context: context, explorationShortID: shortID)
            return true
        }

        if data.starts(with: "exp.rec:") {
            let shortID = data.replacingOccurrences(of: "exp.rec:", with: "")
            try await controller.recallExplorer(context: context, explorationShortID: shortID)
            return true
        }

        if data.starts(with: "exp.col:") {
            let shortID = data.replacingOccurrences(of: "exp.col:", with: "")
            try await controller.collectLoot(context: context, explorationShortID: shortID)
            return true
        }

        // MARK: - Incident Callbacks

        if data == "inc.list" {
            try await controller.showIncidentsList(context: context)
            return true
        }

        if data.starts(with: "inc:") && !data.contains(".") {
            let shortID = data.replacingOccurrences(of: "inc:", with: "")
            print("[VaultController] Handling incident detail for shortID: '\(shortID)'")
            try await controller.showIncidentDetail(context: context, incidentShortID: shortID)
            return true
        }

        if data.starts(with: "inc.send:") {
            let shortID = data.replacingOccurrences(of: "inc.send:", with: "")
            try await controller.showSendFighters(context: context, incidentShortID: shortID)
            return true
        }

        if data.starts(with: "inc.fight:") {
            let parts = data.replacingOccurrences(of: "inc.fight:", with: "").split(separator: ":")
            if parts.count == 2 {
                let incidentID = String(parts[0])
                let dwellerID = String(parts[1])
                try await controller.sendDwellerToFight(context: context, incidentShortID: incidentID, dwellerShortID: dwellerID)
            }
            return true
        }

        if data.starts(with: "inc.stim:") {
            let shortID = data.replacingOccurrences(of: "inc.stim:", with: "")
            try await controller.useStimpakInIncident(context: context, incidentShortID: shortID)
            return true
        }

        print("[VaultController] onCallbackQuery: Unhandled callback data: '\(data)'")
        return false
    }
}
