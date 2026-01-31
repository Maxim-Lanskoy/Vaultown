//
//  RoomModel.swift
//  Vaultown
//
//  Fluent model for vault rooms
//

import Fluent
import Foundation
import GameLogic

/// Database model for a room in a vault
final public class RoomModel: Model, @unchecked Sendable {
    public static let schema = "rooms"

    @ID(key: .id)
    public var id: UUID?

    /// Reference to the owning vault
    @Parent(key: "vault_id")
    var vault: Vault

    /// Room type (stored as raw string)
    @Field(key: "type")
    var type: String

    /// Room level (1, 2, or 3)
    @Field(key: "level")
    var level: Int

    /// X position in vault grid (column)
    @Field(key: "x")
    var x: Int

    /// Y position in vault grid (floor/row)
    @Field(key: "y")
    var y: Int

    /// Width of the room (1=single, 2=double, 3=triple)
    @Field(key: "width")
    var width: Int

    /// Production state (idle, producing, ready, rushing)
    @Field(key: "production_state")
    var productionState: String

    /// Current production progress (0.0 - 1.0)
    @Field(key: "production_progress")
    var productionProgress: Double

    /// Last production update timestamp
    @Field(key: "last_production_update")
    var lastProductionUpdate: Date

    /// Whether room has power
    @Field(key: "has_power")
    var hasPower: Bool

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    /// Children relationship to assigned dwellers
    @Children(for: \.$assignedRoom)
    var assignedDwellers: [DwellerModel]

    public init() {}

    /// Initialize a new room
    init(
        id: UUID? = nil,
        vaultID: Vault.IDValue,
        type: RoomType,
        level: RoomLevel = .level1,
        x: Int,
        y: Int,
        width: RoomWidth = .single
    ) {
        self.id = id
        self.$vault.id = vaultID
        self.type = type.rawValue
        self.level = level.rawValue
        self.x = x
        self.y = y
        self.width = width.rawValue
        self.productionState = RoomProductionState.idle.rawValue
        self.productionProgress = 0
        self.lastProductionUpdate = Date()
        self.hasPower = true
    }
}

// MARK: - GameLogic Integration

public extension RoomModel {
    /// Get the RoomType enum value
    var roomType: RoomType? {
        RoomType(rawValue: type)
    }

    /// Get the RoomLevel enum value
    var roomLevel: RoomLevel {
        RoomLevel(rawValue: level) ?? .level1
    }

    /// Get the RoomWidth enum value
    var roomWidth: RoomWidth {
        RoomWidth(rawValue: width) ?? .single
    }

    /// Get the production state enum value
    var roomProductionState: RoomProductionState {
        RoomProductionState(rawValue: productionState) ?? .idle
    }

    /// Convert to GameLogic Room struct
    func toRoom(assignedDwellerIDs: [UUID] = []) -> Room? {
        guard let roomType = roomType else { return nil }

        return Room(
            id: id ?? UUID(),
            type: roomType,
            level: roomLevel,
            x: x,
            y: y,
            width: roomWidth,
            assignedDwellerIDs: assignedDwellerIDs,
            productionState: roomProductionState,
            productionProgress: productionProgress,
            lastProductionUpdate: lastProductionUpdate,
            hasPower: hasPower
        )
    }

    /// Update from GameLogic Room struct
    func update(from room: Room) {
        self.level = room.level.rawValue
        self.width = room.width.rawValue
        self.productionState = room.productionState.rawValue
        self.productionProgress = room.productionProgress
        self.lastProductionUpdate = room.lastProductionUpdate
        self.hasPower = room.hasPower
    }
}

// MARK: - Room Capacity

public extension RoomModel {
    /// Maximum dweller capacity for this room
    var capacity: Int {
        roomType?.capacity(width: width) ?? 0
    }

    /// Get assigned dweller count
    func assignedCount(on db: any Database) async throws -> Int {
        try await DwellerModel.query(on: db)
            .filter(\DwellerModel.$assignedRoom.$id, .equal, self.id)
            .count()
    }

    /// Check if room can accept more dwellers
    func canAssignMore(on db: any Database) async throws -> Bool {
        let count = try await assignedCount(on: db)
        return count < capacity
    }
}

// MARK: - Room Costs

public extension RoomModel {
    /// Total build cost for this room
    var totalBuildCost: Int {
        guard let roomType = roomType else { return 0 }
        return Int(Double(roomType.baseBuildCost) * roomWidth.buildCostMultiplier)
    }

    /// Cost to upgrade to next level
    var upgradeCost: Int? {
        guard let roomType = roomType,
              let nextLevel = roomLevel.next else { return nil }
        let baseCost = Double(roomType.baseBuildCost) * nextLevel.upgradeCostMultiplier
        return Int(baseCost * roomWidth.upgradeDiscount)
    }

    /// Power consumption of this room
    var powerConsumption: Int {
        roomType?.powerConsumption(width: width, level: level) ?? 0
    }
}

// MARK: - Display

public extension RoomModel {
    /// Short display for Telegram
    var shortDescription: String {
        guard let roomType = roomType else { return "Unknown Room" }
        return "\(roomType.emoji) \(roomType.name) L\(level)"
    }

    /// Position description
    var positionDescription: String {
        "[\(x),\(y)] \(shortDescription)"
    }

    /// Localized status display
    func localizedStatusDisplay(
        assignedCount: Int,
        dwellersLabel: String
    ) -> String {
        guard let roomType = roomType else { return "Unknown Room" }
        let dwellers = assignedCount > 0 ? "👥\(assignedCount)/\(capacity)" : "👥-"
        let power = hasPower ? "⚡" : "⚫"
        return "\(roomType.emoji) \(roomType.name) L\(level) \(dwellers) \(power)"
    }
}

// MARK: - Factory Methods

public extension RoomModel {
    /// Create starting rooms for a new vault (per GDD)
    /// Layout:
    /// Floor 0: 🚪🚪🛗🏠  [Vault Door 2-wide][Elevator][Living Quarters]
    /// Floor 1: ⬛🍲🛗⚡  [empty][Diner][Elevator][Power Generator]
    /// Floor 2: ⬛💧🛗    [empty][Water Treatment][Elevator]
    /// All rooms must be adjacent to elevator column at x=2
    static func createStartingRooms(vaultID: Vault.IDValue) -> [RoomModel] {
        [
            // Floor 0 (ground level)
            RoomModel(vaultID: vaultID, type: .vaultDoor, x: 0, y: 0, width: .double),  // 2-wide vault door at x=0,1
            RoomModel(vaultID: vaultID, type: .elevator, x: 2, y: 0),
            RoomModel(vaultID: vaultID, type: .livingQuarters, x: 3, y: 0),  // Adjacent to elevator on right

            // Floor 1 (1st underground)
            RoomModel(vaultID: vaultID, type: .diner, x: 1, y: 1),  // Adjacent to elevator on left
            RoomModel(vaultID: vaultID, type: .elevator, x: 2, y: 1),
            RoomModel(vaultID: vaultID, type: .powerGenerator, x: 3, y: 1),  // Adjacent to elevator on right

            // Floor 2 (2nd underground)
            RoomModel(vaultID: vaultID, type: .waterTreatment, x: 1, y: 2),  // Adjacent to elevator on left
            RoomModel(vaultID: vaultID, type: .elevator, x: 2, y: 2)
        ]
    }

    /// Check if a position is valid for a new room in a vault grid
    static func isValidPosition(
        x: Int,
        y: Int,
        width: Int,
        existingRooms: [RoomModel],
        maxWidth: Int = 10,
        maxHeight: Int = 25
    ) -> Bool {
        // Check bounds
        guard x >= 0 && y >= 0 && y < maxHeight && (x + width) <= maxWidth else {
            return false
        }

        // Check for overlap with existing rooms
        for room in existingRooms {
            let roomEndX = room.x + room.width
            let newEndX = x + width

            // Check if on same floor and overlapping
            if room.y == y {
                if x < roomEndX && newEndX > room.x {
                    return false  // Overlap detected
                }
            }
        }

        return true
    }

    /// Check if a room position is adjacent to at least one elevator or other room on the same floor
    /// Rules:
    /// 1. Rooms can only be built adjacent (left/right) to existing rooms on the same floor
    /// 2. Elevators can be built above/below existing elevators to extend the shaft
    /// 3. To build on a new floor, first extend an elevator, then build rooms adjacent to it
    static func isConnected(
        x: Int,
        y: Int,
        width: Int,
        existingRooms: [RoomModel],
        roomType: RoomType? = nil
    ) -> Bool {
        // First room is always connected
        if existingRooms.isEmpty { return true }

        // Check if adjacent to any existing room on same floor (left or right)
        for room in existingRooms where room.y == y {
            let roomEndX = room.x + room.width
            let newEndX = x + width

            // Adjacent on left or right
            if x == roomEndX || newEndX == room.x {
                return true
            }
        }

        // Special case: Elevators can be built directly above/below existing elevators
        if roomType == .elevator {
            for room in existingRooms where room.roomType == .elevator && room.x == x {
                // Elevator directly above or below
                if room.y == y - 1 || room.y == y + 1 {
                    return true
                }
            }
        }

        return false
    }
}
