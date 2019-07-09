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
    
    // MARK: Instance properties
    
    var name: String
    /// Description string for displaying on UserDetailViewController
    var description: String
    var image: UIImage
    /// User level changes as the game progresses. This is related to the difficulty of the quiz questions and other aspects of the game.
    var level: Level {
        didSet {
            // Update the user status
            statusDisplayDelegate?.updateUserStatus()
            
            // If level increases for the first time
            if level.levelNumberChangeState == .increased && level.levelNumber > level.highestLevelNumber {
                // Trigger chat events
                triggerChatEventsForLevel(level.levelNumber)
            }
        }
    }
    /// User support rate reprented as percentage. When support drops to 0, the game ends.
    var support: Percentage {
        didSet {
            statusDisplayDelegate?.updateUserStatus()
        }
    }
    /// Coins can be used to upgrade power for User and Friends.
    var coins: Int
    /// Friends the user currently has.
    var friends: [Friend]
    /// Powers the user has.
    var powers: [Power]
    /// The view controller currently displaying user level and support progress informations.
    unowned var statusDisplayDelegate: UserStatusDisplayDelegate?
    
    
    // MARK: - Initializers
    
    /// Full initializer.
    init(name: String, description: String, image: UIImage, level: Level, support: Percentage, coins: Int, friends: [Friend], powers: [Power]) {
        self.name = name
        self.description = description
        self.image = image
        self.level = level
        self.support = support
        self.coins = coins
        self.friends = friends
        self.powers = powers
        self.applyAllPowers()
        // FIXME: Do we start chat for all friends during initialization? Do we reinitialize the User for persistence, thus causing problems?
        // Trigger begin chat for all friends
        for friend in self.friends {
            // friend.startChat()
        }
    }
    

    /// Handles changes in level progress.
    func changeLevelBy(progress: Int) {
        // Level progress does not go beyond maximum
        let newProgress = level.progress + progress
        level.progress = min(newProgress, level.maximumProgress)
    }
    
    /// Handles changes in support progress.
    func changeSupportBy(progress: Int) {
        // Support progress does not go beyond maximum
        let newProgress = support.progress + progress
        support.progress = min(newProgress, support.maximumProgress)
    }
    
    /// Handle the addition of a new friend.
    func makeNewFriend(friend: Friend) {
        friends.insert(friend, at: 0)
        friend.applyAllPowers(to: self, and: friend)
    }
    
    /// Handle the upgrade of a power.
    func upgradePower(_ power: Power) {
        coins -= power.coinsNeeded
        power.upgrade()
        applyPower(power)
    }
    
    /// Apply all powers. This is called when the user is initialized.
    func applyAllPowers() {
        for power in powers {
            applyPower(power)
        }
    }
    
    /// Apply a power to self.
    private func applyPower(_ power: Power) {
        
        if let interval = power.effectInterval {
            // Apply power that effects periodically
            switch power.type {
            case .userLevel:
                let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { (_) in
                    self.changeLevelBy(progress: power.strength)
                })
                timer.tolerance = 0.5
                power.timer = timer
            case .userEnergy:
                let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { (_) in
                    self.changeSupportBy(progress: power.strength)
                })
                timer.tolerance = 0.5
                power.timer = timer
            default:
                break
            }
            
        } else {
            // Apply one-time power
            switch power.type {
            case .userLevel:
                self.changeLevelBy(progress: power.strength)
            case .userEnergy:
                self.changeSupportBy(progress: power.strength)
            default:
                break
            }
        }
    }
    
    /// Upgrade all friends to a specified level. Typically called when a user level increases for the first time.
    private func upgradeAllFriendsToLevel(_ level: Int) {
        for friend in friends {
            friend.upgradeToLevel(level)
        }
    }
    
    // FIXME: Incomplete implementation
    /// Trigger chat events
    private func triggerChatEventsForLevel(_ level: Int) {
        // Upgrade friends and record the highest level number
        upgradeAllFriendsToLevel(level)
        self.level.highestLevelNumber = level
        
        // Trigger specified friends to start chat
        switch level {
        case 1:
            Friend.akimov.startChat()
            Friend.fomin.startChat()
        case 2:
            Friend.dyatlov.startChat()
            Friend.legasov.startChat()
        case 3:
            break
        case 4:
            break
        case 5:
            break
        case 6:
            break
        case 7:
            break
        case 8:
            break
        case 9:
            break
        case 10:
            break
        default:
            break
        }
    }
    
    // MARK: - Static properties
    
    static var currentUser = User(name: "President Gorbachev", description: "What we need is Star Peace, not Star Wars.", image: UIImage(named: "Gorbachev")!, level: Level(progress: 50), support: Percentage(progress: 100), coins: 100, friends: Friend.allPossibleFriends, powers: Power.testPowers)
}

// MARK: -

/// A progress tracker which tracks level number and progress. Level number changes as progress increases or decreases.
struct Level {
    
    // MARK: Instance properties
    
    /// Internal progress represented as an Int.
    var progress: Int {
        didSet {
            // Set the properties differently when the progress hits maximum
            if progress < maximumProgress {
                // level increases every 100 progress
                levelNumber = (progress / 100) + 1
                currentUpperBound = upperBounds[levelNumber]
                previousUpperBound = upperBounds[levelNumber - 1]
                let rawNormalizedProgress = Float(progress - previousUpperBound) / Float(currentUpperBound - previousUpperBound)
                normalizedProgress = rawNormalizedProgress * 0.95 + 0.05
                previousProgress = oldValue
            } else {
                levelNumber = 10
                normalizedProgress = 1
                previousProgress = oldValue
            }
            
        }
    }
    /// Initialized to be the same as progress. When progress changes, this records the old value of progress.
    var previousProgress: Int
    /// Progress normalized into value from 0 to 1 inclusive, useful for updating progress views.
    var normalizedProgress: Float = 0
    /// Level number represented as an Int.
    var levelNumber: Int {
        didSet {
            let difference = self.levelNumber - previousLevelNumber
            if difference > 0 {
                levelNumberChangeState = .increased
            } else if difference < 0 {
                levelNumberChangeState = .decreased
            } else {
                levelNumberChangeState = .noChange
            }
            previousLevelNumber = self.levelNumber
        }
    }
    /// A tracker of the previous level number before the level progress changes
    var previousLevelNumber: Int = 0
    /// Status of level number changes, useful for visualizing the level number changes.
    var levelNumberChangeState: LevelNumberChangeState = .noChange
    /// A tracker of the highest level number reached in the past.
    var highestLevelNumber: Int = 0
    /// currentUpperBound, previousUpperBound, and upperBounds are internal data that determines when changes in level number occurs, and what to display on progress labels.
    var currentUpperBound: Int = 100
    private var previousUpperBound: Int = 0
    private var upperBounds = [0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100]
    var maximumProgress: Int = 1000
    /// Returns a string to display on progress labels.
    var progressDescription: String {
        if progress < maximumProgress {
            return "\(progress)/\(currentUpperBound)"
        } else {
            return "MAX"
        }
        
    }
    
    
    // MARK: - Initializers
    
    /**
     Initializes using progress.
     */
    init(progress: Int) {
        self.progress = progress
        self.previousProgress = progress
        levelNumber = (progress / 100) + 1
        currentUpperBound = upperBounds[levelNumber]
        previousUpperBound = upperBounds[levelNumber - 1]
        normalizedProgress = Float(progress - previousUpperBound) / Float(currentUpperBound - previousUpperBound)
    }
}

// MARK: -

/// States of the changes of level number.
enum LevelNumberChangeState {
    case increased, decreased, noChange
}

// MARK: -

/// A progress tracker which represents progress in percentage. Does not have a level property.
struct Percentage {
    
    // MARK: Instance properties
    
    /// Internal progress represented as an Int.
    var progress: Int {
        didSet {
            normalizedProgress = Float(progress) / Float(maximumProgress)
        }
    }
    let maximumProgress = 100
    /// Progress normalized into value from 0 to 1 inclusive, useful for updating progress views.
    var normalizedProgress: Float = 0
    /// Returns a string to display on progress labels.
    var progressDescription: String {
        if progress < maximumProgress {
            return "\(progress)%"
        } else {
            return "MAX"
        }
        
    }
    
    
    // MARK: - Initializers
    
    /**
     Initializes using progress.
     */
    init(progress: Int) {
        self.progress = progress
        normalizedProgress = Float(progress) / Float(maximumProgress)
    }
}
