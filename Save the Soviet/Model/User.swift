//
//  User.swift
//  Uncommon Application
//
//  Created by qizihan  on 12/20/18.
//  Copyright © 2018 qzhann. All rights reserved.
//

import UIKit
import UserNotifications

class User: Codable {
    
    // MARK: Instance properties
    var name: String
    /// Description string for displaying on UserDetailViewController
    var description: String
    var imageName: String
    var image: UIImage {
        return UIImage(named: imageName)!
    }
    /// User level changes as the game progresses. This is related to the difficulty of the quiz questions and other aspects of the game.
    var level: Level {
        didSet {
            // We call update here but not the setter method to achieve incrementing effect on the text
            statusDisplayDelegate?.updateUserStatus()
            
            // If level increases for the first time
            if level.levelNumberChangeState == .increased && level.levelNumber > level.highestLevelNumber {
                // Handle level up
                levelUpHandlingDelegate?.userLevelIncreasedTo(level.levelNumber)
                // Trigger chat events
                triggerChatEventsForLevel(level.levelNumber)
            }
        }
    }
    /// User support rate reprented as percentage. When support drops to 0, the game ends. Note that support is automatically calculated as the average of the friend loyalty.
    var support: Percentage = Percentage(progress: 1) {
        didSet {
            // We call update here but not the setter method to achieve incrementing effect on the text
            statusDisplayDelegate?.updateUserStatus()
            
            if support.progress == 0 {
                restartGameHandlingDelegate?.restartGameWith(winState: false)
            } else if support.progress == support.maximumProgress {
                restartGameHandlingDelegate?.restartGameWith(winState: true)
            }
            
        }
    }
    /// Coins can be used to upgrade power for User and Friends.
    var coins: Int {
        didSet {
            statusDisplayDelegate?.updateUserStatus()
        }
    }
    /// Friends the user currently has.
    var friends: [Friend]
    /// Retursn a value copy of the friends, useful for initializing a new user using the copy initializer.
    var friendCopies: [Friend] {
        var result = [Friend]()
        for friend in friends {
            result.append(Friend(copyOf: friend))
        }
        return result
    }
    /// Powers the user has.
    var powers: [Power]
    /// Returns a value copy of the powers, useful for initializing a new user using the copy initializer.
    var powerCopies: [Power] {
        var result = [Power]()
        for power in powers {
            result.append(Power(copyOf: power))
        }
        return result
    }
    /// The view controller currently displaying and visualizing user level and support progress informations
    unowned var statusDisplayDelegate: UserStatusDisplayDelegate?
    /// The view controller that should visualize the consequence on the screen.
    unowned var visualizationDelegate: ConsequenceVisualizationDelegate?
    /// The view controller that handles level up, typically MainViewController.
    unowned var levelUpHandlingDelegate: LevelUpHandlingDelegate?
    /// The view controller responsible for trigger the segue to the RestartGameViewController, typically MainViewController.
    unowned var restartGameHandlingDelegate: RestartGameHandlingDelegate?
    /// Tracks whether the user is new. A true value will trigger tutorial.
    var isNewUser: Bool
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case imageName
        case level
        case coins
        case friends
        case powers
        case isNewUser
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(imageName, forKey: .imageName)
        try container.encode(level, forKey: .level)
        try container.encode(coins, forKey: .coins)
        try container.encode(friends, forKey: .friends)
        try container.encode(powers, forKey: .powers)
        try container.encode(isNewUser, forKey: .isNewUser)
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let description = try container.decode(String.self, forKey: .description)
        let imageName = try container.decode(String.self, forKey: .imageName)
        let level = try container.decode(Level.self, forKey: .level)
        let coins = try container.decode(Int.self, forKey: .coins)
        let friends = try container.decode(Array<Friend>.self, forKey: .friends)
        let powers = try container.decode(Array<Power>.self, forKey: .powers)
        let isNewUser = try container.decode(Bool.self, forKey: .isNewUser)
        
        self.init(name: name, description: description, imageName: imageName, isNewUser: isNewUser, level: level, coins: coins, friends: friends, powers: powers)
    }
    
    
    // MARK: - Initializers
    
    /// Full initializer.
    init(name: String, description: String, imageName: String, isNewUser: Bool, level: Level, coins: Int, friends: [Friend], powers: [Power]) {
        self.name = name
        self.description = description
        self.imageName = imageName
        self.isNewUser = isNewUser
        self.level = level
        self.coins = coins
        self.friends = friends
        self.powers = powers
        self.applyAllPowers()
        self.friendLoyaltyDidChange()
    }
    
    /// Initialize a value copy of another user, typically useful for
    init(copyOf other: User) {
        self.name = other.name
        self.description = other.description
        self.imageName = other.imageName
        self.isNewUser = other.isNewUser
        self.level = other.level
        self.coins = other.coins
        self.friends = other.friendCopies
        self.powers = other.powerCopies
    }
    
    /// Initialize sample user.
    init(sampleUserNamed name: String, description: String, imageName: String, isNewUser: Bool, level: Level, coins: Int, friends: [Friend], powers: [Power]) {
        self.name = name
        self.description = description
        self.imageName = imageName
        self.isNewUser = isNewUser
        self.level = level
        self.coins = coins
        self.friends = friends
        self.powers = powers
    }
    
    
    // MARK: - Instance methods
    
    /// Handles changes in level progress.
    func changeLevelBy(progress: Int) {
        // Level progress does not go beyond maximum
        let newProgress = level.progress + progress
        let correctProgress = min(newProgress, level.maximumProgress)
        
        // Guard that progress should change
        guard level.progress != correctProgress else { return }
        
        // Visualize the change
        visualizationDelegate?.visualizeConsequence(.changeUserLevelBy(progress))
        
        // Schedule timers to change the progress over time
        if level.progress < correctProgress {
            // If incrementing the progress
            let duration = 1.5
            let increment = duration / Double(correctProgress - level.progress)
            var delay: Double = 0
            
            // Schedule timer for each increment
            for progress in level.progress ... correctProgress {
                delay += increment
                let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { (_) in
                    self.level.progress = progress
                }
                timer.tolerance = 0.1
            }
            
        } else {
            // If decrementing the progress
            let duration = 1.5
            let increment = duration / Double(correctProgress - level.progress)
            var delay: Double = 0
            
            // Schedule timer for each increment
            for progress in correctProgress ... level.progress {
                delay += increment
                let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { (_) in
                    self.level.progress = progress
                }
                timer.tolerance = 0.1
            }
        }
        
    }
    
    /// Handles changes in support progress.
    func changeSupportBy(progress: Int) {
        // Change the loyalty of each friend to get the effect of changing user support
        for friend in friends {
            friend.changeLoyaltyBy(progress: progress)
        }
        
        // Visualize the change
        visualizationDelegate?.visualizeConsequence(.changeUserSupportBy(progress))
    }
    
    /// Handle changes in coins.
    func changeCoinsBy(number: Int) {
        // Guard that coins should change
        guard number != 0 else { return }
        
        // Visualize the change
        visualizationDelegate?.visualizeConsequence(.changeUserCoinsBy(number))
        
        let correctCoins = coins + number
        
        // Schedule timers to change the coins over time
        if number > 0 {
            // If incrementing coins
            let duration = 1.2
            let increment = duration / Double(correctCoins - coins)
            var delay: Double = 0
            
            // Schedule timer for each increment
            for coins in coins ... correctCoins {
                delay += increment
                let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { (_) in
                    self.coins = coins
                }
                timer.tolerance = 0.1
            }
            
        } else {
            // If decrementing the progress
            let duration = 1.2
            let increment = duration / Double(coins - correctCoins)
            var delay: Double = 0
            
            // Schedule timer for each increment
            for coins in correctCoins ... coins {
                delay += increment
                let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { (_) in
                    self.coins = coins
                }
                timer.tolerance = 0.1
            }
        }
    }
    
    /// Handle the addition of a new friend.
    func makeNewFriend(friend: Friend) {
        // Add the friend, apply the powers, and then immediately start chat.
        friends.insert(friend, at: 0)
        friend.applyAllPowers(to: self, and: friend)
        friend.startChat()
    }
    
    /// Handle the upgrade of a power.
    func upgradePower(_ power: Power) {
        coins -= power.coinsNeeded
        power.upgrade()
        // If the power changes friend loyalty, apply the power on the friend, otherwise apply the power on the user.
        if power.type == .friendLoyalty, let lastName = power.friendLastName, let friend = self.friendWithLastName(lastName) {
            friend.apply(power: power, to: self, and: friend)
            self.friendLoyaltyDidChange()
        } else {
            self.applyPower(power)
        }
        
        
        applyPower(power)
    }
    
    /// Apply all powers, called when the user is initialized from file, or when the new user starts game.
    func applyAllPowers() {
        for power in powers {
            applyPower(power)
        }
        
        for friend in friends {
            friend.applyAllPowers(to: self, and: friend)
        }
 
    }
    
    /// Apply a power to self. Note that user does not need to worry about applying friendLoyalty powers.
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
            case .userSupport:
                let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { (_) in
                    self.changeSupportBy(progress: power.strength)
                    self.friendLoyaltyDidChange()
                })
                timer.tolerance = 0.5
                power.timer = timer
            case .userCoins:
                let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { (_) in
                    self.changeCoinsBy(number: power.strength)
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
            case .userSupport:
                self.changeSupportBy(progress: power.strength)
            case .userCoins:
                self.changeCoinsBy(number: power.strength)
            default:
                break
            }
            power.strength = 0
        }
    }
    
    /// Upgrade all friends to a specified level. Typically called when a user level increases for the first time.
    private func upgradeAllFriendsToLevel(_ level: Int) {
        for friend in friends {
            friend.upgradeToLevel(level)
        }
    }
    
    func friendWithLastName(_ name: String) -> Friend? {
        return friends.first { $0.lastName == name }
    }
    
    /// Calls start chat on the friend with the given name.
    private func startChatForFriend(_ friend: Friend?) {
        friend?.startChat()
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
            startChatForFriend(friendWithLastName(Friend.oldPartyMember.lastName))
        case 2:
            break
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
    
    /// Updates user support when the loyalty of a friend changes or when a new friend is made or deleted.
    func friendLoyaltyDidChange() {
        var totalLoyalty = 0
        for friend in friends {
            totalLoyalty += friend.loyalty.progress
        }
        // The support is calculated as an average of the loyalty across all friends
        let average = Int(Double(totalLoyalty) / Double(friends.count))
        self.support.progress = average
    }
    
    /// Stop all timers on user's powers and the friends' powers.
    func stopTimers() {
        for power in powers {
            power.stopTimer()
        }
        
        for friend in friends {
            for power in friend.powers {
                power.stopTimer()
            }
        }
    }
    
    /// Start updating chat history for all friends, typically called when the user reenters the app.
    func updateChatHistoryForFriends() {
        for friend in friends {
            friend.updateChatHistoryInBackground()
        }
    }
    
    // MARK: - Static properties
    
    /// currentUser will be modified during the game.
    static var currentUser = User(sampleUserNamed: "currentUser", description: "What we need is Star Peace, not Star Wars.", imageName: "Gorbachev", isNewUser: false, level: Level(progress: 0), coins: 100, friends: [Friend.oldPartyMember], powers: Power.testPowers)
    
    static var newUser = User(sampleUserNamed: "newUser", description: "What we need is Star Peace, not Star Wars.", imageName: "Gorbachev", isNewUser: true, level: Level(progress: 0), coins: 100, friends: [Friend.oldPartyMember], powers: Power.testPowers)
    
    static var sampleUser = User(sampleUserNamed: "sampleUser", description: "What we need is Star Peace, not Star Wars.", imageName: "Gorbachev", isNewUser: false, level: Level(progress: 0), coins: 100, friends: [Friend.oldPartyMember], powers: Power.testPowers)
    
    
    // MARK: - Static methods
    
    /// Saves the user data to file.
    static func saveToFile() {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let archiveURL = documentDirectory.appendingPathComponent("user_data").appendingPathExtension("plist")
        let propertyListEncoder = PropertyListEncoder()
        let data = try? propertyListEncoder.encode(User.currentUser)
        try? data?.write(to: archiveURL, options: .noFileProtection)
    }
    
    /// Loads the user data from file.
    static func loadFromFile() {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let archiveURL = documentDirectory.appendingPathComponent("user_data").appendingPathExtension("plist")
        let propertyListDecoder = PropertyListDecoder()
        if let data = try? Data(contentsOf: archiveURL), let decodedUser = try? propertyListDecoder.decode(User.self, from: data) {
            currentUser = decodedUser
        } else {
            // If there was really NOTHING, then use the new user.
            currentUser = User(copyOf: User.newUser)
        }
        
        // FIXME: To debug as a new user, build the app twice in a row quickly. To debug as continuing user, build the app, then enter background.
        try? FileManager().removeItem(at: archiveURL)
    }
    
    static func clearFile() {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let archiveURL = documentDirectory.appendingPathComponent("user_data").appendingPathExtension("plist")
        let propertyListEncoder = PropertyListEncoder()
        let data = try? propertyListEncoder.encode(User.sampleUser)
        try? data?.write(to: archiveURL, options: .noFileProtection)
    }
    
    static func startGame() {
        User.currentUser.applyAllPowers()
        User.currentUser.friendLoyaltyDidChange()
        User.currentUser.isNewUser = false
    }
    
    static func stopGame() {
        User.currentUser.stopTimers()
    }
    
    static func restartGame() {
        clearFile()
        loadFromFile()
    }
}

// MARK: -

/// A progress tracker which tracks level number and progress. Level number changes as progress increases or decreases.
struct Level: Codable {
    
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
    private var previousLevelNumber: Int = 0
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
enum LevelNumberChangeState: String, Codable {
    case increased, decreased, noChange
}

// MARK: -

/// A progress tracker which represents progress in percentage. Does not have a level property.
struct Percentage: Codable {
    
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


extension User {
    static var allPossibleFriends: [Friend] = [
        Friend.oldPartyMember,
        Friend.dyatlov,
        Friend.legasov,
        Friend.fomin,
        Friend.akimov,
        Friend.quizFriend
    ]
}
