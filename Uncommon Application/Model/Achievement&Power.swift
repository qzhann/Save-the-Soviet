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

class Power {
    
    // FIXME: We may not need a powerType
    enum PowerType {
        case good
        case bad
    }
    
// Instance properties
    
    var name: String
    var image: UIImage
    var description: String
    var levelNeeded: Int?
    var coinsNeeded: Int?
    var type: PowerType
    var upgrades: [Power] = []
    
    /**
     Initializes a basic power. Typically used as power that does not involve upgrading.
     */
    init(name: String, image: UIImage, description: String, type: PowerType) {
        self.name = name
        self.image = image
        self.description = description
        self.type = type
    }
    
    /**
     Initializes a fully functional power. Power instances initialized using this initializer should support upgrading.
     - Important: The max power in the series of power upgrades should have a nil value for coinsNeeded, while any other power in the upgrade series should have a non-nil value for coinsNeeded.
     */
    convenience init(name: String, image: UIImage, description: String, type: PowerType, levelNeeded: Int?, coinsNeeded: Int?, upgrades: [Power]) {
        self.init(name: name, image: image, description: description, type: type)
        self.levelNeeded = levelNeeded
        self.coinsNeeded = coinsNeeded
        self.upgrades = upgrades
    }
    
// Instance methods

    
// Type methods
    var allPowers: [Power] = []
    
// Type properties
    static var testPowers: [Power] = [
        Power(name: "Healer", image: UIImage(named: "HeartPowerLevel3")!, description: "5 Energy recovered per minute.", type: .good),
        Power(name: "Lucky Dog", image: UIImage(named: "GiftPowerLevel3")!, description: "Receives some gifts from a friend every 30 mins.", type: .good, levelNeeded: nil, coinsNeeded: 30, upgrades: [Power(name: "Lucky Dog", image: UIImage(named: "GiftPowerLevel3")!, description: "Receives a gift from a friend every 30 mins.", type: .good)]),
        
        Power(name: "Amatuer Cheater", image: UIImage(named: "Dog")!, description: "Cheat once every 5 quizzes.", type: .bad)
    ]
}
