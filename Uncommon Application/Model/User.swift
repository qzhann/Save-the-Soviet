//
//  User.swift
//  Uncommon Application
//
//  Created by qizihan  on 12/20/18.
//  Copyright © 2018 qzhann. All rights reserved.
//

import Foundation
import UIKit

class User {
    var name: String
    var description: String
    var image: UIImage
    
    var level = Level(progress: 240)  // FIXME: Replace with default initializer
    var energy: Energy = Energy(progress: 15)    // FIXME: Replace with default initializer
    
    
    var coins: Int
    var quizLevel: Int = 0
    
    var friends: [Friend] = []

    var powers: [Power] = Power.testPowers
    
    static var allPossibleFriends: [Friend] = Friend.allPossibleFriends
    static var allPossiblePowers: [Power] = []      // FIXME: Replace with real powers
    static var allPossibleQuizQuestions: [Int: [QuizQuestion]] = QuizQuestion.allPossibleQuizQuestions
    
    init(name: String, description: String, image: UIImage, level: Level, energy: Energy, coins: Int, quizLevel: Int, friends: [Friend], powers: [Power]) {
        self.name = name
        self.description = description
        self.image = image
        self.level = level
        self.energy = energy
        self.coins = coins
        self.quizLevel = quizLevel
        self.friends = friends
        self.powers = powers
        // FIXME: Handle all the powers
    }
    
    /**
     Initialize with name, description, and image.
     */
    init(name: String, description: String, image: UIImage) {
        self.name = name
        self.description = description
        self.image = image
        self.coins = 100
    }
    
    /**
     Initialize with name, description, image, and friends.
     */
    init(name: String, description: String, image: UIImage, friends: [Friend], coins: Int) {
        self.name = name
        self.description = description
        self.image = image
        self.friends = friends
        self.coins = coins
    }
    
    func changeLevelProgressBy(_ progress: Int) {
        level.progress += progress
    }
    
    func changeEnergyProgressBy(_ progress: Int) {
        energy.progress += progress
    }
    
    func makeNewFriend(friend: Friend) {}
    // FIXME: Continue to write more user functions
    
    func upgradePower(_ power: Power) {
        coins -= power.coinsNeeded
        power.upgrade()
    }
    
    func handlePower(_ power: Power) {
        
    }
    
    
    // FIXME: Test User
    static var currentUser = User(name: "Gavin", description: "The guy who stays in his room all day.", image: UIImage(named: "Dog")!, friends: Friend.allPossibleFriends, coins: 100)
}

/**
 ### Instance Properties
    * progress: Progress of the Level in Int values. Whenever updated, automatically updates levelNumber, currentUpperBound, and progressForCurrentLevel
    * normalizedProgress: Progress of made from the previous level upperbound to the current level upperbound in Float.
    * levelNumber: Level Number displayed on UI
    * currentUpperBound: The maximum progress number to remain in the same levelNumber
 
 ### Initializer
    * Default initializer. Typically used to create a Level instance for a new user.
    * Initialize with progress.
 */
struct Level {
    var progress: Int {
        didSet {
            levelNumber = (progress / 100) + 1
            currentUpperBound = upperBounds[levelNumber]
            previousUpperBound = upperBounds[levelNumber - 1]
            normalizedProgress = Float(progress - previousUpperBound) / Float(currentUpperBound - previousUpperBound)
        }
    }
    
    var normalizedProgress: Float = 0
    
    var levelNumber: Int = 0
    
    var currentUpperBound: Int = 100
    private var previousUpperBound: Int = 0
    private var upperBounds = [0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700]
    
    /**
     Default initializer, typically used to create a Level instance for a new user.
     */
    init() {
        self.progress = 0
    }
    
    /**
     - parameter progress: progress for the level in Int
     */
    init(progress: Int) {
        self.progress = progress
        levelNumber = (progress / 100) + 1
        currentUpperBound = upperBounds[levelNumber]
        previousUpperBound = upperBounds[levelNumber - 1]
        normalizedProgress = Float(progress - previousUpperBound) / Float(currentUpperBound - previousUpperBound)
    }
}

/**
 ### Instance properties:
    * progress: Progress of energy in Int. Whenever updated, automatically updates the normalized progress.
    * maximum: The current upperbound for energy.
    * currentReplenishRate: The current rate of replenishing for energy.
    * time: Time remaining until the energy is full.
 
 ### Initializers:
    * Initialze using progress in Int.
 
 */
struct Energy {
    var progress: Int {
        didSet {
            normalizedProgress = Float(progress / maximum)
        }
    }
    
    var maximum: Int = 20
    
    var normalizedProgress: Float = 0
    
    // Energy replenished per minute
    var currentReplenishRate: Int = 1
    
    // Could be DateInterval or TimeInterval(Double) and then we format it using formatter. Need Verification.
    var remainingTime: TimeInterval = 0
    
    /**
     Set the new maximum by a non-negative integer. Useful as a helper method called by user functions that are more descriptive of their effects, and is thus fileprivate.
     */
    fileprivate mutating func increaseMaximum(by value: Int) {
        guard value >= 0 else { return }
        maximum += value
    }
    
    
    /**
     Initializes using progress.
     - parameter progress: progress in Int
     */
    init(progress: Int) {
        self.progress = progress
        normalizedProgress = Float(progress) / Float(maximum)
    }
}
