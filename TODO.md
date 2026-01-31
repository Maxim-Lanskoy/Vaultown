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
- [x] Registration, Main, Settings controllers
- [x] Global commands handler
- [x] GameLogic package scaffolding

---

## Phase 1: Core Game Mechanics (Telegram MVP)

### 1.1 GameLogic Package - Character System

**S.P.E.C.I.A.L. Stats:**
- [ ] `SPECIAL.swift` - Enum with 7 stats (Strength, Perception, Endurance, Charisma, Intelligence, Agility, Luck)
- [ ] `AbilityScores.swift` - Struct holding all 7 stats with min/max validation (1-10 base, 17 with outfit)
- [ ] `StatModifier.swift` - Outfit/pet bonus system

**Dweller Model:**
- [ ] `Dweller.swift` - Base dweller struct with:
  - [ ] Name (first/last from pools)
  - [ ] S.P.E.C.I.A.L. stats
  - [ ] Level (1-50)
  - [ ] Current HP / Max HP
  - [ ] Radiation level
  - [ ] Happiness (0-100%)
  - [ ] Gender
  - [ ] Rarity (Common/Rare/Legendary)
  - [ ] Equipment slots (weapon, outfit, pet)
- [ ] `DwellerRarity.swift` - Common (12 pts), Rare (28 pts), Legendary (40 pts)
- [ ] `NameGenerator.swift` - Random name generation from predefined pools

**HP & Leveling:**
- [ ] `LevelingSystem.swift` - XP thresholds and HP calculation
- [ ] HP formula: `HP per level = 2.5 + (Endurance × 0.5)`
- [ ] Starting HP: 105 for all dwellers
- [ ] Max HP: 644 (E17 throughout leveling)

**Death & Revival:**
- [ ] `RevivalSystem.swift` - Cost formula: `100 + (Level - 1) × 20 caps`
- [ ] 24-hour revival timer

### 1.2 GameLogic Package - Vault System

**Room Types:**
- [ ] `RoomType.swift` - Enum with all room types:
  - [ ] Production: Power Generator, Nuclear Reactor, Diner, Garden, Water Treatment, Water Purification, Nuka-Cola Bottler
  - [ ] Training: Weight Room, Armory, Fitness Room, Lounge, Classroom, Athletics Room, Game Room
  - [ ] Medical: Medbay, Science Lab
  - [ ] Special: Living Quarters, Storage Room, Radio Studio, Overseer's Office, Vault Door, Elevator
  - [ ] Crafting: Weapon Workshop, Outfit Workshop, Theme Workshop, Barbershop
- [ ] `RoomLevel.swift` - L1, L2, L3 with upgrade costs
- [ ] `RoomSize.swift` - Single (2 dwellers), Double (4), Triple (6)

**Room Mechanics:**
- [ ] `Room.swift` - Room instance with position, level, assigned dwellers
- [ ] `RoomProduction.swift` - Production cycle calculations
- [ ] `ProductionFormula.swift` - `Cycle Time = Base_Time / (1 + Total_SPECIAL / 10 + Happiness_Bonus)`
- [ ] `RoomCapacity.swift` - Population and storage limits per room type

**Vault Grid:**
- [ ] `VaultGrid.swift` - 2D grid layout (max 25 floors)
- [ ] `RoomPlacement.swift` - Room placement validation
- [ ] `RoomMerging.swift` - Adjacent same-type/level room merging
- [ ] `PowerGrid.swift` - Power distribution from source

**Population Unlocks:**
- [ ] `PopulationUnlocks.swift` - Room unlock thresholds (0-100 pop)

### 1.3 GameLogic Package - Resource System

**Resources:**
- [ ] `Resource.swift` - Power, Food, Water, Caps
- [ ] `ResourcePool.swift` - Current/max storage per resource
- [ ] `ConsumptionRate.swift` - 0.36 units/min/dweller for food/water

**Medical Supplies:**
- [ ] `Stimpak.swift` - Heal HP (40-50%)
- [ ] `RadAway.swift` - Remove radiation (25-30%)
- [ ] `MedicalProduction.swift` - Intelligence-based production

**Caps Economy:**
- [ ] `CapsEconomy.swift` - Earning methods and spending

### 1.4 GameLogic Package - Equipment System

**Weapons:**
- [ ] `Weapon.swift` - Name, damage range (min-max), type, rarity
- [ ] `WeaponType.swift` - Pistol, Rifle, Shotgun, Energy, Heavy, Melee
- [ ] `WeaponDatabase.swift` - All 50+ weapons from GDD

**Outfits:**
- [ ] `Outfit.swift` - Name, SPECIAL bonuses, rarity
- [ ] `OutfitDatabase.swift` - All outfits with stat bonuses

**Pets:**
- [ ] `Pet.swift` - Species, rarity, bonus type/value
- [ ] `PetBonus.swift` - Damage, HP, wasteland junk/caps, return speed, crafting time, etc.
- [ ] `PetDatabase.swift` - All pet types and bonuses

**Inventory:**
- [ ] `Inventory.swift` - Storage container with capacity
- [ ] `InventorySlot.swift` - Item stack/count management
- [ ] `Item.swift` - Base item protocol

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
- [ ] `Incident.swift` - Base incident with spawn/spread logic
- [ ] `Fire.swift` - Spread to empty adjacent rooms
- [ ] `Radroach.swift` - Weapon-based combat
- [ ] `Raider.swift` - Enter from vault door, steal caps
- [ ] `MoleRat.swift` - Spawn at dirt-adjacent rooms only
- [ ] `FeralGhoul.swift` - HP + radiation damage
- [ ] `Radscorpion.swift` - Teleport, heavy radiation
- [ ] `Deathclaw.swift` - Tear through doors/elevators

**Incident Triggers:**
- [ ] `IncidentSpawner.swift` - Rush failure incidents
- [ ] `PopulationThresholds.swift` - Min population per incident type
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
- [ ] `Exploration.swift` - Automatic exploration with events
- [ ] `ExplorationEvent.swift` - Combat, loot, location, NPC, radiation
- [ ] `ExplorationLog.swift` - Text log generation
- [ ] `ExplorationLoot.swift` - Item/caps generation based on Luck

**Explorer Mechanics:**
- [ ] `ExplorerSupplies.swift` - Stimpak/RadAway auto-use thresholds
- [ ] `ExplorerReturn.swift` - Return time = 50% of exploration time
- [ ] `RadiationImmunity.swift` - E11+ = immune in wasteland

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
- [ ] `Vault.swift` - Fluent model for vault data
- [ ] `CreateVault.swift` migration
- [ ] Fields: owner_id, name, caps, power/food/water storage, population_cap

**Dweller Model:**
- [ ] `DwellerModel.swift` - Fluent model linking to GameLogic Dweller
- [ ] `CreateDweller.swift` migration
- [ ] Fields: vault_id, name, level, HP, radiation, SPECIAL stats, equipment IDs

**Room Model:**
- [ ] `RoomModel.swift` - Fluent model for vault rooms
- [ ] `CreateRoom.swift` migration
- [ ] Fields: vault_id, type, level, x, y, width, assigned_dweller_ids

**Equipment Models:**
- [ ] `WeaponModel.swift`, `OutfitModel.swift`, `PetModel.swift`
- [ ] Migrations for each

**Inventory Model:**
- [ ] `InventoryItem.swift` - Fluent model for stored items
- [ ] `CreateInventoryItem.swift` migration

### 1.12 Telegram Controllers

**Vault Controller:**
- [ ] `VaultController.swift` - Main vault view
- [ ] Vault status display (power, water, food bars)
- [ ] Room grid emoji visualization
- [ ] Quick actions menu

**Build Controller:**
- [ ] `BuildController.swift` - Room construction
- [ ] Room type selection
- [ ] Position selection
- [ ] Cost confirmation
- [ ] Upgrade/merge options

**Dweller Controller:**
- [ ] `DwellerController.swift` - Dweller management
- [ ] Dweller list view
- [ ] Dweller detail view (stats, equipment)
- [ ] Assignment to rooms
- [ ] Training initiation

**Inventory Controller:**
- [ ] `InventoryController.swift` - Item management
- [ ] Weapon/outfit/pet tabs
- [ ] Equip/unequip actions
- [ ] Sell items

**Exploration Controller:**
- [ ] `ExplorationController.swift` - Wasteland exploration
- [ ] Send dweller to explore
- [ ] View exploration log
- [ ] Recall explorer
- [ ] Collect loot on return

**Quest Controller:**
- [ ] `QuestController.swift` - Quest management
- [ ] Available quests list
- [ ] Party formation
- [ ] Quest progress/combat UI

**Incident Controller:**
- [ ] `IncidentController.swift` - Handle active incidents
- [ ] Incident alerts
- [ ] Manual Stimpak usage during combat
- [ ] Victory/defeat handling

### 1.13 Localization Keys

- [ ] Add all vault-related strings to `en.json` and `uk.json`:
  - [ ] Room names and descriptions
  - [ ] SPECIAL stat names
  - [ ] Equipment names
  - [ ] Incident messages
  - [ ] Exploration log templates
  - [ ] Quest text
  - [ ] UI button labels

### 1.14 Real-time Updates

**Background Tasks:**
- [ ] `ProductionScheduler.swift` - Background resource generation
- [ ] `TrainingScheduler.swift` - SPECIAL training timers
- [ ] `ExplorationScheduler.swift` - Exploration event timing
- [ ] `BreedingScheduler.swift` - Pregnancy/growth timers

**Notification System:**
- [ ] Production ready notifications
- [ ] Training complete notifications
- [ ] Explorer return notifications
- [ ] Incident alerts

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

1. **Start PostgreSQL container**
2. **Verify bot runs correctly**
3. **Begin GameLogic S.P.E.C.I.A.L. system implementation**
4. **Create Vault and Dweller database models**
5. **Implement VaultController for basic vault view**

---

*Last updated: January 2026*
