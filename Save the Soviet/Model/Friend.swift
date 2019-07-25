//
//  Friend.swift
//  Uncommon Application
//
//  Created by qizihan  on 12/20/18.
//  Copyright © 2018 qzhann. All rights reserved.
//

import UIKit
import UserNotifications

/// A tracker for whether the chat has ended, useful for resuming chat display in the chatDelegate.
enum ChatEndingState: Codable {
    case notEnded
    case endedFrom(MessageDirection)
    
    // MARK: Codable
    
    enum CodingKeys: String, CodingKey {
        case notEnded
        case endedFrom
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .notEnded:
            try container.encode("", forKey: .notEnded)
        case .endedFrom(let direction):
            try container.encode(direction, forKey: .endedFrom)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let direction = try? container.decode(MessageDirection.self, forKey: .endedFrom) {
            self = .endedFrom(direction)
        } else {
            self = .notEnded
        }
    }
}

// MARK: -

/// A tracker for whether the user is expecting choices, just responded, or just began a chat.
enum ResponseState: Codable {
    /// Friend is expecting an optional array of OutgoingMessage instances as response. If not nil, then ChatViewController should prompt the user for responses.
    case willPromptUserWith([OutgoingMessage]?)
    /// User completed a whole set of responses in a chat.
    case completed
    
    // MARK: Codable
    
    enum CodingKeys: String, CodingKey {
        case willPromptUserWith
        case completed
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .willPromptUserWith(let choices):
            try container.encode(choices, forKey: .willPromptUserWith)
        case .completed:
            try container.encode("", forKey: .completed)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let choices = try? container.decode(Optional<Array<OutgoingMessage>>.self, forKey: .willPromptUserWith) {
            self = .willPromptUserWith(choices)
        } else {
            self = .completed
        }
    }
}

// MARK: -

/// Describes how a friend should begin a chat when being a new friend to the user.
enum ChatStartOption: Codable {
    /// Start chat by prompting user with some choices
    case promptUserWith([OutgoingMessage])
    /// Start chat by sending incoming message
    case sendIncomingMessage(IncomingMessage)
    /// Does not start chat
    case none
    
    // MARK: Codable
    enum CodingKeys: String, CodingKey {
        case promptUserWith = " "
        case sendIncomingMessage
        case none
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .promptUserWith(let choices):
            try container.encode(choices, forKey: .promptUserWith)
        case .sendIncomingMessage(let message):
            try container.encode(message, forKey: .sendIncomingMessage)
        case .none:
            try container.encode("", forKey: .none)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let choices = try? container.decode(Array<OutgoingMessage>.self, forKey: .promptUserWith) {
            self = .promptUserWith(choices)
        } else if let message = try? container.decode(IncomingMessage.self, forKey: .sendIncomingMessage) {
            self = .sendIncomingMessage(message)
        } else {
            self = .none
        }
    }
    
}

// MARK: -

/// A tracker indicating what conditions will allow the user the execute the friend. Useful for controlling the state of the executeFriendButton.
enum ExecutionRestriction: Codable {
    /// No limitation. The friend can be executed at any time.
    case none
    /// The friend can only be executed at or above the level number given.
    case level(Int)
    /// The friend can never be executed.
    case never
    
    // MARK: Codable
    enum CodingKeys: String, CodingKey {
        case none
        case level
        case never
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try container.encode("", forKey: .none)
        case .level(let level):
            try container.encode(level, forKey: .level)
        case .never:
            try container.encode("", forKey: .never)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if (try? container.decode(String.self, forKey: .none)) != nil {
            self = .none
        } else if let level = try? container.decode(Int.self, forKey: .level) {
            self = .level(level)
        } else {
            self = .never
        }
    }
}

/// Stores the upgrade information for a friend. Each property is of an optional type. A nil value indicates no need for upgrade for that particular property.
struct FriendUpgrade: Codable {
    var shortTitle: String?
    var fullTitle: String?
    var description: String?
    var chatStartOption: ChatStartOption?
    
    init(shortTitle: String? = nil, fullTitle: String? = nil, description: String? = nil, chatStartOption: ChatStartOption? = nil) {
        self.shortTitle = shortTitle
        self.fullTitle = fullTitle
        self.description = description
        self.chatStartOption = chatStartOption
    }
}

// MARK: -

/**
 A class which holds information about a friend and the chat history with that friend.
 */
class Friend: Equatable, Codable {
    
    // MARK: Instance properties
    var lastName: String
    var shortTitle: String
    var fullTitle: String
    var shortName: String {
        return "\(shortTitle) \(lastName)"
    }
    var fullName: String {
        return "\(fullTitle) \(lastName)"
    }
    var imageName: String
    var image: UIImage {
        return UIImage(named: imageName)!
    }
    /// The description displayed on FriendDetailViewController
    var description: String
    var loyalty: Percentage {
        didSet {
            statusDisplayDelegate?.updateFriendStatus()
        }
    }
    var powers: [Power]
    /// Returns a value copy of the powers, useful for initializing a new friend using the copy initializer.
    var powerCopies: [Power] {
        var result = [Power]()
        for power in powers {
            result.append(Power(copyOf: power))
        }
        return result
    }
    /// Describes what limitations the user must meet before executing a friend.
    var executionRestriction: ExecutionRestriction
    /// The object responsible for displaying the chat history, typically the ChatViewController.
    weak var chatDelegate: ChatDisplayDelegate?
    /// chatHistory records all ChatMessage send to and from the Friend. If the chatDelegate did not finish the delayed display of the chatHistory upon dismissal, chatHistory will be copied over to update the chatDelegate when presenting it.
    var chatHistory: [ChatMessage]
    /// This tracks the number of ChatMessages displayed by the chatDelegate. When the chatDelegate was dismissed, this resumes chat from the appropriate message.
    var displayedMessageCount: Int
    /// Used to show or hide the end chat cell.
    var hasNewMessage = false
    /// When set to false, the friend will update the chat history in the background.
    var isChatting = false
    ///  A tracker of the most recent response in the chat history, useful for smoothly resuming chat display in the chatDelegate.
    var responseState: ResponseState = .completed
    /// This tracks whether the chat has ended, useful for resuming chat display in the chatDelegate.
    var chatEndingState: ChatEndingState = .notEnded
    /// The data store for all messages that can be sent to and from a Friend.
    private var allPossibleMessages: [Int: IncomingMessage]
    /// Describes how the friend should start a chat when startChat() is called. This stores the information of how to start a chat before it actually happens by calling startChat().
    var chatStartOption: ChatStartOption
    /// A dictionary of upgrades for a friend based on level.
    var levelUpgrades: [Int: FriendUpgrade]
    /// An array of upgrades for a friend.
    var nonLevelUpgrades: [FriendUpgrade]
    /// The object responsible for displaying the new message status of the friend, typically the MainViewController.
    weak var messageStatusDisplayDelegate: FriendMessageStatusDisplayDelegate?
    /// The object responsible for displaying the status of the friend, typically the FrienDetailViewController.
    weak var statusDisplayDelegate: FriendStatusDisplayDelegate?
    /// The object responsible for visualizing changes in friend status, typically the FriendDetailViewController.
    weak var visualizationDelegate: ConsequenceVisualizationDelegate?
    
    // MARK: - Codable
    
    enum PropertyKeys: String, CodingKey {
        case lastName
        case shortTitle
        case fullTitle
        case imageName
        case description
        case loyalty
        case powers
        case executionRestriction
        case chatHistory
        case displayedMessageCount
        case hasNewMessage
        case isChatting
        case responseState
        case chatEndState
        case allPossibleMessages
        case chatStartOption
        case levelUpgrades
        case nonLevelUpgrades
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: PropertyKeys.self)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(shortTitle, forKey: .shortTitle)
        try container.encode(fullTitle, forKey: .fullTitle)
        try container.encode(imageName, forKey: .imageName)
        try container.encode(description, forKey: .description)
        try container.encode(loyalty, forKey: .loyalty)
        try container.encode(powers, forKey: .powers)
        try container.encode(executionRestriction, forKey: .executionRestriction)
        try container.encode(chatHistory, forKey: .chatHistory)
        try container.encode(displayedMessageCount, forKey: .displayedMessageCount)
        try container.encode(hasNewMessage, forKey: .hasNewMessage)
        try container.encode(isChatting, forKey: .isChatting)
        try container.encode(responseState, forKey: .responseState)
        try container.encode(chatEndingState, forKey: .chatEndState)
        try container.encode(allPossibleMessages, forKey: PropertyKeys.allPossibleMessages)
        try container.encode(chatStartOption, forKey: .chatStartOption)
        try container.encode(levelUpgrades, forKey: .levelUpgrades)
        try container.encode(nonLevelUpgrades, forKey: .nonLevelUpgrades)
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PropertyKeys.self)
        let lastName = try container.decode(String.self, forKey: .lastName)
        let shortTitle = try container.decode(String.self, forKey: .shortTitle)
        let fullTitle = try container.decode(String.self, forKey: .fullTitle)
        let imageName = try container.decode(String.self, forKey: .imageName)
        let description = try container.decode(String.self, forKey: .description)
        let loyalty = try container.decode(Percentage.self, forKey: .loyalty)
        let powers = try container.decode(Array<Power>.self, forKey: .powers)
        let chatHistory = try container.decode(Array<ChatMessage>.self, forKey: .chatHistory)
        let displayedMessageCount = try container.decode(Int.self, forKey: .displayedMessageCount)
        let allPossibleMessages = try container.decode(Dictionary<Int, IncomingMessage>.self, forKey: .allPossibleMessages)
        let executionRestriction = try container.decode(ExecutionRestriction.self, forKey: .executionRestriction)
        let chatStartOption = try container.decode(ChatStartOption.self, forKey: .chatStartOption)
        let levelUpgrades = try container.decode(Dictionary<Int, FriendUpgrade>.self, forKey: .levelUpgrades)
        let nonLevelUpgrades = try container.decode(Array<FriendUpgrade>.self, forKey: .nonLevelUpgrades)
        self.init(lastName: lastName, shortTitle: shortTitle, fullTitle: fullTitle, imageName: imageName, description: description, loyalty: loyalty, chatHistory: chatHistory, displayedMessageCount: displayedMessageCount, executionRestriction: executionRestriction, powers: powers, levelUpgrades: levelUpgrades, nonLevelUpgrades: nonLevelUpgrades, startChatUsing: chatStartOption, allPossibleMessages: allPossibleMessages)
        
        hasNewMessage = try container.decode(Bool.self, forKey: .hasNewMessage)
        isChatting = try container.decode(Bool.self, forKey: .hasNewMessage)
        responseState = try container.decode(ResponseState.self, forKey: .responseState)
        chatEndingState = try container.decode(ChatEndingState.self, forKey: .chatEndState)
    }
    
    
    // MARK: - Initializers
    
    /// Full intializer for a Friend, begins chat with sending incoming message.
    init(lastName: String, shortTitle: String, fullTitle: String, imageName: String, description: String, loyalty: Percentage, chatHistory: [ChatMessage], displayedMessageCount: Int, executionRestriction: ExecutionRestriction, powers: [Power], levelUpgrades: [Int: FriendUpgrade], nonLevelUpgrades: [FriendUpgrade], startChatUsing chatStartOption: ChatStartOption, allPossibleMessages: [Int: IncomingMessage]) {
        self.lastName = lastName
        self.shortTitle = shortTitle
        self.fullTitle = fullTitle
        self.imageName = imageName
        self.description = description
        self.loyalty = loyalty
        self.powers = powers
        self.chatHistory = chatHistory
        self.displayedMessageCount = displayedMessageCount
        self.executionRestriction = executionRestriction
        self.levelUpgrades = levelUpgrades
        self.nonLevelUpgrades = nonLevelUpgrades
        self.chatStartOption = chatStartOption
        self.allPossibleMessages = allPossibleMessages
    }
    
    /// Initialize a copy of another Friend.
    init(copyOf other: Friend) {
        self.lastName = other.lastName
        self.shortTitle = other.shortTitle
        self.fullTitle = other.fullTitle
        self.imageName = other.imageName
        self.description = other.description
        self.loyalty = other.loyalty
        self.powers = other.powerCopies
        self.chatHistory = other.chatHistory
        self.displayedMessageCount = other.displayedMessageCount
        self.allPossibleMessages = other.allPossibleMessages
        self.executionRestriction = other.executionRestriction
        self.chatStartOption = other.chatStartOption
        self.levelUpgrades = other.levelUpgrades
        self.nonLevelUpgrades = other.nonLevelUpgrades
    }
    
    
    // MARK: - Equatable
    
    static func == (lhs: Friend, rhs: Friend) -> Bool {
        return lhs.lastName == rhs.lastName && lhs.description == rhs.description
    }
    
    // MARK: - Chat status control methods
    /**
     Helper method to retrieve an IncomingMessage from allPossibleMessages using its corresponding number index.
     - returns: Optional IncomingMessage whose index in allPossibleMessages is the number, nil if number is invalid.
     */
    private func incomingMessageNumbered(_ number: Int) -> IncomingMessage? {
        return allPossibleMessages[number]
    }
    
    /**
     Sends IncomingMessage with the corresponding index number in allPossibleMessages. Generates ChatMessages from the IncomingMessage and append to the chat history. Notifies chatDelegate of the addition. Records the IncomingMessage's responses to set the responseStatus, if responses is nil,
     */
    func sendIncomingMessageNumbered(_ number: Int) {
        guard let incomingMessage = incomingMessageNumbered(number) else { return }
        chatEndingState = .notEnded
        chatHistory.append(contentsOf: incomingMessage.chatMessages)
        chatDelegate?.didAddIncomingMessageWith(responses: incomingMessage.responses, consequences: incomingMessage.consequences)
        responseState = .willPromptUserWith(incomingMessage.responses)
    }
    
    /**
     Sends OutgoingMessage chosen by the user. Generates ChatMessages from the OutgoingMessage and appends to chatHistory. Notifies chatDelegate of the addition. Records the responseStatus as completed.
     */
    func respondedWith(_ outgoingMessage: OutgoingMessage) {
        chatHistory.append(contentsOf: outgoingMessage.chatMessages)
        chatDelegate?.didAddOutgoingMessageWith(responseId: outgoingMessage.responseMessageId, consequences: outgoingMessage.consequences)
        responseState = .completed
    }
    
    /// Directly sends an incoming message. Useful for continue chatting after a quiz or after making a new friend.
    func sendIncomingMessage(_ message: IncomingMessage) {
        chatEndingState = .notEnded
        chatHistory.append(contentsOf: message.chatMessages)
        chatDelegate?.didAddIncomingMessageWith(responses: message.responses, consequences: message.consequences)
    }
    
    /// Starts chat using the corresponding start chat option. This is called during user's initialization and by ConsequenceController.
    func startChat() {
        switch chatStartOption {
        case .sendIncomingMessage(let message):
            sendIncomingMessage(message)
            updateChatHistoryInBackground()
            hasNewMessage = true
            messageStatusDisplayDelegate?.updateNewMessageStatusFor(self)
            responseState = .willPromptUserWith(message.responses)
            chatEndingState = .notEnded
        case .promptUserWith(let choices):
            responseState = .willPromptUserWith(choices)
            chatDelegate?.didAddIncomingMessageWith(responses: choices, consequences: nil)
            chatEndingState = .notEnded
        case .none:
            break
        }
        chatStartOption = .none
    }
    
    
    // MARK: - Instance methods
    
    /// When friend is not chatting, this updates chat history at the same time.
    func updateChatHistoryInBackground() {
        var messageAdditionTime: Double = 0
        
        // Every time we update chat history in background, we start with a state of no new message
        hasNewMessage = false
        messageStatusDisplayDelegate?.updateNewMessageStatusFor(self)
        
        hasNewMessage = chatHistory.count - displayedMessageCount != 0
        
        guard displayedMessageCount < chatHistory.count else { return }
        
        // Update the chat history
        for messageIndex in displayedMessageCount ..< chatHistory.count {
            let message = chatHistory[messageIndex]
            guard message.direction == .incoming else { continue }
            
            messageAdditionTime += message.delay
            
            // Schedule notification if required
            if message.direction == .incoming {
                let content = UNMutableNotificationContent()
                content.title = self.shortName
                content.body = message.text
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: messageAdditionTime, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                let notificationCenter = UNUserNotificationCenter.current()
                notificationCenter.add(request, withCompletionHandler: { (error) in
                    if error != nil {
                        print("Something went wrong.")
                    }
                })
            }
            
            let messageBackgroundAdditionTimer = Timer(timeInterval: messageAdditionTime, repeats: false) { (timer) in
                // Stop updating as soon as the friend is chatting again
                guard self.isChatting == false else {
                    timer.invalidate()
                    return
                }
                
                // Update related delegates
                self.displayedMessageCount += 1
                self.messageStatusDisplayDelegate?.updateNewMessageStatusFor(self)
                self.messageStatusDisplayDelegate?.moveCellToTopFor(self)
            }
            
            messageBackgroundAdditionTimer.tolerance = 0.5
            RunLoop.current.add(messageBackgroundAdditionTimer, forMode: .common)
        }
    }
    
    /// Before dismissing chat delegate, update the displayed message count, isChatting status and start updating chat in background. This is called when the the chat delegate is about to be dismissed.
    func willDismissChatDelegateWithChatHistoryCount(_ count: Int) {
        displayedMessageCount = count
        isChatting = false
        updateChatHistoryInBackground()
    }
    
    /// Changes loyalty progress.
    func changeLoyaltyBy(progress: Int) {
        // Progress does not go beyond maximum.
        let newProgress = loyalty.progress + progress
        var correctProgress = min(newProgress, loyalty.maximumProgress)
        // Progress does not go below 0.
        if correctProgress < 0 {
            correctProgress = 0
        }
        
        // Guard that progress should change
        guard loyalty.progress != correctProgress else { return }
        loyalty.progress = correctProgress
        visualizationDelegate?.visualizeConsequence(.changeFriendLoyaltyBy(progress))
    }
    
    /// Applys all powers to user and self. This is called when the friend becomes the user's new friend.
    func applyAllPowers(to user: User, and friend: Friend) {
        for power in powers {
            apply(power: power, to: user, and: self)
        }
    }
    
    /// Applys power to user and self, depending on the power type.
    func apply(power: Power, to user: User, and friend: Friend) {
        if let interval = power.effectInterval {
            // Apply power that effects periodically
            switch power.type {
            case .userLevel:
                let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { (_) in
                    user.changeLevelBy(progress: power.strength)
                })
                timer.tolerance = 0.5
                power.timer = timer
            case .userSupport:
                let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { (_) in
                    user.changeSupportBy(progress: power.strength)
                })
                timer.tolerance = 0.5
                power.timer = timer
            case .userCoins:
                let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { (_) in
                    user.changeCoinsBy(number: power.strength)
                })
                timer.tolerance = 0.5
                power.timer = timer
            case .friendLoyalty:
                let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { (_) in
                    friend.changeLoyaltyBy(progress: power.strength)
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
                user.changeLevelBy(progress: power.strength)
            case .userSupport:
                user.changeSupportBy(progress: power.strength)
            case .userCoins:
                user.changeCoinsBy(number: power.strength)
            case .friendLoyalty:
                friend.changeLoyaltyBy(progress: power.strength)
            default:
                break
            }
            power.strength = 0
        }
    }
    
    /// Level-based upgrade, called when the upgrade is strictly related the the level up of the user, or when the friend is the tutorial friend.
    func upgradeToLevel(_ level: Int) {
        // Check for available upgrade
        guard let upgrade = levelUpgrades[level] else { return }
        
        // Upgrade
        if let shortTitle = upgrade.shortTitle {
            self.shortTitle = shortTitle
        }
        
        if let fullTitle = upgrade.fullTitle {
            self.fullTitle = fullTitle
        }
        
        if let description = upgrade.description {
            self.description = description
        }
        
        if let chatStartOption = upgrade.chatStartOption {
            self.chatStartOption = chatStartOption
        }
        
        levelUpgrades.removeValue(forKey: level)
    }
    
    /// Non-level based upgrade, called when the .upgradeAndStartChatForFriendWithLastName() consequence is being handled.
    func upgrade() {
        // Check for available upgrade
        guard let upgrade = nonLevelUpgrades.first else { return }
        
        // Upgrade
        if let shortTitle = upgrade.shortTitle {
            self.shortTitle = shortTitle
        }
        
        if let fullTitle = upgrade.fullTitle {
            self.fullTitle = fullTitle
        }
        
        if let description = upgrade.description {
            self.description = description
        }
        
        if let chatStartOption = upgrade.chatStartOption {
            self.chatStartOption = chatStartOption
        }
        
        nonLevelUpgrades.removeFirst()
    }
    
    
    // MARK: - Static properties
    
    /// Old party member is the tutorial friend, who also introduces the user to the game features.
    static var oldPartyMember = Friend(lastName: "Old Party Member", shortTitle: "", fullTitle: "", imageName: "OldPartyMember", description: "I have faith in communism.", loyalty: Percentage(progress: 50), chatHistory: [], displayedMessageCount: 0, executionRestriction: .never,
        powers: Power.powersForFriendWithLastName("Old Party Member"),
        levelUpgrades: [
            1: FriendUpgrade(chatStartOption: .sendIncomingMessage(
                IncomingMessage(texts: "How was your first day in office?", responses: [
                    OutgoingMessage(description: "It's fine.", texts: "It's fine.", "I haven't really found anything I need to deal with.", responseMessageId: 101),
                    OutgoingMessage(text: "It's alright.", responseMessageId: 101),
                    OutgoingMessage(text: "Nothing happened.", responseMessageId: 101, levelRestriction: 2)
                    ])
            )),
        ],
        nonLevelUpgrades: [
            // After finish talking with chebrikov's introduction
            
            FriendUpgrade(chatStartOption: .sendIncomingMessage(IncomingMessage(texts: "How was the talk with them?", responses: [
            OutgoingMessage(text: "Successful", responseMessageId: 103, consequences: [.changeUserLevelBy(5)]),
            OutgoingMessage(text: "Smooth", responseMessageId: 103, consequences: [.changeUserLevelBy(5)])
            ]))),
            // After finish talking with fomin's intro to chernobyl safety test
            FriendUpgrade(chatStartOption: .sendIncomingMessage(IncomingMessage(texts: "Comerade Gorbachev", "In the main page, you will find that your image and the profile images of people who talk to you are all tappable.", "By tapping on the images, you can see detailed information about you and others", "Tip of the day, everyone, including you, has 3 powers. These powers may help you a lot.", "Use your coins wisely to upgrade these powers when you can.", responses: [
                OutgoingMessage(description: "(Get another tip)", texts: "That was a really useful tip, comerade.", responseMessageId: 105)
            ]))),
            
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])])),

        ],
        startChatUsing: .sendIncomingMessage(
            IncomingMessage(texts: "Congratulations on becoming the president of the Soviet Union, comerade Gorbachev.", responses: [OutgoingMessage(text: "Thank you comerade.", responseMessageId: 1)])
        ),
        allPossibleMessages:[
            // Tutorial messages.
            1: IncomingMessage(texts: "Although you are the ultimate leader, not every one is 100% loyal to you.", "Your support is determined by the average loyalty of everyone working for you.", "Promise me you will keep this in mind, comerade Gorbachev.", "Because The Union will collapse if people no longer support you.", responses: [
                OutgoingMessage(text: "I promise.", responseMessageId: 2),
                OutgoingMessage(text: "I know.", responseMessageId: 2)
            ]),
            2: IncomingMessage(texts: "Now the country depends on you.", "Remember to turn on notifications so you won't miss anything important.", responses: [
                OutgoingMessage(text: "I will.", responseMessageId: 3, consequences: [.askForNotificationPermission]),
                OutgoingMessage(text: "Nope.", responseMessageId: 3, consequences: [.askForNotificationPermission])
            ]),
            3: IncomingMessage(texts: "Good luck.", responses: [
                OutgoingMessage(description: "Start Game", consequences: [.startGame])
            ]),
            
            // Introduction.
            101: IncomingMessage(texts: "Have you talked to the ministers yet?", responses: [
                OutgoingMessage(text: "Not yet", responseMessageId: 102)
            ]),
            102: IncomingMessage(texts: "They should come to your office at any minute.", "Be prepared.", responses: [
                OutgoingMessage(description: "(Talk to Minister of Energy)", consequences: [.makeNewFriend(Friend.shcherbina), .setChatStartOption(.promptUserWith([OutgoingMessage(description: "(Talk to Chairman of KGB)", consequences: [.makeNewFriend(Friend.chebrikov), .setChatStartOption(.sendIncomingMessage(IncomingMessage(texts: "The ministers should give you a good amount of information.", "Talk to them when you are ready.", responses: [
                        OutgoingMessage(text: "OK", responseMessageId: nil)
                    ])))])])),
                    ])
            ]),
            103: IncomingMessage(texts: "Well", "Let's see if you remembered the important details.", responses: [
                OutgoingMessage(text: "Go Ahead", responseMessageId: nil, levelRestriction: nil, consequences: [.startQuizOfCategory(.facts), .setChatStartOption(.sendIncomingMessage(IncomingMessage(texts: "Not bad.", "I'm sure that the Minister of Energy and Oil Boris Shcherbina told you a lot about our nuclear reactors.", "Let's see how much you know about them.", responses: [
                    OutgoingMessage(text: "Fire away", responseMessageId: nil, consequences: [.startQuizOfCategory(.nuclear), .setChatStartOption(.sendIncomingMessage(IncomingMessage(texts: "Well, I guess there's plenty of stuff you must know as the president of USSR, comerade Gorbachev.", "You should talk more with the Ministers", consequences: [.upgradeAndStartChatForFriendWithLastName("Shcherbina")], responses: [
                        OutgoingMessage(description: "Certainly", texts: "Certainly", "Thank you for all the help, comerade.", responseMessageId: 104, consequences: [.changeUserLevelBy(10)]),
                        OutgoingMessage(description: "Thank you", texts: "Thank you, comerade.", "There's plenty I need to learn even as the president.", responseMessageId: 104, consequences: [.changeUserLevelBy(15)]),
                        ])))])
                ])))])
            ]),
            104: IncomingMessage(texts: "I have faith in you, comerade Gorbachev.", "Our country needs a leader like you.", consequences: [.changeFriendLoyaltyBy(5)], responses: [
                OutgoingMessage(description: "Leave Chat", texts: "I will not let anyone down.", responseMessageId: nil, consequences: [.endChatFrom(.outgoing)])
            ]),
            105: IncomingMessage(texts: "Some people might have powers that harm your support and unstablize the country.", "When your level gets higher, you will be allowed to execute some of them.", responses: [
                OutgoingMessage(text: "Thank you, comerade.", responseMessageId: 106, levelRestriction: 2, consequences: [.changeFriendLoyaltyBy(5)]),
                OutgoingMessage(text: "I will never kill anyone.", responseMessageId: 107, consequences: [.changeUserLevelBy(10)]),
            ]),
            106: IncomingMessage(texts: "Remember, use your power wisely. Don't abuse it.", responses: [
                OutgoingMessage(text: "I will do the right thing.", responseMessageId: 108)
            ]),
            107: IncomingMessage(texts: "Empathy is your virtue", "But it might also be your weakness.", consequences: [.changeFriendLoyaltyBy(5)], responses: [
                OutgoingMessage(text: "I do what's right.", responseMessageId: 108)
            ]),
            108: IncomingMessage(texts: "I think now you are able to work on anything without my guidance.", "You will make tough decisions as the president of USSR, and people are going to talk whatever you do.", "Don't be afraid to do the right thing you belive in", "because history is the ultimate judge.", responses: [
                OutgoingMessage(description: "Thank you", texts: "Thank you for all your guidance, comerade.", "Will I ever be able to talk to you again?", responseMessageId: 109)
            ]),
            109: IncomingMessage(texts: "I never said I won't talk to you anymore.", "You can still come to me to get challenged for timed questions, in case you want to increase your level or to get more coins.", consequences: [.upgradeAndStartChatForFriendWithLastName("Fomin")], responses: [
                OutgoingMessage.startQuizInCategory(.all, withDescription: "Start Challenge", consequences: [.upgradeFriendWithLastName("Old Party Member")])
            ]),
            
        ]
    )
    
    /// Minister of energy.
    static var shcherbina = Friend(lastName: "Shcherbina", shortTitle: "Minister", fullTitle: "Minister of Energy", imageName: "Shcherbina", description: "USSR is the strongest nation.", loyalty: Percentage(progress: 50), chatHistory: [], displayedMessageCount: 0, executionRestriction: .level(10),
        powers: Power.powersForFriendWithLastName("Shcherbina"),
        levelUpgrades: [
            4: FriendUpgrade(chatStartOption: .sendIncomingMessage(IncomingMessage(texts: "My president, I have good news and bad news.", responses: [
                OutgoingMessage(description: "(Good news first)", texts: "Tell me the good news first.", responseMessageId: nil, levelRestriction: 10),
                OutgoingMessage(description: "(Bad news first)", texts: "Tell me the bad news first.", responseMessageId: 401, consequences: [.changeUserLevelBy(10)])
                ]))),
        ],
        nonLevelUpgrades: [
            // Introduction to fomin
            FriendUpgrade(chatStartOption: .sendIncomingMessage(IncomingMessage(texts: "President Gorbachev, Vladimir Llyich Lenin Nuclear Power Plant Chief Engineer Nikolai Fomin wants to talk to you.", responses: [
            OutgoingMessage(text: "OK.", responseMessageId: nil, consequences: [.makeNewFriend(Friend.fomin), .setChatStartOption(.promptUserWith([OutgoingMessage.leaveChat]))]),
            OutgoingMessage(text: "Later", responseMessageId: 106, levelRestriction: 2, consequences: [.changeFriendLoyaltyBy(-1)]),
            ]))),
            
            // Introduction to radioactivity
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage(description: "(Reach level 4 to continue)", responseMessageId: nil, levelRestriction: 4)])),
            
            // Crisis handling
            FriendUpgrade(chatStartOption: .promptUserWith([
                OutgoingMessage(text: "Things went really wrong.", responseMessageId: 501)
            ])),
            
            // Ending
            FriendUpgrade(chatStartOption: .sendIncomingMessage(IncomingMessage(texts: "The Chernobyl crisis has been dealth with succesfully, president Gorbachev.", "You saved lives of countless people, although at a cost of the lives of many other.", "You will be remembered by the history, and the history is the ultimate judge.", consequences: [.changeUserSupportBy(100), .changeFriendLoyaltyBy(100)], responses: [
                OutgoingMessage.leaveChat
            ]))),
            
        ],
        startChatUsing: .sendIncomingMessage(IncomingMessage(texts: "My President...", "Congratulations on becoming the new leader.", responses: [
                OutgoingMessage(text: "Who are you?", responseMessageId: 101, consequences: [.changeUserLevelBy(-1)]),
                OutgoingMessage(text: "Introduce yourself.", responseMessageId: 101),
            ])),
        allPossibleMessages: [
            // Introduction.
            101: IncomingMessage(texts: "I am Boris Shcherbina, Minister of Energy and Oil.", "The energy production of the country has been steadily increasing over the years", "Electricity is available in regions wider than ever", "Thanks to the nuclear power plants we built in recent years", responses: [
                OutgoingMessage(description: "(Talk about energy production.)", texts: "How did we increase energy production over the years?", responseMessageId: 102),
                OutgoingMessage(description: "(Talk about nuclear power plant.)", texts: "Give me a brief report on the nuclear power plants in the country.", responseMessageId: 103, consequences: [.changeUserLevelBy(10)])
            ]),
            102: IncomingMessage(texts: "We have built dams on main streams of rivers", "They were huge projects with thousands of people working day and night on the contruction sites", responses: [
                OutgoingMessage(description: "(Keep listening)", responseMessageId: 103, consequences: [.changeUserLevelBy(10)]),
                OutgoingMessage(description: "(Stop listening)", responseMessageId: 103, levelRestriction: 3)
            ]),
            103: IncomingMessage(texts: "We have built several nuclear power plants in the Union", "Several of them are RBMK reactors, whose core technologies are devised purely by Soviet scientists.", responses: [
                OutgoingMessage(text: "How safe are these reactors?", responseMessageId: 104, consequences: [.changeUserLevelBy(10)]),
                OutgoingMessage(description: "Good", texts: "Good", "You have done a good job serving your contry, Comerade Shcherbina.", responseMessageId: 105)
            ]),
            104: IncomingMessage(texts: "All the reactors have gone through rigorous safety tests before they are put into work.", "No accident ever happened to these reactors since they were built.", responses: [
                OutgoingMessage(description: "Good", texts: "Good", "You have done a good job serving your contry, Comerade Shcherbina.", responseMessageId: 105)
            ]),
            105: IncomingMessage(texts: "Thank you president Gorbachev.", consequences: [.changeFriendLoyaltyBy(10)], responses: [
                OutgoingMessage.leaveChat
            ]),
            
            // Introduction to Fomin
            106: IncomingMessage(texts: "My President", "Fomin insisted that he had important things to talk about.", responses: [
                OutgoingMessage(description: "OK then.", texts: "OK then. I'll talk to him.", responseMessageId: nil, consequences: [.makeNewFriend(Friend.fomin), .setChatStartOption(.promptUserWith([OutgoingMessage.leaveChat]))])
            ]),
            
            // Introduction to radioactivity
            401: IncomingMessage(texts: "The bad news is that Ukrainian Soviet Socialist Republic has reported higher than normal radioactivity reading in Pripyat, Kiev.", "But", "The good news is that this has just happened", "and no foreign media is aware of this.", responses: [
               OutgoingMessage(text: "Have we found the cause?", responseMessageId: 402, consequences: [.changeUserLevelBy(10)]),
               OutgoingMessage(description: "Don't do anything yet", texts: "Don't do anything yet.", "We should all get a good rest tonight, and have faith in our comerades, who are definitely capable of solving their own problems.", responseMessageId: 403)
            ]),
            402: IncomingMessage(texts: "Nuclear expert Valery Legasov is now investigating this incident under my supervision.", responses: [
                OutgoingMessage(text: "Let me talk to him", responseMessageId: nil, consequences: [.makeNewFriend(Friend.legasov), .setChatStartOption(.promptUserWith([OutgoingMessage.leaveChat]))])
            ]),
            403: IncomingMessage(texts: "Yes my president.", consequences: [.changeFriendLoyaltyBy(10)], responses: [
                OutgoingMessage.leaveChatWith(consequences: .upgradeAndStartChatForFriendWithLastName("Chebrikov"))
            ]),
            
            // Crisis handling
            501: IncomingMessage(texts: "What happened my president?", responses: [
                OutgoingMessage(description: "Chernobyl's reactor exploded.", texts: "Chernobyl's reactor exploded. There was nothing left.", responseMessageId: 502)
            ]),
            502: IncomingMessage(texts: "What can I do for you, president Gorbachev?", responses: [
                OutgoingMessage(description: "Nothing.", texts: "Nothing.", "Everything is over.", "We can't undo history.", responseMessageId: 582, consequences: [.changeUserLevelBy(-50)]),
                OutgoingMessage(description: "Anything.", texts: "Anything.", "This is a complete disaster for the entire mankind.", "And we have to face it together.", responseMessageId: 503)
            ]),
            582: IncomingMessage(texts: "I am sorry, president Gorbachev.", consequences: [.upgradeAndStartChatForFriendWithLastName("Chebrikov"), .setChatStartOption(.promptUserWith([OutgoingMessage.leaveChat]))]),
            503: IncomingMessage(texts: "We should start dealing with the crisis now, my president.", "I am willing to take on the responsibility.", consequences: [.changeFriendLoyaltyBy(20)], responses: [
                OutgoingMessage(description: "Thank you, comerade.", texts: "Thank you, comerade.", "What should we do then?", responseMessageId: 504, consequences: [.changeFriendLoyaltyBy(10)])
            ]),
            504: IncomingMessage(texts: "There's plenty of stuff we need to do, on the national scale, my President.", "For now, we should evacuate the civilians living near Chernobyl as soon as possible.", responses: [
               OutgoingMessage(description: "Good", texts: "Good.", "What next?", responseMessageId: 505)
            ]),
            505: IncomingMessage(texts: "We need to limit the contamination as much as possible.", "The debris emitted due to the explosion must be collected, and we must prevent the reactor core from exploding again.", "Scientist Legasov had proposed 2 plans", "Plan A is to cover up the melted reactor core with boron sand, but this might increase the core temprature of the melted fuel, also known as the nuclear lava.", "Plan B is to cool down the lava quickly with large amounts of water, but this might contaminate the water cycle even more.", responses: [
                OutgoingMessage(text: "Use Plan A!", responseMessageId: 506),
                OutgoingMessage(text: "Use Plan B!", responseMessageId: 507)
            ]),
            506: IncomingMessage(texts: "President Gorbachev", "The plan you chose worked!", "But the lava has become even hotter than before", "If we do not take actions, the lava might melt deeper into the ground", "if it touches any underground water, the lava will explode immediately.", "Scientist Legasov said the only way to stop this from happening is to construct a huge cooling structure underground, below the lava.", consequences: [.changeUserLevelBy(10)], responses: [
                OutgoingMessage(description: "(Raise question)", texts: "If the plan would work, why aren't they working on it?", responseMessageId: 508),
                OutgoingMessage(description: "(Start now!)", texts: "Start the construction right now!", "We cannot afford to wait.", responseMessageId: 508)
            ]),
            507: IncomingMessage(texts: "President Grobachev", "The lava unexpectedly exploded when it met the water.", "There was nothing we could do.", "I failed your trust, president Gorbachev.", consequences: [.changeUserLevelBy(-100)], responses: [
                OutgoingMessage(text: "You are fired.", responseMessageId: nil, consequences: [.endChatFrom(.outgoing), .upgradeAndStartChatForFriendWithLastName("Chebrikov")])
            ]),
            508: IncomingMessage(texts: "My President...", "The radiation below the lava is fatal.", "To construct this structure, you must give the order to KILL a group of construction workers, miners, and engineers.", responses: [
                OutgoingMessage(description: "(Approve)", texts: "All victories come at a cost, comerade Shcherbina.", responseMessageId: 509, consequences: [.changeUserLevelBy(10)]),
                OutgoingMessage(description: "(Disapprove)", texts: "No one should die for the mistake of someone they don't even know.", "Comerade Shcherbina, history will be our judge.", responseMessageId: 510, consequences: [.changeUserLevelBy(99)]),
            ]),
            509: IncomingMessage(texts: "Yes ... my President.", consequences: [.changeFriendLoyaltyBy(1)], responses: [
               OutgoingMessage(text: "Have we done the right thing?", responseMessageId: 511),
            ]),
            510: IncomingMessage(texts: "My President...", "The lava exploded when it met the underground water.", "There was nothing we could do.", "I failed your trust, president Gorbachev.", responses: [
                OutgoingMessage(description: "It was my choice.", texts: "It was my choice.", "Do not blame everything on yourself, comerade.", "Go home and take a good rest. You have done your job.", responseMessageId: 582)
            ]),
            511: IncomingMessage(texts: "Yes!", "The temprature of the lava has been reducing steadily, my President.", "All miners, workers, and engineers are receiving professional medical treatment right now.", "It was a job well done.", responses: [
                OutgoingMessage(text: "Anything else we need to do?", responseMessageId: 512)
            ]),
            512: IncomingMessage(texts: "There is one last thing...", "The initial explosion has emitted highly radioactive rocks on to the roof of the reactor.", "We tried using robots to clear off these debris, but the radiation was so extreme that they all broke down even before reaching these rocks.", "We need... approximately 500,000 men to take turns to clean up these debris before everyone leaves the power plant, we will offically refer to them as bio-robots.", responses: [
                OutgoingMessage(description: "(Approve)", texts: "History will be our judge, Comerade Shcherbina.", "It has to be done.", responseMessageId: 513, consequences: [.changeUserLevelBy(10)]),
                OutgoingMessage(description: "(Disapprove)", texts: "No one should die for the mistake of someone they don't even know.", "Comerade Shcherbina, history will be our judge.", responseMessageId: 514, consequences: [.changeUserLevelBy(99)]),
            ]),
            513: IncomingMessage(texts: "President Gorbachev", "Bio-robots are now on their way to Chernobyl for the very last task.", consequences: [.changeUserLevelBy(1000), .upgradeAndStartChatForFriendWithLastName("Shcherbina")])
            
        ]
    )
    
    /// Chairman of KGB.
    static var chebrikov = Friend(lastName: "Chebrikov", shortTitle: "Chairman", fullTitle: "Chairman of KGB", imageName: "Chebrikov", description: "Safety is relative, information is definite.", loyalty: Percentage(progress: 50), chatHistory: [], displayedMessageCount: 0, executionRestriction: .level(10),
        powers: Power.powersForFriendWithLastName("Chebrikov"),
        levelUpgrades: [
            :
        ],
        nonLevelUpgrades: [
            // The end of game.
            FriendUpgrade(chatStartOption: .sendIncomingMessage(IncomingMessage(texts: "President Gorbachev", "The ambassador of the US wanted to talk to you urgently.", responses: [
                OutgoingMessage(text: "OK", responseMessageId: nil, consequences: [.makeNewFriend(Friend.americanAmbassador)])
            ]))),
        ],
        startChatUsing: .sendIncomingMessage(IncomingMessage(texts: "President Gorbachev", "KGB pledges loyalty to you.", responses: [
            OutgoingMessage(description: "Certainly.", texts: "Certainly.","I hope you and your colleges could protect our country from danger and instability.", responseMessageId: 101),
            OutgoingMessage(description: "Thank you, comerade.", texts: "Thank you, comerade.", "Now give me a brief of KGB.", responseMessageId: 101)
        ])),
        allPossibleMessages: [
            // Introduction.
            101: IncomingMessage(texts: "KGB is the main security agency for our country", "We ensure the leadership of the CCCP, the integrity of USSR", "The country is safe as long as KGB still operates.", responses: [
                OutgoingMessage(description: "(Reply seriously)", texts: "Comerade Chebrikov", "I hope KGB works up to your standards.", responseMessageId: 103, consequences: [.changeUserLevelBy(10)]),
                OutgoingMessage(description: "(Reply with humor)", consequences: [], levelRestriction: 3)
            ]),
            102: IncomingMessage(texts: "Certainly.", "KGB is the main security agency for our country", "We ensure the leadership of the CCCP, the integrity of USSR", "The country is safe as long as KGB still operates.", responses: [
                OutgoingMessage(description: "(Reply seriously)", texts: "Comerade Chebrikov", "I hope KGB works up to your standards.", responseMessageId: 103, consequences: [.changeUserLevelBy(10)]),
                OutgoingMessage(description: "(Reply with humor)", consequences: [], levelRestriction: 3)
            ]),
            103: IncomingMessage(texts: "Certainly, president Gorbachev.", consequences: [.changeFriendLoyaltyBy(5)], responses: [
                OutgoingMessage.leaveChatWith(consequences: .upgradeAndStartChatForFriendWithLastName("Old Party Member"))
            ]),
        ]
    )
    
    /// Chernobyl chief engineer.
    static var fomin = Friend(lastName: "Fomin", shortTitle: "Engineer", fullTitle: "Chernobyl Chief Engineer", imageName: "Fomin", description: "Promotion is on the way.", loyalty: Percentage(progress: 50), chatHistory: [], displayedMessageCount: 0, executionRestriction: .level(10),
        powers: Power.powersForFriendWithLastName("Fomin"),
        levelUpgrades: [
        3: FriendUpgrade(chatStartOption: .sendIncomingMessage(IncomingMessage(texts: "President Gorbachev...", "A regional power station in Kiev went offline unexpectedly", "Since many factories rely heavily on electricity ", "we might have to delay the safety test until after midnight in order to sustain power supply", responses: [
            OutgoingMessage(text: "Do what you think is right", responseMessageId: 301, consequences: [.changeUserLevelBy(5)]),
            OutgoingMessage(text: "You seem... uncertain.", responseMessageId: 302, levelRestriction: 10)
        ]))),
        ],
        nonLevelUpgrades: [
            FriendUpgrade(chatStartOption: .promptUserWith([OutgoingMessage(description: "(Reach level 3 to continue)", responseMessageId: 301, levelRestriction: 3)])),
            FriendUpgrade(chatStartOption: .promptUserWith([
                OutgoingMessage(description: "What's going on?", texts: "What's going on?", "People talked to me about radiaction in Chernobyl all night tonight.", "You better explain what happened.", responseMessageId: 401),
                OutgoingMessage(description: "You better tell me everything.", texts: "You better tell me everything.", "People has been talking to me all night about what happened in Chernobyl", "I'm here looking for an explanation.", responseMessageId: 401, levelRestriction: 5, consequences: [.changeUserLevelBy(10)])
            ]))
        ],
        startChatUsing: .sendIncomingMessage(IncomingMessage(texts: "President Gorbachev", "Sorry for disturbing you at this moment.", responses: [
            OutgoingMessage(text: "What's the matter?", responseMessageId: 101),
            OutgoingMessage(description: "No need to be sorry", texts: "No need to be sorry", "Now, what's important that you need to talk to me about?", responseMessageId: 101, levelRestriction: 2, consequences: [.changeUserLevelBy(10)])
        ])),
        allPossibleMessages: [
            // Introduction to chernobyl.
            101: IncomingMessage(texts: "I am the chief engineer at the Vladimir Llyich Lenin Nuclear Power Plant, also known as the Chernobyl nuclear power plant.", "We plan to conduct a safety test on the reactors in a few days.", responses: [
                OutgoingMessage(description: "(Raise questions)", texts: "Aren't the power plants very safe?", "Why do you still need to conduct a safety test?", responseMessageId: 102, consequences: [.changeUserLevelBy(10)]),
                OutgoingMessage(description: "(Approve the test)", texts: "Go ahead and do it.", "You don't have to report everything to me directly", "I believe that you understand the power plants much more than I do", responseMessageId: 103),
                OutgoingMessage(description: "(Disapprove the test)", texts: "Minister of Energy and Oil Boris Shcherbina told me that the power plants are absolutely safe.", "I don't think another safety test is necessary.", responseMessageId: 102, levelRestriction: 3)
            ]),
            102: IncomingMessage(texts: "The nuclear power plants are 100% safe under normal circumstances", "But as engineers", "We want to make sure that even during incidents like a complete power outage, Chernobyl will still be operating safely.", responses: [
                OutgoingMessage(description: "(Say nothing)", responseMessageId: 103),
            ]),
            103: IncomingMessage(texts: "I will report to you a successful test in a few days, president Gorbachev.", consequences: [.changeFriendLoyaltyBy(5)], responses: [
                OutgoingMessage.leaveChatWith(consequences: .upgradeAndStartChatForFriendWithLastName("Old Party Member"))
            ]),
            
            // Delay of test
            301: IncomingMessage(texts: "Understood.", "I will report back to you immediately once the test is completed.", consequences: [.changeFriendLoyaltyBy(5), .endChatFrom(.incoming), .upgradeAndStartChatForFriendWithLastName("Shcherbina")]
            ),
            
            // Explanation for water tank
            401: IncomingMessage(texts: "President Gorbachev", "Everything is under control.", "There was an explosion in the one of the water tanks in the reactor's facility", "but the reactor core is perfectly safe", "A group of engineers at Chernobyl had things in control, firefighters are sent to quickly distinguish the fire, and everything should be back to normal within a week.", responses: [
                OutgoingMessage(text: "Let me talk with the firefighers", responseMessageId: nil, consequences: [.changeUserLevelBy(5), .makeNewFriend(Friend.firefighter)]),
                OutgoingMessage(text: "Let me talk with the engineers", responseMessageId: nil, consequences: [.changeUserLevelBy(5), .makeNewFriend(Friend.akimov)]),
                OutgoingMessage(description: "Don't let me down.",  texts: "Don't let me down.", "Solve this problem as quickly as you can.", responseMessageId: 404),
            ]),
            
            404: IncomingMessage(texts: "Certainly, president Gorbachev.", "Please have a good rest tonight, and I will report to you tomorrow morning when you wake up.", consequences: [.changeFriendLoyaltyBy(10)], responses: [
                OutgoingMessage.leaveChatWith(consequences: .upgradeAndStartChatForFriendWithLastName("Chebrikov"))
            ]),
        ]
    )
    
    static var legasov = Friend(lastName: "Legasov", shortTitle: "Scientist", fullTitle: "Nuclear Expert", imageName: "Legasov", description: "Science is the truth.", loyalty: Percentage(progress: 50), chatHistory: [], displayedMessageCount: 0, executionRestriction: .level(10),
        powers: Power.powersForFriendWithLastName("Legasov"),
        levelUpgrades: [:],
        nonLevelUpgrades: [],
        startChatUsing: .promptUserWith([
            OutgoingMessage(description: "Start talking", texts: "Shcherbina said you are an nuclear expert.", "Now tell me what has happened in Kiev.", responseMessageId: 101)
        ]),
        allPossibleMessages: [
            // Introduction to leakage at chernobyl
            101: IncomingMessage(texts: "Yes, president Gorbachev.", "According to the radiation readings in Kiev", "It seems that...", "there had been an leakage of highly radioactive material into the air.", "We were trying to seek for alternative explanations for this as well", "but for this moment, it is almost certain that something happened at Chernobyl Nuclear Power Plant.", responses: [
                OutgoingMessage(text: "Tell me everything you know.", responseMessageId: 102, consequences: [.changeFriendLoyaltyBy(5)]),
                OutgoingMessage(text: "Why are you sure it's Chernobyl?", responseMessageId: 102, levelRestriction: 4, consequences: [.changeUserLevelBy(10)])
            ]),
            102: IncomingMessage(texts: "There's only one nuclear power plant in Kiev -- Chernobyl.", "To get a reading as large as the one we got, the leakage must've come from a source in which the radioactive materials come in large quantities.", "The source might also be from one of the nuclear mines as well, but the readings they reported excluded that possibility", "which made me come to the conclusion that something probably went very wrong in Chernobyl.", responses: [
               OutgoingMessage(description: "Keep an eye on any updates.", texts: "Keep an eye on any updates, and report anything urgent to me immediately.", responseMessageId: 103, consequences: [.changeUserLevelBy(5)]),
               OutgoingMessage.leaveChatWith(consequences: .upgradeAndStartChatForFriendWithLastName("Fomin"))
            ]),
            103: IncomingMessage(texts: "Yes, president Gorbachev.", responses: [
               OutgoingMessage.leaveChatWith(consequences: .upgradeAndStartChatForFriendWithLastName("Fomin"))
            ]),
        ]
    )
    
    // Firefighter
    static var firefighter = Friend(lastName: "Ignatenko", shortTitle: "Firefighter", fullTitle: "Firefighter", imageName: "Firefighter", description: "Love my life.", loyalty: Percentage(progress: 50), chatHistory: [], displayedMessageCount: 0, executionRestriction: .never,
        powers: Power.powersForFriendWithLastName("Ignatenko"),
        levelUpgrades: [:],
        nonLevelUpgrades: [],
        startChatUsing: .promptUserWith([
            OutgoingMessage(description: "(Ask what happened)", texts: "This is President Gorbachev", "Please tell me what you saw in Chernobyl", responseMessageId: 101),
        ]),
        allPossibleMessages: [
            101: IncomingMessage(texts: "President Gorbachev", "We have been trying to put out the fire in Chernobyl nuclear power plant", "There is fire on the roof, around reactor 4, and the fire is getting smaller than it was.", "Some of us saw dark-colored rocks on the ground, smoking hot. These rocks seem to have been emitted by the explosion from the reactor structures.", responses: [
                OutgoingMessage(text: "Any other information?", responseMessageId: 102),
                OutgoingMessage(description: "Thank you, comerade Ignatenko.", texts: "Thank you, comerade Ignatenko.", "People will remember your bravery and valor tonight.", "Is there anything else you want to tell me?", responseMessageId: 102, consequences: [.changeFriendLoyaltyBy(10)]),
            ]),
            102: IncomingMessage(texts: "Shift Leader of Chernobyl Nuclear Power Plant Akimov sounded really scared when he called the fire department", "Maybe president Gorbachev could ask him what happened inside the control room?", consequences: [.makeNewFriend(Friend.akimov), .setChatStartOption(.promptUserWith([
                    OutgoingMessage(description: "Thank you, comerade Ignatenko.", texts: "Thank you, comerade Ignatenko.", "People will remember your bravery and valor tonight.", responseMessageId: 103, consequences: [.changeUserLevelBy(10)])
            ]))]),
            103: IncomingMessage(texts: "It's an honor fulfilling my duty, president Gorbachev.", consequences: [.changeFriendLoyaltyBy(10)], responses: [
               OutgoingMessage.leaveChat
            ]),
        ])
    
    // Shift leader Akimov
    static var akimov = Friend(lastName: "Akimov", shortTitle: "Engineer", fullTitle: "Chernobyl Shift Leader", imageName: "Akimov", description: "Love being a engineer.", loyalty: Percentage(progress: 50), chatHistory: [], displayedMessageCount: 0, executionRestriction: .level(7),
        powers: Power.powersForFriendWithLastName("Akimov"),
        levelUpgrades: [:],
        nonLevelUpgrades: [],
        startChatUsing: .sendIncomingMessage(IncomingMessage(texts: "President Gorbachev", "I am Chernobyl Nuclear Power Plant Unit 4 Shift Leader Akimov", responses: [
            OutgoingMessage(description: "No time for self-introduction", texts: "No time for self-introduction", "Tell me what happened in the control room.", responseMessageId: 101, consequences: [.changeUserLevelBy(5)])
        ])),
        allPossibleMessages: [
            101: IncomingMessage(texts: "We were performing the safety test as Engineer Fomin instructed", "The first time we tried to lower the power output to 500 MW, it went really unstable and dropped below 200 MW.", "I suggested canceling the safety test and restarting tomorrow, but Engineer Fomin insisted that we must complete it tonight, or he would see to it that we would never be employed anywhere else.", responses: [
                OutgoingMessage(text: "What happened then?", responseMessageId: 102)
            ]),
            102: IncomingMessage(texts: "We continued the test, disregarding all safety protocols and warnings given by the computer.", "When we tried to raise the power again, the power surged to more than 30,000 MW.", "We were really shocked, and all tried all options to lower the power output, none worked", "After a few seconds, Engineer Fomin rushed over to the control panel and pressed the AZ-5 button", responses: [
                OutgoingMessage(text: "AZ-5 button?", responseMessageId: 103, consequences: [.changeUserLevelBy(5)]),
                OutgoingMessage(text: "And?", responseMessageId: 104, levelRestriction: 5)
            ]),
            103: IncomingMessage(texts: "It's the emergency button which is designed to shut down the reactor.", "But...", "But we heard explosions immediately after that", "The dosimeter in the control room maxed to 3.6 Roentgen soon after.", "President Gorbachev, what should I do now?", responses: [
                OutgoingMessage(description: "Manually check the reactor", texts: "Go to the reactor core and report its condition to me directly. I need to know how serious this entire thing is now.", responseMessageId: 104, consequences: [.changeUserLevelBy(5)]),
                OutgoingMessage(description: "Stay put", texts: "Engineer Fomin told me it was not a big issue.", "You have been working for a long night already, comerade Akimov", "Fomin will take care of the problem.", responseMessageId: 105)
            ]),
            104: IncomingMessage(texts: "But...", consequences: [.changeFriendLoyaltyBy(-1)], responses: [
               OutgoingMessage(text: "This is an order.", responseMessageId: 106, consequences: [.changeFriendLoyaltyBy(-5)]),
            ]),
            105: IncomingMessage(texts: "Thank you, President Gorbachev.", "If you need any other information, I am always willing to help, my president.", consequences: [.changeFriendLoyaltyBy(10)], responses: [
               OutgoingMessage(text: "Get some rest, comerade.", responseMessageId: nil, consequences: [.endChatFrom(.outgoing), .upgradeAndStartChatForFriendWithLastName("Chebrikov")])
            ]),
            106: IncomingMessage(texts: "Certainly... I will go check the core now...", ".........", ".........", ".........", responses: [
                OutgoingMessage(text: "Report back to me.", responseMessageId: 107),
                OutgoingMessage(text: "What took you so long?", responseMessageId: 107, consequences: [.changeUserLevelBy(-5)])
            ]),
            107: IncomingMessage(texts: "My...", "My President...", "There is...", "There is nothing left.......", consequences: [.changeFriendLoyaltyBy(-5)], responses: [
                OutgoingMessage(text: "What did you see?!", responseMessageId: 108),
            ]),
            108: IncomingMessage(texts: "The entire reactor core was gone...", "It exploded...", responses: [
                OutgoingMessage(description: "You need a rest, comerade Akimov.", texts: "You need a rest, comerade Akimov.", "I will handle the rest from now on.", responseMessageId: nil, consequences: [.setChatStartOption(.promptUserWith([OutgoingMessage.leaveChat])), .upgradeAndStartChatForFriendWithLastName("Shcherbina")])
            ]),
        ]
    )
    
    
    
    
    static var americanAmbassador = Friend(lastName: "US Ambassador", shortTitle: "", fullTitle: "", imageName: "AmericanAmbassador", description: "One nation, under god.", loyalty: Percentage(progress: 0), chatHistory: [], displayedMessageCount: 0, executionRestriction: .never,
        powers: Power.powersForFriendWithLastName("US Ambassador"),
        levelUpgrades: [:],
        nonLevelUpgrades: [],
        startChatUsing: .sendIncomingMessage(IncomingMessage(texts: "President Gorbachev, not sure if you are aware of this yet", "but our satellite information has shocked many government officals in America over the last night.", consequences: [.changeUserLevelBy(-10)], responses: [
            OutgoingMessage(description: "(Reply softly)", texts: "I do not understand what you are hinting at exactly", "perhaps we could talk a little more about it in my office?", responseMessageId: 1001, consequences: [.changeUserLevelBy(-15)]),
            OutgoingMessage(description: "(Reply harshly)", texts: "At what time did we allow your satellites to pick up our information?", "I consider that an extremely disrespectful and hostile act, ambassador.", responseMessageId: 1002, consequences: [.changeUserLevelBy(-15)])
        ])),
        allPossibleMessages: [
            1001: IncomingMessage(texts: "It seems that ...", "To express it using the most accurate terms...", "There had been a total disaster in Chernobyl nuclear power plant.", "We detected a complete meltdown, followed by a unimaginably destructive explosion.", consequences: [.changeUserLevelBy(-100)], responses: [
           OutgoingMessage(description: "(Say nothing)", responseMessageId: 1002),
        ]),
            1002: IncomingMessage(texts: "I assume that the president of USSR was attempting to hide the truth from the world had we not detected the unbelievable radioactivity in Chernobyl, am I correct?", "This is a complete disaster for the entire mankind.", "For all people living in the Soviet Ukraine, Latvia, Lithuania, Byelorissia, in Poland, Czechoslovakia, Hungary, Romania, they have all received fatal dosages of radiation.", consequences: [.changeFriendLoyaltyBy(-50)], responses: [
                OutgoingMessage(description: "So what?", texts: "So what?", "Soviet Union always handles problems on its own.", "You go and tell your American friends to mind their own business.", responseMessageId: 1003, consequences: [.changeFriendLoyaltyBy(-50)]),
                OutgoingMessage(description: "(Say nothing)", responseMessageId: 1003, consequences: [.changeUserSupportBy(-50)]),
        ]),
            1003: IncomingMessage(texts: "President Gorbachev, what is society without living people?", "What is socialism then, without societies?", "I'm afraid that there will no longer be a Soviet Union of Socialist Republic.", "Because all your republics will have been long dead due to your flawed nuclear power plants.", consequences: [.changeUserSupportBy(-100), .endChatFrom(.incoming)])
        
        ])
}
