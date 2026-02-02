# Vaultown - AI Implementation Reference

Quick reference for AI assistants. For complete game mechanics, see **GDD.md**. For development status, see **TODO.md**.

---

## Project Overview

**Vaultown** is a Fallout Shelter-inspired multiplayer vault management RPG for Telegram (primary) and Godot mobile (planned).

**Tech Stack:** Swift 6.2, Hummingbird 2.x, Fluent/PostgreSQL, SwiftTelegramBot, Lingo (EN/UK)

---

## Architecture

```
Swift/
├── Controllers/         # Telegram UI controllers (only 3!)
│   ├── AllControllers.swift      # Registry - ADD NEW CONTROLLERS HERE
│   ├── Registration.swift        # User registration flow
│   ├── SettingsController.swift  # Language/settings
│   └── VaultController.swift     # Main game (build, explore, incidents, dwellers)
├── Models/              # Fluent database models
│   ├── User.swift, Vault.swift, DwellerModel.swift
│   ├── RoomModel.swift, ExplorationModel.swift, IncidentModel.swift
│   └── GlobalCounter.swift
├── Migrations/          # Database schema
├── Helpers/
│   ├── ResourceScheduler.swift   # Background resource ticks
│   ├── ExplorationScheduler.swift # Exploration events
│   ├── IncidentScheduler.swift   # Incident combat & spawns
│   └── SessionCache.swift
├── routes.swift         # RouterStore with fallback logic
└── Telegram/Router/     # Routing system

GameLogic/Sources/GameLogic/    # PURE GAME LOGIC - NO TELEGRAM DEPS
├── Character/           # Dweller, SPECIAL, AbilityScores, Rarity
├── Equipment/           # Weapon, Outfit, Pet
├── Vault/               # Room, RoomType, Resource, Incident
└── Exploration/         # Exploration, ExplorationEvent
```

**Key Principles:**
- Game mechanics go in `GameLogic/`. Controllers handle UI, DB, localization only.
- Only 2 game controllers: VaultController (all gameplay) and SettingsController. Controllers = "screens".
- RouterStore has fallback logic: unknown router names auto-fix to "vault".

---

## Controller Pattern

```swift
final class SomeController: TGControllerBase, @unchecked Sendable {
    override public func attachHandlers(to bot: TGBot, lingo: Lingo) async {
        let router = Router(bot: bot) { router in
            // Register button handlers for ALL locales
            let buttonLocales = Commands.someButton.buttonsForAllLocales(lingo: lingo)
            for button in buttonLocales { router[button.text] = onSomeAction }

            router.unmatched = unmatched
            router[.callback_query(data: nil)] = SomeController.onCallbackQuery
        }
        await processRouterForEachName(router)
    }

    // Navigate to another controller:
    let otherController = Controllers.otherController
    try await otherController.showMenu(context: context)
    context.session.routerName = otherController.routerName
    try await context.session.saveAndCache(in: context.db)
}

// Register in AllControllers.swift:
static let someController = SomeController(routerName: "some")
static let all: [TGControllerBase] = [..., someController]
```

---

## Key Game Mechanics (from GDD.md)

### S.P.E.C.I.A.L. Stats
| Stat | Room | Effect |
|------|------|--------|
| Strength | Power Generator | Power production |
| Perception | Water Treatment | Water production |
| Endurance | Nuka-Cola | HP per level, E11+ = radiation immune |
| Charisma | Radio Studio | Recruitment, breeding |
| Intelligence | Medbay/Lab | Stimpak/RadAway production |
| Agility | Diner | Food production |
| Luck | All rooms | Caps, loot quality |

### Dweller Rarity
- **Common:** 12 SPECIAL points
- **Rare:** 28 points
- **Legendary:** 40 points

### HP Formula
```
HP per level = 2.5 + (Endurance × 0.5)
Max HP = 644 (E17 throughout leveling)
Starting HP = 105
```

### Resource Consumption
- Food/Water: 0.36 units/min/dweller
- Food depleted → HP damage
- Water depleted → Radiation damage

### Production Formula
```
Cycle Time = Base_Time / (1 + Total_SPECIAL/10 + Happiness_Bonus)
```

### Exploration (auto)
- Events every ~30 min (combat, loot, caps, locations)
- Luck → better loot/caps
- E11+ → radiation immunity
- Return time = 50% of exploration time
- Auto-use stimpaks at <50% HP, RadAway at >50% radiation

---

## Database Models

```swift
// User session (Telegram user)
User: telegramId, locale, nickname, routerName

// Player vault
Vault: vaultNumber, power/food/water/caps, stimpaks/radaway, populationCap

// Dweller (vault inhabitant)
DwellerModel: firstName, lastName, gender, rarity, 7 SPECIAL stats,
              level, experience, currentHP, maxHP, radiation, happiness

// Room in vault
RoomModel: type, level(1-3), x, y, width(1-3), hasPower, productionState

// Active exploration
ExplorationModel: dwellerId, status, startTime, currentHP, supplies, loot
```

---

## Localization

All user-facing text in `Localizations/en.json` and `uk.json`:

```swift
// In controller:
let text = context.lingo.localize("some.key", locale: context.session.locale)

// With interpolation:
let text = context.lingo.localize("key", locale: locale, interpolations: ["name": value])
```

---

## Commands (Swift/Telegram/Router/Commands.swift)

```swift
enum Commands: String {
    case vault = "commands.vault"
    case dwellers = "commands.dwellers"
    case explore = "commands.explore"
    // ... add new commands here

    func button(for session: User, _ lingo: Lingo) -> TGKeyboardButton
    func buttonsForAllLocales(lingo: Lingo) -> [TGKeyboardButton]
}
```

---

## Callback Data Format

Use short IDs (first 8 chars of UUID) to fit Telegram's 64-byte limit:

```swift
// Creating callback
let shortID = String(item.id?.uuidString.prefix(8) ?? "")
callbackData: "prefix:\(shortID)"

// Parsing callback
if data.starts(with: "prefix:") {
    let shortID = data.replacingOccurrences(of: "prefix:", with: "")
    // Find item by short ID match
}
```

---

## Build & Run

```bash
swift build          # Build
swift run            # Run (requires PostgreSQL + .env)

# PostgreSQL via Docker:
docker run -d --name vaultown-postgres \
  -e POSTGRES_USER=VaultUser \
  -e POSTGRES_PASSWORD=your-password \
  -e POSTGRES_DB=VaultDB \
  -p 5432:5432 postgres:16-alpine
```

---

## Current Implementation Status

✅ **Complete:**
- User registration with language/nickname
- Vault creation with starting rooms/dwellers
- Room building, merging, upgrades
- Dweller assignment to rooms
- Resource production & consumption
- Power balance system
- Wasteland exploration with events
- Incident system (fires, radroaches, raiders, deathclaws, etc.)
- Dweller revival system (revive dead dwellers for caps)
- All slash commands (/vault, /dwellers, /resources, /build, /rooms, /explore, /incidents, /settings)

🔄 **Next:**
- Equipment system (equip weapons/outfits)
- Training rooms
- Quest system

See **TODO.md** for full roadmap.
