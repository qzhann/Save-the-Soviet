//
//  Friend.swift
//  Uncommon Application
//
//  Created by qizihan  on 12/20/18.
//  Copyright © 2018 qzhann. All rights reserved.
//

import Foundation
import UIKit

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
    /// A dictionary of upgrades for a friend.
    var upgrades: [Int: FriendUpgrade]
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
        case upgrades
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
        try container.encode(upgrades, forKey: .upgrades)
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
        let upgrades = try container.decode(Dictionary<Int, FriendUpgrade>.self, forKey: .upgrades)
        self.init(lastName: lastName, shortTitle: shortTitle, fullTitle: fullTitle, imageName: imageName, description: description, loyalty: loyalty, powers: powers, chatHistory: chatHistory, displayedMessageCount: displayedMessageCount, executionRestriction: executionRestriction, upgrades: upgrades, startChatUsing: chatStartOption, allPossibleMessages: allPossibleMessages)
        
        hasNewMessage = try container.decode(Bool.self, forKey: .hasNewMessage)
        isChatting = try container.decode(Bool.self, forKey: .hasNewMessage)
        responseState = try container.decode(ResponseState.self, forKey: .responseState)
        chatEndingState = try container.decode(ChatEndingState.self, forKey: .chatEndState)
    }
    
    
    // MARK: - Initializers
    
    /// Full intializer for a Friend, begins chat with sending incoming message.
    init(lastName: String, shortTitle: String, fullTitle: String, imageName: String, description: String, loyalty: Percentage, powers: [Power], chatHistory: [ChatMessage], displayedMessageCount: Int, executionRestriction: ExecutionRestriction, upgrades: [Int: FriendUpgrade], startChatUsing chatStartOption: ChatStartOption, allPossibleMessages: [Int: IncomingMessage]) {
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
        self.upgrades = upgrades
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
        self.upgrades = other.upgrades
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
        chatDelegate?.didAddIncomingMessageWith(responses: nil, consequences: message.consequences)
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
        case .promptUserWith(let choices):
            responseState = .willPromptUserWith(choices)
            chatDelegate?.didAddIncomingMessageWith(responses: choices, consequences: nil)
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
        
        // Update the chat history
        for messageIndex in displayedMessageCount ..< chatHistory.count {
            let message = chatHistory[messageIndex]
            guard message.direction == .incoming else { continue }
            
            messageAdditionTime += message.delay
            let messageBackgroundAdditionTimer = Timer(timeInterval: messageAdditionTime, repeats: false) { (timer) in
                // Stop updating as soon as the friend is chatting again
                guard self.isChatting == false else {
                    timer.invalidate()
                    return
                }
                
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
    private func apply(power: Power, to user: User, and friend: Friend) {
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
    
    func upgradeToLevel(_ level: Int) {
        // Check for available upgrade
        guard let upgrade = upgrades[level] else { return }
        
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
        
        upgrades.removeValue(forKey: level)
    }
    
    
    // MARK: - Static properties
    
    static var dyatlov = Friend(lastName: "Dyatlov", shortTitle: "Engineer", fullTitle: "Deputy Chief Engineer", imageName: "Dyatlov", description: "I hate Fomin.", loyalty: Percentage(progress: 2), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, executionRestriction: .level(10),
        upgrades: [:],
        startChatUsing: .sendIncomingMessage(IncomingMessage(texts: "My President...", "Congratulations on becoming the new leader.", "Our country needs someone like you to guide us forward", "I will serve you with all of my loyalty.", consequences: [.changeFriendLoyaltyBy(5)], responses: [
            OutgoingMessage(text: "Who are you?", responseMessageId: 1, consequences: [.changeUserLevelBy(-5)]),
            OutgoingMessage(text: "Introduce yourself.", responseMessageId: 1),
            OutgoingMessage(text: "Serve your country, not me.", responseMessageId: 2, consequences: [.changeUserLevelBy(5)])
        ])),
        allPossibleMessages: Friend.allTestMessages
    )
    
    static var legasov = Friend(lastName: "Legasov", shortTitle: "Scientist", fullTitle: "Nuclear Expert", imageName: "Legasov", description: "Science is the truth.", loyalty: Percentage(progress: 2), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, executionRestriction: .level(10),
        upgrades: [:],
        startChatUsing: .sendIncomingMessage(IncomingMessage(texts: "My President...", "Congratulations on becoming the new leader.", "Our country needs someone like you to guide us forward", "I will serve you with all of my loyalty.", consequences: [.changeFriendLoyaltyBy(5)], responses: [
            OutgoingMessage(text: "Who are you?", responseMessageId: 1, consequences: [.changeUserLevelBy(-5)]),
            OutgoingMessage(text: "Introduce yourself.", responseMessageId: 1),
            OutgoingMessage(text: "Serve your country, not me.", responseMessageId: 2, consequences: [.changeUserLevelBy(5)])
        ])),
        allPossibleMessages: Friend.allTestMessages
    )
    
    static var fomin = Friend(lastName: "Fomin", shortTitle: "Engineer", fullTitle: "Chernobyl Chief Engineer", imageName: "Fomin", description: "Promotion is on the way.", loyalty: Percentage(progress: 2), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, executionRestriction: .level(10),
        upgrades: [:],
        startChatUsing: .promptUserWith([
            OutgoingMessage(text: "Who are you?", responseMessageId: 1, consequences: [.changeUserLevelBy(-5)]),
            OutgoingMessage(text: "Introduce yourself.", responseMessageId: 1, levelRestriction: 10),
            OutgoingMessage(text: "Serve your country, not me.", responseMessageId: 2, levelRestriction: 8, consequences: [.changeUserLevelBy(5)])
        ]),
        allPossibleMessages: Friend.allTestMessages
    )
    
    static var akimov = Friend(lastName: "Akimov", shortTitle: "Engineer", fullTitle: "Chernobyl Shift Leader", imageName: "Akimov", description: "Love being a engineer.", loyalty: Percentage(progress: 2), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, executionRestriction: .level(7),
        upgrades: [:],
        startChatUsing: .sendIncomingMessage(IncomingMessage(texts: "My President...", "Congratulations on becoming the new leader.", "Our country needs someone like you to guide us forward", "I will serve you with all of my loyalty.", consequences: [.changeFriendLoyaltyBy(5)], responses: [
            OutgoingMessage(text: "Who are you?", responseMessageId: 1, consequences: [.changeUserLevelBy(-5)]),
            OutgoingMessage(text: "Introduce yourself.", responseMessageId: 1),
            OutgoingMessage(text: "Serve your country, not me.", responseMessageId: 2, levelRestriction: 8, consequences: [.changeUserLevelBy(5)])
        ])),
        allPossibleMessages: Friend.allTestMessages
    )
    
    static var quizFriend = Friend(lastName: "Friend", shortTitle: "Quiz", fullTitle: "Test Quiz", imageName: "Akimov", description: "I test the quiz.", loyalty: Percentage(progress: 2), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, executionRestriction: .never,
        upgrades:[
            2: FriendUpgrade(shortTitle: "New Quiz", description: "Something new.", chatStartOption: .sendIncomingMessage(IncomingMessage(texts: "Whatss up", responses: [
                    OutgoingMessage(description: "Lets do quiz", consequences: [.startQuizOfCategory(.all)])
                ])))
        ],
        startChatUsing: .promptUserWith([
            OutgoingMessage(description: "(Start Quiz)", consequences: [.setChatStartOption(.promptUserWith([OutgoingMessage(text: "How about that", responseMessageId: 0)])), .startQuizOfCategory(.all)])
        ]),
        allPossibleMessages: Friend.quizFriendMessages
    )
    
    static var testNewFriend = Friend(lastName: "Friend", shortTitle: "Quiz", fullTitle: "Test Quiz", imageName: "Akimov", description: "I test the quiz.", loyalty: Percentage(progress: 2), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, executionRestriction: .never,
        upgrades:[
            2: FriendUpgrade(shortTitle: "New Quiz", description: "Something new.", chatStartOption: .sendIncomingMessage(IncomingMessage(texts: "Whatss up", responses: [
                    OutgoingMessage(description: "Lets do quiz", consequences: [.startQuizOfCategory(.all)])
            ])))
        ],
        startChatUsing: .promptUserWith([
            OutgoingMessage(description: "(Start Quiz)", consequences: [.setChatStartOption(.promptUserWith([OutgoingMessage(text: "How about that", responseMessageId: 0)])), .startQuizOfCategory(.all)])
        ]),
        allPossibleMessages: Friend.quizFriendMessages
    )
    
    static var tutorialFriend = Friend(lastName: "Gorbachev", shortTitle: "Mrs", fullTitle: "Mrs", imageName: "Gorbachev", description: "I am the wife.", loyalty: Percentage(progress: 99), powers: [], chatHistory: [], displayedMessageCount: 0, executionRestriction: .never,
        upgrades: [
        1: FriendUpgrade(chatStartOption: .promptUserWith([
            OutgoingMessage(text: "Yo", responseMessageId: nil)
            ]))
        ],
        startChatUsing: .sendIncomingMessage(
            IncomingMessage(texts: "My Darling...", "Now that you have become the president of the Soviet Union", "There are a few things you need to keep in mind before you set off for Moscow...", responses: [OutgoingMessage(text: "Yes?", responseMessageId: 1)])
        ),
        allPossibleMessages:[
            1: IncomingMessage(texts: "Although you are the ultimate leader, not every one is 100% loyal.", "Your support is determined by the average loyalty of everyone working for you.", "Remember", "Our country is very unstable now", "The Union will collapse if people no longer support you.", "Promise me you will remember what I said, darling.", responses: [
                    OutgoingMessage(text: "I promise.", responseMessageId: 2),
                    OutgoingMessage(text: "I already know this.", responseMessageId: 2)
                ]),
            2: IncomingMessage(texts: "Good luck at Moscow my darling.", responses: [
                OutgoingMessage(description: "(Start Game)", consequences: [.startGame])
                ])
        ]
    )
    
    
    
    
    static var allTestMessages: [Int: IncomingMessage] = [
        0: IncomingMessage(texts: "My President...", "Congratulations on becoming the new leader.", "Our country needs someone like you to guide us forward", "I will serve you with all of my loyalty.", consequences: [.changeFriendLoyaltyBy(5)], responses: [
                OutgoingMessage(text: "Who are you?", responseMessageId: 1, consequences: [.changeUserLevelBy(-5)]),
                OutgoingMessage(text: "Introduce yourself.", responseMessageId: 1, consequences: [.changeFriendLoyaltyBy(5)]),
                OutgoingMessage(text: "Serve your country, not me.", responseMessageId: 2, levelRestriction: 8, consequences: [.changeUserLevelBy(5)])
            ]),
        1: IncomingMessage(texts: "I work at the Chernobyl nuclear power plant", "this is my first year here", "I have to say that I really enjoy the job", responses: [
                OutgoingMessage(description: "Good", texts: "Good.", "I will check on your work later on", "It is an honor working on the job you have now", "people depend on your work", responseMessageId: 2),
                OutgoingMessage(description: "Wonderful", texts: "Wonderful.", responseMessageId: nil, consequences: [.setChatStartOption(.sendIncomingMessage(IncomingMessage(texts: "Good job.", consequences: [.endChatFrom(.incoming)], responses: nil))), .makeNewFriend(Friend.testNewFriend)]),
                OutgoingMessage(description: "OK", texts: "OK.", "Keep it up.", responseMessageId: 3, consequences: [.changeFriendLoyaltyBy(-1)]),
            ]),
        2: IncomingMessage(texts: "Thank you, president Gorbachev.", consequences: [.changeUserSupportBy(1), .changeFriendLoyaltyBy(2)], responses: [
                OutgoingMessage(description: "Leave Chat", consequences: [.endChatFrom(.outgoing)])
            ]),
        3: IncomingMessage(texts: "Certainly... Thank you president Gorbachev.", consequences: [.endChatFrom(.incoming)], responses: nil),
        
        
        
        
        
        100: IncomingMessage(texts: "Good luck President Gorbachev.", consequences: [.endChatFrom(.incoming)], responses: nil)
    ]
    
    
    static var newTestMessages: [Int: IncomingMessage] = [
        0: IncomingMessage(texts: "My President...", "Congratulations on becoming the new leader.", "Our country needs someone like you to guide us forward", "I will serve you with all of my loyalty.", consequences: [.changeFriendLoyaltyBy(5)], responses: [
            OutgoingMessage(text: "Who are you?", responseMessageId: 1, consequences: [.changeUserLevelBy(-5)]),
            OutgoingMessage(text: "Introduce yourself.", responseMessageId: 1),
            OutgoingMessage(text: "Serve your country, not me.", responseMessageId: 2, consequences: [.changeUserLevelBy(5)])
            ]),
        1: IncomingMessage(texts: "I work at the Chernobyl nuclear power plant", "this is my first year here", "I have to say that I really enjoy the job", responses: [
            OutgoingMessage(description: "Good", texts: "Good.", "I will check on your work later on", "It is an honor working on the job you have now", "people depend on your work", responseMessageId: 2),
            OutgoingMessage(description: "Wonderful", texts: "Wonderful.", responseMessageId: nil, consequences: nil),
            OutgoingMessage(description: "OK", texts: "OK.", "Keep it up.", responseMessageId: 3, consequences: [.changeFriendLoyaltyBy(-1)]),
            ]),
        2: IncomingMessage(texts: "Thank you, president Gorbachev.", consequences: [.changeUserSupportBy(1), .changeFriendLoyaltyBy(2)], responses: [
            OutgoingMessage(description: "Leave Chat", consequences: [.endChatFrom(.outgoing)])
            ]),
        3: IncomingMessage(texts: "Certainly... Thank you president Gorbachev.", consequences: [.endChatFrom(.incoming)], responses: nil),
        
        
        
        
        
        100: IncomingMessage(texts: "Good luck President Gorbachev.", consequences: [.endChatFrom(.incoming)], responses: nil)
    ]
    
    static var quizFriendMessages: [Int: IncomingMessage] = [
        0: IncomingMessage(texts: "Never mind.", consequences: [.endChatFrom(.incoming)], responses: nil)
    ]
}
