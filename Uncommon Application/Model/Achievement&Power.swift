//
//  Achievement&Power.swift
//  Uncommon Application
//
//  Created by qizihan  on 12/20/18.
//  Copyright © 2018 qzhann. All rights reserved.
//

import Foundation
import UIKit

struct Achievement {
// Instance properties
    var id: Int
    
    var name: String
    var description: String
    var image: UIImage
    
// Instance methods
    
// Type methods
    var AllAchievements: [Achievement] = [] // Need to implement!
}

// MARK: -


// FIXME: A power should contain some consequences which will be handled by the user when the power is loaded / updated
class Power {
    
    // MARK: Instance properties
    
    var name: String
    var image: UIImage
    var description: String
    var coinsNeeded: Int
    var levelNeeded: Int?
    private var upgrades: [Power] = []
    var hasUpgrade: Bool {
        return !upgrades.isEmpty
    }
    var type: PowerType
    var strength: Int
    var effectInterval: Double?
    var timer: Timer?
    
    // MARK: - Initializers
    /**
     Initializes a fully functional power. Power instances initialized using this initializer should support upgrading.
     - Important: The max power in the series of power upgrades should have a nil value for coinsNeeded, while any other power in the upgrade series should have a non-nil value for coinsNeeded.
     */
    init(name: String, image: UIImage, description: String, coinsNeeded: Int = 0, levelNeeded: Int? = nil, affecting type: PowerType, strength: Int, every interval: Double? = nil, upgrades: [Power] = []) {
        self.name = name
        self.image = image
        self.description = description
        self.coinsNeeded = coinsNeeded
        self.levelNeeded = levelNeeded
        self.upgrades = upgrades
        self.type = type
        self.strength = strength
        self.effectInterval = interval
    }
    
    // FIXME: Does it really get this far to invalidate the timer?
    deinit {
        self.timer?.invalidate()
    }
    
    
    // MARK: - Instance methods
    
    func upgrade() {
        guard upgrades.isEmpty == false else { return }
        var newUpgrades = self.upgrades
        let nextLevel = newUpgrades.removeFirst()
        
        self.name = nextLevel.name
        self.image = nextLevel.image
        self.description = nextLevel.description
        self.coinsNeeded = nextLevel.coinsNeeded
        self.levelNeeded = nextLevel.levelNeeded
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
        Power(name: "Healer", image: UIImage(named: "HeartPowerLevel3")!, description: "5 Energy recovered per minute.", affecting: .energy, strength: 5, every: 5.minute),
        Power(name: "Lucky Dog", image: UIImage(named: "GiftPowerLevel3")!, description: "Level progress +10 every 2 minutes.", coinsNeeded: 30, affecting: .level, strength: 10, every: 2.minute, upgrades: [Power(name: "Lucky Dog", image: UIImage(named: "GiftPowerLevel3")!, description: "Level progress +10 every 10 seconds.", affecting: .level, strength: 10, every: 10.second)]),
        Power(name: "Amatuer Cheater", image: UIImage(named: "Dog")!, description: "Cheat once every 5 quizzes.", affecting: .other, strength: 0)
    ]
}

enum PowerType {
    case level, energy, other
}


/// Facilitates initialization for power's effect interval
extension Double {
    var second: Double {
        return self
    }
    var minute: Double {
        return self * second
    }
}


// FIXME: Note that levelNeeded is not yet handled by the UI or the logic yet.
