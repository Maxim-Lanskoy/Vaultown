//
//  ExplorationScheduler.swift
//  Vaultown
//
//  Background scheduler for exploration event generation
//
//  Created by Maxim Lanskoy on 02.02.2026.
//

import Foundation
import Fluent
import GameLogic

/// Background scheduler that handles exploration events and return timing
public actor ExplorationScheduler {

    /// Interval between scheduler ticks (in seconds)
    private let tickInterval: TimeInterval = 60.0 // 1 minute

    /// Average interval between events in minutes
    /// Test: 5 min, Prod: 30 min (per GDD)
    private var averageEventInterval: Int {
        isTestMode ? 5 : 30
    }

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

        appState.logger.info("ExplorationScheduler started")
    }

    /// Stop the background scheduler
    public func stop() {
        isRunning = false
        schedulerTask?.cancel()
        schedulerTask = nil
        appState.logger.info("ExplorationScheduler stopped")
    }

    /// Main run loop
    private func runLoop() async {
        while isRunning && !Task.isCancelled {
            do {
                try await processAllExplorations()
            } catch {
                appState.logger.error("ExplorationScheduler error: \(error)")
            }

            // Wait for next tick
            try? await Task.sleep(for: .seconds(tickInterval))
        }
    }

    /// Process all active explorations
    private func processAllExplorations() async throws {
        let explorations = try await ExplorationModel.query(on: appState.db)
            .filter(\ExplorationModel.$status, .notEqual, "completed")
            .all()

        for exploration in explorations {
            do {
                try await processExploration(exploration)
            } catch {
                appState.logger.error("Error processing exploration \(exploration.dwellerName): \(error)")
            }
        }
    }

    /// Process a single exploration
    private func processExploration(_ exploration: ExplorationModel) async throws {
        let currentMinute = exploration.explorationMinutes

        switch exploration.statusEnum {
        case .exploring:
            try await processExploringDweller(exploration, currentMinute: currentMinute)

        case .returning:
            try await processReturningDweller(exploration)

        case .completed, .dead:
            // Nothing to process
            break
        }
    }

    /// Process an actively exploring dweller
    private func processExploringDweller(_ exploration: ExplorationModel, currentMinute: Int) async throws {
        // Check if inventory is full - start return
        if exploration.itemsCollected >= Exploration.maxItems {
            exploration.status = ExplorationStatus.returning.rawValue
            exploration.returnStartTime = Date()
            try await exploration.save(on: appState.db)
            appState.logger.info("Explorer \(exploration.dwellerName) inventory full, returning")
            return
        }

        // Check if dead
        if exploration.currentHP <= 0 {
            exploration.status = ExplorationStatus.dead.rawValue
            try await exploration.save(on: appState.db)
            appState.logger.info("Explorer \(exploration.dwellerName) died")
            return
        }

        // Generate events based on elapsed time
        let lastEventMinute = exploration.lastEventMinute

        // Check if enough time has passed for a new event
        let minutesSinceLastEvent = currentMinute - lastEventMinute

        // First 60 minutes: guaranteed loot at 60 min mark
        if lastEventMinute < 60 && currentMinute >= 60 {
            try await generateEvent(for: exploration, timestamp: 60, forceType: .lootDiscovery)
            exploration.lastEventMinute = 60
        }

        // After that: random events every ~30 minutes (with some variance)
        let eventThreshold = averageEventInterval + Int.random(in: -10...10)
        if minutesSinceLastEvent >= eventThreshold {
            try await generateEvent(for: exploration, timestamp: currentMinute, forceType: nil)
            exploration.lastEventMinute = currentMinute
        }

        try await exploration.save(on: appState.db)
    }

    /// Process a returning dweller
    private func processReturningDweller(_ exploration: ExplorationModel) async throws {
        let returnProgress = exploration.returnProgress

        if returnProgress >= 1.0 {
            // Dweller has arrived
            exploration.status = ExplorationStatus.completed.rawValue
            try await exploration.save(on: appState.db)
            appState.logger.info("Explorer \(exploration.dwellerName) has returned to vault")
        }
    }

    /// Generate an event for an exploration
    private func generateEvent(for exploration: ExplorationModel, timestamp: Int, forceType: ExplorationEventType?) async throws {
        var gameExploration = exploration.toExploration()

        let event: ExplorationEvent?

        if let forcedType = forceType {
            // Generate specific event type
            switch forcedType {
            case .lootDiscovery:
                event = Exploration.generateEvent(exploration: &gameExploration, timestamp: timestamp)
            default:
                event = Exploration.generateEvent(exploration: &gameExploration, timestamp: timestamp)
            }
        } else {
            // Generate random event
            event = Exploration.generateEvent(exploration: &gameExploration, timestamp: timestamp)
        }

        if let event = event {
            appState.logger.debug("Explorer \(exploration.dwellerName): \(event.type.rawValue) at \(timestamp) min")
        }

        // Update the model from the game exploration
        exploration.update(from: gameExploration)
    }
}

/// Global exploration scheduler instance
public nonisolated(unsafe) var explorationScheduler: ExplorationScheduler?
