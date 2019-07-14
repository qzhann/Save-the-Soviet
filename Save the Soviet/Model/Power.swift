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
    private var upgrades: [Power] = []
    var hasUpgrade: Bool {
        return !upgrades.isEmpty
    }
    var type: PowerType
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
        try container.encode(strength, forKey: .strength)
        try container.encode(effectInterval, forKey: .effectInterval)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PropertyKeys.self)
        name = try container.decode(String.self, forKey: .name)
        imageName = try container.decode(String.self, forKey: .imageName)
        description = try container.decode(String.self, forKey: .description)
        coinsNeeded = try container.decode(Int.self, forKey: .coinsNeeded)
        upgrades = try container.decode(Array<Power>.self, forKey: .upgrades)
        type = try container.decode(PowerType.self, forKey: .type)
        strength = try container.decode(Int.self, forKey: .strength)
        effectInterval = try container.decode(Double?.self, forKey: .effectInterval)
    }
    
    // MARK: - Initializers
    /**
     Initializes a fully functional power. Power instances initialized using this initializer should support upgrading.
     - Important: The max power in the series of power upgrades should have a nil value for coinsNeeded, while any other power in the upgrade series should have a non-nil value for coinsNeeded.
     */
    init(name: String, imageName: String, description: String, coinsNeeded: Int = 0, affecting type: PowerType, strength: Int, every interval: Double? = nil, upgrades: [Power] = []) {
        self.name = name
        self.imageName = imageName
        self.description = description
        self.coinsNeeded = coinsNeeded
        self.upgrades = upgrades
        self.type = type
        self.strength = strength
        self.effectInterval = interval
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
        self.strength = nextLevel.strength
        self.effectInterval = nextLevel.effectInterval
        self.upgrades = newUpgrades
    }
    
    func stopTimer() {
        timer?.invalidate()
    }

    // MARK: - Static properties
    static var testPowers: [Power] = [
        Power(name: "Supporter", imageName: "HeartPowerLevel3", description: "1% increase in support every 5 sec.", affecting: .userSupport, strength: -1, every: 10.second),
        Power(name: "Lucky Dog", imageName: "GiftPowerLevel3", description: "Level +5 every 10 seconds.", coinsNeeded: 30, affecting: .userLevel, strength: 5, every: 7.second, upgrades: [Power(name: "Lucky Dog", imageName: "GiftPowerLevel3", description: "Level progress +10 every 10 seconds.", affecting: .userLevel, strength: 10, every: 10.second)]),
        Power(name: "???", imageName: "Dog", description: "???????????????", affecting: .userCoins, strength: 5, every: 5.second)
    ]
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
