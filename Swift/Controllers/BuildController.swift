//
//  BuildController.swift
//  Vaultown
//
//  Controller for room building and upgrades
//

import Foundation
import Fluent
import Lingo
import SwiftTelegramBot
import GameLogic

// MARK: - Build Controller Logic
final class BuildController: TGControllerBase, @unchecked Sendable {
    typealias T = BuildController

    // MARK: - Controller Lifecycle
    override public func attachHandlers(to bot: TGBot, lingo: Lingo) async {
        let router = Router(bot: bot) { router in
            router[Commands.start.command()] = onStart
            router[Commands.build.command()] = onBuild

            // Build button locales
            let buildLocales = Commands.build.buttonsForAllLocales(lingo: lingo)
            for button in buildLocales { router[button.text] = onBuild }

            // Rooms button locales
            let roomsLocales = Commands.rooms.buttonsForAllLocales(lingo: lingo)
            for button in roomsLocales { router[button.text] = onRoomsList }

            // Cancel/back button locales
            let cancelLocales = Commands.cancel.buttonsForAllLocales(lingo: lingo)
            for button in cancelLocales { router[button.text] = onBack }

            // Handle navigation to other menus (when user presses buttons from vault keyboard)
            let dwellersLocales = Commands.dwellers.buttonsForAllLocales(lingo: lingo)
            for button in dwellersLocales { router[button.text] = onDwellers }

            let resourcesLocales = Commands.resources.buttonsForAllLocales(lingo: lingo)
            for button in resourcesLocales { router[button.text] = onResources }

            let settingsLocales = Commands.settings.buttonsForAllLocales(lingo: lingo)
            for button in settingsLocales { router[button.text] = onSettings }

            router.unmatched = unmatched
            router[.callback_query(data: nil)] = BuildController.onCallbackQuery
        }
        await processRouterForEachName(router)
    }

    public func onStart(context: Context) async throws -> Bool {
        try await showBuildMenu(context: context)
        return true
    }

    private func onBack(context: Context) async throws -> Bool {
        // Go back to vault controller
        let vaultController = Controllers.vaultController
        try await vaultController.showVaultMenu(context: context)
        context.session.routerName = vaultController.routerName
        try await context.session.saveAndCache(in: context.db)
        return true
    }

    private func onDwellers(context: Context) async throws -> Bool {
        // Navigate to dwellers in vault controller
        let vaultController = Controllers.vaultController
        try await vaultController.showDwellersList(context: context)
        context.session.routerName = vaultController.routerName
        try await context.session.saveAndCache(in: context.db)
        return true
    }

    private func onResources(context: Context) async throws -> Bool {
        // Navigate to resources in vault controller
        let vaultController = Controllers.vaultController
        try await vaultController.showResourcesDetail(context: context)
        context.session.routerName = vaultController.routerName
        try await context.session.saveAndCache(in: context.db)
        return true
    }

    private func onSettings(context: Context) async throws -> Bool {
        // Navigate to settings controller
        let settingsController = Controllers.settingsController
        try await settingsController.showSettingsMenu(context: context)
        context.session.routerName = settingsController.routerName
        try await context.session.saveAndCache(in: context.db)
        return true
    }

    override func unmatched(context: Context) async throws -> Bool {
        guard try await super.unmatched(context: context) else { return false }
        return try await onStart(context: context)
    }

    private func onBuild(context: Context) async throws -> Bool {
        try await showBuildMenu(context: context)
        return true
    }

    private func onRoomsList(context: Context) async throws -> Bool {
        try await showRoomsList(context: context)
        return true
    }

    // MARK: - Display Methods

    public func showBuildMenu(context: Context, text: String? = nil) async throws {
        let locale = context.session.locale
        let title = context.lingo.localize("build.title", locale: locale)
        let selectCategory = context.lingo.localize("build.select.category", locale: locale)

        let text = text ?? """
        🔨 <b>\(title)</b>

        \(selectCategory)
        """

        // Create category selection buttons
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

        // Get buildable rooms in this category (filter out non-buildable like vault door)
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

        // Add back button
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

        // Display current vault grid
        text += renderVaultGrid(existingRooms)

        // Find available positions
        let availablePositions = findAvailablePositions(existingRooms: existingRooms, roomWidth: 1, roomType: roomType)

        var inlineKeyboard: [[TGInlineKeyboardButton]] = []

        // Limit to 10 positions to avoid too long keyboard
        for position in availablePositions.prefix(10) {
            let button = TGInlineKeyboardButton(
                text: "[\(position.x),\(position.y)]",
                callbackData: "build.position:\(roomType.rawValue):\(position.x):\(position.y)"
            )
            inlineKeyboard.append([button])
        }

        // Add back button
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

        // Validate position
        guard RoomModel.isValidPosition(x: x, y: y, width: 1, existingRooms: existingRooms) else {
            let errorText = context.lingo.localize("build.invalid.position", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "❌ \(errorText)", parseMode: .html)
            return
        }

        // Check if connected (except for first few rooms)
        if existingRooms.count >= 3 && !RoomModel.isConnected(x: x, y: y, width: 1, existingRooms: existingRooms, roomType: roomType) {
            let errorText = context.lingo.localize("build.not.connected", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "❌ \(errorText)", parseMode: .html)
            return
        }

        // Check caps
        guard vault.caps >= cost else {
            let errorText = context.lingo.localize("build.insufficient.caps", locale: locale, interpolations: [
                "have": "\(vault.caps)",
                "need": "\(cost)"
            ])
            try await context.bot.sendMessage(session: context.session, text: "❌ \(errorText)", parseMode: .html)
            return
        }

        // Deduct caps
        vault.caps -= cost
        try await vault.save(on: context.db)

        // Create room
        let room = RoomModel(vaultID: vault.id!, type: roomType, x: x, y: y)
        try await room.save(on: context.db)

        // Success message
        let successText = context.lingo.localize("build.success", locale: locale, interpolations: [
            "room": roomName
        ])

        try await context.bot.sendMessage(session: context.session, text: "✅ \(successText)", parseMode: .html)

        // Try to merge with adjacent rooms of same type and level
        try await tryMergeRooms(context: context, newRoom: room)

        // Show updated vault menu
        _ = try await onBack(context: context)
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

        // Group rooms by type for display
        for room in rooms.sorted(by: { ($0.y, $0.x) < ($1.y, $1.x) }) {
            guard let roomType = room.roomType else { continue }
            let roomName = localizedRoomName(roomType, locale: locale, lingo: context.lingo)
            let assignedCount = try await room.assignedCount(on: context.db)

            // Repeat emoji based on room width (merged rooms)
            let widthEmojis = String(repeating: roomType.emoji, count: room.width)

            // Use short room ID (first 8 chars of UUID)
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

        // Repeat emoji based on room width (merged rooms)
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
            // Show each dweller with their relevant SPECIAL stat for this room
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

        // Create action buttons
        var inlineKeyboard: [[TGInlineKeyboardButton]] = []

        // Use short room ID (first 8 chars of UUID)
        let shortRoomID = String(room.id?.uuidString.prefix(8) ?? "")

        // Upgrade button (if upgradable)
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

        // Assign dweller button (if has capacity)
        if assignedCount < room.capacity {
            let assignText = context.lingo.localize("button.assign.dweller", locale: locale)
            let assignButton = TGInlineKeyboardButton(
                text: assignText,
                callbackData: "r.as:\(shortRoomID)"
            )
            inlineKeyboard.append([assignButton])
        }

        // Back button
        let backText = context.lingo.localize("button.back", locale: locale)
        let backButton = TGInlineKeyboardButton(text: backText, callbackData: "r.list")
        inlineKeyboard.append([backButton])

        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: text, parseMode: .html, replyMarkup: markup)
    }

    override public func generateControllerKB(session: User, lingo: Lingo) -> TGReplyMarkup? {
        let markup = TGReplyKeyboardMarkup(keyboard: [
            [
                Commands.build.button(for: session, lingo),
                Commands.rooms.button(for: session, lingo)
            ],
            [
                Commands.cancel.button(for: session, lingo)
            ]
        ], resizeKeyboard: true)
        return TGReplyMarkup.replyKeyboardMarkup(markup)
    }

    // MARK: - Room Merging

    /// Attempt to merge the newly built room with adjacent same-type/same-level rooms
    private func tryMergeRooms(context: Context, newRoom: RoomModel) async throws {
        guard let roomType = newRoom.roomType,
              roomType.canMerge else {
            return  // Room type cannot be merged (e.g., vault door, overseer's office)
        }

        let vault = try await Vault.forUser(context.session, on: context.db)
        let allRooms = try await vault.getRooms(on: context.db)
        let locale = context.session.locale

        // Find adjacent rooms on the same floor with same type and level
        let adjacentRooms = allRooms.filter { room in
            guard room.id != newRoom.id,
                  room.y == newRoom.y,
                  room.type == newRoom.type,
                  room.level == newRoom.level else {
                return false
            }

            // Check if adjacent (touching on left or right)
            let roomEndX = room.x + room.width
            let newRoomEndX = newRoom.x + newRoom.width

            // Room is immediately to the left of newRoom
            if roomEndX == newRoom.x { return true }
            // Room is immediately to the right of newRoom
            if newRoomEndX == room.x { return true }

            return false
        }

        guard !adjacentRooms.isEmpty else { return }

        // Collect all rooms to merge (including the new one)
        var roomsToMerge: [RoomModel] = [newRoom]
        roomsToMerge.append(contentsOf: adjacentRooms)

        // Sort by x position to get correct order
        roomsToMerge.sort { $0.x < $1.x }

        // Calculate total width
        let totalWidth = roomsToMerge.reduce(0) { $0 + $1.width }

        // Check if merge would exceed max width
        guard totalWidth <= 3 else {
            // Can't merge - would exceed triple width
            // Try merging a subset (just the first two touching rooms)
            if roomsToMerge.count >= 2 {
                let firstTwo = Array(roomsToMerge.prefix(2))
                let width = firstTwo.reduce(0) { $0 + $1.width }
                if width <= 3 {
                    try await performMerge(context: context, rooms: firstTwo, locale: locale)
                }
            }
            return
        }

        // Perform the merge
        try await performMerge(context: context, rooms: roomsToMerge, locale: locale)
    }

    /// Perform the actual merge of rooms
    private func performMerge(context: Context, rooms: [RoomModel], locale: String) async throws {
        guard rooms.count >= 2,
              let keepRoom = rooms.first,
              let roomType = keepRoom.roomType else {
            return
        }

        // Calculate new width
        let newWidth = rooms.reduce(0) { $0 + $1.width }
        guard newWidth <= 3 else { return }

        // The leftmost room becomes the merged room
        let leftmostX = rooms.map { $0.x }.min() ?? keepRoom.x

        // Collect all assigned dwellers from rooms being absorbed
        var allDwellerIDs: [UUID] = []
        for room in rooms where room.id != keepRoom.id {
            let dwellers = try await DwellerModel.query(on: context.db)
                .filter(\DwellerModel.$assignedRoom.$id, .equal, room.id)
                .all()
            allDwellerIDs.append(contentsOf: dwellers.compactMap { $0.id })
        }

        // Update the keep room
        keepRoom.x = leftmostX
        keepRoom.width = newWidth
        try await keepRoom.save(on: context.db)

        // Reassign dwellers from absorbed rooms to the merged room
        for dwellerID in allDwellerIDs {
            if let dweller = try await DwellerModel.find(dwellerID, on: context.db) {
                dweller.$assignedRoom.id = keepRoom.id
                try await dweller.save(on: context.db)
            }
        }

        // Delete absorbed rooms
        for room in rooms where room.id != keepRoom.id {
            try await room.delete(on: context.db)
        }

        // Send merge notification
        let roomName = localizedRoomName(roomType, locale: locale, lingo: context.lingo)
        let widthKey = "merge.width.\(RoomWidth(rawValue: newWidth)?.name.lowercased() ?? "single")"
        let widthName = context.lingo.localize(widthKey, locale: locale)

        let mergeText = context.lingo.localize("merge.success", locale: locale, interpolations: [
            "width": widthName,
            "room": roomName
        ])

        try await context.bot.sendMessage(session: context.session, text: "🔗 \(mergeText)", parseMode: .html)
    }

    // MARK: - Helper Methods

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

    /// Calculate escalating room cost based on how many of this type already exist
    /// Formula: baseCost * (existingCount + 1)
    /// Example: First Power Generator = 100, second = 200, third = 300
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
                    // Show emoji for every cell the room occupies
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

        // Find max dimensions
        // For elevators, allow building one floor below existing elevators
        let maxY: Int
        if roomType == .elevator {
            let deepestElevator = existingRooms.filter { $0.roomType == .elevator }.map { $0.y }.max() ?? 0
            maxY = deepestElevator + 1
        } else {
            maxY = existingRooms.map { $0.y }.max() ?? 0
        }
        let maxX = 10

        // Check each position
        for y in 0...min(maxY, 24) {
            for x in 0..<maxX {
                if RoomModel.isValidPosition(x: x, y: y, width: roomWidth, existingRooms: existingRooms) {
                    // Check if connected (except for empty vault)
                    if existingRooms.isEmpty || RoomModel.isConnected(x: x, y: y, width: roomWidth, existingRooms: existingRooms, roomType: roomType) {
                        positions.append((x: x, y: y))
                    }
                }
            }
        }

        return positions
    }
}

// MARK: - Callback Queries Processing
extension BuildController {
    static func onCallbackQuery(context: Context) async throws -> Bool {
        guard let query = context.update.callbackQuery else { return false }
        guard let data = query.data else { return false }

        // Answer callback to remove loading state
        let answerParams = TGAnswerCallbackQueryParams(callbackQueryId: query.id)
        try await context.bot.answerCallbackQuery(params: answerParams)

        // Delete the message with inline keyboard to keep chat clean
        if let message = query.message {
            let chatId = TGChatId.chat(message.chat.id)
            let deleteParams = TGDeleteMessageParams(chatId: chatId, messageId: message.messageId)
            _ = try? await context.bot.deleteMessage(params: deleteParams)
        }

        let controller = Controllers.buildController

        // Handle category selection
        if data.starts(with: "build.category:") {
            let categoryRaw = data.replacingOccurrences(of: "build.category:", with: "")
            if let category = RoomCategory(rawValue: categoryRaw) {
                try await controller.showRoomsInCategory(context: context, category: category)
            }
            return true
        }

        // Handle room type selection
        if data.starts(with: "build.select:") {
            let roomRaw = data.replacingOccurrences(of: "build.select:", with: "")
            if let roomType = RoomType(rawValue: roomRaw) {
                try await controller.showPositionSelection(context: context, roomType: roomType)
            }
            return true
        }

        // Handle position selection
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

        // Handle build confirmation
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

        // Handle back to build menu
        if data == "build.back" {
            try await controller.showBuildMenu(context: context)
            return true
        }

        // Handle rooms list (short format: r.list)
        if data == "r.list" {
            try await controller.showRoomsList(context: context)
            return true
        }

        // Handle room detail (short format: r.d:SHORTID)
        if data.starts(with: "r.d:") {
            let shortID = data.replacingOccurrences(of: "r.d:", with: "")
            let vault = try await Vault.forUser(context.session, on: context.db)
            if let room = try await controller.findRoomByShortID(shortID, vault: vault, db: context.db) {
                try await controller.showRoomDetail(context: context, roomID: room.id!)
            }
            return true
        }

        // Handle room upgrade (short format: r.up:SHORTID)
        if data.starts(with: "r.up:") {
            let shortID = data.replacingOccurrences(of: "r.up:", with: "")
            let vault = try await Vault.forUser(context.session, on: context.db)
            if let room = try await controller.findRoomByShortID(shortID, vault: vault, db: context.db) {
                try await controller.upgradeRoom(context: context, roomID: room.id!)
            }
            return true
        }

        // Handle room assignment (short format: r.as:SHORTID)
        if data.starts(with: "r.as:") {
            let shortID = data.replacingOccurrences(of: "r.as:", with: "")
            let vault = try await Vault.forUser(context.session, on: context.db)
            if let room = try await controller.findRoomByShortID(shortID, vault: vault, db: context.db) {
                try await controller.showAssignDwellerToRoom(context: context, roomID: room.id!)
            }
            return true
        }

        // Handle dweller assignment confirmation (short format: a.d:ROOMSHORT:DWELLERSHORT)
        if data.starts(with: "a.d:") {
            let parts = data.replacingOccurrences(of: "a.d:", with: "").split(separator: ":")
            if parts.count == 2 {
                let roomShortID = String(parts[0])
                let dwellerShortID = String(parts[1])
                let vault = try await Vault.forUser(context.session, on: context.db)
                if let room = try await controller.findRoomByShortID(roomShortID, vault: vault, db: context.db),
                   let dweller = try await controller.findDwellerByShortID(dwellerShortID, vault: vault, db: context.db) {
                    try await controller.assignDwellerToRoom(context: context, roomID: room.id!, dwellerID: dweller.id!)
                }
            }
            return true
        }

        return false
    }

    // MARK: - Helper: Find by Short ID

    func findRoomByShortID(_ shortID: String, vault: Vault, db: any Database) async throws -> RoomModel? {
        let rooms = try await vault.getRooms(on: db)
        return rooms.first { room in
            guard let id = room.id?.uuidString else { return false }
            return id.prefix(8).lowercased() == shortID.lowercased()
        }
    }

    func findDwellerByShortID(_ shortID: String, vault: Vault, db: any Database) async throws -> DwellerModel? {
        let dwellers = try await DwellerModel.query(on: db)
            .filter(\DwellerModel.$vault.$id, .equal, vault.id!)
            .all()
        return dwellers.first { dweller in
            guard let id = dweller.id?.uuidString else { return false }
            return id.prefix(8).lowercased() == shortID.lowercased()
        }
    }

    // MARK: - Upgrade Room

    func upgradeRoom(context: Context, roomID: UUID) async throws {
        guard let room = try await RoomModel.find(roomID, on: context.db),
              let roomType = room.roomType else {
            return
        }

        let vault = try await Vault.forUser(context.session, on: context.db)
        let locale = context.session.locale
        let roomName = localizedRoomName(roomType, locale: locale, lingo: context.lingo)

        // Check if can upgrade
        guard let upgradeCost = room.upgradeCost else {
            let maxLevel = context.lingo.localize("upgrade.max.level", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(maxLevel)", parseMode: .html)
            return
        }

        // Check population requirement
        let population = try await vault.dwellerCount(on: context.db)
        guard room.toRoom()?.canUpgrade(currentPopulation: population) ?? false else {
            let popRequired = context.lingo.localize("upgrade.population.required", locale: locale, interpolations: ["population": "?"])
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(popRequired)", parseMode: .html)
            return
        }

        // Check caps
        guard vault.caps >= upgradeCost else {
            let insufficientText = context.lingo.localize("build.insufficient.caps", locale: locale, interpolations: [
                "have": "\(vault.caps)",
                "need": "\(upgradeCost)"
            ])
            try await context.bot.sendMessage(session: context.session, text: "❌ \(insufficientText)", parseMode: .html)
            return
        }

        // Deduct caps and upgrade
        vault.caps -= upgradeCost
        room.level += 1
        try await vault.save(on: context.db)
        try await room.save(on: context.db)

        let successText = context.lingo.localize("upgrade.success", locale: locale, interpolations: [
            "room": roomName,
            "level": "\(room.level)"
        ])

        try await context.bot.sendMessage(session: context.session, text: "✅ \(successText)", parseMode: .html)

        // Show updated room detail
        try await showRoomDetail(context: context, roomID: roomID)
    }

    // MARK: - Assign Dweller

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

        // Get unassigned dwellers
        let unassignedDwellers = try await DwellerModel.query(on: context.db)
            .filter(\DwellerModel.$vault.$id, .equal, vault.id!)
            .filter(\DwellerModel.$assignedRoom.$id, .equal, .none)
            .all()

        var text = """
        👥 <b>\(title)</b>

        \(roomType.emoji) \(roomName)

        \(selectDweller)
        """

        // Use short IDs (first 8 chars of UUID)
        let shortRoomID = String(room.id?.uuidString.prefix(8) ?? "")

        if unassignedDwellers.isEmpty {
            let noUnassigned = context.lingo.localize("assign.no.unassigned", locale: locale)
            text += "\n\n\(noUnassigned)"

            // Add back button even when no dwellers
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
            // Show primary stat for the room if applicable
            let statInfo: String
            if let primaryStat = roomType.primaryStat {
                let statValue = dweller.toDweller().baseStats.base(primaryStat)
                statInfo = " (\(primaryStat.emoji)\(statValue))"
            } else {
                statInfo = ""
            }

            // Use short dweller ID (first 8 chars)
            let shortDwellerID = String(dweller.id?.uuidString.prefix(8) ?? "")
            let button = TGInlineKeyboardButton(
                text: "\(dweller.rarityEmoji) \(dweller.fullName)\(statInfo)",
                callbackData: "a.d:\(shortRoomID):\(shortDwellerID)"
            )
            inlineKeyboard.append([button])
        }

        // Back button with localized text
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

        // Check capacity
        let assignedCount = try await room.assignedCount(on: context.db)
        guard assignedCount < room.capacity else {
            let roomFull = context.lingo.localize("assign.room.full", locale: locale)
            try await context.bot.sendMessage(session: context.session, text: "⚠️ \(roomFull)", parseMode: .html)
            return
        }

        // Assign dweller
        dweller.$assignedRoom.id = roomID
        try await dweller.save(on: context.db)

        let successText = context.lingo.localize("assign.success", locale: locale, interpolations: [
            "dweller": dweller.fullName,
            "room": roomName
        ])

        try await context.bot.sendMessage(session: context.session, text: "✅ \(successText)", parseMode: .html)

        // Show updated room detail
        try await showRoomDetail(context: context, roomID: roomID)
    }
}
