//
//  Incident.swift
//  GameLogic
//
//  Active incident tracking and combat resolution
//

import Foundation

/// Represents an active incident in a vault room
public struct Incident: Codable, Sendable, Identifiable {
    public let id: UUID
    public let type: IncidentType
    public let roomID: UUID
    public let startTime: Date

    /// Current HP of the incident (damage dealt by dwellers reduces this)
    public var currentHP: Int

    /// Total HP the incident started with
    public let maxHP: Int

    /// Whether the incident is still active
    public var isActive: Bool

    /// Caps stolen (for raiders)
    public var capsStolen: Int

    /// Rooms the incident has spread to
    public var spreadRoomIDs: [UUID]

    /// Combat log entries
    public var combatLog: [IncidentCombatEntry]

    /// Initialize a new incident
    public init(
        id: UUID = UUID(),
        type: IncidentType,
        roomID: UUID,
        roomLevel: Int = 1,
        roomWidth: Int = 1,
        avgDwellerLevel: Int = 1
    ) {
        self.id = id
        self.type = type
        self.roomID = roomID
        self.startTime = Date()
        self.isActive = true
        self.capsStolen = 0
        self.spreadRoomIDs = []
        self.combatLog = []

        // Calculate HP based on scaling factors
        // HP scales with: room level, room width, average dweller level
        let levelMultiplier = 1.0 + (Double(roomLevel - 1) * 0.25)
        let widthMultiplier = Double(roomWidth)
        let dwellerLevelMultiplier = 1.0 + (Double(avgDwellerLevel - 1) * 0.02)
        let enemyCount = Double(type.baseEnemyCount)

        let totalHP = Int(Double(type.baseHP) * enemyCount * levelMultiplier * widthMultiplier * dwellerLevelMultiplier)
        self.maxHP = totalHP
        self.currentHP = totalHP
    }

    /// Calculate damage dealt by an incident attack
    public func rollDamage() -> Int {
        let range = type.baseDamageRange
        return Int.random(in: range.min...range.max)
    }

    /// Calculate damage dealt by a dweller (weapon damage + pet bonus)
    /// Note: S.P.E.C.I.A.L. has NO effect on vault incident combat!
    public static func dwellerDamage(weaponMin: Int, weaponMax: Int, petDamageBonus: Int) -> Int {
        let weaponDamage = Int.random(in: weaponMin...weaponMax)
        return weaponDamage + petDamageBonus
    }

    /// Apply damage to the incident
    public mutating func takeDamage(_ damage: Int, fromDweller dwellerName: String) {
        let actualDamage = min(damage, currentHP)
        currentHP -= actualDamage

        combatLog.append(IncidentCombatEntry(
            timestamp: Date(),
            type: .dwellerAttack,
            actorName: dwellerName,
            damage: actualDamage,
            description: "\(dwellerName) dealt \(actualDamage) damage"
        ))

        if currentHP <= 0 {
            isActive = false
            combatLog.append(IncidentCombatEntry(
                timestamp: Date(),
                type: .incidentDefeated,
                actorName: type.emoji,
                damage: 0,
                description: "Incident defeated!"
            ))
        }
    }

    /// Apply incident damage to a dweller
    public mutating func attackDweller(dwellerName: String, currentHP: inout Int, radiation: inout Int) -> (hpDamage: Int, radDamage: Int) {
        let hpDamage = rollDamage()
        currentHP = max(0, currentHP - hpDamage)

        var radDamage = 0
        if type.dealsRadiation {
            radDamage = type.radiationDamage
            radiation = min(100, radiation + radDamage)
        }

        combatLog.append(IncidentCombatEntry(
            timestamp: Date(),
            type: .incidentAttack,
            actorName: type.emoji,
            damage: hpDamage,
            radiationDamage: radDamage,
            description: "\(type.emoji) attacked \(dwellerName) for \(hpDamage) damage" +
                (radDamage > 0 ? " (+\(radDamage) rads)" : "")
        ))

        if currentHP <= 0 {
            combatLog.append(IncidentCombatEntry(
                timestamp: Date(),
                type: .dwellerDeath,
                actorName: dwellerName,
                damage: 0,
                description: "\(dwellerName) was killed!"
            ))
        }

        return (hpDamage, radDamage)
    }

    /// Steal caps (for raiders)
    public mutating func stealCaps(available: Int, deltaSeconds: Double) -> Int {
        guard type.stealsCaps else { return 0 }
        let stolen = min(available, Int(Double(type.capsStealRate) * deltaSeconds))
        capsStolen += stolen
        return stolen
    }

    /// Check if incident should spread to adjacent rooms
    public func shouldSpread(elapsed: TimeInterval) -> Bool {
        guard type.spreadsToEmptyRooms else { return false }
        // Spread every 30 seconds
        let spreadInterval: TimeInterval = 30
        let spreadCount = Int(elapsed / spreadInterval)
        return spreadCount > spreadRoomIDs.count
    }

    /// Mark the incident as spread to a new room
    public mutating func spreadToRoom(_ roomID: UUID) {
        if !spreadRoomIDs.contains(roomID) {
            spreadRoomIDs.append(roomID)
            // Increase HP when spreading
            let bonusHP = type.baseHP / 2
            currentHP += bonusHP
        }
    }

    /// Progress percentage (for display)
    public var progressPercent: Double {
        guard maxHP > 0 else { return 100 }
        return Double(maxHP - currentHP) / Double(maxHP) * 100
    }
}

/// Combat log entry for incident battles
public struct IncidentCombatEntry: Codable, Sendable {
    public let timestamp: Date
    public let type: IncidentCombatEntryType
    public let actorName: String
    public let damage: Int
    public let radiationDamage: Int
    public let description: String

    public init(
        timestamp: Date,
        type: IncidentCombatEntryType,
        actorName: String,
        damage: Int,
        radiationDamage: Int = 0,
        description: String
    ) {
        self.timestamp = timestamp
        self.type = type
        self.actorName = actorName
        self.damage = damage
        self.radiationDamage = radiationDamage
        self.description = description
    }
}

/// Types of combat log entries
public enum IncidentCombatEntryType: String, Codable, Sendable {
    case incidentStart
    case dwellerAttack
    case incidentAttack
    case dwellerDeath
    case incidentDefeated
    case incidentSpread
    case capsStolen
    case stimpakUsed
}

// MARK: - Rush Mechanics

public struct RushAttempt: Sendable {
    public let room: Room
    public let dwellers: [Dweller]
    public let recentRushCount: Int

    /// Calculate rush failure probability
    /// Formula: Fail% = 40 - 2 × (Avg_Luck + Avg_SPECIAL) + 10 × Recent_Rushes
    public var failureProbability: Double {
        guard !dwellers.isEmpty else { return 100 }

        let avgLuck = Double(dwellers.map { $0.baseStats.luck }.reduce(0, +)) / Double(dwellers.count)
        let avgSpecial = Double(dwellers.map { $0.baseStats.total }.reduce(0, +)) / Double(dwellers.count)

        let failPercent = 40.0 - 2.0 * (avgLuck + avgSpecial / 7.0) + 10.0 * Double(recentRushCount)
        return max(0, min(100, failPercent))
    }

    /// Attempt a rush
    public func attempt(population: Int, isNearDoor: Bool = false) -> RushResult {
        let roll = Double.random(in: 0...100)
        let failed = roll < failureProbability

        if failed {
            // Determine incident type based on population
            var availableTypes = IncidentType.rushFailureTypes(forPopulation: population)

            // Raiders only spawn if room is near vault door
            if !isNearDoor {
                availableTypes.removeAll { $0 == .raider }
            }

            let incidentType = availableTypes.randomElement() ?? .fire
            return RushResult(success: false, incidentType: incidentType, capsReward: 0, xpReward: 0)
        } else {
            // Success: reward caps and XP
            let caps = Int.random(in: 20...100)
            let xp = Int.random(in: 5...15) * dwellers.count
            return RushResult(success: true, incidentType: nil, capsReward: caps, xpReward: xp)
        }
    }

    public init(room: Room, dwellers: [Dweller], recentRushCount: Int) {
        self.room = room
        self.dwellers = dwellers
        self.recentRushCount = recentRushCount
    }
}

public struct RushResult: Sendable {
    public let success: Bool
    public let incidentType: IncidentType?
    public let capsReward: Int
    public let xpReward: Int
}
