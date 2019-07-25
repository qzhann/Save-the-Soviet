//
//  Power.swift
//  Uncommon Application
//
//  Created by qizihan  on 12/20/18.
//  Copyright © 2018 qzhann. All rights reserved.
//

import Foundation
import UIKit

class Power: Codable {
    
    // MARK: Instance properties
    
    var name: String
    var imageName: String
    var image: UIImage {
        return UIImage(named: imageName)!
    }
    var description: String
    var coinsNeeded: Int
    private var upgrades: [PowerUpgrade] = []
    var hasUpgrade: Bool {
        return !upgrades.isEmpty
    }
    var type: PowerType
    var friendLastName: String?
    var strength: Int
    var effectInterval: Double?
    var timer: Timer?
    
    // MARK: - Codable
    
    enum PropertyKeys: String, CodingKey {
        case name
        case imageName
        case description
        case coinsNeeded
        case upgrades
        case type
        case friendLastName
        case strength
        case effectInterval
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: PropertyKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(imageName, forKey: .imageName)
        try container.encode(description, forKey: .description)
        try container.encode(coinsNeeded, forKey: .coinsNeeded)
        try container.encode(upgrades, forKey: .upgrades)
        try container.encode(type, forKey: .type)
        try container.encode(friendLastName, forKey: .friendLastName)
        try container.encode(strength, forKey: .strength)
        try container.encode(effectInterval, forKey: .effectInterval)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PropertyKeys.self)
        name = try container.decode(String.self, forKey: .name)
        imageName = try container.decode(String.self, forKey: .imageName)
        description = try container.decode(String.self, forKey: .description)
        coinsNeeded = try container.decode(Int.self, forKey: .coinsNeeded)
        upgrades = try container.decode(Array<PowerUpgrade>.self, forKey: .upgrades)
        type = try container.decode(PowerType.self, forKey: .type)
        friendLastName = try container.decode(String?.self, forKey: .friendLastName)
        strength = try container.decode(Int.self, forKey: .strength)
        effectInterval = try container.decode(Double?.self, forKey: .effectInterval)
    }
    
    // MARK: - Initializers
    /**
     Initializes a fully functional power. Power instances initialized using this initializer should support upgrading.
     - Important: The max power in the series of power upgrades should have a nil value for coinsNeeded, while any other power in the upgrade series should have a non-nil value for coinsNeeded.
     */
    init(name: String, imageName: String, description: String, coinsNeeded: Int = 0, affecting type: PowerType, forFriendWithLastName friendLastName: String? = nil, strength: Int, every interval: Double? = nil, upgrades: [PowerUpgrade] = []) {
        self.name = name
        self.imageName = imageName
        self.description = description
        self.coinsNeeded = coinsNeeded
        self.upgrades = upgrades
        self.type = type
        self.strength = strength
        self.effectInterval = interval
        self.friendLastName = friendLastName
        
        // If the type is friend loyalty, the power must provide a last name.
        assert(type != .friendLoyalty || friendLastName != nil)
    }
    
    /// Initialize a copy of another power.
    init(copyOf other: Power) {
        self.name = other.name
        self.imageName = other.imageName
        self.description = other.description
        self.coinsNeeded = other.coinsNeeded
        self.upgrades = other.upgrades
        self.type = other.type
        self.strength = other.strength
        self.effectInterval = other.effectInterval
        self.friendLastName = other.friendLastName
    }
    
    
    // MARK: - Instance methods
    
    func upgrade() {
        guard upgrades.isEmpty == false else { return }
        // Stop the timer before upgrading
        stopTimer()
        
        var newUpgrades = self.upgrades
        let nextLevel = newUpgrades.removeFirst()
        
        self.name = nextLevel.name
        self.imageName = nextLevel.imageName
        self.description = nextLevel.description
        self.coinsNeeded = nextLevel.coinsNeeded
        self.type = nextLevel.type
        self.friendLastName = nextLevel.friendLastName
        self.strength = nextLevel.strength
        self.effectInterval = nextLevel.effectInterval
        self.upgrades = newUpgrades
    }
    
    func stopTimer() {
        timer?.invalidate()
    }

    
    // MARK: - Static properties
    
    static var levelBoosters = Power(name: "???", imageName: "?", description: "????????????????????", coinsNeeded: 1, affecting: .other, strength: 0, upgrades: [
        PowerUpgrade(name: "Level Booster 1", imageName: "LevelBooster1", description: "Add 1 to level progress every minute.", coinsNeeded: 5, affecting: .userLevel, strength: 1, every: 1.minute),
        PowerUpgrade(name: "Level Booster 2", imageName: "LevelBooster2", description: "Add 5 to level progress every minute.", coinsNeeded: 10, affecting: .userLevel, strength: 5, every: 1.minute),
        PowerUpgrade(name: "Level Booster 3", imageName: "LevelBooster3", description: "Add 10 to level progress every minute.", affecting: .userLevel, strength: 10, every: 1.minute)
    ])
    
    static var supportBooster = Power(name: "???", imageName: "?", description: "????????????????????", coinsNeeded: 100, affecting: .userSupport, strength: 0, upgrades: [
        PowerUpgrade(name: "Support Booster 1", imageName: "SupportBooster1", description: "Add 1 to your support every 5 min.", coinsNeeded: 200, affecting: .userLevel, strength: 1, every: 5.minute),
        PowerUpgrade(name: "Support Booster 2", imageName: "SupportBooster2", description: "Add 1 to your support every 2 min.", coinsNeeded: 0, affecting: .userLevel, strength: 1, every: 2.minute),
    ])
    
    static var coinGenerator = Power(name: "???", imageName: "?", description: "????????????????????", coinsNeeded: 1, affecting: .other, strength: 0, upgrades: [
        PowerUpgrade(name: "Coin Generator 1", imageName: "CoinGenerator1", description: "Add 1 coin every 1 minute.", coinsNeeded: 5, affecting: .userCoins, strength: 1, every: 1.minute),
        PowerUpgrade(name: "Coin Generator 2", imageName: "CoinGenerator2", description: "Add 1 coin every 20 seconds.", coinsNeeded: 20, affecting: .userCoins, strength: 1, every: 20.second),
        PowerUpgrade(name: "Coin Generator 3", imageName: "CoinGenerator3", description: "Add 5 coins every 30 seconds.", coinsNeeded: 0, affecting: .userCoins, strength: 5, every: 30.second)
    ])
    
    static func loyaltyBoosterForFriendWithLastName(_ lastName: String) -> Power {
        return Power(name: "???", imageName: "?", description: "????????????????????", coinsNeeded: 10, affecting: .friendLoyalty, forFriendWithLastName: lastName, strength: 0, upgrades: [
                PowerUpgrade(name: "Loyalty Booster 1", imageName: "SupportBooster1", description: "Add 1 to loyalty every 5 min.", coinsNeeded: 25, affecting: .friendLoyalty, forFriendWithLastName: lastName, strength: 1, every: 5.minute),
                PowerUpgrade(name: "Loyalty Booster 2", imageName: "SupportBooster2", description: "Add 1 to loyalty every 2 min.", coinsNeeded: 0, affecting: .friendLoyalty, forFriendWithLastName: lastName, strength: 1, every: 2.minute)
        ])
    }
    
    static func maximizer(for type: PowerType, friendLastName: String? = nil) -> Power {
        assert(type != .friendLoyalty || friendLastName != nil)
        var powerName = ""
        var powerDescription = ""
        var imageName = ""
        var powerStrength = 100
        switch type {
        case .userLevel:
            powerName = "Maximum Level"
            powerDescription = "You have reached maximum level."
            imageName = "MaximumLevel"
            powerStrength = 1000
        case .userSupport:
            powerName = "Maximum Support"
            powerDescription = "A ruler with 100% support is immortal."
            imageName = "MaximumSupport"
            powerStrength = 100
        case .friendLoyalty:
            powerName = "Maximum Loyalty"
            powerDescription = "No doubt, only loyalty."
            imageName = "MaximumSupport"
            powerStrength = 100
        default:
            break
        }
        
        return Power(name: "???", imageName: "?", description: "????????????????????", coinsNeeded: 1000, affecting: .other, forFriendWithLastName: friendLastName, strength: 0, upgrades: [
            PowerUpgrade(name: powerName, imageName: imageName, description: powerDescription, coinsNeeded: 0, affecting: type, forFriendWithLastName: friendLastName, strength: powerStrength)
        ])
    }

    static var userPowers: [Power] = [
        Power(name: "???", imageName: "?", description: "????????????????????", coinsNeeded: 1, affecting: .userLevel, strength: 1, upgrades: [
            PowerUpgrade(name: "Level Booster 1", imageName: "LevelBooster1", description: "Add 1 to level progress every minute.", coinsNeeded: 5, affecting: .userLevel, strength: 1, every: 1.minute),
            PowerUpgrade(name: "Level Booster 2", imageName: "LevelBooster2", description: "Add 5 to level progress every minute.", coinsNeeded: 10, affecting: .userLevel, strength: 5, every: 1.minute),
            PowerUpgrade(name: "Level Booster 3", imageName: "LevelBooster3", description: "Add 10 to level progress every minute.", affecting: .userLevel, strength: 10, every: 1.minute)
        ]),
        Power(copyOf: Power.supportBooster),
        Power(copyOf: Power.coinGenerator)
    ]
    
    static func powersForFriendWithLastName(_ lastName: String) -> [Power] {
        return [
            Power(copyOf: Power.levelBoosters),
            Power(copyOf: Power.loyaltyBoosterForFriendWithLastName(lastName)),
            Power(copyOf: Power.maximizer(for: .friendLoyalty, friendLastName: lastName))
        ]
    }
    
}

struct PowerUpgrade: Codable {
    var name: String
    var imageName: String
    var description: String
    var coinsNeeded: Int
    var type: PowerType
    var friendLastName: String?
    var strength: Int
    var effectInterval: Double?
    
    init(name: String, imageName: String, description: String, coinsNeeded: Int = 0, affecting type: PowerType, forFriendWithLastName friendLastName: String? = nil, strength: Int, every interval: Double? = nil) {
        self.name = name
        self.imageName = imageName
        self.description = description
        self.coinsNeeded = coinsNeeded
        self.friendLastName = friendLastName
        self.type = type
        self.strength = strength
        self.effectInterval = interval
        
        // If the type is friend loyalty, the powerUpgrade must provide a last name.
        assert(type != .friendLoyalty || friendLastName != nil)
    }
}


enum PowerType: String, Codable {
    case userLevel
    case userSupport
    case friendLoyalty
    case userCoins
    case other
}


/// Facilitates initialization for power's effect interval
extension Double {
    var second: Double {
        return self
    }
    var minute: Double {
        return self * second * 60
    }
}
