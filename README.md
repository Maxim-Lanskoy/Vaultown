# Vaultown [![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)](https://github.com/Maxim-Lanskoy/GPTGram/actions) [![Swift](https://img.shields.io/badge/Swift-6.2-orange)](https://github.com/swiftlang/swift/releases/tag/swift-6.2-RELEASE) [![Hummingbird](https://img.shields.io/badge/Hummingbird-2.10-blue)](https://github.com/hummingbird-project/hummingbird) – Telegram D&D 5e RPG Bot

<table>
  <tr>
    <td width="160" valign="top" halign="center">
      <img src="./icon.png" alt="Vaultown Icon" width="160">
    </td>
    <td width="240" valign="top" halign="center">
      <ul>
        <li><a href="https://docs.hummingbird.codes">Hummingbird Documentation</a></li>
        <li><a href="https://docs.vapor.codes/fluent/overview/#fluent">Fluent ORM / PostgreSQL</a></li>
        <li><a href="https://core.telegram.org/bots/api">Telegram Bot API</a></li>
        <li><a href="https://github.com/nerzh/swift-telegram-sdk">Swift Telegram SDK</a></li>
        <li><a href="https://openai.com/index/gpt-4-1/">OpenAI GPT-4.1</a></li>
      </ul>
    </td>
    <td width="440" valig="top" haligh="center">
    <b>Vaultown</b> is an interactive Vaultown, cross-platform multiplayer game, which is a management simulation with RPG elements. Under the hood it's a modern <b>Swift 6.2 + Hummingbird</b> app with <b>FluentPostgresDriver</b>, <b>SwiftTelegramSdk</b>, and <b>Lingo</b> for localization.
    </td>
  </tr>
</table>

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

## Architecture

### Router–Controller pattern

The bot implements a stateful router that maps Telegram updates to **controllers** (like screens/flows):

```
┌─────────────────────────────────────────────────────────────┐
│                     TGBot + Dispatcher                       │
│           (Bot instance stored in AppState)                  │
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
        ┌─────────────────────┐   ┌───────────────────┐
        │    Controllers      │   │   User Sessions   │
        │ (Handle "UI" logic) │   │ (Persistent state)│
        └─────────────────────┘   └───────────────────┘
```

Each controller encapsulates its own logic and UI flow. A shared `Context` provides the Telegram client, DB, localization, user session, and parsed arguments.

### Bot actor & concurrency

Swift **async/await** is used for all I/O (Telegram, DB, APIs), keeping the bot responsive while multiple players interact concurrently. An **AppState** class holds shared dependencies (database, lingo, HTTP client, bot instance).

### Project structure

```
Vaultown/
├── Swift/
│   ├── Controllers/              # Bot controllers (screens/states)
│   │   ├── AllControllers.swift  # Controller registry
│   │   ├── MainController.swift  # Main menu controller
│   │   ├── RegistrationController.swift
│   │   ├── SettingsController.swift
│   │   └── GlobalCommandsController.swift # Global command handlers
│   │
│   ├── Models/                   # Database models (Fluent ORM)
│   │   └── User.swift            # User session and preferences
│   │
│   ├── Migrations/               # Database schema migrations
│   │   └── CreateUser.swift
│   │
│   ├── Telegram/
│   │   ├── Router/               # Routing system
│   │   │   ├── Router.swift      # Main router logic
│   │   │   ├── Context.swift     # Request context
│   │   │   ├── Commands.swift    # Command definitions
│   │   │   ├── ContentType.swift # Message content types
│   │   │   ├── Arguments.swift   # Command argument parsing
│   │   │   └── Router+Helpers.swift
│   │   │
│   │   └── TGBot/                # Bot infrastructure
│   │       ├── TGDispatcher.swift        # Unified dispatcher
│   │       └── HummingbirdTGClient.swift # AsyncHTTPClient for TG API
│   │
│   ├── Helpers/
│   │   ├── TGBot+Extensions.swift  # Convenience extensions
│   │   ├── SessionCache.swift      # User session caching
│   │   ├── Lingo+Locales.swift     # Locale type-safe extensions
│   │   └── DotEnv+Env.swift        # Environment helpers
│   │
│   ├── entrypoint.swift         # Application entry point
│   ├── configure.swift          # Hummingbird configuration
│   └── routes.swift             # Router store for controllers
│
├── Localizations/               # Multi-language support
│   ├── en.json                  # English translations
│   └── uk.json                  # Ukrainian translations
│
├── PostgreSQL/                  # PostgreSQL data (Docker volume)
├── Public/
│   └── favicon.ico
├── docker-compose.yml
├── Dockerfile
├── .env.example
├── Package.swift
└── README.md
```

---

## Setup & Installation

### Prerequisites

* **Swift 6.2+** (and Xcode 16+ on macOS, optional)
* **Docker** (for PostgreSQL)
* **Telegram Bot Token** from @BotFather
* **OpenAI API Key** (optional, for AI quests)

### Docker PostgreSQL setup

Start PostgreSQL with Docker:

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

### Local setup

1. **Clone**

```bash
git clone <repo-url>
cd Vaultown
```

2. **Configure env**

```bash
cp .env.example .env
```

Edit `.env` with your settings:

```env
# Telegram Configuration
TELEGRAM_BOT_TOKEN=YOUR_BOT_TOKEN_HERE

# PostgreSQL Connection
DB_HOST=localhost
DB_PORT=5432
DB_USER=VaultUser
DB_PASSWORD=your-secure-password
DB_NAME=VaultDB

# OpenAI (optional)
OPENAI_API_KEY=your-openai-key
```

3. **Build & Run**

```bash
swift build
swift run
```

The bot will automatically run migrations on startup. Open Telegram, start the bot, and follow the prompts.

### Docker Commands Reference

```bash
# Check if container is running
docker ps

# View logs
docker logs vaultown-postgres

# Stop container
docker stop vaultown-postgres

# Start existing container
docker start vaultown-postgres

# Remove container (data persists in volume)
docker rm vaultown-postgres

# Connect to psql shell
docker exec -it vaultown-postgres psql -U VaultUser -d VaultDB

# Remove volume (WARNING: deletes all data)
docker volume rm vault_pgdata
```

### Docker Compose setup

For a complete setup with both PostgreSQL and the bot:

```bash
docker-compose up --build
```

This brings up Postgres and the Vaultown bot, applies migrations, and begins polling Telegram.

---

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `TELEGRAM_BOT_TOKEN` | Bot token from BotFather | Yes |
| `DB_HOST` | PostgreSQL host | Yes |
| `DB_PORT` | PostgreSQL port (default: 5432) | No |
| `DB_USER` | PostgreSQL username | Yes |
| `DB_PASSWORD` | PostgreSQL password | Yes |
| `DB_NAME` | PostgreSQL database name | Yes |
| `OPENAI_API_KEY` | OpenAI API key for AI quests | No |

---

## Working with Keyboards (examples)

**Reply keyboard** (persistent):

```swift
let markup = TGReplyKeyboardMarkup(
  keyboard: [[TGKeyboardButton(text: "Button 1"), TGKeyboardButton(text: "Button 2")]],
  resizeKeyboard: true
)
```

**Inline keyboard** (under message):

```swift
let inline = TGInlineKeyboardMarkup(
  inlineKeyboard: [[TGInlineKeyboardButton(text: "Click", callbackData: "action:123")]]
)
```

---

## Localization

* Strings live in `Localizations/*.json` and are served via **Lingo**.
* Use code like:

```swift
let text = lingo.localize("welcome", locale: user.locale,
  interpolations: ["full-name": user.name])
```

* Keep **all** user‑facing text out of code; add keys to JSON. English is provided; add more by creating additional JSON files and registering the locale in `configure.swift`.

---

## Health Check Endpoint

Hummingbird provides a health check endpoint at `http://localhost:8080/health` for monitoring.
