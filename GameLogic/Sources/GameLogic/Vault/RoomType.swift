//
//  RoomType.swift
//  GameLogic
//
//  Room types and their properties
//

import Foundation

/// Categories of rooms
public enum RoomCategory: String, CaseIterable, Codable, Sendable {
    case production   // Power, food, water generation
    case training     // SPECIAL training
    case medical      // Stimpak/RadAway production
    case crafting     // Weapon/outfit creation
    case special      // Living quarters, storage, etc.
    case infrastructure // Vault door, elevator
}

/// All room types in the vault
public enum RoomType: String, CaseIterable, Codable, Sendable {
    // Infrastructure (always available)
    case vaultDoor = "vault_door"
    case elevator

    // Production Rooms
    case powerGenerator = "power_generator"
    case nuclearReactor = "nuclear_reactor"
    case diner
    case garden
    case waterTreatment = "water_treatment"
    case waterPurification = "water_purification"
    case nukaCola = "nuka_cola"

    // Training Rooms
    case weightRoom = "weight_room"        // Strength
    case armory                            // Perception
    case fitnessRoom = "fitness_room"      // Endurance
    case lounge                            // Charisma
    case classroom                         // Intelligence
    case athleticsRoom = "athletics_room"  // Agility
    case gameRoom = "game_room"            // Luck

    // Medical Rooms
    case medbay
    case scienceLab = "science_lab"

    // Special Rooms
    case livingQuarters = "living_quarters"
    case storageRoom = "storage_room"
    case radioStudio = "radio_studio"
    case overseersOffice = "overseers_office"
    case barbershop

    // Crafting Rooms
    case weaponWorkshop = "weapon_workshop"
    case outfitWorkshop = "outfit_workshop"
    case themeWorkshop = "theme_workshop"

    /// Display name
    public var name: String {
        switch self {
        case .vaultDoor: return "Vault Door"
        case .elevator: return "Elevator"
        case .powerGenerator: return "Power Generator"
        case .nuclearReactor: return "Nuclear Reactor"
        case .diner: return "Diner"
        case .garden: return "Garden"
        case .waterTreatment: return "Water Treatment"
        case .waterPurification: return "Water Purification"
        case .nukaCola: return "Nuka-Cola Bottler"
        case .weightRoom: return "Weight Room"
        case .armory: return "Armory"
        case .fitnessRoom: return "Fitness Room"
        case .lounge: return "Lounge"
        case .classroom: return "Classroom"
        case .athleticsRoom: return "Athletics Room"
        case .gameRoom: return "Game Room"
        case .medbay: return "Medbay"
        case .scienceLab: return "Science Lab"
        case .livingQuarters: return "Living Quarters"
        case .storageRoom: return "Storage Room"
        case .radioStudio: return "Radio Studio"
        case .overseersOffice: return "Overseer's Office"
        case .barbershop: return "Barbershop"
        case .weaponWorkshop: return "Weapon Workshop"
        case .outfitWorkshop: return "Outfit Workshop"
        case .themeWorkshop: return "Theme Workshop"
        }
    }

    /// Emoji representation
    public var emoji: String {
        switch self {
        case .vaultDoor: return "🚪"
        case .elevator: return "🛗"
        case .powerGenerator, .nuclearReactor: return "⚡"
        case .diner, .garden: return "🍲"
        case .waterTreatment, .waterPurification: return "💧"
        case .nukaCola: return "🥤"
        case .weightRoom: return "🏋️"
        case .armory: return "🎯"
        case .fitnessRoom: return "🏃"
        case .lounge: return "🛋️"
        case .classroom: return "📚"
        case .athleticsRoom: return "⚡"
        case .gameRoom: return "🎲"
        case .medbay: return "💊"
        case .scienceLab: return "🔬"
        case .livingQuarters: return "🏠"
        case .storageRoom: return "📦"
        case .radioStudio: return "📻"
        case .overseersOffice: return "🎖️"
        case .barbershop: return "💇"
        case .weaponWorkshop: return "🔫"
        case .outfitWorkshop: return "👔"
        case .themeWorkshop: return "🎨"
        }
    }

    /// Room category
    public var category: RoomCategory {
        switch self {
        case .vaultDoor, .elevator:
            return .infrastructure
        case .powerGenerator, .nuclearReactor, .diner, .garden,
             .waterTreatment, .waterPurification, .nukaCola:
            return .production
        case .weightRoom, .armory, .fitnessRoom, .lounge,
             .classroom, .athleticsRoom, .gameRoom:
            return .training
        case .medbay, .scienceLab:
            return .medical
        case .weaponWorkshop, .outfitWorkshop, .themeWorkshop:
            return .crafting
        case .livingQuarters, .storageRoom, .radioStudio,
             .overseersOffice, .barbershop:
            return .special
        }
    }

    /// Primary SPECIAL stat that affects this room's efficiency
    public var primaryStat: SPECIAL? {
        switch self {
        case .powerGenerator, .nuclearReactor: return .strength
        case .waterTreatment, .waterPurification: return .perception
        case .nukaCola: return .endurance
        case .diner, .garden: return .agility
        case .medbay, .scienceLab: return .intelligence
        case .livingQuarters, .radioStudio: return .charisma
        case .weightRoom: return .strength
        case .armory: return .perception
        case .fitnessRoom: return .endurance
        case .lounge: return .charisma
        case .classroom: return .intelligence
        case .athleticsRoom: return .agility
        case .gameRoom: return .luck
        default: return nil
        }
    }

    /// Whether the room can be merged with adjacent same-type rooms
    public var canMerge: Bool {
        switch self {
        case .vaultDoor, .overseersOffice:
            return false
        default:
            return true
        }
    }

    /// Population required to unlock this room
    public var unlockPopulation: Int {
        switch self {
        case .vaultDoor, .elevator, .powerGenerator, .diner,
             .waterTreatment, .livingQuarters:
            return 0
        case .storageRoom: return 12
        case .medbay: return 14
        case .scienceLab: return 16
        case .overseersOffice: return 18
        case .radioStudio: return 20
        case .weaponWorkshop: return 22
        case .weightRoom, .classroom: return 24
        case .lounge: return 30
        case .outfitWorkshop: return 32
        case .armory, .fitnessRoom, .athleticsRoom: return 35
        case .gameRoom: return 40
        case .themeWorkshop: return 42
        case .barbershop: return 50
        case .nuclearReactor: return 60
        case .garden: return 70
        case .waterPurification: return 80
        case .nukaCola: return 100
        }
    }

    /// Base build cost in caps (single room, level 1)
    public var baseBuildCost: Int {
        switch self {
        case .vaultDoor: return 0  // Built-in
        case .elevator: return 100
        case .powerGenerator, .diner, .waterTreatment, .livingQuarters: return 100
        case .storageRoom: return 150
        case .garden: return 300
        case .barbershop: return 300
        case .medbay, .scienceLab, .weightRoom, .classroom: return 400
        case .waterPurification: return 400
        case .lounge: return 450
        case .armory, .fitnessRoom, .athleticsRoom: return 500
        case .themeWorkshop: return 500
        case .radioStudio, .gameRoom: return 600
        case .weaponWorkshop, .outfitWorkshop: return 800
        case .overseersOffice: return 1000
        case .nuclearReactor: return 1200
        case .nukaCola: return 3000
        }
    }

    /// Dweller capacity per room width
    public func capacity(width: Int) -> Int {
        switch self {
        case .vaultDoor:
            return 2  // Fixed
        case .overseersOffice:
            return 3  // Fixed, cannot merge
        case .livingQuarters:
            // Special scaling for population cap
            return width * 8  // Simplified; actual is more complex
        default:
            return width * 2  // Standard: 2/4/6 for 1/2/3-wide
        }
    }

    /// Power consumption per room width and level
    public func powerConsumption(width: Int, level: Int) -> Int {
        if self == .elevator {
            return 0  // Elevators consume no power
        }
        return width * level
    }
}

// MARK: - Room Production

public extension RoomType {
    /// Resource produced by this room type
    var producesResource: ResourceType? {
        switch self {
        case .powerGenerator, .nuclearReactor: return .power
        case .diner, .garden: return .food
        case .waterTreatment, .waterPurification: return .water
        case .nukaCola: return nil  // Produces both food and water
        default: return nil
        }
    }

    /// Whether this room produces both food and water
    var producesFoodAndWater: Bool {
        self == .nukaCola
    }

    /// Whether this room can be built by the player
    /// Some rooms like Vault Door come pre-built and cannot be constructed
    var isBuildable: Bool {
        switch self {
        case .vaultDoor:
            return false  // Vault door comes pre-built, can only upgrade
        default:
            return true
        }
    }

    /// Whether this is a production room
    var isProductionRoom: Bool {
        category == .production
    }

    /// Whether this is a training room
    var isTrainingRoom: Bool {
        category == .training
    }
}
