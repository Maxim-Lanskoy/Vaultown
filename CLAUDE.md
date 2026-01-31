# Vaultown Project - Implementation Reference

Comprehensive reference for AI assistants working on the Vaultown, cross-platform multiplayer game, which is a management simulation with RPG elements. Contains architecture, patterns, file locations, and step-by-step implementation guidance.

---

## 0. PROJECT OVERVIEW

### What is Vaultown?

**Vaultown** is a cross-platform multiplayer RPG built on...

### Cross-Platform Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENTS                                 │
│  ┌─────────────────┐              ┌─────────────────────────┐   │
│  │  Telegram Bot   │              │   Godot Mobile Client   │   │
│  │  (Primary)      │              │   (SwiftGodot)          │   │
│  │  - Emoji maps   │              │   - Tilemap graphics    │   │
│  │  - Button UI    │              │   - Touch controls      │   │
│  └────────┬────────┘              └────────────┬────────────┘   │
│           │                                    │                │
│           │  SwiftTelegramBot                  │  REST API      │
│           │                                    │  WebSocket     │
│           └──────────────┬─────────────────────┘                │
│                          ▼                                      │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                 SHARED BACKEND                            │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │              Hummingbird (Swift)                    │  │  │
│  │  │  - HTTP API routes (for Godot)                      │  │  │
│  │  │  - Telegram bot handlers                            │  │  │
│  │  │  - WebSocket for real-time sync                     │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  │                          │                                │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │              PostgreSQL + Fluent                    │  │  │
│  │  │  - User accounts, characters                        │  │  │
│  │  │  - World state, inventories                         │  │  │
│  │  │  - Guilds, auctions, parties                        │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### GameLogic Package (Critical Design Decision)

All **game mechanics must be implemented in the `GameLogic` package** - a separate Swift Package that:
- Contains **pure game logic** with no dependencies on Telegram or Godot
- Is **shared between** the backend (Telegram bot) and mobile client (Godot)
- Ensures **consistent rules** across all platforms

```
GameLogic/
├── Character/      # Fallout based character system (s.p.e.c.i.a.l. system)
├── Combat/         # Attack calculations, damage, conditions
├── .../            # ...
├── Equipment/      # Weapons, armor, items, inventory
└── GameLogic.swift # Public API exports
```

**Key Principle**: If it's a game rule or calculation, it goes in GameLogic. Controllers only handle:
- User input/output
- Database persistence
- Platform-specific rendering

### Tech Stack

| Layer | Technology |
|-------|------------|
| Backend Framework | Hummingbird (Swift) |
| Database | PostgreSQL + Fluent ORM |
| Telegram | SwiftTelegramBot |
| Localization | Lingo (EN, UK) |
| Game Logic | GameLogic (Swift Package) |
| Mobile Client | Godot 4.5 + SwiftGodot |

---

## 1. PROJECT STRUCTURE

```
Vaultown/
├── Package.swift              # Main Swift package
├── Swift/
│   ├── entrypoint.swift       # App entry point
│   ├── configure.swift        # Hummingbird configuration
│   ├── routes.swift           # HTTP routes (for Godot API)
│   ├── Controllers/           # Telegram bot controllers
│   │   ├── AllControllers.swift   # Controller registry
│   │   ├── ValutController.swift  # Main vault menu
│   │   └── SettingsController.swift
│   ├── Models/                # Database models (Fluent)
│   │   └── User.swift
│   ├── Migrations/            # Database migrations
│   ├── Helpers/               # Utilities
│   │   └── TGBot+Extensions.swift  # TGControllerBase
│   └── Telegram/
│       └── Router/            # Router system
│           ├── Router.swift
│           ├── Commands.swift
│           └── Context.swift
├── GameLogic/                 # Shared game mechanics (SPM package)
│   └── Sources/GameLogic/
│       ├── Character/         # Fallout based character, S.P.E.C.I.A.L.
│       └── GameLogic.swift    # Public API
├── Vault-2D/                 # Godot client (SwiftGodot)
│   └── Sources/Vault-2D/
├── Localizations/             # i18n files
│   ├── en.json
│   └── uk.json
├── VISION.md                  # Game design document
├── TODO.md                    # Development plan
└── docker-compose.yml         # PostgreSQL + app
```

---

## 2. CONTROLLER PATTERN (CRITICAL)

### 2.1 Base Class

Location: `Swift/Helpers/TGBot+Extensions.swift`

```swift
public class TGControllerBase: @unchecked Sendable { ... }
```

### 2.2 Controller Template

**FOLLOW THIS EXACTLY** when creating new controllers:

```swift
import Foundation
import Lingo
import SwiftTelegramBot

// MARK: - Some Controller Logic
final class SomeController: TGControllerBase, @unchecked Sendable {
    typealias T = SettingsController
    
    // MARK: - Controller Lifecycle
    override public func attachHandlers(to bot: TGBot, lingo: Lingo) async {
        let router = Router(bot: bot) { router in
            router[Commands.start.command()]     = onStart
            router[Commands.language.command()]  = onLanguage
                        
            let languageLocales = Commands.language.buttonsForAllLocales(lingo: lingo)
            for button in languageLocales { router[button.text] = onLanguage }
            
            let cancelLocales = Commands.cancel.buttonsForAllLocales(lingo: lingo)
            for button in cancelLocales { router[button.text] = onCancel }
                        
            let someLocales = Commands.some.buttonsForAllLocales(lingo: lingo)
            for button in someLocales { router[button.text] = onSomeMenu }
            
            router.unmatched = unmatched
            router[.callback_query(data: nil)] = SettingsController.onCallbackQuery
        }
        await processRouterForEachName(router)
    }
    
    public func onStart(context: Context) async throws -> Bool {
        let vaultController = Controllers.vaultController
        try await vaultController.showVaultMenu(context: context)
        context.session.routerName = vaultController.routerName
        try await context.session.saveAndCache(in: context.db)
        return true
    }
    
    private func onCancel(context: Context) async throws -> Bool {
        return try await onStart(context: context)
    }
    
    override func unmatched(context: Context) async throws -> Bool {
        guard try await super.unmatched(context: context) else { return false }
        return try await onStart(context: context)
    }
        
    private func onSome(context: Context) async throws -> Bool {
        let prompt = context.lingo.localize("controllers.some.prompt", locale: context.session.locale)
        var inlineKeyboard: [[TGInlineKeyboardButton]] = []
        for locale in SupportedLocale.allCases {
            let string = context.lingo.localize("some.string", locale: locale)
            let button = TGInlineKeyboardButton(text: "\(some.emoji()) \(string)", callbackData: "set_something:\(string.rawValue)")
            inlineKeyboard.append([button])
        }
        let markup = TGReplyMarkup.inlineKeyboardMarkup(TGInlineKeyboardMarkup(inlineKeyboard: inlineKeyboard))
        try await context.bot.sendMessage(session: context.session, text: prompt, parseMode: .html, replyMarkup: markup)
        return true
    }
        
    private func onSomeMenu(context: Context) async throws -> Bool {
        try await showSomeMenu(context: context)
        return true
    }
    
    public func showSomeMenu(context: Context, text: String? = nil) async throws {
        try await showSomeMenuLogic(bot: context.bot, session: context.session, lingo: context.lingo, text: text)
    }
    
    public func showSomeMenuLogic(bot: TGBot, session: User, lingo: Lingo, text: String? = nil) async throws {
        let settings = lingo.localize("some.title", locale: session.locale)
        let text = text ?? "\(emoji) \(settings)"
        let markup = generateControllerKB(session: session, lingo: lingo)
        try await bot.sendMessage(session: session, text: text, parseMode: .html, replyMarkup: markup)
    }
    
    override public func generateControllerKB(session: User, lingo: Lingo) -> TGReplyMarkup? {
        let markup = TGReplyKeyboardMarkup(keyboard: [[
            Commands.some.button(for: session, lingo),
            Commands.cancel.button(for: session, lingo)
        ]], resizeKeyboard: true)
        return TGReplyMarkup.replyKeyboardMarkup(markup)
    }
    
    // MARK: - Custom Methods
}
 
// MARK: - Callback Queries Processing
extension SomeController {
    static func onCallbackQuery(context: Context) async throws -> Bool {
        guard let query = context.update.callbackQuery else { return false }
        guard let message = query.message else { return false }
        let chatId = TGChatId.chat(message.chat.id)
        let deleteParams = TGDeleteMessageParams(chatId: chatId, messageId: message.messageId)
        try await context.bot.deleteMessage(params: deleteParams)
        guard let data = query.data, data.starts(with: "set_something:") else { return false }
        let value = data.replacingOccurrences(of: "set_something:", with: "")
        context.session.something = value
        try await context.session.saveAndCache(in: context.db)
        try await Controllers.someController.showSomeMenu(context: context)
        return true
    }
} 
```

### 2.3 Controller Registration

Location: `Swift/Controllers/AllControllers.swift`

```swift
struct Controllers {
    static let vaultController = VaultController(routerName: "vault")
    static let settingsController = SettingsController(routerName: "settings")
    static let worldController = FieldController(routerName: "field")
    static let combatController = CombatController(routerName: "combat")
    static let cityController = CityController(routerName: "city")

    static let all: [TGControllerBase] = [
        vaultController,
        settingsController,
        worldController,
        combatController,
        cityController,
    ]
}
```

---

## 3. COMMANDS SYSTEM

Location: `Swift/Telegram/Router/Commands.swift`

### 3.1 Adding New Commands

```swift
enum Commands: String {
    // Navigation
    case start = "start"
    case settings = "settings"
    case cancel = "cancel"

    // Field exploration
    case field = "field"
    case moveN = "move_n"
    case moveNE = "move_ne"
    case moveE = "move_e"
    case moveSE = "move_se"
    case moveS = "move_s"
    case moveSW = "move_sw"
    case moveW = "move_w"
    case moveNW = "move_nw"
    case contextAction = "context_action"

    // Combat
    case attack = "attack"
    case cast = "cast"
    case item = "item"
    case dodge = "dodge"
    case flee = "flee"

    // Social
    case inventory = "inventory"
    case party = "party"
    case guild = "guild"
    case auction = "auction"

    func command() -> String {
        return "/\(self.rawValue)"
    }

    func button(for session: User, _ lingo: Lingo) -> TGKeyboardButton {
        let key = "commands.\(self.rawValue)"
        let text = lingo.localize(key, locale: session.locale)
        return TGKeyboardButton(text: text)
    }

    func buttonsForAllLocales(lingo: Lingo) -> [TGKeyboardButton] {
        let locales = ["en", "uk"]
        return locales.map { locale in
            let key = "commands.\(self.rawValue)"
            let text = lingo.localize(key, locale: locale)
            return TGKeyboardButton(text: text)
        }
    }
}
```

### 3.2 Localization Keys

Location: `Localizations/en.json`

```json
{
  "commands": {
    "start": "/start",
    "settings": "⚙️ Settings",
    "cancel": "❌ Cancel",
    "field": "🗺️ Explore",
    "move_n": "⬆️",
    "move_ne": "↗️",
    "move_e": "➡️",
    "move_se": "↘️",
    "move_s": "⬇️",
    "move_sw": "↙️",
    "move_w": "⬅️",
    "move_nw": "↖️",
    "context_action": "🎯",
    "attack": "⚔️ Attack",
    "cast": "✨ Cast",
    "item": "🧪 Item",
    "dodge": "🛡️ Dodge",
    "flee": "🚪 Flee",
    "inventory": "🎒 Inventory",
    "party": "👥 Party",
    "guild": "🏰 Guild",
    "auction": "💰 Auction"
  },
  "field": {
    "look_around": "You look around and see...",
    "cannot_move": "You cannot move there!",
    "entered_city": "You entered {city_name}"
  },
  "combat": {
    "round": "Round {round}",
    "your_turn": "Your turn",
    "enemy_attacks": "{enemy} attacks you!",
    "you_hit": "You hit for {damage} damage!",
    "you_miss": "You miss!",
    "victory": "Victory! You gained {xp} XP"
  }
}
```

---

## 4. DATABASE MODELS

### 4.1 User Model with Game Fields

Location: `Swift/Models/User.swift`

```swift
import Fluent
import Foundation

final class User: Model, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "telegram_id")
    var telegramId: Int64

    @Field(key: "username")
    var username: String?

    @Field(key: "first_name")
    var firstName: String?

    @Field(key: "language_code")
    var languageCode: String

    @Field(key: "router_name")
    var routerName: String

    @Field(key: "created_at")
    var createdAt: Date

    // Computed properties
    var locale: String { languageCode }
    var name: String { username ?? firstName ?? "Player" }

    init() { }

    init(
        telegramId: Int64,
        username: String?,
        firstName: String?,
        languageCode: String,
        character: Character
    ) {
        self.telegramId = telegramId
        self.username = username
        self.firstName = firstName
        self.languageCode = languageCode
        self.state = "new"
        self.routerName = "main"
        self.createdAt = Date()
    }
}
```

### 4.2 Example of Migration for Fluent

Location: `Swift/Migrations/ExampleAddGameFields.swift`

---

## 5. GAMELOGIC PACKAGE

### 5.1 Package Structure

Location: `GameLogic/Sources/GameLogic/`

```
GameLogic/
├── GameLogic.swift           # Public API
├── Character/
│   ├── Character.swift       # Main character struct
│   ├── Race.swift            # 9 races + subraces
│   ├── CharacterClass.swift  # 13 classes
│   ├── AbilityScores.swift   # 6 abilities
│   ├── Skill.swift           # 18 skills
│   └── Proficiencies.swift
├── Combat/
│   ├── Dice.swift            # Dice rolling
│   ├── DiceRoll.swift        # Roll results
│   ├── Attack.swift          # Attack resolution
│   ├── Damage.swift          # Damage types
│   ├── Condition.swift       # Status effects
│   └── CombatAction.swift    # Action types
├── World/
│   ├── Position.swift        # X, Y coordinates
│   ├── Direction.swift       # 8 directions
│   ├── WorldTile.swift       # Tile types
│   ├── Matrix.swift          # 2D grid
│   └── WorldGenerator.swift  # Terrain generation
├── Equipment/
│   ├── Weapon.swift
│   ├── Armor.swift
│   ├── Item.swift
│   └── Inventory.swift
└── Spells/
    ├── Spell.swift
    ├── SpellSlot.swift
    └── SpellList.swift
```

---

## 6. COMMON PATTERNS

### 6.1 Controller Navigation

```swift
// Navigate from one controller to another
func navigateTo(controller: TGControllerBase, context: Context) async throws {
    context.session.routerName = controller.routerName
    try await context.session.saveAndCache(in: context.db)
    // Controller-specific show method
}

// Example: From inventory to equipment
private func onEquipment(context: Context) async throws -> Bool {
    let equipmentController = Controllers.equipmentController
    try await equipmentController.showEquipment(context: context)
    context.session.routerName = equipmentController.routerName
    try await context.session.saveAndCache(in: context.db)
    return true
}
```

### 6.2 Inline Keyboards for Selection

```swift
func generateMonsterTargetKB(monsters: [Monster]) -> TGInlineKeyboardMarkup {
    var rows: [[TGInlineKeyboardButton]] = []

    for monster in monsters where monster.currentHP > 0 {
        let button = TGInlineKeyboardButton(
            text: "\(monster.emoji) \(monster.name) (\(monster.currentHP) HP)",
            callbackData: "combat.target_\(monster.id.uuidString)"
        )
        rows.append([button])
    }

    return TGInlineKeyboardMarkup(inlineKeyboard: rows)
}
```

### 6.3 Context Data Storage

```swift
// Store temporary data in context.properties
context.properties["selected_item"] = itemId

// Retrieve in next handler
if let itemId = context.properties["selected_item"] as? UUID {
    // Use itemId
}
```

### 6.4 Error Handling

```swift
func safeHandle(context: Context, action: () async throws -> Void) async {
    do {
        try await action()
    } catch {
        try? await context.bot.sendMessage(
            session: context.session,
            text: "❌ An error occurred. Please try again.",
            parseMode: .html
        )
        print("Error: \(error)")
    }
}
```

---

## 7. ENVIRONMENT SETUP

### 7.1 Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `TG_TOKEN` | Telegram bot token | `123456:ABC-DEF...` |
| `DATABASE_URL` | PostgreSQL connection | `postgres://user:pass@localhost/vaultdb` |
| `LOG_LEVEL` | Logging verbosity | `debug`, `info`, `warning` |

### 7.2 Build Commands

```bash
# Development
swift build
swift run

# Tests
swift test

# Docker
docker-compose up -d

# Godot client
cd Vault-2D && make && make run
```
