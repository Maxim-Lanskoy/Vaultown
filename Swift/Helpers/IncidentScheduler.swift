//
//  IncidentScheduler.swift
//  Vaultown
//
//  Background scheduler for incident combat and spawning
//
//  Created by Maxim Lanskoy on 02.02.2026.
//

import Foundation
import Fluent
import GameLogic

/// Background scheduler that handles incident combat ticks, spreading, and random spawns
public actor IncidentScheduler {

    /// Interval between combat ticks (in seconds)
    private let combatTickInterval: TimeInterval = 5.0

    /// Minimum interval between random incidents (in seconds)
    /// Test: 2 min, Prod: 30 min
    private var minIncidentInterval: TimeInterval {
        isTestMode ? 2 * 60 : 30 * 60
    }

    /// Random incident spawn chance per check
    /// Test: 15%, Prod: 1%
    private var incidentSpawnChance: Double {
        isTestMode ? 0.15 : 0.01
    }

    /// Whether the scheduler is running
    private var isRunning = false

    /// Task handle for cancellation
    private var schedulerTask: Task<Void, Never>?

    /// Reference to app state
    private let appState: AppState

    /// Track last random incident time per vault
    private var lastRandomIncidentTime: [UUID: Date] = [:]

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

        appState.logger.info("IncidentScheduler started")
    }

    /// Stop the background scheduler
    public func stop() {
        isRunning = false
        schedulerTask?.cancel()
        schedulerTask = nil
        appState.logger.info("IncidentScheduler stopped")
    }

    /// Main run loop
    private func runLoop() async {
        var tickCount = 0
        while isRunning && !Task.isCancelled {
            do {
                try await processAllIncidents()

                // Every 12 ticks (60 seconds at 5s interval), try random incident for all vaults
                tickCount += 1
                if tickCount >= 12 {
                    tickCount = 0
                    try await tryRandomIncidentsForAllVaults()
                }
            } catch {
                appState.logger.error("IncidentScheduler error: \(error)")
            }

            // Wait for next tick
            try? await Task.sleep(for: .seconds(combatTickInterval))
        }
    }

    /// Try to spawn random incidents for all vaults
    private func tryRandomIncidentsForAllVaults() async throws {
        let vaults = try await Vault.query(on: appState.db).all()
        for vault in vaults {
            guard let vaultID = vault.id else { continue }
            try await tryRandomIncident(vaultID: vaultID)
        }
    }

    /// Process all active incidents
    private func processAllIncidents() async throws {
        let incidents = try await IncidentModel.query(on: appState.db)
            .filter(\IncidentModel.$isActive == true)
            .all()

        for incident in incidents {
            do {
                try await processIncident(incident)
            } catch {
                appState.logger.error("Error processing incident \(incident.type): \(error)")
            }
        }
    }

    /// Process a single active incident
    private func processIncident(_ incident: IncidentModel) async throws {
        guard var gameIncident = incident.toIncident(),
              let incidentType = incident.incidentType else {
            return
        }

        // Get dwellers in the room
        let dwellersInRoom = try await DwellerModel.query(on: appState.db)
            .filter(\.$assignedRoom.$id == incident.roomID)
            .filter(\.$currentHP > 0)
            .all()

        // If no dwellers and incident spreads, try to spread
        if dwellersInRoom.isEmpty && incidentType.spreadsToEmptyRooms {
            try await trySpreadIncident(incident)
            return
        }

        // Combat tick: dwellers attack incident, incident attacks dwellers
        for dweller in dwellersInRoom {
            // Dweller attacks incident
            // TODO: Load weapon from weaponID when weapons are implemented
            let weaponMin = 1
            let weaponMax = 2
            let petBonus = 0  // TODO: Add pet damage bonus

            let damage = Incident.dwellerDamage(
                weaponMin: weaponMin,
                weaponMax: weaponMax,
                petDamageBonus: petBonus
            )

            gameIncident.takeDamage(damage, fromDweller: dweller.fullName)

            // Check if incident defeated
            if !gameIncident.isActive {
                break
            }

            // Incident attacks back
            var hp = Int(dweller.currentHP)
            var rad = Int(dweller.radiation)
            _ = gameIncident.attackDweller(
                dwellerName: dweller.fullName,
                currentHP: &hp,
                radiation: &rad
            )

            // Update dweller
            dweller.currentHP = Double(hp)
            dweller.radiation = Double(rad)
            try await dweller.save(on: appState.db)

            // Check if dweller died
            if hp <= 0 {
                appState.logger.warning("Dweller \(dweller.fullName) killed by \(incidentType.rawValue)")
            }
        }

        // Handle raiders stealing caps
        if incidentType.stealsCaps {
            let vault = try await Vault.find(incident.$vault.id, on: appState.db)
            if let vault = vault {
                let stolen = gameIncident.stealCaps(available: vault.caps, deltaSeconds: combatTickInterval)
                if stolen > 0 {
                    vault.caps -= stolen
                    try await vault.save(on: appState.db)
                }
            }
        }

        // Update incident in database
        incident.update(from: gameIncident)
        try await incident.save(on: appState.db)

        // If incident defeated, give rewards
        if !gameIncident.isActive {
            try await giveIncidentRewards(incident, dwellers: dwellersInRoom)
        }
    }

    /// Try to spread an incident to adjacent empty rooms
    private func trySpreadIncident(_ incident: IncidentModel) async throws {
        guard let incidentType = incident.incidentType,
              incidentType.spreadsToEmptyRooms else {
            return
        }

        // Get the room
        guard let room = try await RoomModel.find(incident.roomID, on: appState.db) else {
            return
        }

        // Get all rooms in the vault
        let allRooms = try await RoomModel.query(on: appState.db)
            .filter(\.$vault.$id == incident.$vault.id)
            .all()

        // Find adjacent rooms on the same floor that are empty
        let currentSpreadIDs = incident.spreadRoomIDs
        var availableToSpread: [RoomModel] = []

        for otherRoom in allRooms {
            guard let otherRoomID = otherRoom.id,
                  otherRoom.y == room.y,  // Same floor
                  !currentSpreadIDs.contains(otherRoomID),
                  otherRoomID != incident.roomID else {
                continue
            }

            // Check if adjacent
            let roomEndX = room.x + room.width
            let otherEndX = otherRoom.x + otherRoom.width

            if otherRoom.x == roomEndX || otherEndX == room.x {
                // Check if room is empty
                let dwellerCount = try await otherRoom.assignedCount(on: appState.db)
                if dwellerCount == 0 {
                    availableToSpread.append(otherRoom)
                }
            }
        }

        // Spread to one random adjacent empty room
        if let targetRoom = availableToSpread.randomElement(), let targetID = targetRoom.id {
            var gameIncident = incident.toIncident()!
            gameIncident.spreadToRoom(targetID)
            incident.update(from: gameIncident)
            try await incident.save(on: appState.db)

            appState.logger.info("Incident \(incidentType.rawValue) spread to room at [\(targetRoom.x),\(targetRoom.y)]")
        }
    }

    /// Give rewards for defeating an incident
    private func giveIncidentRewards(_ incident: IncidentModel, dwellers: [DwellerModel]) async throws {
        guard let incidentType = incident.incidentType else { return }

        let xpPerDweller = incidentType.xpReward / max(1, dwellers.count)

        for dweller in dwellers {
            dweller.experience += xpPerDweller
            // Check for level up
            while dweller.experience >= Dweller.xpForLevel(dweller.level + 1) && dweller.level < 50 {
                dweller.level += 1
                // Increase max HP based on Endurance
                let hpGain = Dweller.hpPerLevel(endurance: dweller.endurance)
                dweller.maxHP += hpGain
            }
            try await dweller.save(on: appState.db)
        }

        // Caps reward (raiders drop their stolen caps back)
        if incident.capsStolen > 0 || incidentType.capsReward > 0 {
            let vault = try await Vault.find(incident.$vault.id, on: appState.db)
            if let vault = vault {
                vault.caps += incident.capsStolen + incidentType.capsReward
                try await vault.save(on: appState.db)
            }
        }

        appState.logger.info("Incident \(incidentType.rawValue) defeated, \(xpPerDweller) XP per dweller")
    }

    // MARK: - Random Incident Spawning

    /// Spawn a random incident for a vault (called from rush failure or random event)
    public func spawnIncident(
        vaultID: UUID,
        roomID: UUID,
        type: IncidentType,
        roomLevel: Int = 1,
        roomWidth: Int = 1
    ) async throws {
        // Get average dweller level for scaling
        let dwellers = try await DwellerModel.query(on: appState.db)
            .filter(\.$vault.$id == vaultID)
            .all()
        let avgLevel = dwellers.isEmpty ? 1 : dwellers.reduce(0) { $0 + $1.level } / dwellers.count

        let incident = Incident(
            type: type,
            roomID: roomID,
            roomLevel: roomLevel,
            roomWidth: roomWidth,
            avgDwellerLevel: avgLevel
        )

        let incidentModel = IncidentModel(vaultID: vaultID, incident: incident)
        try await incidentModel.save(on: appState.db)

        // Send alert to vault owner
        try await Controllers.vaultController.sendIncidentAlert(
            vaultID: vaultID,
            incident: incident,
            on: appState.db,
            bot: appState.bot,
            lingo: appState.lingo
        )

        appState.logger.info("Spawned \(type.rawValue) incident in vault")
    }

    /// Attempt random incident spawn (called periodically or from radio station)
    public func tryRandomIncident(vaultID: UUID) async throws {
        // Check cooldown
        let now = Date()
        if let lastTime = lastRandomIncidentTime[vaultID],
           now.timeIntervalSince(lastTime) < minIncidentInterval {
            appState.logger.debug("Incident cooldown active for vault")
            return
        }

        // Get vault and population
        guard let vault = try await Vault.find(vaultID, on: appState.db) else { return }
        let population = try await vault.dwellerCount(on: appState.db)

        // Get available incident types
        let availableTypes = IncidentType.availableTypes(forPopulation: population)
        guard !availableTypes.isEmpty else {
            appState.logger.debug("No incident types available for population \(population)")
            return
        }

        // Random chance per check
        let roll = Double.random(in: 0...1)
        appState.logger.debug("Incident roll: \(roll) (need < \(incidentSpawnChance)), population: \(population), types: \(availableTypes.map { $0.rawValue })")
        guard roll < incidentSpawnChance else { return }

        // Pick random type (weighted toward less severe)
        let weights = availableTypes.map { type -> Double in
            switch type {
            case .fire: return 5.0
            case .radroach: return 4.0
            case .moleRat: return 3.0
            case .raider: return 2.0
            case .feralGhoul: return 1.5
            case .radscorpion: return 1.0
            case .deathclaw: return 0.5
            }
        }
        let totalWeight = weights.reduce(0, +)
        var random = Double.random(in: 0..<totalWeight)
        var selectedType = availableTypes.first!

        for (index, type) in availableTypes.enumerated() {
            random -= weights[index]
            if random <= 0 {
                selectedType = type
                break
            }
        }

        // Pick random room
        let rooms = try await RoomModel.query(on: appState.db)
            .filter(\.$vault.$id == vaultID)
            .all()
            .filter { $0.roomType != .elevator && $0.roomType != .vaultDoor }

        guard let targetRoom = rooms.randomElement(), let roomID = targetRoom.id else { return }

        // Spawn incident
        try await spawnIncident(
            vaultID: vaultID,
            roomID: roomID,
            type: selectedType,
            roomLevel: targetRoom.level,
            roomWidth: targetRoom.width
        )

        lastRandomIncidentTime[vaultID] = now
    }
}

/// Global incident scheduler instance
public nonisolated(unsafe) var incidentScheduler: IncidentScheduler?
