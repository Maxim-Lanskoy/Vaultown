//
//  Room.swift
//  GameLogic
//
//  Room instance with position, level, and production state
//

import Foundation

/// Room levels (L1, L2, L3)
public enum RoomLevel: Int, CaseIterable, Codable, Sendable {
    case level1 = 1
    case level2 = 2
    case level3 = 3

    /// Display name
    public var name: String {
        "L\(rawValue)"
    }

    /// Upgrade cost multiplier (relative to base build cost)
    public var upgradeCostMultiplier: Double {
        switch self {
        case .level1: return 1.0
        case .level2: return 2.5
        case .level3: return 7.5
        }
    }

    /// Next level (if available)
    public var next: RoomLevel? {
        switch self {
        case .level1: return .level2
        case .level2: return .level3
        case .level3: return nil
        }
    }

    /// Whether this room can be upgraded
    public var canUpgrade: Bool {
        next != nil
    }
}

/// Room width (single, double, triple for merged rooms)
public enum RoomWidth: Int, CaseIterable, Codable, Sendable {
    case single = 1
    case double = 2
    case triple = 3

    /// Display name
    public var name: String {
        switch self {
        case .single: return "Single"
        case .double: return "Double"
        case .triple: return "Triple"
        }
    }

    /// Upgrade cost discount for merged rooms
    public var upgradeDiscount: Double {
        switch self {
        case .single: return 1.0
        case .double: return 0.75  // 25% cheaper
        case .triple: return 0.66  // 34% cheaper
        }
    }

    /// Build cost multiplier for room width
    public var buildCostMultiplier: Double {
        switch self {
        case .single: return 1.0
        case .double: return 1.75
        case .triple: return 2.0
        }
    }
}

/// Room production state
public enum RoomProductionState: String, Codable, Sendable {
    case idle           // Room not producing (no power or no dwellers)
    case producing      // Actively producing resources
    case ready          // Resources ready for collection
    case rushing        // Currently being rushed
}

/// A room instance in the vault
public struct Room: Codable, Sendable, Identifiable {
    public let id: UUID

    /// Type of room
    public let type: RoomType

    /// Room level (L1, L2, L3)
    public var level: RoomLevel

    /// Position in vault grid (x = column, y = floor)
    public let x: Int
    public let y: Int

    /// Width of room (1-3 tiles)
    public var width: RoomWidth

    /// IDs of dwellers assigned to this room
    public var assignedDwellerIDs: [UUID]

    /// Current production state
    public var productionState: RoomProductionState

    /// Progress of current production cycle (0.0 - 1.0)
    public var productionProgress: Double

    /// Last time production was updated
    public var lastProductionUpdate: Date

    /// Whether room has power
    public var hasPower: Bool

    public init(
        id: UUID = UUID(),
        type: RoomType,
        level: RoomLevel = .level1,
        x: Int,
        y: Int,
        width: RoomWidth = .single,
        assignedDwellerIDs: [UUID] = [],
        productionState: RoomProductionState = .idle,
        productionProgress: Double = 0,
        lastProductionUpdate: Date = Date(),
        hasPower: Bool = true
    ) {
        self.id = id
        self.type = type
        self.level = level
        self.x = x
        self.y = y
        self.width = width
        self.assignedDwellerIDs = assignedDwellerIDs
        self.productionState = productionState
        self.productionProgress = productionProgress
        self.lastProductionUpdate = lastProductionUpdate
        self.hasPower = hasPower
    }
}

// MARK: - Room Capacity

public extension Room {
    /// Maximum dweller capacity for this room
    var capacity: Int {
        type.capacity(width: width.rawValue)
    }

    /// Current number of assigned dwellers
    var assignedCount: Int {
        assignedDwellerIDs.count
    }

    /// Whether room can accept more dwellers
    var canAssignMore: Bool {
        assignedCount < capacity
    }

    /// Whether room has any dwellers assigned
    var hasAssignedDwellers: Bool {
        !assignedDwellerIDs.isEmpty
    }
}

// MARK: - Room Costs

public extension Room {
    /// Total build cost for this room at current size
    var totalBuildCost: Int {
        Int(Double(type.baseBuildCost) * width.buildCostMultiplier)
    }

    /// Cost to upgrade to next level
    var upgradeCost: Int? {
        guard let nextLevel = level.next else { return nil }
        let baseCost = Double(type.baseBuildCost) * nextLevel.upgradeCostMultiplier
        return Int(baseCost * width.upgradeDiscount)
    }

    /// Power consumption of this room
    var powerConsumption: Int {
        type.powerConsumption(width: width.rawValue, level: level.rawValue)
    }
}

// MARK: - Room Production

public extension Room {
    /// Base production cycle time in seconds
    static let baseProductionCycleTime: TimeInterval = 60  // 1 minute base

    /// Calculate production cycle time based on assigned dwellers' stats
    /// Formula: Cycle Time = Base_Time / (1 + Total_SPECIAL / 10 + Happiness_Bonus)
    func productionCycleTime(totalStat: Int, averageHappiness: Double) -> TimeInterval {
        let statBonus = Double(totalStat) / 10.0
        let happinessBonus = averageHappiness / 100.0 * 0.1  // Max 10% bonus
        let divisor = 1.0 + statBonus + happinessBonus
        return Room.baseProductionCycleTime / divisor
    }

    /// Base production amount per cycle
    var baseProductionPerCycle: Int {
        switch level {
        case .level1: return 10
        case .level2: return 12
        case .level3: return 15
        }
    }

    /// Whether this room is actively producing
    var isProducing: Bool {
        productionState == .producing
    }

    /// Whether resources are ready for collection
    var hasResourcesReady: Bool {
        productionState == .ready
    }
}

// MARK: - Room Assignment

public extension Room {
    /// Check if a dweller is assigned to this room
    func isAssigned(_ dwellerID: UUID) -> Bool {
        assignedDwellerIDs.contains(dwellerID)
    }

    /// Assign a dweller to this room (mutating)
    mutating func assignDweller(_ dwellerID: UUID) -> Bool {
        guard canAssignMore && !isAssigned(dwellerID) else { return false }
        assignedDwellerIDs.append(dwellerID)
        return true
    }

    /// Remove a dweller from this room (mutating)
    mutating func unassignDweller(_ dwellerID: UUID) -> Bool {
        guard let index = assignedDwellerIDs.firstIndex(of: dwellerID) else { return false }
        assignedDwellerIDs.remove(at: index)
        return true
    }
}

// MARK: - Room Upgrade

public extension Room {
    /// Upgrade room to next level (mutating)
    mutating func upgrade() -> Bool {
        guard let nextLevel = level.next else { return false }
        level = nextLevel
        return true
    }

    /// Check if room meets population requirement for upgrade
    func canUpgrade(currentPopulation: Int) -> Bool {
        guard level.canUpgrade else { return false }

        // Check workshop upgrade population requirements
        switch type {
        case .weaponWorkshop:
            switch level {
            case .level1: return currentPopulation >= 45
            case .level2: return currentPopulation >= 75
            case .level3: return false
            }
        case .outfitWorkshop:
            switch level {
            case .level1: return currentPopulation >= 55
            case .level2: return currentPopulation >= 90
            case .level3: return false
            }
        case .themeWorkshop:
            switch level {
            case .level1: return currentPopulation >= 65
            case .level2: return currentPopulation >= 105
            case .level3: return false
            }
        case .overseersOffice:
            switch level {
            case .level1: return currentPopulation >= 30
            case .level2: return currentPopulation >= 55
            case .level3: return false
            }
        default:
            return true
        }
    }
}

// MARK: - Display

public extension Room {
    /// Short display for Telegram
    var shortDescription: String {
        "\(type.emoji) \(type.name) \(level.name)"
    }

    /// Display with position
    var positionDescription: String {
        "[\(x),\(y)] \(shortDescription)"
    }

    /// Status description
    var statusDescription: String {
        let dwellers = assignedCount > 0 ? "👥\(assignedCount)/\(capacity)" : "👥-"
        let power = hasPower ? "⚡" : "⚫"
        return "\(shortDescription) \(dwellers) \(power)"
    }
}
