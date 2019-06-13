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
    var didUpgrade = false

    
    // MARK: - Initializers
    /**
     Initializes a fully functional power. Power instances initialized using this initializer should support upgrading.
     - Important: The max power in the series of power upgrades should have a nil value for coinsNeeded, while any other power in the upgrade series should have a non-nil value for coinsNeeded.
     */
    init(name: String, image: UIImage, description: String, coinsNeeded: Int = 0, levelNeeded: Int? = nil, upgrades: [Power] = []) {
        self.name = name
        self.image = image
        self.description = description
        self.coinsNeeded = coinsNeeded
        self.levelNeeded = levelNeeded
        self.upgrades = upgrades
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
        self.upgrades = newUpgrades
        self.didUpgrade = true
    }

    // Type properties
    static var testPowers: [Power] = [
        Power(name: "Healer", image: UIImage(named: "HeartPowerLevel3")!, description: "5 Energy recovered per minute."),
        Power(name: "Lucky Dog", image: UIImage(named: "GiftPowerLevel3")!, description: "Receives some gifts from a friend every 30 mins.", coinsNeeded: 30,  upgrades: [Power(name: "Lucky Dog", image: UIImage(named: "GiftPowerLevel3")!, description: "Receives a gift from a friend every 30 mins.", coinsNeeded: 50)]),
        Power(name: "Amatuer Cheater", image: UIImage(named: "Dog")!, description: "Cheat once every 5 quizzes.")
    ]
}


// FIXME: Note that levelNeeded is not yet handled by the UI or the logic yet.
