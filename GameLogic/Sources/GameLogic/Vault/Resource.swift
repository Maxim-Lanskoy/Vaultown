//
//  Resource.swift
//  GameLogic
//
//  Vault resources (Power, Food, Water, Caps)
//

import Foundation

/// Types of resources in the vault
public enum ResourceType: String, CaseIterable, Codable, Sendable {
    case power
    case food
    case water
    case caps

    /// Display name
    public var name: String {
        rawValue.capitalized
    }

    /// Emoji representation
    public var emoji: String {
        switch self {
        case .power: return "⚡"
        case .food: return "🍲"
        case .water: return "💧"
        case .caps: return "💰"
        }
    }

    /// Whether this resource is consumable by dwellers
    public var isConsumable: Bool {
        self == .food || self == .water
    }
}

/// Container for vault resources
public struct VaultResources: Codable, Sendable, Equatable {
    /// Current power level
    public var power: Double

    /// Maximum power storage
    public var maxPower: Double

    /// Current food level
    public var food: Double

    /// Maximum food storage
    public var maxFood: Double

    /// Current water level
    public var water: Double

    /// Maximum water storage
    public var maxWater: Double

    /// Current caps
    public var caps: Int

    /// Create vault resources with specified values
    public init(
        power: Double = 50,
        maxPower: Double = 100,
        food: Double = 50,
        maxFood: Double = 100,
        water: Double = 50,
        maxWater: Double = 100,
        caps: Int = 500
    ) {
        self.power = power
        self.maxPower = maxPower
        self.food = food
        self.maxFood = maxFood
        self.water = water
        self.maxWater = maxWater
        self.caps = caps
    }

    /// Default starting resources for a new vault
    public static let starting = VaultResources(
        power: 50,
        maxPower: 100,
        food: 50,
        maxFood: 100,
        water: 50,
        maxWater: 100,
        caps: 500
    )

    /// Maximum caps a vault can hold
    public static let maxCaps: Int = 1_000_000
}

// MARK: - Resource Management

public extension VaultResources {
    /// Get current value for a resource type
    func current(_ type: ResourceType) -> Double {
        switch type {
        case .power: return power
        case .food: return food
        case .water: return water
        case .caps: return Double(caps)
        }
    }

    /// Get maximum value for a resource type
    func maximum(_ type: ResourceType) -> Double {
        switch type {
        case .power: return maxPower
        case .food: return maxFood
        case .water: return maxWater
        case .caps: return Double(Self.maxCaps)
        }
    }

    /// Get fill percentage for a resource type (0-100)
    func percentage(_ type: ResourceType) -> Double {
        let max = maximum(type)
        guard max > 0 else { return 0 }
        return (current(type) / max) * 100
    }

    /// Add resources (clamped to max)
    mutating func add(_ type: ResourceType, amount: Double) {
        switch type {
        case .power:
            power = min(power + amount, maxPower)
        case .food:
            food = min(food + amount, maxFood)
        case .water:
            water = min(water + amount, maxWater)
        case .caps:
            caps = min(caps + Int(amount), Self.maxCaps)
        }
    }

    /// Consume resources (returns actual amount consumed)
    @discardableResult
    mutating func consume(_ type: ResourceType, amount: Double) -> Double {
        switch type {
        case .power:
            let consumed = min(power, amount)
            power -= consumed
            return consumed
        case .food:
            let consumed = min(food, amount)
            food -= consumed
            return consumed
        case .water:
            let consumed = min(water, amount)
            water -= consumed
            return consumed
        case .caps:
            let consumed = min(Double(caps), amount)
            caps -= Int(consumed)
            return consumed
        }
    }

    /// Check if vault has enough of a resource
    func hasEnough(_ type: ResourceType, amount: Double) -> Bool {
        current(type) >= amount
    }

    /// Spend caps if available (returns true if successful)
    @discardableResult
    mutating func spendCaps(_ amount: Int) -> Bool {
        guard caps >= amount else { return false }
        caps -= amount
        return true
    }
}

// MARK: - Consumption Rates

public extension VaultResources {
    /// Food consumption rate per dweller per minute
    static let foodConsumptionPerDwellerPerMinute: Double = 0.36

    /// Water consumption rate per dweller per minute
    static let waterConsumptionPerDwellerPerMinute: Double = 0.36

    /// Calculate food consumption for given dweller count and time
    static func foodConsumption(dwellers: Int, minutes: Double) -> Double {
        Double(dwellers) * foodConsumptionPerDwellerPerMinute * minutes
    }

    /// Calculate water consumption for given dweller count and time
    static func waterConsumption(dwellers: Int, minutes: Double) -> Double {
        Double(dwellers) * waterConsumptionPerDwellerPerMinute * minutes
    }
}

// MARK: - Display

public extension VaultResources {
    /// Resource bar for Telegram display
    func resourceBar(_ type: ResourceType, segments: Int = 5) -> String {
        let pct = percentage(type) / 100.0
        let filled = Int(pct * Double(segments))
        let filledStr = String(repeating: "█", count: filled)
        let emptyStr = String(repeating: "░", count: segments - filled)
        return "[\(filledStr)\(emptyStr)]"
    }

    /// Full status display for Telegram
    var statusDisplay: String {
        """
        ⚡ Power: \(resourceBar(.power)) \(Int(power))/\(Int(maxPower))
        🍲 Food: \(resourceBar(.food)) \(Int(food))/\(Int(maxFood))
        💧 Water: \(resourceBar(.water)) \(Int(water))/\(Int(maxWater))
        💰 Caps: \(caps)
        """
    }

    /// Compact status for inline display
    var compactStatus: String {
        "⚡\(Int(power)) 🍲\(Int(food)) 💧\(Int(water)) 💰\(caps)"
    }
}
