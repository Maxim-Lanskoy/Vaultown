# Vaultown Development TODO

> Comprehensive development plan for the Vaultown multiplayer vault management RPG.
> Check items as completed: `- [x]` when done.

---

## Current Status

**Template bot infrastructure is complete:**
- [x] Hummingbird server setup with health endpoint
- [x] PostgreSQL + Fluent ORM integration
- [x] Telegram bot with long-polling
- [x] Router-Controller pattern implemented
- [x] Session caching system
- [x] Localization system (EN, UK)
- [x] User model with basic fields
- [x] User nickname field with validation (latin/cyrillic only)
- [x] Registration, Main, Settings controllers
- [x] Registration flow: language → nickname → main menu
- [x] Global commands handler
- [x] GameLogic package scaffolding

**Phase 1 Progress (January 2026):**
- [x] S.P.E.C.I.A.L. system implemented
- [x] Dweller model with full stats, leveling, HP system
- [x] Equipment system (Weapons, Outfits, Pets)
- [x] Resource system (Power, Food, Water, Caps)
- [x] Room types enum with all properties
- [x] Vault and DwellerModel database models
- [x] VaultController for basic vault view
- [x] Dweller list and detail views
- [x] Registration with nickname input (latin/cyrillic validation)
- [x] Unique vault numbering system (GlobalCounter)
- [x] Ethnic name variants for EN/UK locales
- [x] Localized resource display strings
- [x] Room model with position, level, production state
- [x] RoomModel database model with migrations
- [x] BuildController for room construction and upgrades
- [x] Dweller assignment to rooms
- [x] Localized room names (24 room types, EN/UK)
- [x] Starting rooms created with new vault (8 rooms)
- [x] Room merging (auto-merge adjacent same-type/level)
- [x] Escalating room prices (baseCost × existingCount + 1)
- [x] Room connection rules (elevator-based expansion)
- [x] Dweller work indicator in list (room emoji or idle)
- [x] Dweller unassign feature
- [x] Production formula with SPECIAL + happiness bonus
- [x] Power balance system (production vs consumption)
- [x] Resource scheduler with background ticks

---

## Phase 1: Core Game Mechanics (Telegram MVP)

### 1.1 GameLogic Package - Character System

**S.P.E.C.I.A.L. Stats:**
- [x] `SPECIAL.swift` - Enum with 7 stats (Strength, Perception, Endurance, Charisma, Intelligence, Agility, Luck)
- [x] `AbilityScores.swift` - Struct holding all 7 stats with min/max validation (1-10 base, 17 with outfit)
- [x] `StatModifier.swift` - Outfit/pet bonus system (implemented in `StatBonuses` struct)

**Dweller Model:**
- [x] `Dweller.swift` - Base dweller struct with:
  - [x] Name (first/last from pools)
  - [x] S.P.E.C.I.A.L. stats
  - [x] Level (1-50)
  - [x] Current HP / Max HP
  - [x] Radiation level
  - [x] Happiness (0-100%)
  - [x] Gender
  - [x] Rarity (Common/Rare/Legendary)
  - [x] Equipment slots (weapon, outfit, pet)
- [x] `DwellerRarity.swift` - Common (12 pts), Rare (28 pts), Legendary (40 pts)
- [x] `NameGenerator.swift` - Random name generation from predefined pools
- [x] Ethnic name variants for EN (English/American) and UK (Ukrainian) locales

**HP & Leveling:**
- [x] `LevelingSystem.swift` - XP thresholds and HP calculation (in `Dweller.swift`)
- [x] HP formula: `HP per level = 2.5 + (Endurance × 0.5)`
- [x] Starting HP: 105 for all dwellers
- [x] Max HP: 644 (E17 throughout leveling)

**Death & Revival:**
- [x] `RevivalSystem.swift` - Cost formula: `100 + (Level - 1) × 20 caps` (in `Dweller.swift`)
- [x] Dweller revival UI in VaultController (revive button, caps deduction)
- [ ] 24-hour revival timer (optional)

### 1.2 GameLogic Package - Vault System

**Room Types:**
- [x] `RoomType.swift` - Enum with all room types:
  - [x] Production: Power Generator, Nuclear Reactor, Diner, Garden, Water Treatment, Water Purification, Nuka-Cola Bottler
  - [x] Training: Weight Room, Armory, Fitness Room, Lounge, Classroom, Athletics Room, Game Room
  - [x] Medical: Medbay, Science Lab
  - [x] Special: Living Quarters, Storage Room, Radio Studio, Overseer's Office, Vault Door, Elevator
  - [x] Crafting: Weapon Workshop, Outfit Workshop, Theme Workshop, Barbershop
- [x] `RoomLevel.swift` - L1, L2, L3 with upgrade costs (in `Room.swift`)
- [x] `RoomSize.swift` - Single (2 dwellers), Double (4), Triple (6) (in `Room.swift`)

**Room Mechanics:**
- [x] `Room.swift` - Room instance with position, level, assigned dwellers
- [x] `RoomProduction.swift` - Production cycle calculations (in ResourceScheduler)
- [x] `ProductionFormula.swift` - `Cycle Time = Base_Time / (1 + Total_SPECIAL / 10 + Happiness_Bonus)` (in ResourceScheduler)
- [x] `RoomCapacity.swift` - Population and storage limits per room type (in `RoomType.swift`)

**Vault Grid:**
- [ ] `VaultGrid.swift` - 2D grid layout (max 25 floors)
- [ ] `RoomPlacement.swift` - Room placement validation
- [x] `RoomMerging.swift` - Adjacent same-type/level room merging (implemented in BuildController)
- [ ] `PowerGrid.swift` - Power distribution from source

**Population Unlocks:**
- [x] `PopulationUnlocks.swift` - Room unlock thresholds (0-100 pop) (in `RoomType.swift`)

### 1.3 GameLogic Package - Resource System

**Resources:**
- [x] `Resource.swift` - Power, Food, Water, Caps (includes VaultResources struct)
- [x] `ResourcePool.swift` - Current/max storage per resource (in `Resource.swift`)
- [x] `ConsumptionRate.swift` - 0.36 units/min/dweller for food/water (in `Resource.swift`)

**Medical Supplies:**
- [ ] `Stimpak.swift` - Heal HP (40-50%)
- [ ] `RadAway.swift` - Remove radiation (25-30%)
- [ ] `MedicalProduction.swift` - Intelligence-based production

**Caps Economy:**
- [ ] `CapsEconomy.swift` - Earning methods and spending

### 1.4 GameLogic Package - Equipment System

**Weapons:**
- [x] `Weapon.swift` - Name, damage range (min-max), type, rarity
- [x] `WeaponType.swift` - Pistol, Rifle, Shotgun, Energy, Heavy, Melee (in `Weapon.swift`)
- [x] `WeaponDatabase.swift` - All 50+ weapons from GDD (in `Weapon.swift`)

**Outfits:**
- [x] `Outfit.swift` - Name, SPECIAL bonuses, rarity
- [x] `OutfitDatabase.swift` - All outfits with stat bonuses (in `Outfit.swift`)

**Pets:**
- [x] `Pet.swift` - Species, rarity, bonus type/value
- [x] `PetBonus.swift` - Damage, HP, wasteland junk/caps, return speed, crafting time, etc. (in `Pet.swift`)
- [x] `PetDatabase.swift` - All pet types and bonuses (in `Pet.swift`)

**Inventory:**
- [x] `DwellerEquipment.swift` - Equipment loadout (weapon, outfit, pet slots)
- [x] `ItemRarity.swift` - Common, Rare, Legendary with properties
- [ ] `Inventory.swift` - Storage container with capacity
- [ ] `InventorySlot.swift` - Item stack/count management

### 1.5 GameLogic Package - Combat System

**Vault Combat:**
- [ ] `VaultCombat.swift` - Simplified combat (weapon damage + pet bonus only)
- [ ] `DamageCalculation.swift` - `Damage = random(Weapon_Min, Weapon_Max) + Pet_Damage_Bonus`

**Quest Combat:**
- [ ] `QuestCombat.swift` - Full combat with A/L/P effects
- [ ] `CriticalHit.swift` - 1-5× multiplier based on timing
- [ ] `CriticalMeter.swift` - Luck-based fill rate

### 1.6 GameLogic Package - Incidents

**Incident Types:**
- [x] `Incident.swift` - Base incident with spawn/spread logic
- [x] `IncidentType.swift` - All incident types with behaviors
- [x] Fire - Spread to empty adjacent rooms
- [x] Radroach - Weapon-based combat
- [x] Raider - Enter from vault door, steal caps
- [x] MoleRat - Combat with spread behavior
- [x] FeralGhoul - HP + radiation damage
- [x] Radscorpion - Heavy radiation damage
- [x] Deathclaw - Highest damage, ignores doors

**Incident Triggers:**
- [x] `RushAttempt` - Rush failure incidents (in Incident.swift)
- [x] Population thresholds - Min population per incident type
- [ ] `DeathclawTrigger.swift` - Hidden value accumulation formula

### 1.7 GameLogic Package - Production & Rush

**Production:**
- [ ] `ProductionCycle.swift` - Resource generation timing
- [ ] `HappinessBonus.swift` - +10% max production bonus

**Rush Mechanic:**
- [ ] `Rush.swift` - Rush attempt with success/failure
- [ ] `RushFormula.swift` - `Fail% = 40 - 2 × (Avg_Luck + Avg_SPECIAL) + 10 × Recent_Rushes`
- [ ] `RushReward.swift` - Caps, XP, happiness on success

### 1.8 GameLogic Package - Breeding

**Breeding System:**
- [ ] `Breeding.swift` - Male + Female in Living Quarters
- [ ] `BreedingRestrictions.swift` - Family relationship checks
- [ ] `PregnancyTimer.swift` - 3 hours pregnancy, 3 hours child growth
- [ ] `ChildStatInheritance.swift` - Formula for child rarity/stats

### 1.9 GameLogic Package - Exploration

**Wasteland Exploration:**
- [x] `Exploration.swift` - Automatic exploration with events
- [x] `ExplorationEvent.swift` - Combat, loot, location, NPC, radiation
- [x] `ExplorationLog.swift` - Text log generation (integrated in Exploration)
- [x] `ExplorationLoot.swift` - Item/caps generation based on Luck (integrated in Exploration)

**Explorer Mechanics:**
- [x] `ExplorerSupplies.swift` - Stimpak/RadAway auto-use thresholds (integrated in Exploration)
- [x] `ExplorerReturn.swift` - Return time = 50% of exploration time (integrated in Exploration)
- [x] `RadiationImmunity.swift` - E11+ = immune in wasteland (integrated in Exploration)

### 1.10 GameLogic Package - Quests

**Quest System:**
- [ ] `Quest.swift` - Quest definition with locations, rewards
- [ ] `QuestParty.swift` - Up to 3 dwellers
- [ ] `QuestLocation.swift` - Discovered through exploration (Perception)
- [ ] `QuestReward.swift` - Caps, items, legendary dwellers

---

## Phase 1: Telegram Bot Controllers

### 1.11 Database Models

**Vault Model:**
- [x] `Vault.swift` - Fluent model for vault data
- [x] `CreateVault.swift` migration
- [x] Fields: owner_id, name, caps, power/food/water storage, population_cap
- [x] Unique vault numbering system (vault_number field, never reused)
- [x] `GlobalCounter.swift` - Atomic counter for vault numbers
- [x] `CreateGlobalCounter.swift` migration

**Dweller Model:**
- [x] `DwellerModel.swift` - Fluent model linking to GameLogic Dweller
- [x] `CreateDweller.swift` migration
- [x] Fields: vault_id, name, level, HP, radiation, SPECIAL stats, equipment IDs

**Room Model:**
- [x] `RoomModel.swift` - Fluent model for vault rooms
- [x] `CreateRoom.swift` migration
- [x] Fields: vault_id, type, level, x, y, width, assigned dwellers via relationship

**Equipment Models:**
- [ ] `WeaponModel.swift`, `OutfitModel.swift`, `PetModel.swift`
- [ ] Migrations for each

**Inventory Model:**
- [ ] `InventoryItem.swift` - Fluent model for stored items
- [ ] `CreateInventoryItem.swift` migration

### 1.12 Telegram Controllers

**Vault Controller:**
- [x] `VaultController.swift` - Main vault view
- [x] Vault status display (power, water, food bars)
- [x] Room grid emoji visualization (in BuildController)
- [x] Quick actions menu (Dwellers, Resources, Build, Rooms, Settings)

**VaultController (consolidated - all game features):**
- [x] Room building (category selection, position, cost confirmation)
- [x] Room upgrades and auto-merge adjacent rooms
- [x] Dweller list and detail views
- [x] Dweller assignment to rooms
- [x] Dweller revival (revive dead dwellers for caps)
- [x] Wasteland exploration (send, view log, recall, collect)
- [x] Incident handling (view, send fighters, use stimpaks)
- [x] Incident alerts (push notification when incident spawns)
- [x] All slash commands registered (/vault, /dwellers, /build, /rooms, /explore, /incidents, /resources)
- [ ] Training initiation

**Inventory Controller:**
- [ ] `InventoryController.swift` - Item management (add to VaultController when needed)
- [ ] Weapon/outfit/pet tabs
- [ ] Equip/unequip actions
- [ ] Sell items

**Quest Controller:**
- [ ] Quest management (add to VaultController when needed)
- [ ] Available quests list
- [ ] Party formation
- [ ] Quest progress/combat UI

### 1.13 Localization Keys

- [x] Registration strings (welcome, nickname prompt, validation errors)
- [x] Vault UI strings (title, status, population)
- [x] Dweller UI strings (list, detail, empty state)
- [x] Resource display strings (title, consumption rates)
- [x] Room names and descriptions (all 24 room types)
- [x] Build/upgrade UI strings
- [x] Room assignment strings
- [ ] Add remaining vault-related strings to `en.json` and `uk.json`:
  - [ ] SPECIAL stat names
  - [ ] Equipment names
  - [x] Incident messages (added EN/UK localization)
  - [ ] Exploration log templates
  - [ ] Quest text

### 1.14 Real-time Updates

**Background Tasks:**
- [x] `ResourceScheduler.swift` - Background resource consumption (food/water drain, health/radiation damage)
- [x] `ProductionScheduler.swift` - Background resource generation (integrated into ResourceScheduler)
- [x] `PowerBalanceSystem` - Power consumption vs production, room power state management
- [ ] `TrainingScheduler.swift` - SPECIAL training timers
- [x] `ExplorationScheduler.swift` - Exploration event timing
- [x] `IncidentScheduler.swift` - Incident combat ticks and random spawns
- [ ] `BreedingScheduler.swift` - Pregnancy/growth timers

**Notification System:**
- [ ] Production ready notifications
- [ ] Training complete notifications
- [ ] Explorer return notifications
- [x] Incident alerts (via VaultController.sendIncidentAlert)

---

## Phase 1: Multiplayer Basics

### 1.15 Co-Management

- [ ] Vault sharing system (referral links)
- [ ] Co-manager role with permissions
- [ ] Concurrent action handling

### 1.16 Guild System

- [ ] `Guild.swift` model
- [ ] Guild creation/joining
- [ ] Guild roles (Leader, Officer, Member)
- [ ] Guild chat (basic)

### 1.17 Trading/Marketplace

- [ ] `AuctionController.swift` - Item listings
- [ ] `/auction` command
- [ ] Buy/sell interface
- [ ] Transaction history

---

## Phase 2: Mobile Client Alpha

### 2.1 REST API for Godot

- [ ] Authentication endpoints (link Telegram account)
- [ ] Vault state endpoints
- [ ] Action endpoints (build, assign, explore, etc.)
- [ ] WebSocket for real-time sync

### 2.2 Godot Client

- [ ] SwiftGodot project setup in `Vault-2D/`
- [ ] 2D vault tilemap visualization
- [ ] Touch controls
- [ ] UI scenes (vault, dwellers, inventory)

---

## Phase 3: Rich Features

### 3.1 Interactive Quests

- [ ] Quest map navigation
- [ ] Turn-based combat UI
- [ ] Action selection (Attack, Cast, Item, Dodge, Flee)
- [ ] Critical hit timing minigame

### 3.2 Party System

- [ ] Multi-player parties for quests
- [ ] Real-time coordination

### 3.3 Guild Features

- [ ] Guild events
- [ ] Resource sharing between vaults
- [ ] Guild rankings

### 3.4 Monetization

- [ ] Lunchbox system (5 cards, guaranteed rare+)
- [ ] Mr. Handy robots
- [ ] Pet Carriers
- [ ] Nuka-Cola Quantum premium currency
- [ ] Objectives system with rewards

---

## Phase 4: Late-Game & Polish

### 4.1 Advanced Rooms

- [ ] Nuclear Reactor (60 pop)
- [ ] Garden (70 pop)
- [ ] Water Purification (80 pop)
- [ ] Nuka-Cola Bottler (100 pop)
- [ ] Research Center (crafting)

### 4.2 Crafting System

- [ ] Junk collection (139 types)
- [ ] Recipe discovery
- [ ] Weapon/outfit crafting
- [ ] Crafting time reduction (SPECIAL + pets)

### 4.3 Advanced Threats

- [ ] Deathclaws (61+ pop)
- [ ] Radscorpions (51+ pop)
- [ ] Feral Ghouls (41+ pop)

### 4.4 Statistics & Achievements

- [ ] Vault statistics tracking
- [ ] Achievement system
- [ ] Leaderboards
- [ ] Daily/weekly login rewards

### 4.5 Cross-Vault Interactions

- [ ] Vault visits
- [ ] Trade caravans
- [ ] Alliance system

---

## Technical Debt & Infrastructure

### Testing

- [ ] Unit tests for GameLogic calculations
- [ ] Integration tests for controllers
- [ ] Load testing for multiplayer

### Documentation

- [ ] API documentation for Godot client
- [ ] Controller pattern documentation
- [ ] Deployment guide

### DevOps

- [ ] CI/CD pipeline
- [ ] Staging environment
- [ ] Production deployment
- [ ] Monitoring and logging

---

## Quick Reference: File Locations

| Component | Location |
|-----------|----------|
| Controllers | `Swift/Controllers/` |
| Models | `Swift/Models/` |
| Migrations | `Swift/Migrations/` |
| Router | `Swift/Telegram/Router/` |
| GameLogic | `GameLogic/Sources/GameLogic/` |
| Localizations | `Localizations/` |
| Godot Client | `Vault-2D/` |

---

## Next Immediate Steps

1. ~~**Start PostgreSQL container**~~ ✅
2. ~~**Verify bot runs correctly**~~ ✅
3. ~~**Begin GameLogic S.P.E.C.I.A.L. system implementation**~~ ✅
4. ~~**Create Vault and Dweller database models**~~ ✅
5. ~~**Implement VaultController for basic vault view**~~ ✅
6. ~~**Add registration with nickname input**~~ ✅
7. ~~**Implement unique vault numbering**~~ ✅
8. ~~**Add ethnic names for locales**~~ ✅
9. ~~**Localize remaining strings**~~ ✅

**Current Focus:**
1. ~~**Implement Room model and BuildController**~~ ✅
2. ~~**Add room assignment for dwellers**~~ ✅
3. ~~**Implement resource consumption**~~ ✅ - Background food/water drain with consequences
4. ~~**Implement production cycle timing**~~ ✅ - Background resource generation with power balance
5. ~~**Add room merging**~~ ✅ - Auto-merge adjacent same-type/level rooms on build
6. ~~**Add exploration system**~~ ✅ - Send dwellers to wasteland with event generation
7. ~~**Add incident system**~~ ✅ - Random events (fires, radroaches, raiders)

**Future Vault Number Changes (Donation):**
- Vault number change is prepared in architecture (vault_number field is independent)
- Implementation needed: admin endpoint or donation handler to update vault_number
- GlobalCounter ensures new numbers are unique even after changes

---

*Last updated: February 2, 2026* (Controller consolidation, dweller revival, slash commands fix)
