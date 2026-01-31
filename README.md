# Vaultown [![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen?logo=github)](https://github.com/Maxim-Lanskoy/Vaultown/actions) [![Swift](https://img.shields.io/badge/Swift-6.2.3-DE5D43?logo=swift)](https://github.com/swiftlang/swift/releases/tag/swift-6.2.3-RELEASE) [![Hummingbird](https://img.shields.io/badge/Hummingbird-2.20-F7CD7A)](https://github.com/hummingbird-project/hummingbird) [![Fluent](https://img.shields.io/badge/Fluent-4.13-67C1F9)](https://docs.vapor.codes/fluent/overview/) [![Godot](https://img.shields.io/badge/Godot-4.5.1-478CBF)](https://godotengine.org/) [![Platform](https://img.shields.io/badge/Platform-Telegram-lightgrey?logo=telegram)]()

<table>
  <tr>
    <td width="160" valign="top" align="center">
       <img src="./icon.png" alt="Vaultown Icon" width="160">
    </td>
    <td width="280" valign="top">
      <ul>
        <li><a href="https://docs.hummingbird.codes">Hummingbird Documentation</a></li>
        <li><a href="https://docs.vapor.codes/fluent/overview/#fluent">Fluent ORM / PostgreSQL</a></li>
        <li><a href="https://core.telegram.org/bots/api">Telegram Bot API</a></li>
        <li><a href="https://github.com/nerzh/swift-telegram-sdk">Swift Telegram SDK</a></li>
        <li><a href="https://github.com/migueldeicaza/SwiftGodot">SwiftGodot</a></li>
      </ul>
    </td>
    <td width="440" valign="top">
      <b>Vaultown</b> is a multiplayer vault management RPG inspired by Fallout Shelter. Built entirely in Swift, it features a Telegram bot interface and a Godot-based mobile client sharing the same game logic and database. Players manage underground bunkers, assign dwellers, explore the wasteland, and collaborate with others.
    </td>
  </tr>
</table>

> **📖 Game Design Document:** For complete game mechanics, formulas, S.P.E.C.I.A.L. system, room details, equipment lists, and all gameplay rules, see [GDD.md](GDD.md).

---

## Table of Contents

1. [Tech Stack](#tech-stack)
2. [Project Structure](#project-structure)
3. [Architecture](#architecture)
4. [Localization](#localization)
5. [Setup & Installation](#setup--installation)
6. [Development Roadmap](#development-roadmap)

---

## Tech Stack

* **Swift** 6.2 (macOS 14+)
* **Hummingbird** 2.x (lightweight HTTP server)
* **Fluent** 4 + **FluentPostgresDriver** 2.x (PostgreSQL ORM)
* **AsyncHTTPClient** 1.x (HTTP client for Telegram API)
* **SwiftNIO** 2.x (async networking)
* **SwiftTelegramSdk** 4.x (Telegram Bot API)
* **SwiftDotenv** 2.x (environment config)
* **Lingo** 4.x (localization)
* **Godot** 4.5 + **SwiftGodot** (mobile client)

`Package.swift` (excerpt):

```swift
.platforms([.macOS(.v14)])
.dependencies([
  .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.10.0"),
  .package(url: "https://github.com/vapor/fluent.git", from: "4.13.0"),
  .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.10.0"),
  .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.25.0"),
  .package(url: "https://github.com/apple/swift-nio.git", from: "2.92.0"),
  .package(url: "https://github.com/nerzh/swift-telegram-sdk", from: "4.2.2"),
  .package(url: "https://github.com/thebarndog/swift-dotenv.git", from: "2.1.0"),
  .package(url: "https://github.com/miroslavkovac/Lingo.git", from: "4.0.0"),
])
```

---

## Project Structure

```
Vaultown/
├── Package.swift              # Main Swift package
├── Swift/
│   ├── entrypoint.swift       # Application entry point
│   ├── configure.swift        # Hummingbird configuration
│   ├── routes.swift           # HTTP routes (for Godot API)
│   ├── Controllers/           # Bot controllers (screens/states)
│   ├── Models/                # Database models (Fluent ORM)
│   ├── Migrations/            # Database schema migrations
│   ├── Helpers/               # Utility extensions
│   └── Telegram/
│       ├── Router/            # Routing system
│       └── TGBot/             # Bot infrastructure
├── GameLogic/                 # Shared game mechanics (SPM package)
├── Vault-2D/                  # Godot client (SwiftGodot)
├── Localizations/             # Multi-language support (en.json, uk.json)
├── docker-compose.yml
├── Dockerfile
└── .env.example
```

---

## Architecture

### Router–Controller Pattern

The bot implements a stateful router that maps Telegram updates to **controllers** (like screens/flows):

```
┌─────────────────────────────────────────────────────────────┐
│                     TGBot + Dispatcher                      │
│           (Bot instance stored in AppState)                 │
└─────────────────────────────────────────────────────────────┘
                               │
          ┌────────────────────┼────────────────────┐
          ▼                    ▼                    ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│  Global Commands │ │   Router System  │ │  Session Cache   │
│ (/help /settings)│ │ (State routing)  │ │ (Fast lookups)   │
└──────────────────┘ └──────────────────┘ └──────────────────┘
                               │
                    ┌──────────┴──────────┐
                    ▼                     ▼
        ┌─────────────────────┐   ┌────────────────────┐
        │    Controllers      │   │   User Sessions    │
        │ (Handle "UI" logic) │   │ (Persistent state) │
        └─────────────────────┘   └────────────────────┘
```

Each controller encapsulates its own logic and UI flow. A shared `Context` provides the Telegram client, DB, localization, user session, and parsed arguments.

### Bot Actor & Concurrency

Swift **async/await** is used for all I/O (Telegram, DB, APIs), keeping the bot responsive while multiple players interact concurrently. An **AppState** class holds shared dependencies (database, lingo, HTTP client, bot instance).

### Controller Template

```swift
final class VaultController: TGControllerBase, @unchecked Sendable {
    typealias T = VaultController

    override public func attachHandlers(to bot: TGBot, lingo: Lingo) async {
        let router = Router(bot: bot) { router in
            router[Commands.start.command()] = onStart
            router[Commands.vault.command()] = onVaultView
            router.unmatched = unmatched
        }
        await processRouterForEachName(router)
    }

    public func onStart(context: Context) async throws -> Bool {
        try await showVaultMenu(context: context)
        context.session.routerName = routerName
        try await context.session.saveAndCache(in: context.db)
        return true
    }
}
```

### Controller Registration

Location: `Swift/Controllers/AllControllers.swift`

```swift
struct Controllers {
    static let vaultController = VaultController(routerName: "vault")
    static let settingsController = SettingsController(routerName: "settings")

    static let all: [TGControllerBase] = [
        vaultController, settingsController
    ]
}
```

---

## Localization

Strings live in `Localizations/*.json` and are served via **Lingo**.

```swift
let text = lingo.localize("welcome", locale: user.locale,
  interpolations: ["full-name": user.name])
```

Keep **all** user-facing text out of code; add keys to JSON. English is provided; add more by creating additional JSON files and registering the locale in `configure.swift`.

**Example keys:**

```json
{
  "commands": {
    "vault": "🏠 Vault",
    "explore": "🗺️ Explore",
    "inventory": "🎒 Inventory"
  },
  "vault": {
    "status": "Power ⚡ {power}, Water 💧 {water}, Food 🍲 {food}",
    "incident_alert": "🚨 {incident_type} in {room_name}!"
  }
}
```

---

## Setup & Installation

### Prerequisites

- **Swift 6.2+** (Xcode 16+ on macOS optional)
- **Docker** (for PostgreSQL)
- **Telegram Bot Token** from @BotFather
- **OpenAI API Key** (optional, for AI features)

### Docker PostgreSQL Setup

```bash
docker run -d \
  --name vaultown-postgres \
  -e POSTGRES_USER=VaultUser \
  -e POSTGRES_PASSWORD=your-secure-password \
  -e POSTGRES_DB=VaultDB \
  -p 5432:5432 \
  -v vault_pgdata:/var/lib/postgresql/data \
  postgres:16-alpine
```

### Local Setup

1. **Clone**
```bash
git clone <repo-url>
cd Vaultown
```

2. **Configure environment**
```bash
cp .env.example .env
```

Edit `.env`:
```env
TELEGRAM_BOT_TOKEN=YOUR_BOT_TOKEN_HERE
DB_HOST=localhost
DB_PORT=5432
DB_USER=VaultUser
DB_PASSWORD=your-secure-password
DB_NAME=VaultDB
OPENAI_API_KEY=your-openai-key  # optional
```

3. **Build & Run**
```bash
swift build
swift run
```

### Docker Compose (Full Stack)

```bash
docker-compose up --build
```

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `TELEGRAM_BOT_TOKEN` | Bot token from BotFather | Yes |
| `DB_HOST` | PostgreSQL host | Yes |
| `DB_PORT` | PostgreSQL port (default: 5432) | No |
| `DB_USER` | PostgreSQL username | Yes |
| `DB_PASSWORD` | PostgreSQL password | Yes |
| `DB_NAME` | PostgreSQL database name | Yes |
| `OPENAI_API_KEY` | OpenAI API key | No |
| `LOG_LEVEL` | Logging verbosity | No |

### Health Check

Hummingbird provides endpoint: `http://localhost:8080/health`

---

## Development Roadmap

### Phase 1: Telegram MVP

- [ ] Implement all core game mechanics in GameLogic
- [ ] Vault building and room management
- [ ] Dweller system with S.P.E.C.I.A.L.
- [ ] Resource production and collection
- [ ] Basic incidents (fires, radroaches, raiders)
- [ ] Wasteland exploration (automatic)
- [ ] Equipment and inventory
- [ ] Multiplayer basics (referrals, co-management)
- [ ] Basic guild system
- [ ] Item trading/marketplace

### Phase 2: Mobile Client Alpha

- [ ] Godot/SwiftGodot client development
- [ ] 2D vault visualization
- [ ] REST API for Godot
- [ ] WebSocket real-time sync
- [ ] Touch controls

### Phase 3: Rich Features

- [ ] Interactive quests with combat
- [ ] Party system for quests
- [ ] Guild chat and events
- [ ] Monetization (store, purchases)
- [ ] Mr. Handy robots
- [ ] Lunchbox system

### Phase 4: Late-Game & Polish

- [ ] Advanced rooms (Nuclear Reactor, Bottler)
- [ ] Research Center and crafting
- [ ] Deathclaws and advanced threats
- [ ] Cross-vault interactions
- [ ] Leaderboards and events

---

*Welcome to Vaultown, Overseer. Good luck rebuilding civilization — one vault at a time.*
