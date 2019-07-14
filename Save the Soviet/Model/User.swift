//
//  User.swift
//  Uncommon Application
//
//  Created by qizihan  on 12/20/18.
//  Copyright © 2018 qzhann. All rights reserved.
//

import Foundation
import UIKit

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
                // Trigger chat events
                triggerChatEventsForLevel(level.levelNumber)
            }
        }
    }
    /// User support rate reprented as percentage. When support drops to 0, the game ends.
    var support: Percentage {
        didSet {
            // We call update here but not the setter method to achieve incrementing effect on the text
            statusDisplayDelegate?.updateUserStatus()
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
    /// Powers the user has.
    var powers: [Power]
    /// The view controller currently displaying and visualizing user level and support progress informations
    unowned var statusDisplayDelegate: UserStatusDisplayDelegate?
    /// The view controller that should visualize the consequence on the screen.
    unowned var visualizationDelegate: ConsequenceVisualizationDelegate?
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case imageName
        case level
        case support
        case coins
        case friends
        case powers
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(imageName, forKey: .imageName)
        try container.encode(level, forKey: .level)
        try container.encode(support, forKey: .support)
        try container.encode(coins, forKey: .coins)
        try container.encode(friends, forKey: .friends)
        try container.encode(powers, forKey: .powers)
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let description = try container.decode(String.self, forKey: .description)
        let imageName = try container.decode(String.self, forKey: .imageName)
        let level = try container.decode(Level.self, forKey: .level)
        let support = try container.decode(Percentage.self, forKey: .support)
        let coins = try container.decode(Int.self, forKey: .coins)
        let friends = try container.decode(Array<Friend>.self, forKey: .friends)
        let powers = try container.decode(Array<Power>.self, forKey: .powers)
        
        self.init(name: name, description: description, imageName: imageName, level: level, support: support, coins: coins, friends: friends, powers: powers)
    }
    
    
    // MARK: - Initializers
    
    /// Full initializer.
    init(name: String, description: String, imageName: String, level: Level, support: Percentage, coins: Int, friends: [Friend], powers: [Power]) {
        self.name = name
        self.description = description
        self.imageName = imageName
        self.level = level
        self.support = support
        self.coins = coins
        self.friends = friends
        self.powers = powers
        self.applyAllPowers()
        self.friendLoyaltyDidChange()
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
        }
    }
    
    /// Upgrade all friends to a specified level. Typically called when a user level increases for the first time.
    private func upgradeAllFriendsToLevel(_ level: Int) {
        for friend in friends {
            friend.upgradeToLevel(level)
        }
    }
    
    /// Calls start chat on the friend with the given name.
    private func startChatForFriendNamed(_ name: String) {
        let friend = friends.first { $0.lastName == name }
        friend?.startChat()
    }
    
    // FIXME: Incomplete implementation
    /// Trigger chat events
    private func triggerChatEventsForLevel(_ level: Int) {
        
        // Upgrade friends and record the highest level number
        upgradeAllFriendsToLevel(level)
        self.level.highestLevelNumber = level
        
        // FIXME: Delete this
        
        
        // Trigger specified friends to start chat
        switch level {
        case 1:
            startChatForFriendNamed(Friend.akimov)
            startChatForFriendNamed(Friend.fomin)
            startChatForFriendNamed(Friend.quizFriend)
        case 2:
            startChatForFriendNamed(Friend.dyatlov)
            startChatForFriendNamed(Friend.legasov)
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
    
    // MARK: - Static properties
    
    static var currentUser = User(name: "President Gorbachev", description: "What we need is Star Peace, not Star Wars.", imageName: "Gorbachev", level: Level(progress: 90), support: Percentage(progress: 50), coins: 100, friends: User.allPossibleFriends, powers: Power.testPowers)
    
    static var testUser = User(name: "President Gorbachev", description: "What we need is Star Peace, not Star Wars.", imageName: "Gorbachev", level: Level(progress: 90), support: Percentage(progress: 50), coins: 100, friends: User.allPossibleFriends, powers: Power.testPowers)
    
    
    // MARK: - Static methods
    
    /// Saves the user data to file.
    static func saveToFile(user: User) {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let archiveURL = documentDirectory.appendingPathComponent("user_data").appendingPathExtension("plist")
        let propertyListEncoder = PropertyListEncoder()
        let data = try? propertyListEncoder.encode(user)
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
            currentUser = testUser
        }
        
        // FIXME: Debugging only
        // try? FileManager().removeItem(at: archiveURL)
    }
    
    static func clearFile() {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let archiveURL = documentDirectory.appendingPathComponent("user_data").appendingPathExtension("plist")
        let propertyListEncoder = PropertyListEncoder()
        let data = try? propertyListEncoder.encode("")
        try? data?.write(to: archiveURL, options: .noFileProtection)
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
    
    // MARK: - Static properties
    static var dyatlov = Friend(lastName: "Dyatlov", shortTitle: "Engineer", fullTitle: "Deputy Chief Engineer", imageName: "Dyatlov", description: "I hate Fomin.", loyalty: Percentage(progress: 50), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, allPossibleMessages: Friend.allTestMessages, executionRestriction: .level(10), startChatUsing: .sendIncomingMessage(IncomingMessage(texts: "My President...", "Congratulations on becoming the new leader.", "Our country needs someone like you to guide us forward", "I will serve you with all of my loyalty.", consequences: [.changeFriendLoyaltyBy(5)], responses: [
        OutgoingMessage(text: "Who are you?", responseMessageId: 1, consequences: [.changeUserLevelBy(-5)]),
        OutgoingMessage(text: "Introduce yourself.", responseMessageId: 1),
        OutgoingMessage(text: "Serve your country, not me.", responseMessageId: 2, consequences: [.changeUserLevelBy(5)])
        ])), upgrades:
        [:])
    
    static var legasov = Friend(lastName: "Legasov", shortTitle: "Scientist", fullTitle: "Nuclear Expert", imageName: "Legasov", description: "Science is the truth.", loyalty: Percentage(progress: 50), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, allPossibleMessages: Friend.allTestMessages, executionRestriction: .level(10), startChatUsing: .sendIncomingMessage(IncomingMessage(texts: "My President...", "Congratulations on becoming the new leader.", "Our country needs someone like you to guide us forward", "I will serve you with all of my loyalty.", consequences: [.changeFriendLoyaltyBy(5)], responses: [
        OutgoingMessage(text: "Who are you?", responseMessageId: 1, consequences: [.changeUserLevelBy(-5)]),
        OutgoingMessage(text: "Introduce yourself.", responseMessageId: 1),
        OutgoingMessage(text: "Serve your country, not me.", responseMessageId: 2, consequences: [.changeUserLevelBy(5)])
        ])),
                                upgrades:
        [:])
    static var fomin = Friend(lastName: "Fomin", shortTitle: "Engineer", fullTitle: "Chernobyl Chief Engineer", imageName: "Fomin", description: "Promotion is on the way.", loyalty: Percentage(progress: 50), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, allPossibleMessages: Friend.allTestMessages, executionRestriction: .level(10), startChatUsing: .promptUserWith(
        [OutgoingMessage(text: "Who are you?", responseMessageId: 1, consequences: [.changeUserLevelBy(-5)]),
         OutgoingMessage(text: "Introduce yourself.", responseMessageId: 1, levelRestriction: 10),
         OutgoingMessage(text: "Serve your country, not me.", responseMessageId: 2, levelRestriction: 8, consequences: [.changeUserLevelBy(5)])]),
                              upgrades:
        [:])
    
    static var akimov = Friend(lastName: "Akimov", shortTitle: "Engineer", fullTitle: "Chernobyl Shift Leader", imageName: "Akimov", description: "Love being a engineer.", loyalty: Percentage(progress: 50), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, allPossibleMessages: Friend.allTestMessages, executionRestriction: .level(7), startChatUsing: .sendIncomingMessage(IncomingMessage(texts: "My President...", "Congratulations on becoming the new leader.", "Our country needs someone like you to guide us forward", "I will serve you with all of my loyalty.", consequences: [.changeFriendLoyaltyBy(5)], responses: [
        OutgoingMessage(text: "Who are you?", responseMessageId: 1, consequences: [.changeUserLevelBy(-5)]),
        OutgoingMessage(text: "Introduce yourself.", responseMessageId: 1),
        OutgoingMessage(text: "Serve your country, not me.", responseMessageId: 2, levelRestriction: 8, consequences: [.changeUserLevelBy(5)])
        ])),
                               upgrades:
        [:])
    
    static var quizFriend = Friend(lastName: "Friend", shortTitle: "Quiz", fullTitle: "Test Quiz", imageName: "Akimov", description: "I test the quiz.", loyalty: Percentage(progress: 50), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, allPossibleMessages: Friend.quizFriendMessages, executionRestriction: .never, startChatUsing: .promptUserWith([
        OutgoingMessage(description: "(Start Quiz)", consequences: [.setChatStartOption(.promptUserWith([OutgoingMessage(text: "How about that", responseMessageId: 0)])), .startQuizOfCategory(nil)])
        ]),
                                   upgrades:
        [7: FriendUpgrade(shortTitle: "New Quiz", description: "Something new.", chatStartOption: .sendIncomingMessage(IncomingMessage(texts: "Whatss up", responses: [OutgoingMessage(description: "Lets do quiz", consequences: [.startQuizOfCategory(nil)])])))])
    
    static var testNewFriend = Friend(lastName: "Dyatlov", shortTitle: "Engineer", fullTitle: "Deputy Chief Engineer 2", imageName: "Dyatlov", description: "I hate Fomin.", loyalty: Percentage(progress: 50), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, allPossibleMessages: Friend.newTestMessages, executionRestriction: .level(10), startChatUsing: .sendIncomingMessage(IncomingMessage(texts: "My President...", "Congratulations on becoming the new leader.", "Our country needs someone like you to guide us forward", "I will serve you with all of my loyalty.", consequences: [.changeFriendLoyaltyBy(5)], responses: [
        OutgoingMessage(text: "Who are you?", responseMessageId: 1, consequences: [.changeUserLevelBy(-5)]),
        OutgoingMessage(text: "Introduce yourself.", responseMessageId: 1),
        OutgoingMessage(text: "Serve your country, not me.", responseMessageId: 2, consequences: [.changeUserLevelBy(5)])
        ])),
                                      upgrades:
        [:])
    
    static var allPossibleFriends: [Friend] = [
        User.dyatlov,
        User.legasov,
        User.fomin,
        User.akimov,
        User.quizFriend
    ]
}
