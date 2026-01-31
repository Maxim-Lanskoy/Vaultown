# Vaultown - Game Design Document

> This document contains all game mechanics, rules, formulas, and design specifications for Vaultown.
> For implementation details, setup instructions, and development roadmap, see [README.md](README.md).

---

## Table of Contents

1. [Game Overview](#game-overview)
2. [Story & Lore](#story--lore)
3. [Cross-Platform Architecture](#cross-platform-architecture)
4. [S.P.E.C.I.A.L. System](#special-system)
5. [Vault Building & Rooms](#vault-building--rooms)
6. [Dweller Mechanics](#dweller-mechanics)
7. [Equipment System](#equipment-system)
8. [Incidents & Threats](#incidents--threats)
9. [Exploration & Quests](#exploration--quests)
10. [Population & Breeding](#population--breeding)
11. [Resource Management](#resource-management)
12. [Multiplayer Features](#multiplayer-features)
13. [Monetization](#monetization)
14. [Tech Stack](#tech-stack)
15. [Project Structure](#project-structure)
16. [Vault Statistics](#vault-statistics)
17. [Hard Limits Reference](#hard-limits-reference)

---

## Game Overview

**Vaultown** is a cross-platform multiplayer vault management RPG that brings the beloved Fallout Shelter experience to Telegram and mobile with added multiplayer capabilities. Players take on the role of survivors in a post-apocalyptic world, tasked with building and managing an underground bunker (vault) to protect what's left of civilization.

### Core Gameplay

- Build and expand underground vaults with modular rooms
- Assign dwellers to production, training, and exploration tasks
- Manage resources: power, water, food, and caps
- Equip dwellers with weapons, outfits, and pets
- Explore the wasteland for loot and encounters
- Defend against incidents: fires, radroaches, raiders, deathclaws
- Collaborate with other players through guilds and trading

### Starting Conditions

New vaults begin with:

| Resource | Starting Amount |
|----------|-----------------|
| Caps | 500 |
| Power | 50 |
| Food | 50 |
| Water | 50 |
| Stimpaks | 2 |
| RadAway | 2 |

**Starting Dwellers:** 3 common dwellers (random SPECIAL, ~12 total points each)

**Starting Rooms:**
- Vault Door (L1)
- 1 Power Generator
- 1 Diner
- 1 Water Treatment
- 1 Living Quarters
- 1 Elevator

**Tutorial Lunchbox:** 1 guaranteed lunchbox during tutorial with helpful starting items

### Platform Support

| Platform | Interface | Status |
|----------|-----------|--------|
| **Telegram Bot** | Text + emoji maps, button UI | Primary (MVP) |
| **iOS/Android** | 2D graphical (Godot + SwiftGodot) | Planned |

Both platforms share the same database and game logic, ensuring seamless cross-platform play.

---

## Story & Lore

### The Awakening

You are a person from the current era who has been cryogenically frozen for decades. After the nuclear half-life period passes, you awaken to help rebuild civilization from the ashes.

### Starting the Game

Your role depends on how you join:

| Entry Method | Role | Description |
|--------------|------|-------------|
| **Solo Start** | Vault Overseer | Full control of a new vault with initial dwellers (also thawed survivors) |
| **Player Referral** | Co-Manager | Join another player's vault as a co-overseer, sharing responsibilities |
| **Guild Referral** | Guild Member | Become part of a larger guild vault with collaborative management |

### Player Character

Uniquely, each player is represented as a dweller within the vault:
- Has full S.P.E.C.I.A.L. stats like any other dweller
- Can be assigned to work in rooms or sent on expeditions
- Can participate in breeding new dwellers
- If the player explores, they get semi-automatic control with interactive choices

---

## Cross-Platform Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENTS                                 │
│  ┌─────────────────┐              ┌─────────────────────────┐   │
│  │  Telegram Bot   │              │   Godot Mobile Client   │   │
│  │  (Primary MVP)  │              │   (SwiftGodot)          │   │
│  │  - Emoji maps   │              │   - 2D tilemap graphics │   │
│  │  - Button UI    │              │   - Touch controls      │   │
│  └────────┬────────┘              └────────────┬────────────┘   │
│           │                                    │                │
│           │  SwiftTelegramSdk                  │  REST API      │
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
│  │  │              PostgreSQL + Fluent ORM                │  │  │
│  │  │  - User accounts, characters                        │  │  │
│  │  │  - Vault state, room layouts                        │  │  │
│  │  │  - Inventories, guilds, auctions                    │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### GameLogic Package (Critical Design)

All game mechanics are implemented in a **shared Swift package** called `GameLogic`:
- Contains pure game logic with **no dependencies** on Telegram or Godot
- Shared between backend and mobile client
- Ensures **identical rules** across all platforms

```
GameLogic/
├── Character/      # S.P.E.C.I.A.L. system, dweller stats
├── Combat/         # Attack calculations, damage, conditions
├── Vault/          # Room types, production, incidents
├── Equipment/      # Weapons, armor, items, inventory
├── World/          # Exploration, map generation
└── GameLogic.swift # Public API exports
```

**Key Principle**: If it's a game rule or calculation, it goes in GameLogic. Controllers only handle user I/O, database persistence, and platform-specific rendering.

---

## S.P.E.C.I.A.L. System

Each dweller has seven trainable stats capped at **10 base** (17 maximum with +7 outfit bonus):

| Stat | Production Room | Rush Contribution | Quest Combat Effect | Exploration Effect |
|------|-----------------|-------------------|---------------------|-------------------|
| **Strength** | Power Generator, Nuclear Reactor | Power rooms | Increased damage output | Opens lockers, increases caps found |
| **Perception** | Water Treatment, Water Purification | Water rooms | Slows crit timing arrow | Finds quest locations, finds items |
| **Endurance** | Nuka-Cola Bottler | Bottler rooms | HP via leveling (permanent) | 11+ = radiation immunity |
| **Charisma** | Living Quarters, Radio Studio | These rooms | Dialogue options | Befriend NPCs, avoid encounters |
| **Intelligence** | Medbay, Science Lab | Medical rooms | Bonus XP gain | Stimpak/RadAway efficiency |
| **Agility** | Diner, Garden | Food rooms | Attack speed | Flee damage reduction |
| **Luck** | All rooms (caps bonus) | All rooms | Crit meter fill speed | Caps quantity, loot quality |

### Critical Implementation Note

**Vault combat uses ONLY:**
1. Dweller HP
2. Weapon damage
3. Pet bonuses

S.P.E.C.I.A.L. stats have **zero effect** on vault incident combat. Quest combat is different and uses Agility (attack speed), Luck (crit meter), and Perception (crit timing).

### Stat Caps by Activity

Not all activities benefit from stats above 10:

| Activity | Effective Cap | Outfit Bonus Helps? |
|----------|---------------|---------------------|
| Room Production | 17 | ✅ Yes - faster cycles |
| Training Speed | 10 | ❌ No - fixed by stat level |
| Rush Success | 17 | ✅ Yes - lower fail % |
| Exploration Loot | 17 | ✅ Yes - better finds |
| Exploration Radiation | 11 | ✅ Yes - E11+ = immune |
| Quest Combat (A/L/P) | 17 | ✅ Yes - faster/crits |
| HP Gain (Endurance) | 17 | ✅ Yes - more HP/level |
| Breeding (Charisma) | 17 | ✅ Yes - faster courtship |

**Key Insight:** Outfit bonuses matter for production, exploration, quests, and HP optimization. Always equip stat-boosting outfits when these activities occur.

---

## Vault Building & Rooms

The vault is a modular construction of rooms that serve different functions. Rooms can cost caps to build, merge when adjacent (up to 3-wide), and upgrade to higher levels.

### Population Unlock Thresholds

| Population | Rooms Unlocked |
|------------|----------------|
| 0 | Vault Door, Power Generator, Diner, Water Treatment, Living Quarters, Elevator |
| 12 | Storage Room |
| 14 | Medbay |
| 16 | Science Lab |
| 18 | Overseer's Office |
| 20 | Radio Studio |
| 22 | Weapon Workshop |
| 24 | Weight Room (S), Classroom (I) |
| 30 | Lounge (C) |
| 32 | Outfit Workshop |
| 35 | Armory (P), Fitness Room (E), Athletics Room (A) |
| 40 | Game Room (L) |
| 42 | Theme Workshop |
| 50 | Barbershop |
| 60 | Nuclear Reactor |
| 70 | Garden |
| 80 | Water Purification |
| 100 | Nuka-Cola Bottler |

### Production Rooms

| Room | SPECIAL | Base Cost | Production (L1/L2/L3) | Capacity (1/2/3-wide) |
|------|---------|-----------|----------------------|----------------------|
| Power Generator ⚡ | Strength | 100 caps | 10/12/15 per cycle | 2/4/6 dwellers |
| Nuclear Reactor ⚡ | Strength | 1,200 caps | 12/14/18 per cycle | 2/4/6 dwellers |
| Diner 🍲 | Agility | 100 caps | 10/12/15 per cycle | 2/4/6 dwellers |
| Garden 🍲 | Agility | 300 caps | Higher than Diner | 2/4/6 dwellers |
| Water Treatment 💧 | Perception | 100 caps | 10/12/15 per cycle | 2/4/6 dwellers |
| Water Purification 💧 | Perception | 400 caps | Higher than Treatment | 2/4/6 dwellers |
| Nuka-Cola Bottler | Endurance | 3,000 caps | Food + Water combined | 2/4/6 dwellers |

### Room Capacity Summary

All rooms (except special) follow the same capacity pattern:

| Room Width | Dweller Capacity |
|------------|------------------|
| Single (1-wide) | 2 dwellers |
| Double (2-wide) | 4 dwellers |
| Triple (3-wide) | 6 dwellers |

**Special Room Capacities:**

| Room | Single | Double | Triple | Function |
|------|--------|--------|--------|----------|
| Living Quarters | 8 | 16 | **40** pop cap | Population limit |
| Storage Room | 10 | 35 | **125** items | Item storage |
| Medbay | 10 | 25 | **75** Stimpaks | Medical storage |
| Science Lab | 10 | 25 | **75** RadAway | Medical storage |
| Vault Door | 2 | - | - | Cannot merge |
| Overseer's Office | 3 | - | - | Cannot merge |
| Weapon Workshop | 2 | 4 | 6 | Crafting capacity |
| Outfit Workshop | 2 | 4 | 6 | Crafting capacity |

**Living Quarters Scaling:**

| Configuration | Population Cap Added |
|---------------|---------------------|
| Single L1 | 8 |
| Single L2 | 12 |
| Single L3 | 16 |
| Double L3 | 28 |
| **Triple L3** | **40** |

Maximum vault population (200) requires ~5 Triple L3 Living Quarters.

### Production Cycle Formula

Production time is calculated based on dweller stats:

```
Cycle Time = Base_Time / (1 + Total_Room_SPECIAL / 10 + Happiness_Bonus)
```

**Key factors:**
- **Total Room SPECIAL** = Sum of relevant SPECIAL from all assigned dwellers (including outfit bonuses)
- **Happiness Bonus** = Room average happiness / 10 (max +10%)
- **Outfit bonuses count** - A dweller with S10 + Commander Fatigues (+7S) contributes S17
- Removing a dweller mid-cycle does NOT reset the timer
- More dwellers = faster cycles (diminishing returns)

### Training Rooms

| Room | SPECIAL | Unlock | Capacity (1/2/3-wide) |
|------|---------|--------|----------------------|
| Weight Room | Strength | 24 pop | 2/4/6 dwellers |
| Armory | Perception | 35 pop | 2/4/6 dwellers |
| Fitness Room | Endurance | 35 pop | 2/4/6 dwellers |
| Lounge | Charisma | 30 pop | 2/4/6 dwellers |
| Classroom | Intelligence | 24 pop | 2/4/6 dwellers |
| Athletics Room | Agility | 35 pop | 2/4/6 dwellers |
| Game Room | Luck | 40 pop | 2/4/6 dwellers |

**Training Times (Level 1 room):**

| Stat Level | Duration | Nuka-Cola to Skip |
|------------|----------|-------------------|
| 1→2 | 25 minutes | 1 |
| 2→3 | 1 hour | 1 |
| 3→4 | 2 hours | 2 |
| 4→5 | 4 hours | 3 |
| 5→6 | 6 hours | 4 |
| 6→7 | 8 hours | 5 |
| 7→8 | 11 hours | 6 |
| 8→9 | 14-15 hours | 8 |
| 9→10 | 18-22 hours | 10 |
| **Total 1→10** | **~64-70 hours** | **40 Quantum** |

### Special Rooms

| Room | Unlock | Function |
|------|--------|----------|
| **Medbay** | 14 pop | Produces Stimpaks (see below) |
| **Science Lab** | 16 pop | Produces RadAway (see below) |

### Medical Production (Medbay & Science Lab)

**Stimpak Production (Medbay):**
- SPECIAL used: **Intelligence**
- Heals dweller HP during incidents and exploration
- Higher Intelligence = faster production cycles

| Room Size | Storage Capacity | Max Production |
|-----------|------------------|----------------|
| Single L1 | 10 | 10 |
| Double L2 | 25 | 25 |
| Triple L3 | 75 | 75 |

**RadAway Production (Science Lab):**
- SPECIAL used: **Intelligence**
- Removes radiation damage (reduces max HP bar)
- Higher Intelligence = faster production cycles

| Room Size | Storage Capacity | Max Production |
|-----------|------------------|----------------|
| Single L1 | 10 | 10 |
| Double L2 | 25 | 25 |
| Triple L3 | 75 | 75 |

**Production Formula:**
```
Cycle Time = Base_Time / (1 + Total_Intelligence / 10)
```

**Usage:**
- Stimpaks: Manually used during vault incidents, auto-used during exploration/quests
- RadAway: Removes accumulated radiation damage
- Explorers automatically use supplies when HP/radiation thresholds hit
- Quest parties share a communal Stimpak/RadAway pool

**Maximum Vault Storage:**
- Stimpaks: 75 (one fully upgraded Triple Medbay)
- RadAway: 75 (one fully upgraded Triple Science Lab)
- Additional Medbay/Science Labs needed for higher storage
| **Storage Room** | 12 pop | Item capacity (Triple L3 = 125 items) |
| **Living Quarters** | 0 pop | Population cap (Triple L3 = 40 dwellers) |
| **Vault Door** | Built-in | Defense against raiders |
| **Radio Studio** | 20 pop | Recruit dwellers + happiness bonus (see below) |

### Radio Studio Recruitment

The Radio Studio broadcasts to attract new dwellers and boost vault happiness.

**Primary Stat:** Charisma

**Recruitment Mechanics:**
- Broadcasts attract wasteland wanderers to vault door
- Higher Charisma = shorter recruitment cycles
- Each successful broadcast has a CHANCE to attract a dweller

**Recruitment Cycle:**
```
Cycle Time = Base_Time / (1 + Total_Charisma / 10)
Success Chance = 25% + (Room_Level × 5%)
```

| Room Level | Base Success Chance |
|------------|---------------------|
| L1 | 30% per cycle |
| L2 | 35% per cycle |
| L3 | 40% per cycle |

**Recruited Dweller Quality:**
- Mostly common dwellers (low SPECIAL totals)
- Rare chance for rare dwellers
- Legendary dwellers: Extremely rare (lunchbox-level odds)
- SPECIAL stats randomized based on wasteland "origin"

**Happiness Bonus:**
- Radio Studio provides vault-wide happiness boost
- Bonus applies even when not actively recruiting

| Room Size | Happiness Bonus |
|-----------|-----------------|
| Single | +0.5% vault-wide |
| Double | +0.75% vault-wide |
| Triple | +1% vault-wide |

**Deathclaw Risk:**
Radio broadcasts increase Deathclaw attack probability:
- Each recruitment cycle adds +0.07 to +0.20 to hidden attack value
- Larger/higher level Radio Studios = more risk per cycle
- Consider disabling Radio when population is stable

**Tips:**
- Staff with high Charisma dwellers for fastest recruitment
- Disable during Deathclaw-vulnerable periods (61+ population)
- Lower priority than production rooms for early game
| **Overseer's Office** | 18 pop | Unlocks quest system (L1: 1 quest, L3: 3 quests) |
| **Barbershop** | 50 pop | Customize dwellers (hair/face). Charisma reduces time. Quantum can speed up. |
| **Theme Workshop** | 42 pop | Craft room themes (cosmetic only). Applied to merged/upgraded rooms. |

### Workshop Upgrade Population Requirements

Unlike room unlocks (permanent), workshop upgrades require current population at time of upgrade:

| Room | Unlock | Level 2 | Level 3 |
|------|--------|---------|---------|
| Weapon Workshop | 22 pop | 45 pop | 75 pop |
| Outfit Workshop | 32 pop | 55 pop | 90 pop |
| Theme Workshop | 42 pop | 65 pop | 105 pop |
| Overseer's Office | 18 pop | 30 pop | 55 pop |

**Note:** If population drops below threshold, existing upgrades are kept but new upgrades cannot be performed.

### Late-Game Rooms (Vaultown Additions)

| Room | Function |
|------|----------|
| **Radio/Communications Center** | Connect with other vaults, alliances, resource trading |
| **Research Center** | Craft armor/weapons, produce items for sale |

### Merge Mechanics

- All rooms except Vault Door, Overseer's Office, and Workshops can merge
- Same type AND same upgrade level required
- Double rooms: **25% cheaper** to upgrade than two singles
- Triple rooms: **34% cheaper** than three singles

### Room Building & Upgrade Costs

Room costs scale with size and upgrade level. Building costs are one-time; merging same-level rooms is free.

**Production Room Costs:**

| Room | Size | Build Cost | L2 Upgrade | L3 Upgrade | Total to L3 |
|------|------|------------|------------|------------|-------------|
| Power Generator | Single | 100 | 250 | 750 | 1,100 |
| Power Generator | Double | 175 | 438 | 1,313 | 1,926 |
| Power Generator | Triple | 200 | 500 | 1,500 | 2,200 |
| Nuclear Reactor | Single | 1,200 | 3,000 | 9,000 | 13,200 |
| Diner | Single | 100 | 250 | 750 | 1,100 |
| Garden | Single | 300 | 750 | 2,250 | 3,300 |
| Water Treatment | Single | 100 | 250 | 750 | 1,100 |
| Water Purification | Single | 400 | 1,000 | 3,000 | 4,400 |
| Nuka-Cola Bottler | Single | 3,000 | 7,500 | 22,500 | 33,000 |

**Training Room Costs:**

| Room | Build Cost | L2 Upgrade | L3 Upgrade |
|------|------------|------------|------------|
| Weight Room | 400 | 1,000 | 3,000 |
| Armory | 500 | 1,250 | 3,750 |
| Fitness Room | 500 | 1,250 | 3,750 |
| Lounge | 450 | 1,125 | 3,375 |
| Classroom | 400 | 1,000 | 3,000 |
| Athletics Room | 500 | 1,250 | 3,750 |
| Game Room | 600 | 1,500 | 4,500 |

**Special Room Costs:**

| Room | Build Cost | L2 Upgrade | L3 Upgrade |
|------|------------|------------|------------|
| Living Quarters | 100 | 250 | 750 |
| Storage Room | 150 | 375 | 1,125 |
| Medbay | 400 | 1,000 | 3,000 |
| Science Lab | 400 | 1,000 | 3,000 |
| Radio Studio | 600 | 1,500 | 4,500 |
| Overseer's Office | 1,000 | 2,500 | 7,500 |
| Weapon Workshop | 800 | 2,000 | 6,000 |
| Outfit Workshop | 800 | 2,000 | 6,000 |
| Theme Workshop | 500 | 1,250 | 3,750 |
| Barbershop | 300 | 750 | 2,250 |

**Elevator & Vault Door:**

| Room | Build Cost | Notes |
|------|------------|-------|
| Elevator | 100 | Cannot upgrade, no power cost |
| Vault Door | 750 (L2), 2,500 (L3) | Built-in L1, upgrades add defense |

**Merged Room Discounts:**
- Double rooms: 25% cheaper to upgrade than two singles
- Triple rooms: 34% cheaper to upgrade than three singles
- Always merge before upgrading to save caps

### Room Power Consumption

Each room consumes power based on size and upgrade level:

| Room Size | Level 1 | Level 2 | Level 3 |
|-----------|---------|---------|---------|
| Single | 1 | 2 | 3 |
| Double | 2 | 4 | 6 |
| Triple | 3 | 6 | 9 |

**Power Priority:**
- When power runs low, rooms shut down starting from **furthest from power source**
- **Elevators consume NO power** (build freely)
- Shut-down rooms stop producing and can't be rushed
- Production rooms should be prioritized near reactors

### Room Assignment Optimization

Assign dwellers to rooms matching their highest SPECIAL stat for maximum efficiency.

**SPECIAL to Room Mapping:**

| Stat | Assign To | Bonus |
|------|-----------|-------|
| Strength | Power Generator, Nuclear Reactor | Faster power cycles |
| Perception | Water Treatment, Water Purification | Faster water cycles |
| Endurance | Nuka-Cola Bottler | Faster F+W cycles |
| Charisma | Radio Studio, Living Quarters | Faster recruitment/breeding |
| Intelligence | Medbay, Science Lab | Faster Stimpak/RadAway |
| Agility | Diner, Garden | Faster food cycles |
| Luck | Any room | Bonus caps on collection |

**Optimization Tips:**
- Match primary stat to room type (highest impact)
- Luck as secondary stat helps all rooms
- Outfit bonuses count toward room production
- One maxed dweller > multiple low-stat dwellers (averages matter for rush)
- Happiness bonus (+10% max) also shortens cycles

**Assignment Priority Order:**
1. Production rooms (power > water > food)
2. Medical rooms (Stimpak/RadAway supply)
3. Training rooms (only need dwellers training)
4. Radio Studio (if actively recruiting)
5. Vault Door (only during active raids)

### Room Destruction & Removal

Rooms can be destroyed to reorganize vault layout, but there are important restrictions.

**Destruction Requirements:**
- Room must be **completely empty** (no dwellers assigned)
- Room must be **unpowered** or willing to lose power connection
- Cannot destroy rooms that would **isolate** other rooms

**Destruction Process:**
1. Remove all dwellers from room
2. Tap/select room and choose "Destroy"
3. Confirm destruction
4. Room is removed, space becomes dirt

**Caps Refund:**
- **NO refund** - all caps spent on building/upgrading are lost
- Destruction is permanent and cannot be undone

**Destruction Restrictions:**

| Room Type | Can Destroy? | Notes |
|-----------|--------------|-------|
| Regular rooms | Yes | Must be empty |
| Vault Door | **No** | Built-in, cannot be removed |
| Elevators | Yes | Must not isolate rooms below |
| Merged rooms | Yes | Entire merged unit destroyed together |

**Isolation Rule:**
A room cannot be destroyed if it would leave other rooms inaccessible. The vault must remain fully connected via elevators and adjacent rooms.

```
Example (Cannot destroy E2):
    [Room A]
       |
      [E1]
       |
    [Room B] - [E2] - [Room C]

Destroying E2 would isolate Room C
```

**Downgrade (Alternative to Destruction):**
- Rooms CANNOT be downgraded (L3 → L2 → L1)
- Only option is full destruction and rebuild
- Plan upgrades carefully before committing

**Room Relocation Tips:**
1. Unassign all dwellers first
2. Collect any pending resources
3. Consider power grid impact before destroying
4. Rebuild in new location (full cost again)

**Merged Room Destruction:**
- Destroying any part destroys the ENTIRE merged room
- A Triple room destruction loses all 3 sections
- Cannot "split" merged rooms after creation

### Telegram Vault Display Example

```
🛡️|⚡⚡⚡|📦
🚪|🍲🍲 |💧💧
```

---

## Dweller Mechanics

### Dweller Name Generation

Random dwellers receive procedurally generated names from predefined pools.

**Name Structure:** `[First Name] [Last Name]`

**First Name Pools (50+ each):**

| Gender | Example Names |
|--------|---------------|
| Male | Adam, Brian, Carl, David, Edward, Frank, George, Henry, Ivan, Jack, Kevin, Larry, Mike, Nick, Oscar, Paul, Quinn, Roger, Steve, Tom, Victor, Walter, Xavier, Zach |
| Female | Alice, Betty, Carol, Diana, Emma, Fiona, Grace, Helen, Iris, Julia, Karen, Laura, Mary, Nancy, Olivia, Patricia, Rachel, Sarah, Tina, Uma, Victoria, Wendy, Zoe |

**Last Name Pool (100+):**
| Examples |
|----------|
| Adams, Baker, Clark, Davis, Edwards, Fisher, Garcia, Harris, Jackson, King, Lee, Miller, Nelson, O'Brien, Parker, Quinn, Roberts, Smith, Taylor, Walker, Young, Zhang |

**Legendary Dweller Names:**
Legendary dwellers have fixed canonical names from Fallout lore:
- **Fallout 3:** Three Dog, Sarah Lyons, Butch DeLoria, Moira Brown
- **Fallout 4:** Preston Garvey, Piper Wright, Nick Valentine, Paladin Danse
- **Fallout 76:** Various Vault 76 residents
- **TV Series:** Lucy MacLean, Maximus, The Ghoul

**Child Naming:**
- Children can be renamed by player at birth
- Default: Random from name pools
- Last name: Inherits from one parent (random)

**Renaming Rules:**
- Any dweller can be renamed at any time
- No profanity filter in original (Vaultown may add)
- Name length limit: ~20 characters

### Leveling and HP System

- **Maximum level:** 50
- **Base starting HP:** 105 (all dwellers)

**HP Gain Formula (CRITICAL):**
```
HP per level = 2.5 + (Endurance × 0.5)
```

| Endurance at Level-Up | HP/Level | Total HP at Level 50 |
|----------------------|----------|---------------------|
| 1 (minimum) | 3.0 | 252 HP |
| 5 | 5.0 | 350 HP |
| 10 (trained max) | 7.5 | 472.5 HP |
| 17 (with +7 outfit) | 11.0 | **644 HP** (maximum) |

**HP is NOT retroactive.** Optimal strategy: Train E to 10, equip Heavy Wasteland Gear (+7E), then level from 1→50.

### Dweller XP Sources

Dwellers gain experience toward levels through various activities:

| Activity | XP Rate | Notes |
|----------|---------|-------|
| Working in rooms | Very Slow | Minimal XP from production |
| Successful Rush | Moderate | All dwellers in room gain XP |
| Vault Combat | Moderate | Fighting incidents |
| Wasteland Exploration | Good | Combat encounters give XP |
| Quest Combat | Best | Highest XP per encounter |

**Important Notes:**
- NO SPECIAL stat affects XP gain rate
- Only **Experience pets** increase XP earned
- Only **Training Time pets** reduce SPECIAL training time
- Intelligence does NOT affect level-up XP (only Stimpak/RadAway efficiency)

### Happiness System

| State | Equilibrium |
|-------|-------------|
| Wrong room | 50% |
| Right room (matching SPECIAL) | 75% |
| Maximum | 100% |

**Production Bonus:**

Production efficiency scales with happiness from 0% to +10%:
- 50% happiness → +5% production
- 75% happiness → +7.5% production
- 100% happiness → **+10% production**

This bonus shortens production cycle time and training time.

**Modifiers:**
- Successful rush: +10%
- Failed rush: -10%
- Breeding: Both partners → 100%
- Radio room: +0.5-1% vault-wide
- Dead dweller in room: Major decrease

### Death and Revival

**Revival Cost Formula:**
```
Cost = 100 + (Level - 1) × 20 caps
```

| Level | Cost |
|-------|------|
| 1 | 100 caps |
| 25 | 580 caps |
| 50 | 1,080 caps |

- Time limit: 24 hours to revive in vault
- After 24 hours: Body and ALL equipped items lost permanently

### Dweller Removal (Eviction)

Unwanted dwellers can be permanently removed from the vault.

**How to Evict:**
1. Select the dweller
2. Drag them to the wasteland (outside vault door)
3. Confirm eviction

**Eviction Rules:**
- Evicted dwellers are **permanently deleted**
- Cannot be recovered or recalled
- Equipment is returned to vault storage (not lost)
- No caps refund for training or leveling investment

**When to Evict:**
- Population at 200 cap, need room for better dwellers
- Low-SPECIAL dwellers with no useful traits
- Duplicate legendary dwellers (keeping best-equipped)
- Freeing Living Quarters space

**Cannot Evict:**
- Dwellers currently exploring (recall first)
- Dwellers on quests (wait for return)
- Pregnant dwellers (wait for birth)
- Children (wait until adult)

**Alternative to Eviction:**
- Let unwanted dwellers die and don't revive (24hr timer)
- Same result but keeps equipment equipped

### Special Dwellers

**Rare Dwellers:**
- Total SPECIAL points: 28
- Can appear at vault door (very rare)
- Found in lunchboxes
- Have randomized appearances and names

**Legendary Dwellers:**
- Total SPECIAL points: 40
- Total count: 32 unique characters (duplicates possible)
- Come equipped with legendary outfit and rare weapon
- Named after Fallout 3, Fallout 4, Fallout 76, and TV series characters

**Obtaining Legendary Dwellers:**
1. **Lunchboxes** - Random chance (~1 in 20-40 lunchboxes)
2. **Quest Rewards** - Specific quests reward legendary dwellers:
   - Sarah Lyons (In Shining Armor quest chain)
   - Three Dog (Run, Three Dog, Run! quest)
   - Preston Garvey (A Settler Needs Your Help quest)
   - Piper (late-game quest)

### Mysterious Stranger

A special visitor who randomly appears in vault rooms:

**Mechanics:**
- Appears briefly (few seconds) in random occupied rooms
- Mobile devices vibrate when he appears
- Tap/click to collect caps before he disappears
- Zooming out to 2D view makes spotting easier

**Rewards:**
- Gives 100-5,000+ caps per appearance (random)
- Average reward scales with vault size/progression
- No limit on daily appearances

**Pet Bonuses:**
- Certain pets increase Mysterious Stranger spawn chance
- Maximum bonus: **+7.5× spawn rate**
- Stacks multiplicatively with base chance

---

## Equipment System

### Equipment Slots

Each dweller has three equipment slots:
1. **Outfit** (Clothing/Armor) - Stat bonuses
2. **Weapon** - Combat damage
3. **Pet** - Passive bonuses

### Complete Weapon List

**Common Weapons (0-7 damage):**
| Weapon | Damage | Type |
|--------|--------|------|
| Rusty BB Gun | 0-1 | Pistol |
| BB Gun | 0-2 | Pistol |
| Rusty .32 Pistol | 1-2 | Pistol |
| .32 Pistol | 2-3 | Pistol |
| Rusty Laser Pistol | 2-3 | Energy |
| Laser Pistol | 3-4 | Energy |
| Rusty 10mm Pistol | 3-4 | Pistol |
| 10mm Pistol | 4-5 | Pistol |
| Rusty Hunting Rifle | 4-5 | Rifle |
| Hunting Rifle | 5-6 | Rifle |
| Rusty Sawed-Off Shotgun | 5-6 | Shotgun |
| Sawed-Off Shotgun | 6-7 | Shotgun |

**Rare Weapons (7-18 damage):**
| Weapon | Damage | Type |
|--------|--------|------|
| Enhanced .32 Pistol | 7-8 | Pistol |
| Enhanced Laser Pistol | 8-9 | Energy |
| Enhanced 10mm Pistol | 9-10 | Pistol |
| Enhanced Hunting Rifle | 10-11 | Rifle |
| Plasma Pistol | 10-11 | Energy |
| Enhanced Sawed-Off Shotgun | 11-12 | Shotgun |
| Enhanced Plasma Pistol | 11-12 | Energy |
| Laser Rifle | 12-13 | Energy |
| Combat Shotgun | 13-14 | Shotgun |
| Assault Rifle | 13-14 | Rifle |
| Enhanced Laser Rifle | 14-15 | Energy |
| Minigun | 14-15 | Heavy |
| Flamer | 15-17 | Heavy |
| Gatling Laser | 16-17 | Energy |
| Plasma Rifle | 17-18 | Energy |

**Legendary Weapons (3-31 damage):**
| Weapon | Damage | Avg | Type | Notes |
|--------|--------|-----|------|-------|
| Blackhawk | 3-8 | 5.5 | Pistol | Low tier legendary |
| Wild Bill's Sidearm | 5-11 | 8 | Pistol | |
| Ol' Painless | 8-13 | 10.5 | Rifle | |
| Lincoln's Repeater | 10-15 | 12.5 | Rifle | |
| Miss Launcher | 13-18 | 15.5 | Heavy | AOE |
| Burnmaster | 14-19 | 16.5 | Heavy | |
| Virgil's Rifle | 15-21 | 18 | Energy | |
| Destabilizer | 17-22 | 19.5 | Energy | |
| Wazer Wifle | 17-22 | 19.5 | Energy | |
| Mean Green Monster | 17-23 | 20 | Heavy | |
| Lead Belcher | 18-25 | 21.5 | Heavy | Multi-shot |
| Technician's Revenge | 19-24 | 21.5 | Energy | |
| Hardened Fatman | 19-24 | 21.5 | Heavy | AOE |
| Fire Hydrant Bat | 19-31 | 25 | Melee | Highest variance |
| Relentless Raider Sword | 19-25 | 22 | Melee | |
| Vengeance | 21-26 | 23.5 | Heavy | **Best multi-shot** |
| MIRV | 22-27 | 24.5 | Heavy | **Best AOE** |
| Plasma Thrower | 21-27 | 24 | Energy | |
| **Dragon's Maw** | 22-29 | **25.5** | Heavy | **Best overall** |

**Weapon Behaviors:**
- **Single-shot** (Dragon's Maw): Hits one target, overkill damage wasted
- **Multi-shot/Burst** (Vengeance, Lead Belcher): Excess damage transfers to next target
- **AOE** (MIRV, Miss Launcher, Fatman): Damage split among ALL enemies

**Recommended Loadouts:**
- **Vault Defense:** Dragon's Maw (highest consistent damage)
- **Wasteland Exploration:** Vengeance (burst carry-over maximizes efficiency)
- **Quest Teams:** Mix of Vengeance + MIRV for versatility

### Complete Outfit List

**Outfit Rarity Bonuses:**
| Rarity | Total SPECIAL | Examples |
|--------|---------------|----------|
| Common | +3 | Single stat or split |
| Rare | +5 | Single stat or split |
| Legendary | +7 | Single stat or split |
| Quest-Exclusive | +16 | Horsemen armors only |

**Legendary Outfits by Primary Stat:**

| Outfit | S | P | E | C | I | A | L | Total | Best Use |
|--------|---|---|---|---|---|---|---|-------|----------|
| **Strength (+7S):** |
| Commander Fatigues | 7 | - | - | - | - | - | - | 7 | Power rooms |
| Heavy Vault Suit | 6 | - | - | - | - | 1 | - | 7 | Power + minor A |
| **Perception (+7P):** |
| Expert Jumpsuit | - | 7 | - | - | - | - | - | 7 | Water rooms |
| Detective Outfit | - | 4 | - | - | 3 | - | - | 7 | Water + crafting |
| **Endurance (+7E):** |
| Heavy Wasteland Gear | - | - | 7 | - | - | - | - | 7 | **HP optimization** |
| Wasteland Surgeon | - | - | 4 | - | 3 | - | - | 7 | E + medical |
| **Charisma (+7C):** |
| Eulogy Jones' Suit | - | - | - | 7 | - | - | - | 7 | Radio/breeding |
| Comedian | - | - | - | 5 | - | 2 | - | 7 | Charisma + A |
| **Intelligence (+7I):** |
| Expert Lab Coat | - | - | - | - | 7 | - | - | 7 | Medical/crafting |
| Professor Outfit | - | - | - | - | 5 | 2 | - | 7 | Int + A |
| **Agility (+7A):** |
| Ninja Outfit | - | - | - | - | - | 7 | - | 7 | Food rooms |
| Minuteman Uniform | - | 3 | - | - | - | 4 | - | 7 | A + P |
| **Luck (+7L):** |
| Lucky Formal Wear | - | - | - | - | - | - | 7 | 7 | Caps/rush |
| Piper's Outfit | - | 1 | - | - | - | - | 6 | 7 | Luck + P |

**Quest-Exclusive Outfits (Horsemen):**
| Outfit | S | P | E | C | I | A | L | Total |
|--------|---|---|---|---|---|---|---|-------|
| War's Armor | 4 | - | 4 | - | - | 4 | 4 | 16 |
| Famine's Vestment | - | 4 | - | 4 | 4 | - | 4 | 16 |
| Pestilence's Plating | 4 | 4 | - | - | 4 | 4 | - | 16 |
| Death's Jacket | - | 4 | 4 | 4 | - | - | 4 | 16 |

**Key Outfit Strategy:**
- **HP Optimization:** Heavy Wasteland Gear (+7E) during leveling
- **Production:** Match outfit to room's primary stat
- **Exploration:** E11+ total for radiation immunity
- **Quests:** Horsemen armors for balanced stats

### Pet System

Pets provide passive bonuses. Only one bonus type stacks per vault.

**Pet Types:**

| Type | Species Examples |
|------|------------------|
| **Dogs** | German Shepherd, Husky, Rottweiler, Boxer, Collie |
| **Cats** | Tabby, Siamese, Calico, Black Cat, Maine Coon |
| **Parrots** | Macaw, Cockatoo, Parakeet |
| **Exotic** | Deathclaw (legendary only), Radroach, Mole Rat |

**Pet Rarity:**

| Rarity | Bonus Strength | Obtain From |
|--------|---------------|-------------|
| **Common** | Weakest bonuses | Pet Carriers, Objectives |
| **Rare** | Moderate bonuses | Pet Carriers, Objectives |
| **Legendary** | Maximum bonuses | Pet Carriers (rare), Special Events |

**Bonus Categories by Rarity:**

| Bonus Type | Common | Rare | Legendary |
|------------|--------|------|-----------|
| Damage | +1 | +3 | +6 |
| HP | +1 | +3 | +6 |
| Wasteland Junk | +10% | +50% | +100% |
| Wasteland Caps | +10% | +50% | +100% |
| Return Speed | ×1.25 | ×2 | ×4 |
| Crafting Time | -6% | -24% | -45% |
| Objective Completion | ×1.5 | ×2 | ×3 |
| Child SPECIALs | +1 | +2 | +3 |
| XP Bonus | +10% | +30% | +50% |
| Training Speed | -10% | -30% | -50% |
| Mysterious Stranger | +1× | +4× | +7.5× |

**Top-tier Bonuses (Legendary):**
| Bonus Type | Max Value | Best Use |
|------------|-----------|----------|
| Objective Completion | ×3 multiplier | Lunchbox farming |
| Child SPECIALs | +3 to all newborn stats | Breeding optimization |
| Wasteland Junk | +100% | Crafting materials |
| Return Speed | ×4 | Fast explorer rotation |
| Damage | +6 | Combat (quests/incidents) |
| Crafting Time | -45% | Legendary item production |
| Mysterious Stranger | +7.5× spawn | Caps farming |

**Pet Rules:**
- Pets cannot die - always return safely
- If dweller dies exploring, pet returns with all collected loot
- One pet per dweller (1 weapon, 1 outfit, 1 pet)
- Maximum 100 pets equipped vault-wide
- Unequipped pets stored in inventory (no cap)
- Pets can be sold for caps

### Inventory Limits

- Dweller equipment: 1 weapon, 1 outfit, 1 pet
- Explorer carry limit: 100 items
- Base vault storage: 10 items
- Maximum caps: 1,000,000
- Pet equip limit: 100 across all dwellers

### Inventory Management

**Storage Capacity:**

| Storage Room Level | Single | Double | Triple |
|-------------------|--------|--------|--------|
| Level 1 | 10 | 20 | 30 |
| Level 2 | 15 | 35 | 55 |
| Level 3 | 25 | 60 | **125** |

Maximum with multiple Triple L3 Storage Rooms: Unlimited (practical limit ~500-1000 items)

**Item Types in Storage:**
- Weapons (equipped and unequipped)
- Outfits (equipped and unequipped)
- Junk (crafting materials)
- Pets (unequipped only)
- Stimpaks and RadAway (in production storage, not vault storage)

**Selling Items:**

All items can be sold for caps:

| Item Rarity | Sell Price Range |
|-------------|------------------|
| Common | 10-50 caps |
| Rare | 50-250 caps |
| Legendary | 250-500 caps |
| Junk (Common) | 1-5 caps |
| Junk (Rare) | 10-25 caps |
| Junk (Legendary) | 50-100 caps |

**Scrapping vs Selling:**
- Junk cannot be scrapped further
- Weapons/Outfits: Sell only (no disassembly)
- Excess duplicates should be sold

**Storage Overflow:**
- Cannot collect items if storage full
- Explorers auto-return at 100 items (not storage limit)
- Lunchbox items go directly to storage (fails if full)
- Build Storage Rooms before heavy exploration

**Inventory Tips:**
1. Keep 1-2 of each legendary weapon/outfit
2. Sell common/rare duplicates immediately
3. Hoard junk until crafting unlocked
4. Don't over-build Storage - caps better spent elsewhere

### Crafting SPECIAL Requirements

Different weapons and outfits require different SPECIAL stats for crafting:

| SPECIAL | Weapons Craftable | Outfits |
|---------|-------------------|---------|
| Strength | 46 weapons | - |
| Perception | 55 weapons | - |
| Intelligence | 13 weapons | 18 outfits |
| Agility | - | Remaining outfits |

Higher stat values reduce crafting time. Crafting requires:
- Weapon Workshop (L2 for rare, L3 for legendary)
- Outfit Workshop (L2 for rare, L3 for legendary)
- Junk components from exploration

### Crafting Times

Base crafting times vary by item rarity. SPECIAL stats and pets reduce these times.

**Base Crafting Times:**

| Rarity | Weapon | Outfit |
|--------|--------|--------|
| Common | 35 seconds | 32 seconds |
| Rare | 3-12 hours | 2-10 hours |
| Legendary | 1-3 days | 18-48 hours |

**Time Reduction Formula:**
```
Actual Time = Base_Time / (1 + Relevant_SPECIAL / 10) × Pet_Multiplier
```

**Crafting Time Pets:**
| Rarity | Time Reduction |
|--------|----------------|
| Common | -6% |
| Rare | -24% |
| Legendary | -45% |

**Example (Legendary Weapon):**
- Base time: 2 days (48 hours)
- With S17 crafter: 48 / 2.7 = ~18 hours
- With legendary pet (-45%): ~10 hours

**Tips:**
- Assign highest relevant SPECIAL dweller to workshops
- Legendary crafting pet is one of the best investments
- Queue multiple items overnight

### Junk Items & Recipes

**Junk Overview:**
- **139 unique junk items** in the game
- Each has rarity: Common, Rare, or Legendary
- Found during wasteland exploration and quests
- Required for all crafting recipes

**Complete Junk List by Category:**

| Category | Common | Rare | Legendary |
|----------|--------|------|-----------|
| **Adhesives** | Duct Tape, Wonderglue | Military Duct Tape | Sealed Wonderglue |
| **Chemicals** | Acid, Antiseptic | Industrial Solvent | Military-Grade Acid |
| **Cloth** | Pre-War Cotton, Yarn | Pre-War Silk | Pre-War Cashmere |
| **Electronics** | Camera, Desk Fan | Microscope, Sensor | Globe, Military Circuit |
| **Glass** | Flask, Glass Bottle | Laboratory Flask | Beaker Set |
| **Leather** | Leather Belt | Leather Jacket | Military Leather |
| **Metal** | Scrap Metal, Tin Can | Steel, Aluminum | Titanium, Gold, Silver |
| **Mechanical** | Gears, Springs, Screws | Ball Bearings | Military Gears |
| **Plastic** | Plastic Spoon | Hard Plastic | Military-Grade Plastic |
| **Wood** | Pencil, Plunger | Wood Block | Yardstick |

**Recipe Requirements by Rarity:**

| Item Rarity | Junk Required | Example Recipe |
|-------------|---------------|----------------|
| Common | 1-3 common junk | .32 Pistol: 2× Scrap Metal |
| Rare | 3-6 common + 1-2 rare | Plasma Rifle: 4× Circuit, 2× Microscope |
| Legendary | 5-10 mixed + 2-4 legendary | Dragon's Maw: 8× Steel, 3× Globe, 2× Military Circuit |

**Sample Legendary Weapon Recipes:**

| Weapon | Junk Required |
|--------|---------------|
| Dragon's Maw | 8× Steel, 4× Gears, 3× Globe, 2× Military Circuit Board |
| Vengeance | 6× Steel, 4× Springs, 3× Microscope, 2× Military Duct Tape |
| MIRV | 10× Scrap Metal, 4× Sensor, 2× Globe, 3× Military-Grade Acid |
| Fire Hydrant Bat | 4× Steel, 3× Screws, 2× Industrial Solvent |

**Sample Legendary Outfit Recipes:**

| Outfit | Junk Required |
|--------|---------------|
| Heavy Wasteland Gear | 6× Leather, 4× Cloth, 2× Military Leather, 2× Pre-War Cashmere |
| Expert Lab Coat | 5× Pre-War Cotton, 3× Pre-War Silk, 2× Laboratory Flask |
| Lucky Formal Wear | 4× Pre-War Silk, 3× Gold, 2× Pre-War Cashmere |

**Recipe Discovery:**
- Recipes drop randomly during exploration
- Legendary recipes more common after **60+ hours** of exploration
- Each recipe specifies exact junk requirements
- Recipes are permanent once discovered
- ~175 total recipes (weapons + outfits + themes)

**Junk Management:**
- Cannot be scrapped further (junk is base component)
- Wasteland Junk pets increase junk find rate (+100% max)
- Explorer hits 100-item limit including junk
- Prioritize keeping legendary junk, sell common duplicates

---

## Incidents & Threats

### Population Thresholds

| Incident | Population Required |
|----------|---------------------|
| Fires | 2+ |
| Radroaches | 9+ |
| Raiders | 14+ |
| Mole Rats | 31+ |
| Feral Ghouls | 41+ |
| Radscorpions | 51+ |
| **Deathclaws** | **61+** |

### Incident Behaviors

| Incident | Behavior |
|----------|----------|
| **Fires** | Spread to adjacent empty rooms. Number of dwellers matters, not weapons. |
| **Radroaches/Mole Rats** | Spread to adjacent empty rooms. Strength scales with room level. |
| **Mole Rats** | Only spawn in rooms touching dirt (vault edges). |
| **Radscorpions** | Teleport to random rooms. Deal radiation damage. |
| **Deathclaws** | Tear through vault door instantly. Smash through elevators. |

### Incident Types Detailed

**Fires:**
- Triggered by: Rush failure, random event
- Damage: Low HP damage over time
- Combat: Dweller count matters, weapons don't
- Spread: To adjacent empty rooms horizontally
- Counter: Fill all rooms with at least 1 dweller

**Radroaches:**
- Triggered by: Rush failure, random event, dead dweller in room
- Damage: Low HP damage per attack
- Combat: Weapon damage matters
- Spread: To adjacent empty rooms
- Counter: Good weapons on all dwellers

**Raiders:**
- Triggered by: Opening vault door (chance-based)
- Damage: Moderate HP damage, steal caps
- Combat: Fight at vault door first, then proceed through vault
- Spread: Move room-to-room until killed
- Counter: Best weapons at vault door and first rooms

**Mole Rats:**
- Triggered by: Rush failure, random (only dirt-adjacent rooms)
- Damage: Low-moderate HP damage
- Combat: Weapon damage matters
- Spread: To adjacent rooms touching dirt
- Counter: Build rooms away from vault edges

**Feral Ghouls:**
- Triggered by: Rush failure, quests
- Damage: Moderate HP + minor radiation damage
- Combat: Standard weapon combat
- Spread: To adjacent empty rooms
- Counter: RadAway ready for affected dwellers

**Radscorpions:**
- Triggered by: Rush failure, random (51+ pop)
- Damage: Heavy HP + heavy radiation damage
- Combat: Teleport to random rooms when damaged
- Spread: Teleportation, unpredictable
- Counter: High-damage weapons in ALL rooms, RadAway stock

**Deathclaws:**
- Triggered by: Opening vault door, Radio broadcasts (61+ pop)
- Damage: Highest damage in game (15-30 per hit)
- Combat: Ignore doors/elevators, tear through vault
- Spread: Move systematically through entire vault
- Counter: Max HP dwellers, best weapons in every room

### Rush Failure Incidents

Failed rush attempts trigger incidents based on current population:

| Population | Possible Incident |
|------------|-------------------|
| 2-8 | Fire only |
| 9-13 | Fire, Radroaches |
| 14-30 | Fire, Radroaches, Raiders (if near door) |
| 31-40 | Fire, Radroaches, Mole Rats |
| 41-50 | Fire, Radroaches, Mole Rats, Feral Ghouls |
| 51-60 | Fire, Radroaches, Mole Rats, Ghouls, Radscorpions |
| 61+ | All incident types possible |

**Rush Failure Tips:**
- Lower population = safer rushing
- Never rush with >60 population unless prepared for Deathclaws
- Keep fail chance below 40% for acceptable risk

### Deathclaw Trigger Formula

```
Hidden value starts at 0
Each door open: +0.05
Radio room call: +0.07 to +0.20 (based on room size/level)
After each action: if random(0-1) < hidden_value → Deathclaw attack
Cap: 0.8 (80% maximum chance)
```

### Combat Damage Formula

Combat in Fallout Shelter uses simplified damage calculations. Different contexts (vault vs quest) have different rules.

**Vault Incident Combat:**

Vault combat ignores most stats. Only these factors matter:

```
Damage Dealt = random(Weapon_Min, Weapon_Max) + Pet_Damage_Bonus
```

| Factor | Effect |
|--------|--------|
| Weapon Damage | Full range used (e.g., 22-29 for Dragon's Maw) |
| Pet Damage Bonus | Added directly (+6 max for legendary) |
| SPECIAL Stats | **NO EFFECT** on vault combat damage |
| Outfit | **NO EFFECT** on vault combat damage |

**Vault Defense DPS Calculation:**
```
Average DPS = (Weapon_Min + Weapon_Max) / 2 × Attack_Speed
```

**Quest Combat (Different!):**

Quest combat uses more factors:

```
Base Damage = random(Weapon_Min, Weapon_Max) + Pet_Damage_Bonus
Attack Speed modifier = Agility / 10
Critical Multiplier = up to 5× (timing-based)
```

| SPECIAL | Quest Combat Effect |
|---------|---------------------|
| Agility | Increases attack frequency |
| Luck | Fills critical meter faster |
| Perception | Slows critical timing arrow (easier perfect hits) |
| Endurance | HP pool (indirect survivability) |
| S/C/I | No direct combat effect |

**Critical Hit Damage:**
```
Critical Damage = Base_Damage × Crit_Multiplier
Crit_Multiplier ranges from 1× (miss) to 5× (perfect center)
```

**Enemy Damage (Incidents):**

Enemies deal damage based on their type and room difficulty:

| Enemy Type | Damage Range | Special |
|------------|--------------|---------|
| Radroach | 2-4 | Scales with room level |
| Mole Rat | 4-8 | Spawns at dirt-adjacent rooms |
| Feral Ghoul | 8-12 | Radiation damage |
| Raider | 6-15 | Varies by raider type |
| Radscorpion | 10-18 | Heavy radiation damage |
| **Deathclaw** | **15-30** | Highest damage, ignores doors |

**Damage Mitigation:**
- NO armor system - outfits provide stat bonuses only
- HP is the only defense
- Stimpaks heal during combat (manual or auto)

### Incident Difficulty Scaling

Incident strength scales based on multiple factors:

```
Difficulty = Average_Dweller_Level + Room_Level + Room_Width_Bonus
```

| Factor | Effect |
|--------|--------|
| Average Dweller Level | Higher level vault = stronger incidents everywhere |
| Room Level (L1/L2/L3) | Higher level rooms spawn stronger enemies |
| Room Width | Triple rooms have hardest incidents |
| Empty Rooms | Incidents spread to adjacent empty rooms |

**Strategy Tips:**
- Keep early rooms at L1 to reduce incident difficulty
- Always have dwellers in rooms to prevent spreading
- Equip best weapons on dwellers in high-traffic rooms (near vault door)
- Prioritize training Endurance before leveling any dweller

### Vault Door Defense System

The Vault Door is the first line of defense against raiders and Deathclaws.

**Vault Door Levels:**

| Level | Upgrade Cost | Defense Time (Raiders) | Defense Time (Deathclaws) |
|-------|-------------|------------------------|---------------------------|
| L1 | Built-in | ~10 seconds | Instant breach |
| L2 | 750 caps | ~20 seconds | Instant breach |
| L3 | 2,500 caps | ~30 seconds | Instant breach |

**How Door Defense Works:**
- Raiders must break through door before entering vault
- Door has invisible HP that scales with level
- Dwellers stationed at door fight attackers WHILE door is being breached
- Once breached, attackers enter first room

**Staffing the Vault Door:**
- Assign up to 2 dwellers to defend
- **Only weapon damage matters** (SPECIAL irrelevant for combat)
- Best weapons = best door defense
- Dwellers take damage during defense

**Deathclaw Exception:**
- Deathclaws **ignore** vault door level completely
- Breach is instantaneous regardless of upgrade
- Deathclaws smash through doors AND elevators
- Only way to slow them: kill them in rooms

**Defense Strategy:**
| Threat | Best Response |
|--------|---------------|
| Raiders | High-damage weapons at door, L3 door delays them |
| Deathclaws | Ignore door level, stack damage in first rooms |
| Mixed | Prioritize first 2-3 rooms over door upgrades |

**Door Combat Notes:**
- Door defenders gain XP from combat
- If defenders die, door continues taking damage alone
- Revive defenders quickly to resume fighting

### Vaultown Additions

- **Mr. Handy Robots**: Premium robots (1 per floor) that auto-collect resources and help during emergencies
- **Repair cost**: 2,000 caps when destroyed

---

## Exploration & Quests

### Wasteland Exploration (Automatic)

Send any dweller to explore automatically:
- **60 minutes**: Guaranteed loot event (best for weapons/outfits)
- **~160 minutes**: Repeatable junk events
- **2.5+ days**: Legendary junk/recipes more common
- **~4 days**: Typically hits 100-item limit

**Maximum explorers:** 25 dwellers + 5 Mr. Handy simultaneously

**SPECIAL Effects:**
- Luck: Caps quantity, loot quality
- Endurance 11+: **Complete radiation immunity**
- Perception: Finds quest locations
- Charisma: Friendly NPC encounters

### Exploration Event Categories

Explorers encounter random events in the wasteland:

| Event Type | Outcome | SPECIAL Influence |
|------------|---------|-------------------|
| **Combat** | Fight enemies, gain XP/loot | Weapon damage, E for HP |
| **Loot Discovery** | Find weapons, outfits, caps | Luck increases quality |
| **Junk Scavenging** | Collect crafting materials | Luck, Junk pets |
| **Location Found** | Discover quest locations | Perception |
| **NPC Encounter** | Dialogue, trade, or combat | Charisma for peaceful options |
| **Radiation Zone** | Take radiation damage | E11+ = immune |
| **Recipe Drop** | Learn crafting recipe | Time-based (60+ hours for legendary) |

**Event Timing:**
- First 60 minutes: Guaranteed quality loot event
- After 60 min: Random events every ~30-60 minutes
- Longer trips = more total events but diminishing item quality gains

### Wasteland Exploration Log

Explorers generate a text log of their journey. Each entry has a timestamp and description.

**Log Entry Format:**
```
[Time elapsed] - [Event description]
```

**Sample Exploration Log:**
```
0:05 - Sarah left the vault in search of adventure... and loot.
0:15 - Sarah encountered a radroach. Killed it with ease.
0:30 - Found a first aid kit. +2 Stimpaks
0:45 - Discovered an abandoned shack. Found 15 caps.
1:00 - Combat! Raiders attacked. Sarah fought bravely.
1:00 - Defeated raiders. Found Hunting Rifle (5-6 damage).
1:30 - Sarah is feeling parched. Used RadAway.
2:00 - Stumbled upon a friendly trader. Bought supplies.
2:15 - Found a locked safe. Luck check passed! +85 caps.
3:00 - Combat! Feral ghouls emerged from the shadows.
3:00 - Victory! Found Leather Armor (+1 E).
4:00 - Radiation storm! Seeking shelter...
```

**Log Entry Types:**

| Type | Example Text | Trigger |
|------|--------------|---------|
| **Departure** | "[Name] left the vault in search of..." | Start exploration |
| **Combat Start** | "Combat! [Enemy] attacked." | Enemy encounter |
| **Combat Victory** | "Defeated [enemy]. Found [loot]." | Win fight |
| **Loot Found** | "Found [item] in [location]." | Loot event |
| **Caps Found** | "Discovered [X] caps." | Caps event |
| **Location** | "Discovered [location name]." | Quest location found |
| **Stimpak Use** | "[Name] is hurting. Used Stimpak." | HP < 50% |
| **RadAway Use** | "[Name] is feeling sick. Used RadAway." | Radiation > 50% |
| **Level Up** | "[Name] leveled up! Now level [X]." | XP threshold |
| **Item Limit** | "Can't carry any more. Heading home." | 100 items |
| **Death** | "[Name] has died in the wasteland." | HP = 0, no Stimpaks |

**Telegram Implementation:**
- Log entries sent as messages or compiled summary
- Option: Real-time updates vs. batch summary on return
- Include emoji for visual clarity (⚔️ combat, 💊 heal, 💀 death)

### Wasteland Return & Death

**Return Mechanics:**
- Recall time = **50% of time spent exploring**
- Example: 10 hours out → 5 hours return
- Return speed pets can reduce this by up to **4×**
- Nuka-Cola Quantum can instant-return explorers

**Return Speed Calculation:**
```
Return Time = Exploration Time × 0.5 / Pet_Speed_Multiplier
```

| Pet Bonus | 10hr Exploration Return |
|-----------|-------------------------|
| No pet | 5 hours |
| ×2 speed | 2.5 hours |
| ×4 speed | 1.25 hours |

**Explorer Death:**
- Occurs when HP reaches 0 and no Stimpaks remain
- Dead explorer stops moving, shows "deceased" status
- All collected loot and caps are KEPT (not lost)
- Pet returns safely with loot

**Revival Options:**
1. **Revive in wasteland**: Pay caps, explorer continues from death point
2. **Recall (dead)**: Return time same as alive, then revive in vault

**Revival Cost (Wasteland):**
```
Cost = 100 + (Level - 1) × 20 caps
```

| Level | Cost |
|-------|------|
| 1 | 100 caps |
| 25 | 580 caps |
| 50 | 1,080 caps |

**Time Limit:**
- **24 hours** to revive dead dwellers (vault or wasteland)
- After 24 hours: Body removed, ALL equipped items lost permanently
- Loot collected before death is transferred to vault storage

**Exploration Auto-Return:**
- Explorers auto-return when hitting 100 item limit
- Mr. Handy auto-returns at 5,000 caps collected

### Explorer Supply Auto-Use

Explorers automatically consume Stimpaks and RadAway based on thresholds.

**Stimpak Auto-Use:**
```
Trigger: HP drops below 50%
Action: Use 1 Stimpak (heals ~40-50% HP)
Repeat: Until HP > 50% or supplies exhausted
```

**RadAway Auto-Use:**
```
Trigger: Radiation exceeds 50% of max HP
Action: Use 1 RadAway (removes ~25-30% radiation)
Repeat: Until radiation < 50% or supplies exhausted
```

**Supply Carry Limits:**

| Item | Max Carried | Recommended |
|------|-------------|-------------|
| Stimpaks | 25 | 15-25 for long trips |
| RadAway | 25 | 5-10 (E11+ needs 0) |

**Optimal Loadout by Build:**

| Explorer Type | Stimpaks | RadAway | Notes |
|---------------|----------|---------|-------|
| E11+ (radiation immune) | 25 | 0 | Max Stimpaks, no radiation |
| E10 or below | 20 | 5 | Balance healing and rad removal |
| Short trip (1-2 hours) | 5-10 | 2-3 | Return before supplies matter |
| Legendary farming (4+ days) | 25 | 10 | Bring maximum |

**Death Scenario:**
- HP reaches 0 AND no Stimpaks remaining = Death
- Explorer stops, must be revived or recalled
- Always send enough supplies for expected trip length

**Supply Efficiency:**
- Higher Endurance = fewer Stimpaks needed
- E11+ = zero RadAway needed
- High HP pool (E17 leveling) = survive longer between heals

### Interactive Exploration (Vaultown Feature)

When the player's own character explores:
- Semi-automatic with player influence
- World grid with directional movement (⬆️ ⬇️ ↗️ etc.)
- Interactive choices during encounters

### Quest System

Requires Overseer's Office:
- Form party of up to 3 dwellers
- Navigate quest locations with commands
- Turn-based combat with action choices

**Overseer's Office Quest Slots:**

| Office Level | Concurrent Quests | Unlock Pop |
|--------------|-------------------|------------|
| L1 | 1 quest | 18 |
| L2 | 2 quests | 30 |
| L3 | 3 quests | 55 |

Quest slots allow running multiple quests simultaneously with different parties.

**Quest Party Composition:**

Optimal 3-dweller party prioritizes damage output and survivability:

| Priority | Stats | Reason |
|----------|-------|--------|
| 1st | High HP (E17 leveled) | Survivability |
| 2nd | Best weapons | Damage output |
| 3rd | High Agility | Attack speed |
| 4th | High Luck | Faster crits |
| 5th | High Perception | Easier crit timing |

**Recommended Loadout:**
- All 3 dwellers: Max HP builds (E17 during leveling)
- Weapons: Dragon's Maw or Vengeance for each
- Pets: Damage bonus (+6 legendary) or HP bonus
- Stimpaks/RadAway: Shared pool, bring 25/10

**Party Synergy Tips:**
- Homogeneous parties (all similar) work best
- No "tank/healer/DPS" roles - everyone fights equally
- Spread damage pets across party for consistent output
- One objective-completion pet if chasing quest achievements

### Quest Location Discovery

New quest locations are discovered through exploration:

**Discovery Mechanics:**
- **Perception** stat increases discovery chance during exploration
- Higher P = more quest locations found per exploration run
- Some locations are story-locked (require completing prerequisite quests)
- Seasonal/time-limited quests appear automatically

**Quest Types:**
| Type | Description |
|------|-------------|
| **Story Quests** | Main quest chains, unlock features/characters |
| **Daily Quests** | Refresh daily, quick rewards |
| **Weekly Quests** | Longer quests, better rewards |
| **Seasonal Quests** | Time-limited special events |

**Quest Difficulty:**
- Scales with party average level
- Recommended level shown before starting
- Higher difficulty = better loot drops

**Combat Commands:**
- ⚔️ Attack
- ✨ Cast (special abilities)
- 🧪 Item (use consumable)
- 🛡️ Dodge
- 🚪 Flee

### Critical Hit System (Quests)

- Build invisible meter during combat
- Perfect center hit = **5× damage multiplier**
- Crits can be saved across rooms within same quest

**Critical Hit Mechanics:**
- Critical meter fills during combat (Luck affects fill speed)
- Perception slows down the critical timing indicator arrow
- Perfect center hit = maximum 5× damage multiplier
- Partial/off-center hits deal reduced critical damage based on timing accuracy
- Unused critical charges persist between rooms in the same quest
- Critical charges are lost when quest ends or party returns to vault

---

## Population & Breeding

### Dweller Recruitment Methods

All ways to obtain new dwellers:

| Method | Dweller Quality | Notes |
|--------|-----------------|-------|
| **Breeding** | Normal (12 SPECIAL), chance for Rare/Legendary | Primary method, 6 hours total |
| **Radio Studio** | Mostly Normal, rare chance for better | Requires 20 pop, attracts wanderers |
| **Vault Door Wanderers** | Normal, very rare Rare | Random arrivals, tap to accept |
| **Lunchboxes** | Rare or Legendary possible | ~10% chance for dweller card |
| **Quest Rewards** | Specific Legendary characters | Story quests only |

**Breeding** (Fastest early-game):
- 6 hours total (3hr pregnancy + 3hr child growth)
- No cap cost, just Living Quarters space
- Quality depends on parent SPECIAL totals

**Radio Studio** (Passive recruitment):
- Requires 20 population to unlock
- Charisma reduces recruitment cycle time
- Increases Deathclaw risk (61+ pop)

**Vault Door Wanderers** (Random):
- Appear randomly at vault entrance
- Tap to accept or ignore
- Usually low-quality dwellers
- Very rare chance for Rare dwellers

**Lunchboxes** (Best for Legendaries):
- ~5-10% chance to contain a dweller
- Only reliable source of Legendary dwellers
- Can get duplicates (same name/appearance)

**Quest Rewards** (Specific characters):
- Certain quests reward named Legendary dwellers
- Sarah Lyons, Three Dog, Preston Garvey, Piper, etc.
- One-time rewards per quest chain

### Breeding Requirements

- 1 male + 1 female in Living Quarters
- Must NOT be related (parents, children, siblings, grandparents)
- Cousins, uncles/aunts, nieces/nephews CAN breed

**Gender Balance:**
- Optimal ratio: ~40% male, 60% female (females unavailable during pregnancy)
- Males can breed continuously; females have 3hr cooldown (pregnancy)
- For fast population growth: more females, fewer high-Charisma males
- Child gender is random (50/50)

### Timers

| Phase | Duration |
|-------|----------|
| Courtship | Variable (Charisma-dependent) |
| **Pregnancy** | **3 hours** real-time |
| **Child → Adult** | **3 hours** real-time |

### Pregnancy Restrictions

- Can work any room
- CANNOT fight incidents (will flee)
- Cannot explore or go on quests

### Stat Inheritance Formula

```
max = (male_total_SPECIAL + female_total_SPECIAL - 14) / 126
random = random(max/4, max)

if random > 0.95: LEGENDARY child (40 SPECIAL points)
if random > 0.85: RARE child (28 SPECIAL points)
else: NORMAL child (12 SPECIAL points)
```

With both parents at 70 total SPECIAL (all 10s): ~6.6% legendary, ~13.3% rare chance.

### Population Limits

- Living Quarters capacity determines vault cap
- Maximum population: **200 dwellers**

---

## Resource Management

### Consumption Rates

- **Food**: 0.36 units/minute/dweller
- **Water**: 0.36 units/minute/dweller
- **Total**: 0.72 units/minute/dweller

### Depletion Consequences

| Resource | Effect When Depleted |
|----------|---------------------|
| Power | Rooms shut down (furthest first) |
| Food | Dwellers lose health |
| Water | Dwellers take radiation damage |

### Radiation Mechanics

Radiation reduces a dweller's **maximum HP**, shown as a red portion of their health bar.

**Radiation Sources:**
| Source | Radiation Applied |
|--------|-------------------|
| Water shortage | Continuous while depleted |
| Radscorpion attacks | Moderate per hit |
| Wasteland encounters | Variable per event |
| Mole rat attacks | Minor (some variants) |

**Radiation Effects:**
- Shrinks the green HP bar from the right side
- Cannot heal past radiation cap (Stimpaks limited)
- At 100% radiation: dweller dies
- Radiation persists until cured

**Curing Radiation:**
- **RadAway**: Removes radiation damage instantly
- Each RadAway removes ~25-30% radiation
- Multiple RadAway needed for heavily irradiated dwellers

**Radiation Immunity:**
- **Endurance 11+** grants complete radiation immunity during exploration
- Does NOT prevent radiation from vault incidents
- Achieved via: E10 (trained) + outfit bonus (+1 to +7)

**Optimal Explorer Build:**
```
Endurance: 10 (trained) + 1 (outfit) = 11 minimum
Result: Never take radiation damage in wasteland
```

**Vault Radiation Tips:**
- Keep water production ahead of consumption
- Station high-E dwellers in rooms near vault edges (mole rat spawn)
- RadAway is more valuable than Stimpaks for long explorations

### Caps Earning Methods

Caps are the primary currency for building, upgrading, and reviving. Here's how to earn them:

**Passive Methods:**

| Method | Caps/Hour (Approx) | Notes |
|--------|-------------------|-------|
| Room Collection | 5-20 | Luck affects bonus caps |
| Successful Rush | 20-100 | Risk of incident on failure |
| Leveling Dwellers | 10-50 per level | One-time per level-up |

**Active Methods:**

| Method | Caps Earned | Notes |
|--------|-------------|-------|
| Wasteland Exploration | 100-5,000+ per trip | Luck increases finds |
| Quest Completion | 50-500+ per quest | Scales with difficulty |
| Selling Items | Variable | Junk, weapons, outfits |
| Mysterious Stranger | 100-5,000+ per tap | Random appearances |
| Mr. Handy (Wasteland) | Up to 5,000 | Returns at cap limit |

**Lunchbox/Objective Rewards:**

| Source | Caps Range |
|--------|------------|
| Lunchbox card | 100-500 (common), 500-2,500 (rare) |
| Daily objectives | 50-500 |
| Weekly objectives | 200-1,000 |
| Achievements | 100-5,000+ |

**Caps Optimization Tips:**
1. **Luck training** - Affects caps from ALL sources
2. **Max-Luck explorers** - L10 Luck = best wasteland caps
3. **Rush high-risk rooms** - Higher risk = higher caps reward
4. **Mysterious Stranger pets** - Increase spawn rate dramatically
5. **Sell duplicate items** - Excess weapons/outfits convert to caps

**Spending Priority:**
1. Room upgrades (production efficiency)
2. Training rooms (long-term investment)
3. Workshop upgrades (crafting legendary items)
4. Vault door (diminishing returns after L2)

**Maximum Caps:** 1,000,000

### Rush Mechanic

**Failure Rate Formula:**
```
Fail% = 40 - 2 × (Average_Luck + Average_Room_SPECIAL) + 10 × Recent_Rush_Attempts
Minimum: 10% (90% success max)
```

Uses **AVERAGE** stats—one maxed dweller beats multiple low-stat dwellers.

**Success Rewards:**
- Instant resources
- Caps bonus (scales with risk)
- +10% room happiness
- Dweller XP

**Failure:** Triggers incident (type depends on population)

**Rush Cooldown:**
- Each rush adds +10% to failure rate for THAT room
- Penalty decays over ~10 minutes per rush
- Rushing multiple rooms simultaneously: each has separate cooldown
- Wait for cooldown to reset before rushing same room again

### Offline Behavior

**Continues offline:**
- Resource production (fills pool)
- Training progress
- Exploration time
- Quest travel

**Does NOT continue:**
- Resource collection (without Mr. Handy)
- Incidents
- Dweller vault deaths

---

## Multiplayer Features

### Cooperative Vault Management

- Multiple players can share a vault
- All co-managers can build, move dwellers, collect resources
- Server-side arbitration for simultaneous actions
- Real-time sync via WebSocket (mobile) or polling (Telegram)

### Guilds and Alliances

| Role | Permissions |
|------|-------------|
| Guild Leader (Overseer) | Full control |
| Officers (Co-managers) | Build, manage resources |
| Members | Quest, contribute resources, limited build |

### Trading and Marketplace

- `/auction` command for Telegram
- List items for caps
- Buy from other players
- Guild-specific or global marketplace

### Resource Sharing

- Radio/Communications room enables vault-to-vault contact
- Send resource aid to allied vaults
- Trade caravans for resource-to-caps exchanges

### Joint Quests (Planned)

- Form multi-player parties for difficult quests
- Each player controls their own character
- Real-time coordination via WebSocket

### Leaderboards

Categories:
- Longest survival time
- Most powerful vault
- Top explorer (distance/loot)
- Guild rankings

---

## Monetization

Free-to-play with optional purchases:

### Lunchboxes (Vault Crates)

Each lunchbox contains **5 cards** with guaranteed quality on the last card.

**Card Type Probabilities:**

| Card Type | Approximate Chance | Notes |
|-----------|-------------------|-------|
| Caps | ~25% | 100-500 common, 500-2,500 rare |
| Resources | ~20% | Food, Water, Power bundles |
| Weapons | ~15% | Common to Legendary |
| Outfits | ~15% | Common to Legendary |
| Junk | ~10% | Crafting materials |
| Dwellers | ~10% | Rare/Legendary dwellers |
| Pets | ~5% | From Pet Carriers only |

**Rarity Distribution (per card):**

| Rarity | Chance (Cards 1-4) | Card 5 (Guaranteed) |
|--------|-------------------|---------------------|
| Common | ~60% | 0% |
| Rare | ~30% | ~85% |
| Legendary | ~10% | ~15% |

**Guaranteed Mechanics:**
- **Card 5 is always Rare or better** (no common)
- Legendary dweller chance: ~1 in 20-40 lunchboxes
- Legendary weapon/outfit: ~1 in 10 lunchboxes

**Lunchbox Sources:**
| Source | Frequency |
|--------|-----------|
| Objectives | Primary free source |
| Achievements | Major milestones |
| Daily Login (Day 7) | Weekly |
| Real money purchase | Anytime |
| Quest rewards | Rare quests |

**Opening Strategy:**
- Save lunchboxes for early game (caps/resources valuable)
- Or save for late game (legendary items matter more)
- No "pity timer" - each box is independent

### Mr. Handy Robots

Premium helper robots with multiple functions.

**Vault Behavior:**
- Assigned to ONE floor at a time
- Auto-collects ready resources from all rooms on floor
- Participates in incident combat (deals ~5-10 damage)
- Cannot be killed by incidents (but can be damaged)

**Limits:**
- Maximum 1 Mr. Handy per floor
- Maximum 5 Mr. Handy per vault total
- Cannot merge or upgrade

**Wasteland Mode:**
- Send to wasteland instead of floor assignment
- Collects CAPS ONLY (no items, no combat)
- Auto-returns when reaching 5,000 caps
- No Stimpaks/RadAway needed - cannot die in wasteland

**Durability:**
- Has HP bar that depletes during vault incidents
- At 0 HP: Destroyed, requires repair
- Repair cost: **2,000 caps**
- Damaged Mr. Handy still functions until destroyed

**Priority:**
1. Early game: Assign to production floors (auto-collect while offline)
2. Mid game: One in wasteland for passive caps
3. Late game: All on floors for incident support

**Obtaining Mr. Handy:**
- Lunchboxes (rare)
- Real money purchase
- Special objectives/achievements

### Pet Carriers

Loot box guaranteeing a pet with chance for Legendary.

### Nuka-Cola Quantum (Premium Currency)

**Conversion:** 1 Quantum = 2 hours skipped

**Uses:**
- Quest/wasteland travel time
- Crafting timers
- Training timers
- Barbershop customization
- Objective skipping (escalating costs: 2, 3, 5, 8, 12, 18, 27, 41, 62)

### Objectives System

Players receive objectives that grant rewards when completed:

**Objective Types:**
- Daily objectives (refresh daily)
- Weekly objectives (refresh weekly)
- Standard objectives (always available)

**Reward Types:**
- Caps
- Lunchboxes (most valuable)
- Nuka-Cola Quantum
- Pet Carriers

**Objective Skipping:**
Players can skip difficult objectives using Nuka-Cola Quantum. Skip costs escalate with each skip: 2, 3, 5, 8, 12, 18, 27, 41, 62 Quantum.

**Strategy:** Focus on lunchbox-rewarding objectives; skip difficult objectives with low rewards.

### Daily/Weekly Login Rewards

Regular check-ins provide escalating rewards over 7 days:
- Days 1-6: Caps, resources, or Nuka-Cola Quantum
- Day 7: Guaranteed Lunchbox

Weekly quest chains also provide additional rewards.

### Achievement System

Players earn achievements for reaching milestones:

**Achievement Categories:**
| Category | Examples |
|----------|----------|
| **Population** | Reach 25/50/100/200 dwellers |
| **Resources** | Collect 10,000/100,000/1,000,000 caps |
| **Exploration** | Explore 100 hours, find 50 locations |
| **Quests** | Complete 10/50/100 quests |
| **Crafting** | Craft 25 weapons, 25 outfits |
| **Training** | Max out 10 dwellers' SPECIAL |
| **Combat** | Survive 50 incidents, defeat 100 raiders |
| **Collection** | Collect all legendary weapons/outfits |

**Achievement Rewards:**
- Caps (scaling with difficulty)
- Lunchboxes (major milestones)
- Nuka-Cola Quantum
- Exclusive titles/badges (Vaultown multiplayer)

**Vaultown Multiplayer Achievements:**
- Guild cooperation achievements
- Trading milestones
- Joint quest completions
- Leaderboard rankings

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Swift 6.2 (macOS 14+) |
| Backend Framework | Hummingbird 2.x |
| Database | PostgreSQL + Fluent ORM 4.x |
| HTTP Client | AsyncHTTPClient 1.x |
| Networking | SwiftNIO 2.x |
| Telegram | SwiftTelegramSdk 4.x |
| Mobile Engine | Godot 4.5 + SwiftGodot |
| Localization | Lingo 4.x (EN, UK) |
| Environment | SwiftDotenv 2.x |

### Package Dependencies

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
│   ├── entrypoint.swift       # App entry point
│   ├── configure.swift        # Hummingbird configuration
│   ├── routes.swift           # HTTP routes (for Godot API)
│   ├── Controllers/           # Telegram bot controllers
│   │   ├── AllControllers.swift   # Controller registry
│   │   ├── VaultController.swift  # Main vault menu
│   │   ├── RegistrationController.swift
│   │   ├── SettingsController.swift
│   │   └── GlobalCommandsController.swift
│   ├── Models/                # Database models (Fluent)
│   │   └── User.swift
│   ├── Migrations/            # Database schema migrations
│   │   └── CreateUser.swift
│   ├── Helpers/
│   │   ├── TGBot+Extensions.swift  # TGControllerBase
│   │   ├── SessionCache.swift      # User session caching
│   │   ├── Lingo+Locales.swift     # Locale extensions
│   │   └── DotEnv+Env.swift        # Environment helpers
│   └── Telegram/
│       ├── Router/            # Router system
│       │   ├── Router.swift
│       │   ├── Context.swift
│       │   ├── Commands.swift
│       │   ├── ContentType.swift
│       │   ├── Arguments.swift
│       │   └── Router+Helpers.swift
│       └── TGBot/
│           ├── TGDispatcher.swift
│           └── HummingbirdTGClient.swift
├── GameLogic/                 # Shared game mechanics (SPM package)
│   └── Sources/GameLogic/
│       ├── Character/         # S.P.E.C.I.A.L. system
│       ├── Combat/            # Damage, conditions
│       ├── Vault/             # Rooms, production
│       ├── Equipment/         # Items, inventory
│       └── GameLogic.swift    # Public API
├── Vault-2D/                  # Godot client (SwiftGodot)
│   └── Sources/Vault-2D/
├── Localizations/             # i18n files
│   ├── en.json
│   └── uk.json
├── Docs/                      # Documentation
├── docker-compose.yml
├── Dockerfile
├── .env.example
└── README.md
```

---

## Vault Statistics

The game tracks lifetime statistics for each vault, used for achievements and leaderboards.

### Tracked Metrics

**Population Statistics:**
| Metric | Description |
|--------|-------------|
| Dwellers Born | Total children born in vault |
| Dwellers Recruited | Wanderers + Radio recruits |
| Dwellers from Lunchboxes | Dwellers obtained from lunchboxes |
| Dwellers Died | Total deaths (not revived within 24hr) |
| Dwellers Evicted | Permanently removed dwellers |
| Current Population | Active dweller count |
| Max Population Reached | Highest population achieved |

**Resource Statistics:**
| Metric | Description |
|--------|-------------|
| Total Caps Earned | Lifetime caps collected |
| Total Caps Spent | Caps used on building/upgrades/revival |
| Caps from Exploration | Wasteland + quest caps |
| Caps from Mysterious Stranger | Stranger tap rewards |
| Total Power Produced | Lifetime power generated |
| Total Food Produced | Lifetime food generated |
| Total Water Produced | Lifetime water generated |

**Combat Statistics:**
| Metric | Description |
|--------|-------------|
| Incidents Survived | Fires, radroaches, etc. resolved |
| Raiders Defeated | Total raiders killed |
| Deathclaws Defeated | Total deathclaws killed |
| Dwellers Lost to Incidents | Deaths during vault attacks |

**Exploration Statistics:**
| Metric | Description |
|--------|-------------|
| Total Exploration Time | Combined hours all explorers |
| Quests Completed | Finished quest count |
| Quest Locations Discovered | Unique locations found |
| Legendary Items Found | Exploration legendary drops |
| Recipes Discovered | Crafting recipes learned |

**Crafting Statistics:**
| Metric | Description |
|--------|-------------|
| Weapons Crafted | Total weapons made |
| Outfits Crafted | Total outfits made |
| Legendary Items Crafted | Legendary tier crafted |
| Junk Collected | Total junk items gathered |

**Vaultown Multiplayer Statistics:**
| Metric | Description |
|--------|-------------|
| Items Traded | Marketplace transactions |
| Caps from Trading | Profit from sales |
| Guild Contributions | Resources shared with guild |
| Joint Quests Completed | Multi-player quest count |

### Statistics Display

Statistics viewable via:
- Vault overview screen
- Dweller individual stats
- Leaderboard rankings
- Achievement progress

---

## Hard Limits Reference

| Limit | Value |
|-------|-------|
| Maximum population | 200 dwellers |
| Maximum floors | 25 |
| Maximum rooms | ~100 (excluding elevators) |
| Maximum caps | 1,000,000 |
| Maximum explorers | 25 dwellers + 5 Mr. Handy |
| Maximum concurrent quests | 3 (L3 Overseer's Office) |
| Maximum SPECIAL (base) | 10 |
| Maximum SPECIAL (with outfit) | 17 |
| Maximum dweller level | 50 |
| Maximum HP | 644 (E17 throughout leveling) |

---

*Welcome to Vaultown, Overseer. Good luck rebuilding civilization — one vault at a time.*
