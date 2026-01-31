//
//  ResourceScheduler.swift
//  Vaultown
//
//  Background scheduler for resource consumption and vault updates
//

import Foundation
import Fluent
import GameLogic

/// Background scheduler that handles resource consumption, production, and vault events
public actor ResourceScheduler {

    /// Consumption rate per dweller per minute (from GDD)
    private let consumptionRatePerMinute: Double = 0.36

    /// Health damage per minute when food is depleted
    private let healthDamagePerMinute: Double = 1.0

    /// Radiation damage per minute when water is depleted
    private let radiationDamagePerMinute: Double = 0.5

    /// Base production cycle time in seconds (1 minute)
    private let baseProductionCycleTime: Double = 60.0

    /// Base production amount per cycle per level
    private let baseProductionPerLevel: [Int: Double] = [1: 10.0, 2: 12.0, 3: 15.0]

    /// Interval between scheduler ticks (in seconds)
    private let tickInterval: TimeInterval = 60.0 // 1 minute

    /// Whether the scheduler is running
    private var isRunning = false

    /// Task handle for cancellation
    private var schedulerTask: Task<Void, Never>?

    /// Reference to app state
    private let appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    /// Start the background scheduler
    public func start() {
        guard !isRunning else { return }
        isRunning = true

        schedulerTask = Task { [weak self] in
            await self?.runLoop()
        }

        appState.logger.info("ResourceScheduler started")
    }

    /// Stop the background scheduler
    public func stop() {
        isRunning = false
        schedulerTask?.cancel()
        schedulerTask = nil
        appState.logger.info("ResourceScheduler stopped")
    }

    /// Main run loop
    private func runLoop() async {
        while isRunning && !Task.isCancelled {
            do {
                try await processAllVaults()
            } catch {
                appState.logger.error("ResourceScheduler error: \(error)")
            }

            // Wait for next tick
            try? await Task.sleep(for: .seconds(tickInterval))
        }
    }

    /// Process all vaults for resource consumption
    private func processAllVaults() async throws {
        let vaults = try await Vault.query(on: appState.db).all()

        for vault in vaults {
            do {
                try await processVault(vault)
            } catch {
                appState.logger.error("Error processing vault \(vault.vaultNumber): \(error)")
            }
        }
    }

    /// Process a single vault's resource consumption
    private func processVault(_ vault: Vault) async throws {
        guard let vaultID = vault.id else { return }

        // Get current time and calculate time since last update
        let now = Date()
        let lastUpdate = vault.lastUpdate
        let elapsedMinutes = now.timeIntervalSince(lastUpdate) / 60.0

        // Skip if very little time has passed (less than 0.1 minute)
        guard elapsedMinutes >= 0.1 else { return }

        // Get all rooms and dwellers for this vault
        let rooms = try await RoomModel.query(on: appState.db)
            .filter(\RoomModel.$vault.$id, .equal, vaultID)
            .all()

        let dwellers = try await DwellerModel.query(on: appState.db)
            .filter(\DwellerModel.$vault.$id, .equal, vaultID)
            .with(\.$assignedRoom)
            .all()

        let dwellerCount = dwellers.count
        guard dwellerCount > 0 else {
            // No dwellers, just update timestamp
            vault.lastUpdate = now
            try await vault.save(on: appState.db)
            return
        }

        // 1. Update power balance
        try await updatePowerBalance(vault: vault, rooms: rooms, dwellers: dwellers, elapsedMinutes: elapsedMinutes)

        // 2. Process production rooms
        try await processProduction(vault: vault, rooms: rooms, dwellers: dwellers, elapsedMinutes: elapsedMinutes)

        // 3. Calculate consumption
        let totalConsumption = consumptionRatePerMinute * Double(dwellerCount) * elapsedMinutes

        // Consume food
        let previousFood = vault.food
        vault.food = max(0, vault.food - totalConsumption)

        // Consume water
        let previousWater = vault.water
        vault.water = max(0, vault.water - totalConsumption)

        // Apply consequences for depleted resources
        if vault.food <= 0 && previousFood > 0 {
            // Food just depleted - dwellers start losing health
            try await applyHealthDamage(vaultID: vaultID, elapsedMinutes: elapsedMinutes)
            appState.logger.warning("Vault \(vault.vaultNumber): Food depleted!")
        } else if vault.food <= 0 {
            // Food was already depleted - continue health damage
            try await applyHealthDamage(vaultID: vaultID, elapsedMinutes: elapsedMinutes)
        }

        if vault.water <= 0 && previousWater > 0 {
            // Water just depleted - dwellers start taking radiation
            try await applyRadiationDamage(vaultID: vaultID, elapsedMinutes: elapsedMinutes)
            appState.logger.warning("Vault \(vault.vaultNumber): Water depleted!")
        } else if vault.water <= 0 {
            // Water was already depleted - continue radiation damage
            try await applyRadiationDamage(vaultID: vaultID, elapsedMinutes: elapsedMinutes)
        }

        // Update timestamp
        vault.lastUpdate = now

        // Save vault
        try await vault.save(on: appState.db)
    }

    /// Apply health damage to all dwellers in a vault when food is depleted
    private func applyHealthDamage(vaultID: UUID, elapsedMinutes: Double) async throws {
        let dwellers = try await DwellerModel.query(on: appState.db)
            .filter(\DwellerModel.$vault.$id, .equal, vaultID)
            .all()

        let damage = healthDamagePerMinute * elapsedMinutes

        for dweller in dwellers {
            dweller.currentHP = max(0, dweller.currentHP - damage)
            try await dweller.save(on: appState.db)
        }
    }

    /// Apply radiation damage to all dwellers in a vault when water is depleted
    private func applyRadiationDamage(vaultID: UUID, elapsedMinutes: Double) async throws {
        let dwellers = try await DwellerModel.query(on: appState.db)
            .filter(\DwellerModel.$vault.$id, .equal, vaultID)
            .all()

        let radiation = radiationDamagePerMinute * elapsedMinutes

        for dweller in dwellers {
            dweller.radiation = min(100, dweller.radiation + radiation)
            try await dweller.save(on: appState.db)
        }
    }

    // MARK: - Power Balance

    /// Update power balance for a vault - turn off rooms if not enough power
    private func updatePowerBalance(vault: Vault, rooms: [RoomModel], dwellers: [DwellerModel], elapsedMinutes: Double) async throws {
        // Calculate total power consumption per minute (all rooms except elevators)
        var totalConsumptionPerMin = 0.0
        for room in rooms {
            // Power consumption = width * level per minute
            totalConsumptionPerMin += Double(room.powerConsumption)
        }

        // Calculate power production per minute (from power generators with assigned dwellers)
        var totalProductionPerMin = 0.0
        for room in rooms {
            guard let roomType = room.roomType,
                  roomType.producesResource == .power,
                  room.hasPower else { continue }

            // Count assigned dwellers for this room
            let assignedDwellers = dwellers.filter { $0.$assignedRoom.id == room.id }
            guard !assignedDwellers.isEmpty else { continue }

            // Base production per level, scaled by room width
            let baseProduction = baseProductionPerLevel[room.level] ?? 10.0
            let widthMultiplier = Double(room.width)

            // Calculate total SPECIAL stat bonus (Strength for power rooms)
            let totalStrength = assignedDwellers.reduce(0) { $0 + $1.strength }
            let statBonus = Double(totalStrength) / 5.0  // More impactful bonus

            // Calculate average happiness bonus
            let avgHappiness = assignedDwellers.reduce(0.0) { $0 + $1.happiness } / Double(assignedDwellers.count)
            let happinessBonus = avgHappiness / 100.0 * 2.0  // Up to +2 per 100% happiness

            // Dweller count bonus
            let dwellerBonus = Double(assignedDwellers.count) * 5.0

            let productionPerMin = baseProduction * widthMultiplier + dwellerBonus + statBonus + happinessBonus
            totalProductionPerMin += productionPerMin
        }

        // Calculate net power change over elapsed time
        let netPowerChange = (totalProductionPerMin - totalConsumptionPerMin) * elapsedMinutes

        // Update vault power (as a buffer that fills/drains)
        let newPower = vault.power + netPowerChange
        vault.power = max(0, min(vault.maxPower, newPower))

        // Log power status periodically
        if netPowerChange != 0 {
            appState.logger.info("Vault \(vault.vaultNumber): Power +\(Int(totalProductionPerMin))/min -\(Int(totalConsumptionPerMin))/min = \(Int(vault.power))/\(Int(vault.maxPower))")
        }

        // Determine which rooms have power based on vault power level
        // If power > 0, all rooms are powered
        // If power <= 0, rooms lose power from deepest floors first
        if vault.power > 0 {
            // All rooms have power
            for room in rooms {
                if !room.hasPower {
                    room.hasPower = true
                    try await room.save(on: appState.db)
                    appState.logger.info("Vault \(vault.vaultNumber): Room at [\(room.x),\(room.y)] regained power")
                }
            }
        } else {
            // Power depleted - turn off rooms from deepest floors first
            let sortedRooms = rooms.sorted { $0.y > $1.y }  // Deepest first
            var roomsToTurnOff = sortedRooms.count / 2  // Turn off half the rooms when depleted

            for room in sortedRooms {
                if roomsToTurnOff > 0 && room.roomType != .elevator && room.roomType != .vaultDoor {
                    if room.hasPower {
                        room.hasPower = false
                        try await room.save(on: appState.db)
                        appState.logger.warning("Vault \(vault.vaultNumber): Room at [\(room.x),\(room.y)] lost power!")
                    }
                    roomsToTurnOff -= 1
                }
            }
        }
    }

    // MARK: - Production

    /// Process production for all production rooms
    private func processProduction(vault: Vault, rooms: [RoomModel], dwellers: [DwellerModel], elapsedMinutes: Double) async throws {
        for room in rooms {
            guard let roomType = room.roomType,
                  roomType.isProductionRoom,
                  room.hasPower else { continue }

            // Get assigned dwellers
            let assignedDwellers = dwellers.filter { $0.$assignedRoom.id == room.id }

            // No dwellers = no production
            if assignedDwellers.isEmpty {
                if room.productionState != RoomProductionState.idle.rawValue {
                    room.productionState = RoomProductionState.idle.rawValue
                    room.productionProgress = 0
                    try await room.save(on: appState.db)
                }
                continue
            }

            // If room was idle, start producing
            if room.productionState == RoomProductionState.idle.rawValue {
                room.productionState = RoomProductionState.producing.rawValue
                room.productionProgress = 0
                room.lastProductionUpdate = Date()
            }

            // Calculate production speed based on dweller stats
            // Get primary stat for this room type
            let primaryStat = roomType.primaryStat
            let totalStat: Int
            if let stat = primaryStat {
                totalStat = assignedDwellers.reduce(0) { total, dweller in
                    total + dweller.toDweller().baseStats.base(stat)
                }
            } else {
                totalStat = 0
            }

            // Calculate average happiness
            let avgHappiness = assignedDwellers.reduce(0.0) { $0 + $1.happiness } / Double(assignedDwellers.count)

            // Calculate cycle time: Base_Time / (1 + Total_SPECIAL / 10 + Happiness_Bonus)
            let statBonus = Double(totalStat) / 10.0
            let happinessBonus = avgHappiness / 100.0 * 0.1
            let divisor = 1.0 + statBonus + happinessBonus
            let cycleTimeSeconds = baseProductionCycleTime / divisor
            let cycleTimeMinutes = cycleTimeSeconds / 60.0

            // Calculate progress increment (as fraction of cycle completed)
            let progressIncrement = elapsedMinutes / cycleTimeMinutes

            // Update progress
            room.productionProgress += progressIncrement
            room.lastProductionUpdate = Date()

            // Check if production cycle complete
            if room.productionProgress >= 1.0 {
                // Calculate how many cycles completed
                let cyclesCompleted = Int(room.productionProgress)
                room.productionProgress = room.productionProgress.truncatingRemainder(dividingBy: 1.0)

                // Calculate production amount
                let baseAmount = baseProductionPerLevel[room.level] ?? 10.0
                let widthMultiplier = Double(room.width)
                let productionAmount = baseAmount * widthMultiplier * Double(cyclesCompleted)

                // Add resources to vault based on room type
                if let resource = roomType.producesResource {
                    switch resource {
                    case .power:
                        // Power is handled in power balance, but we can add surplus
                        vault.power = min(vault.maxPower, vault.power + productionAmount)
                    case .food:
                        vault.food = min(vault.maxFood, vault.food + productionAmount)
                    case .water:
                        vault.water = min(vault.maxWater, vault.water + productionAmount)
                    case .caps:
                        vault.caps += Int(productionAmount)
                    }
                    appState.logger.info("Vault \(vault.vaultNumber): Produced \(Int(productionAmount)) \(resource.rawValue)")
                } else if roomType.producesFoodAndWater {
                    // Nuka-Cola produces both food and water
                    let halfAmount = productionAmount / 2.0
                    vault.food = min(vault.maxFood, vault.food + halfAmount)
                    vault.water = min(vault.maxWater, vault.water + halfAmount)
                    appState.logger.info("Vault \(vault.vaultNumber): Nuka-Cola produced \(Int(halfAmount)) food and water")
                }
            }

            try await room.save(on: appState.db)
        }
    }
}

/// Global scheduler instance
public nonisolated(unsafe) var resourceScheduler: ResourceScheduler?
