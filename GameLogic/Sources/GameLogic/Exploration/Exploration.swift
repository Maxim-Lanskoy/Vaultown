//
//  Exploration.swift
//  GameLogic
//
//  Core exploration mechanics for wasteland exploration
//

import Foundation

/// Status of an exploration
public enum ExplorationStatus: String, Codable, Sendable {
    /// Dweller is actively exploring
    case exploring
    /// Dweller is returning to vault
    case returning
    /// Exploration complete, dweller waiting at vault door
    case completed
    /// Dweller died during exploration
    case dead
}

/// Represents an active or completed exploration.
///
/// Key mechanics from GDD:
/// - 60 minutes: Guaranteed quality loot event
/// - ~160 minutes: Repeatable junk events
/// - 2.5+ days: Legendary junk/recipes more common
/// - ~4 days: Typically hits 100-item limit
/// - Return time = 50% of exploration time
/// - Endurance 11+ = radiation immunity
/// - Max 25 dwellers + 5 Mr. Handy exploring simultaneously
public struct Exploration: Identifiable, Codable, Sendable {
    /// Unique identifier
    public let id: UUID

    /// ID of the exploring dweller
    public let dwellerID: UUID

    /// Dweller's name for display
    public let dwellerName: String

    /// Exploration start time
    public let startTime: Date

    /// Time when return was initiated (nil if still exploring)
    public var returnStartTime: Date?

    /// Current status
    public var status: ExplorationStatus

    /// Current HP of the explorer
    public var currentHP: Double

    /// Max HP of the explorer
    public let maxHP: Double

    /// Current radiation level
    public var radiation: Double

    /// Whether explorer has radiation immunity (E11+)
    public let hasRadiationImmunity: Bool

    /// Stimpaks carried
    public var stimpaks: Int

    /// RadAway carried
    public var radAway: Int

    /// Caps collected during exploration
    public var capsCollected: Int

    /// Items collected (count only - detailed items stored separately)
    public var itemsCollected: Int

    /// Event log
    public var events: [ExplorationEvent]

    /// Current dweller level (for leveling during exploration)
    public var dwellerLevel: Int

    /// Current dweller XP
    public var dwellerXP: Int

    /// Dweller's Luck stat (affects loot quality and caps)
    public let luck: Int

    /// Dweller's Perception stat (affects location discovery)
    public let perception: Int

    /// Dweller's Charisma stat (affects NPC encounters)
    public let charisma: Int

    /// Pet return speed multiplier (1.0 = normal, 4.0 = max)
    public let returnSpeedMultiplier: Double

    // MARK: - Constants

    /// Maximum items an explorer can carry
    public static let maxItems: Int = 100

    /// Maximum stimpaks an explorer can carry
    public static let maxStimpaks: Int = 25

    /// Maximum RadAway an explorer can carry
    public static let maxRadAway: Int = 25

    /// Maximum concurrent explorers (dwellers)
    public static let maxExplorers: Int = 25

    /// HP threshold for auto-stimpak use (50%)
    public static let stimpakThreshold: Double = 0.5

    /// Radiation threshold for auto-RadAway use (50%)
    public static let radAwayThreshold: Double = 0.5

    /// Stimpak heal amount (percentage of max HP)
    public static let stimpakHealPercent: Double = 45.0

    /// RadAway removal amount (percentage)
    public static let radAwayRemovePercent: Double = 27.5

    /// Time for guaranteed loot event (minutes)
    public static let guaranteedLootTime: Int = 60

    /// Average time between events (minutes)
    public static let averageEventInterval: Int = 30

    // MARK: - Initialization

    /// Create a new exploration
    public init(
        id: UUID = UUID(),
        dwellerID: UUID,
        dwellerName: String,
        startTime: Date = Date(),
        currentHP: Double,
        maxHP: Double,
        radiation: Double = 0,
        hasRadiationImmunity: Bool,
        stimpaks: Int,
        radAway: Int,
        dwellerLevel: Int,
        dwellerXP: Int,
        luck: Int,
        perception: Int,
        charisma: Int,
        returnSpeedMultiplier: Double = 1.0
    ) {
        self.id = id
        self.dwellerID = dwellerID
        self.dwellerName = dwellerName
        self.startTime = startTime
        self.returnStartTime = nil
        self.status = .exploring
        self.currentHP = currentHP
        self.maxHP = maxHP
        self.radiation = radiation
        self.hasRadiationImmunity = hasRadiationImmunity
        self.stimpaks = min(stimpaks, Self.maxStimpaks)
        self.radAway = min(radAway, Self.maxRadAway)
        self.capsCollected = 0
        self.itemsCollected = 0
        self.events = []
        self.dwellerLevel = dwellerLevel
        self.dwellerXP = dwellerXP
        self.luck = luck
        self.perception = perception
        self.charisma = charisma
        self.returnSpeedMultiplier = returnSpeedMultiplier

        // Add departure event
        let departureEvent = ExplorationEvent(
            type: .lootDiscovery,
            timestamp: 0,
            description: "\(dwellerName) left the vault in search of adventure... and loot."
        )
        self.events.append(departureEvent)
    }

    // MARK: - Computed Properties

    /// Total exploration time in minutes
    public var explorationMinutes: Int {
        let endTime = returnStartTime ?? Date()
        return Int(endTime.timeIntervalSince(startTime) / 60)
    }

    /// Time spent returning in minutes
    public var returningMinutes: Int {
        guard let returnStart = returnStartTime else { return 0 }
        return Int(Date().timeIntervalSince(returnStart) / 60)
    }

    /// Expected return duration in minutes (50% of exploration time, reduced by pet)
    public var expectedReturnDuration: Int {
        let baseReturn = Double(explorationMinutes) * 0.5
        return Int(baseReturn / returnSpeedMultiplier)
    }

    /// Progress of return journey (0.0 to 1.0)
    public var returnProgress: Double {
        guard status == .returning, expectedReturnDuration > 0 else { return 0 }
        return min(1.0, Double(returningMinutes) / Double(expectedReturnDuration))
    }

    /// Whether explorer has reached item limit
    public var isInventoryFull: Bool {
        itemsCollected >= Self.maxItems
    }

    /// Whether explorer is alive
    public var isAlive: Bool {
        currentHP > 0
    }

    /// Effective max HP after radiation
    public var effectiveMaxHP: Double {
        max(0, maxHP - radiation)
    }

    /// HP as percentage of effective max
    public var hpPercent: Double {
        guard effectiveMaxHP > 0 else { return 0 }
        return currentHP / effectiveMaxHP
    }

    /// Radiation as percentage of max HP
    public var radiationPercent: Double {
        guard maxHP > 0 else { return 0 }
        return radiation / maxHP
    }

    // MARK: - Actions

    /// Start returning to vault
    public mutating func startReturn() {
        guard status == .exploring else { return }
        returnStartTime = Date()
        status = .returning
    }

    /// Complete the exploration (dweller arrived at vault)
    public mutating func complete() {
        status = .completed
    }

    /// Apply damage to explorer
    public mutating func takeDamage(_ amount: Double, timestamp: Int) {
        currentHP = max(0, currentHP - amount)

        // Check for death
        if currentHP <= 0 {
            die(timestamp: timestamp)
        } else {
            // Auto-use stimpak if below threshold
            tryAutoStimpak(timestamp: timestamp)
        }
    }

    /// Apply radiation damage
    public mutating func takeRadiation(_ amount: Double, timestamp: Int) {
        // Radiation immunity check
        guard !hasRadiationImmunity else { return }

        radiation = min(radiation + amount, maxHP)

        // Adjust HP if it exceeds effective max
        if currentHP > effectiveMaxHP {
            currentHP = effectiveMaxHP
        }

        // Auto-use RadAway if above threshold
        tryAutoRadAway(timestamp: timestamp)

        // Check for death from radiation
        if effectiveMaxHP <= 0 || currentHP <= 0 {
            die(timestamp: timestamp)
        }
    }

    /// Try to auto-use stimpak if HP below threshold
    private mutating func tryAutoStimpak(timestamp: Int) {
        guard stimpaks > 0, hpPercent < Self.stimpakThreshold else { return }

        stimpaks -= 1
        let healAmount = effectiveMaxHP * (Self.stimpakHealPercent / 100)
        currentHP = min(currentHP + healAmount, effectiveMaxHP)

        let event = ExplorationEvent(
            type: .stimpakUsed,
            timestamp: timestamp,
            description: "\(dwellerName) used a Stimpak. HP restored."
        )
        events.append(event)
    }

    /// Try to auto-use RadAway if radiation above threshold
    private mutating func tryAutoRadAway(timestamp: Int) {
        guard radAway > 0, radiationPercent > Self.radAwayThreshold else { return }

        radAway -= 1
        let removeAmount = maxHP * (Self.radAwayRemovePercent / 100)
        radiation = max(0, radiation - removeAmount)

        let event = ExplorationEvent(
            type: .radAwayUsed,
            timestamp: timestamp,
            description: "\(dwellerName) used RadAway. Radiation reduced."
        )
        events.append(event)
    }

    /// Mark explorer as dead
    private mutating func die(timestamp: Int) {
        status = .dead
        currentHP = 0

        let event = ExplorationEvent(
            type: .death,
            timestamp: timestamp,
            description: "\(dwellerName) has died in the wasteland."
        )
        events.append(event)
    }

    /// Add collected caps
    public mutating func addCaps(_ amount: Int) {
        capsCollected += amount
    }

    /// Add collected item
    public mutating func addItem() {
        itemsCollected += 1
    }

    /// Add XP and check for level up
    public mutating func addXP(_ amount: Int, timestamp: Int, effectiveEndurance: Int) {
        dwellerXP += amount

        // Check for level up
        let xpForNext = Dweller.xpForLevel(dwellerLevel + 1)
        if dwellerXP >= xpForNext && dwellerLevel < Dweller.maxLevel {
            dwellerLevel += 1
            _ = Dweller.hpPerLevel(endurance: effectiveEndurance) // HP will be applied when explorer returns

            let event = ExplorationEvent(
                type: .levelUp,
                timestamp: timestamp,
                description: "\(dwellerName) leveled up to level \(dwellerLevel)!",
                xpGained: amount
            )
            events.append(event)

            // Note: Actual HP increase should be applied when explorer returns
        }
    }

    /// Add an event to the log
    public mutating func addEvent(_ event: ExplorationEvent) {
        events.append(event)
    }
}

// MARK: - Display

public extension Exploration {
    /// Status emoji
    var statusEmoji: String {
        switch status {
        case .exploring: return "🏃"
        case .returning: return "🔙"
        case .completed: return "✅"
        case .dead: return "💀"
        }
    }

    /// Status description
    var statusDescription: String {
        switch status {
        case .exploring:
            let hours = explorationMinutes / 60
            let mins = explorationMinutes % 60
            return "Exploring (\(hours)h \(mins)m)"
        case .returning:
            let progress = Int(returnProgress * 100)
            return "Returning (\(progress)%)"
        case .completed:
            return "Waiting at vault door"
        case .dead:
            return "Deceased"
        }
    }

    /// Short summary for list display
    var summary: String {
        "\(statusEmoji) \(dwellerName) - \(statusDescription) | 💰\(capsCollected) 📦\(itemsCollected)"
    }

    /// Health bar display
    func healthBar(segments: Int = 5) -> String {
        let filledCount = Int(hpPercent * Double(segments))
        let filled = String(repeating: "█", count: filledCount)
        let empty = String(repeating: "░", count: segments - filledCount)
        return "[\(filled)\(empty)]"
    }

    /// Last few log entries for display
    func recentLogs(count: Int = 5) -> [ExplorationEvent] {
        Array(events.suffix(count))
    }
}

// MARK: - Event Generation

public extension Exploration {
    /// Generate a random event based on current exploration state
    static func generateEvent(
        exploration: inout Exploration,
        timestamp: Int
    ) -> ExplorationEvent? {
        // Don't generate events if dead or returning
        guard exploration.status == .exploring else { return nil }

        // Determine event type based on time and randomness
        let eventType = randomEventType(explorationMinutes: timestamp, luck: exploration.luck)

        switch eventType {
        case .combat:
            return generateCombatEvent(exploration: &exploration, timestamp: timestamp)
        case .lootDiscovery:
            return generateLootEvent(exploration: &exploration, timestamp: timestamp)
        case .junkScavenging:
            return generateJunkEvent(exploration: &exploration, timestamp: timestamp)
        case .capsFound:
            return generateCapsEvent(exploration: &exploration, timestamp: timestamp)
        case .locationFound:
            return generateLocationEvent(exploration: &exploration, timestamp: timestamp)
        case .npcEncounter:
            return generateNPCEvent(exploration: &exploration, timestamp: timestamp)
        case .radiationZone:
            return generateRadiationEvent(exploration: &exploration, timestamp: timestamp)
        case .recipeFound:
            return generateRecipeEvent(exploration: &exploration, timestamp: timestamp)
        default:
            return nil
        }
    }

    /// Random event type based on exploration time
    private static func randomEventType(explorationMinutes: Int, luck: Int) -> ExplorationEventType {
        let roll = Int.random(in: 1...100)
        let luckBonus = luck * 2

        // Weighted distribution
        if roll <= 25 {
            return .combat
        } else if roll <= 40 {
            return .capsFound
        } else if roll <= 55 {
            return .junkScavenging
        } else if roll <= 70 + luckBonus / 2 {
            return .lootDiscovery
        } else if roll <= 80 {
            return .npcEncounter
        } else if roll <= 88 {
            return .radiationZone
        } else if roll <= 95 {
            return .locationFound
        } else {
            return .recipeFound
        }
    }

    /// Generate a combat event
    private static func generateCombatEvent(exploration: inout Exploration, timestamp: Int) -> ExplorationEvent {
        let enemy = ExplorationEnemy.random(explorationMinutes: timestamp)
        let damage = Double(Int.random(in: enemy.damageRange))
        let xp = enemy.xpReward
        let caps = Int.random(in: 5...25)

        // Apply damage
        exploration.takeDamage(damage, timestamp: timestamp)

        // Apply radiation if applicable
        if enemy.dealsRadiation {
            exploration.takeRadiation(Double(Int.random(in: 2...8)), timestamp: timestamp)
        }

        // Gain XP and caps
        exploration.addXP(xp, timestamp: timestamp, effectiveEndurance: 10) // TODO: pass actual endurance
        exploration.addCaps(caps)

        let event = ExplorationEvent(
            type: .combat,
            timestamp: timestamp,
            description: "Encountered a \(enemy.name). Defeated it and found \(caps) caps.",
            capsGained: caps,
            damageReceived: damage,
            xpGained: xp,
            enemyDefeated: enemy.name
        )
        exploration.addEvent(event)

        return event
    }

    /// Generate a loot discovery event
    private static func generateLootEvent(exploration: inout Exploration, timestamp: Int) -> ExplorationEvent {
        guard !exploration.isInventoryFull else {
            return generateCapsEvent(exploration: &exploration, timestamp: timestamp)
        }

        // Luck affects loot quality
        let luckBonus = exploration.luck
        let qualityRoll = Int.random(in: 1...100) + luckBonus * 2

        let rarity: String
        if qualityRoll >= 95 {
            rarity = "legendary"
        } else if qualityRoll >= 75 {
            rarity = "rare"
        } else {
            rarity = "common"
        }

        let itemType = ["weapon", "outfit"].randomElement()!
        exploration.addItem()

        let event = ExplorationEvent(
            type: .lootDiscovery,
            timestamp: timestamp,
            description: "Found a \(rarity) \(itemType) in an abandoned building!",
            itemFound: "\(rarity) \(itemType)"
        )
        exploration.addEvent(event)

        return event
    }

    /// Generate a junk scavenging event
    private static func generateJunkEvent(exploration: inout Exploration, timestamp: Int) -> ExplorationEvent {
        guard !exploration.isInventoryFull else {
            return generateCapsEvent(exploration: &exploration, timestamp: timestamp)
        }

        let junkCount = Int.random(in: 1...3)
        for _ in 0..<junkCount {
            if !exploration.isInventoryFull {
                exploration.addItem()
            }
        }

        let event = ExplorationEvent(
            type: .junkScavenging,
            timestamp: timestamp,
            description: "Scavenged \(junkCount) pieces of junk from the ruins."
        )
        exploration.addEvent(event)

        return event
    }

    /// Generate a caps found event
    private static func generateCapsEvent(exploration: inout Exploration, timestamp: Int) -> ExplorationEvent {
        let baseCaps = Int.random(in: 10...50)
        let luckBonus = exploration.luck * 3
        let totalCaps = baseCaps + luckBonus

        exploration.addCaps(totalCaps)

        let event = ExplorationEvent(
            type: .capsFound,
            timestamp: timestamp,
            description: "Found \(totalCaps) caps in an old cash register.",
            capsGained: totalCaps
        )
        exploration.addEvent(event)

        return event
    }

    /// Generate a location discovery event
    private static func generateLocationEvent(exploration: inout Exploration, timestamp: Int) -> ExplorationEvent {
        // Perception affects location discovery
        let locations = [
            "Abandoned Factory", "Old Hospital", "Military Bunker",
            "Ruined School", "Collapsed Subway", "Forgotten Vault",
            "Raider Camp", "Trading Post", "Research Facility"
        ]
        let location = locations.randomElement()!

        let event = ExplorationEvent(
            type: .locationFound,
            timestamp: timestamp,
            description: "Discovered a new location: \(location)",
            locationName: location
        )
        exploration.addEvent(event)

        return event
    }

    /// Generate an NPC encounter event
    private static func generateNPCEvent(exploration: inout Exploration, timestamp: Int) -> ExplorationEvent {
        // Charisma affects NPC outcomes
        let charismaBonus = exploration.charisma
        let outcome = Int.random(in: 1...100) + charismaBonus * 3

        let description: String
        var caps = 0

        if outcome >= 80 {
            // Friendly trade
            caps = Int.random(in: 20...50)
            exploration.addCaps(caps)
            description = "Met a friendly trader. Traded some goods for \(caps) caps."
        } else if outcome >= 50 {
            // Friendly but no reward
            description = "Met a wastelander who shared some survival tips."
        } else {
            // Hostile - avoided conflict
            description = "Spotted a suspicious group and avoided them."
        }

        let event = ExplorationEvent(
            type: .npcEncounter,
            timestamp: timestamp,
            description: description,
            capsGained: caps > 0 ? caps : nil
        )
        exploration.addEvent(event)

        return event
    }

    /// Generate a radiation zone event
    private static func generateRadiationEvent(exploration: inout Exploration, timestamp: Int) -> ExplorationEvent {
        let radiation = Double(Int.random(in: 5...15))

        if exploration.hasRadiationImmunity {
            let event = ExplorationEvent(
                type: .radiationZone,
                timestamp: timestamp,
                description: "Passed through a radiation zone unaffected (E11+ immunity)."
            )
            exploration.addEvent(event)
            return event
        }

        exploration.takeRadiation(radiation, timestamp: timestamp)

        let event = ExplorationEvent(
            type: .radiationZone,
            timestamp: timestamp,
            description: "Entered a radiation zone and took \(Int(radiation)) rads.",
            radiationReceived: radiation
        )
        exploration.addEvent(event)

        return event
    }

    /// Generate a recipe discovery event
    private static func generateRecipeEvent(exploration: inout Exploration, timestamp: Int) -> ExplorationEvent {
        let recipeTypes = ["weapon", "outfit", "theme"]
        let recipeType = recipeTypes.randomElement()!

        let event = ExplorationEvent(
            type: .recipeFound,
            timestamp: timestamp,
            description: "Found a \(recipeType) crafting recipe!",
            itemFound: "\(recipeType) recipe"
        )
        exploration.addEvent(event)

        return event
    }
}
