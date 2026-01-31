//
//  Vault.swift
//  Vaultown
//
//  Fluent model for player vaults
//

import Fluent
import Foundation
import GameLogic

/// Database model for a player's vault
final public class Vault: Model, @unchecked Sendable {
    public static let schema = "vaults"

    @ID(key: .id)
    public var id: UUID?

    /// Reference to the owning user
    @Parent(key: "user_id")
    var user: User

    /// Unique vault number (never reused, even after deletion)
    @Field(key: "vault_number")
    var vaultNumber: Int64

    /// Vault name (customizable by player)
    @Field(key: "name")
    var name: String

    /// Current power level
    @Field(key: "power")
    var power: Double

    /// Maximum power storage
    @Field(key: "max_power")
    var maxPower: Double

    /// Current food level
    @Field(key: "food")
    var food: Double

    /// Maximum food storage
    @Field(key: "max_food")
    var maxFood: Double

    /// Current water level
    @Field(key: "water")
    var water: Double

    /// Maximum water storage
    @Field(key: "max_water")
    var maxWater: Double

    /// Current caps
    @Field(key: "caps")
    var caps: Int

    /// Stimpak count
    @Field(key: "stimpaks")
    var stimpaks: Int

    /// RadAway count
    @Field(key: "radaway")
    var radaway: Int

    /// Maximum population (from Living Quarters)
    @Field(key: "population_cap")
    var populationCap: Int

    /// Last resource update timestamp
    @Field(key: "last_update")
    var lastUpdate: Date

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    /// Children relationship to dwellers
    @Children(for: \.$vault)
    var dwellers: [DwellerModel]

    /// Children relationship to rooms
    @Children(for: \.$vault)
    var rooms: [RoomModel]

    public init() {}

    /// Create a new vault with starting resources
    init(
        id: UUID? = nil,
        userID: User.IDValue,
        vaultNumber: Int64,
        name: String? = nil
    ) {
        self.id = id
        self.$user.id = userID
        self.vaultNumber = vaultNumber
        self.name = name ?? "Vault \(vaultNumber)"

        // Starting resources from GDD
        self.power = 50
        self.maxPower = 100
        self.food = 50
        self.maxFood = 100
        self.water = 50
        self.maxWater = 100
        self.caps = 500
        self.stimpaks = 2
        self.radaway = 2
        self.populationCap = 8  // One Living Quarters
        self.lastUpdate = Date()
    }
}

// MARK: - GameLogic Integration

extension Vault {
    /// Convert to GameLogic VaultResources struct
    var resources: VaultResources {
        VaultResources(
            power: power,
            maxPower: maxPower,
            food: food,
            maxFood: maxFood,
            water: water,
            maxWater: maxWater,
            caps: caps
        )
    }

    /// Update from GameLogic VaultResources struct
    func updateResources(_ resources: VaultResources) {
        self.power = resources.power
        self.maxPower = resources.maxPower
        self.food = resources.food
        self.maxFood = resources.maxFood
        self.water = resources.water
        self.maxWater = resources.maxWater
        self.caps = resources.caps
    }

    /// Get current dweller count
    func dwellerCount(on db: any Database) async throws -> Int {
        try await DwellerModel.query(on: db)
            .filter(\.$vault.$id == self.id!)
            .count()
    }

    /// Check if vault can accept more dwellers
    func canAddDweller(on db: any Database) async throws -> Bool {
        let count = try await dwellerCount(on: db)
        return count < populationCap
    }
}

// MARK: - Display

extension Vault {
    /// Localized status display for Telegram
    func localizedStatusDisplay(
        dwellerCount: Int,
        vaultName: String,
        population: String,
        power: String,
        food: String,
        water: String,
        caps: String,
        stimpaksLabel: String,
        radawayLabel: String
    ) -> String {
        """
        🏠 \(vaultName) #\(vaultNumber)
        👥 \(population): \(dwellerCount)/\(populationCap)

        ⚡ \(power): \(resources.resourceBar(.power)) \(Int(self.power))/\(Int(maxPower))
        🍲 \(food): \(resources.resourceBar(.food)) \(Int(self.food))/\(Int(maxFood))
        💧 \(water): \(resources.resourceBar(.water)) \(Int(self.water))/\(Int(maxWater))
        💰 \(caps): \(self.caps)

        💊 \(stimpaksLabel): \(stimpaks)
        ☢️ \(radawayLabel): \(radaway)
        """
    }

    /// Compact status for inline display
    var compactStatus: String {
        "\(resources.compactStatus) 💊\(stimpaks) ☢️\(radaway)"
    }
}

// MARK: - Vault Queries

extension Vault {
    /// Get vault for a user (creates if not exists)
    static func forUser(_ user: User, on db: any Database) async throws -> Vault {
        if let existing = try await Vault.query(on: db)
            .filter(\.$user.$id == user.id!)
            .first() {
            return existing
        }

        // Get next unique vault number
        let vaultNumber = try await GlobalCounter.nextVaultNumber(on: db)

        // Create new vault
        let vault = Vault(userID: user.id!, vaultNumber: vaultNumber)
        try await vault.save(on: db)

        // Create starting rooms (per GDD)
        let startingRooms = RoomModel.createStartingRooms(vaultID: vault.id!)
        for room in startingRooms {
            try await room.save(on: db)
        }

        // Create player's dweller first (using nickname)
        if let nickname = user.nickname, !nickname.isEmpty {
            let playerDweller = DwellerModel.createPlayerDweller(vaultID: vault.id!, nickname: nickname, rarity: .common)
            try await playerDweller.save(on: db)
        }

        // Create 2 more random dwellers with user's locale for ethnic names
        for _ in 1...2 {
            let dweller = DwellerModel.createRandom(vaultID: vault.id!, rarity: .common, locale: user.locale)
            try await dweller.save(on: db)
        }

        return vault
    }

    /// Get rooms for this vault
    func getRooms(on db: any Database) async throws -> [RoomModel] {
        try await RoomModel.query(on: db)
            .filter(\.$vault.$id == self.id!)
            .all()
    }

    /// Get room at specific position
    func getRoom(at x: Int, y: Int, on db: any Database) async throws -> RoomModel? {
        try await RoomModel.query(on: db)
            .filter(\.$vault.$id == self.id!)
            .filter(\.$x == x)
            .filter(\.$y == y)
            .first()
    }
}
