//
//  TGBot+Extensions.swift
//  Vaultown
//
//  Created by Maxim Lanskoy on 13.06.2025.
//

import Foundation
import Lingo
import SwiftTelegramBot

// MARK: - TGBot Image Sending Extension

extension TGBot {
    /// Send a PNG image to a chat
    /// - Parameters:
    ///   - chatId: Target chat ID
    ///   - imageData: PNG image data
    ///   - caption: Optional caption for the image
    ///   - replyMarkup: Optional reply markup (keyboard)
    /// - Returns: The sent message
    @discardableResult
    func sendImage(
        chatId: TGChatId,
        imageData: Data,
        filename: String = "image.png",
        caption: String? = nil,
        parseMode: TGParseMode? = nil,
        replyMarkup: TGReplyMarkup? = nil
    ) async throws -> TGMessage {
        let inputFile = TGInputFile(filename: filename, data: imageData, mimeType: "image/png")
        let fileInfo = TGFileInfo.file(inputFile)
        let params = TGSendPhotoParams(
            chatId: chatId,
            photo: fileInfo,
            caption: caption,
            parseMode: parseMode,
            replyMarkup: replyMarkup
        )
        return try await sendPhoto(params: params)
    }

    /// Send a PNG image to a user session
    @discardableResult
    func sendImage(
        session: User,
        imageData: Data,
        filename: String = "image.png",
        caption: String? = nil,
        parseMode: TGParseMode? = nil,
        replyMarkup: TGReplyMarkup? = nil
    ) async throws -> TGMessage {
        let chatId = TGChatId.chat(session.telegramId)
        return try await sendImage(
            chatId: chatId,
            imageData: imageData,
            filename: filename,
            caption: caption,
            parseMode: parseMode,
            replyMarkup: replyMarkup
        )
    }
}

extension Context {
    var session: User {
        get { return   properties["session"]!  }
        set { properties["session"] = newValue }
    }
}

protocol TGControllerProtocol {
    var routerNames: [String] { get }
    func attachHandlers(to bot: TGBot, lingo: Lingo) async
    func generateControllerKB(session: User, lingo: Lingo) -> TGReplyMarkup?
}

public class TGControllerBase: @unchecked Sendable {
    public let routerName: String
    
    public init(routerName: String) {
        self.routerName = routerName
    }
    
    public func generateControllerKB(session: User, lingo: Lingo) -> TGReplyMarkup? { return nil }
    
    public func attachHandlers(to bot: SwiftTelegramBot.TGBot, lingo: Lingo) async { }
    
    public func unmatched(context: Context) async throws -> Bool {
        guard let message = context.update.message else { return false }
        let globalCommands = ["/buttons", "/help", "/settings"]
        if let text = message.text {
            return globalCommands.contains(text) == false
        } else {
            return true
        }
    }
    
    internal func processRouterForEachName(_ router: Router) async {
        // for routerName in routerNames {
        await store.set(router, forKey: routerName)
        // }
    }
}

extension TGMaybeInaccessibleMessage {
    public func getMessage() -> TGMessage? {
        switch self {
        case .message(let message):
            return message
        default:
            return nil
        }
    }
}

extension TGMessageOrigin {
    var isUserOrigin: Bool {
        if case .messageOriginUser = self { return true }
        return false
    }
    
    var isChatOrigin: Bool {
        if case .messageOriginChat = self { return true }
        return false
    }
    
    var originDate: Int? {
        switch self {
        case .messageOriginUser(let userModel): return userModel.date
        case .messageOriginChat(let chatModel): return chatModel.date
        default:                       return nil
        }
    }
}

extension TGMessage {
    public func extractCommand() -> String? {
        guard let text = text else { return nil }
        let components = text.components(separatedBy: "@")
        guard components.count == 2 else { return text }
        guard text.starts(with: "/") else { return text }
        guard let botName = components.last else { return text }
        return text.without(botName: botName)
    }
}

extension String {
    /// - Parameter botName: bot name to remove.
    /// - Returns: "/command@botName arguments" -> "/command arguments". Nil if bot name does not match `botName` parameter.
    public func without(botName: String) -> String? {
        let scanner = Scanner(string: self)
        scanner.caseSensitive = false
        scanner.charactersToBeSkipped = nil
        
        let whitespaceAndNewline = CharacterSet.whitespacesAndNewlines
        scanner.skipCharacters(from: whitespaceAndNewline)

        guard scanner.skipString("/") else {
            return self
        }
        
        let alphanumericCharacters = CharacterSet.alphanumerics
        guard scanner.skipCharacters(from: alphanumericCharacters) else {
            return self
        }

        let usernameSeparatorLocation = scanner.currentIndex

        let usernameSeparator = "@"
        guard scanner.skipString(usernameSeparator) else {
            return self
        }

        // A set of characters allowed in bot names
        let usernameCharacters = CharacterSet(charactersIn:
            "abcdefghijklmnopqrstuvwxyz" +
            "ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
            "1234567890_")
        guard let username = scanner.scanCharacters(from: usernameCharacters) else {
            // Empty bot name. Treat as no bot name and process the comamnd.
            return self
        }
        
        guard username == botName else {
            // Another bot's message, skip it.
            return nil
        }
        
        let range = usernameSeparatorLocation...scanner.currentIndex
        let substring = String(self[range])
        return substring
    }

    public func hasPrefix(_ prefix: String, caseInsensitive: Bool) -> Bool {
        if caseInsensitive {
            return nil != self.range(of: prefix, options: [.caseInsensitive, .anchored])
        }
        return hasPrefix(prefix)
    }
    
    /// Converts a TSV‐encoded table returned by Unstructured’s `text` field
    /// into GitHub-flavoured Markdown (pipes and header rule).
    static func tableToMarkdown(tsv: String) -> String {
        // Each input row:  col1\tcol2\t…
        let rows: [String] = tsv
            .split(separator: "\n")
            .map { row in
                row.split(separator: "\t")
                    .map { cell in
                        // escape pipes so they don’t break the table
                        cell.replacingOccurrences(of: "|", with: "\\|")
                    }
                    .joined(separator: " | ")
            }

        guard !rows.isEmpty else { return "" }

        // Single-row table → treat as a one-row table without header
        if rows.count == 1 { return "| \(rows[0]) |" }

        // Build the header separator (---) matching the number of columns
        let header = rows[0]
        let colCount = header.filter { $0 == "|" }.count + 1
        let bar = Array(repeating: "---", count: colCount).joined(separator: " | ")

        var markdown = "| \(header) |\n| \(bar) |"
        for dataRow in rows.dropFirst() {
            markdown += "\n| \(dataRow) |"
        }
        return markdown
    }
}
