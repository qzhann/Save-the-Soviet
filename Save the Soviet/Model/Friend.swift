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
enum ChatEndingState {
    case notEnded
    case endedFrom(MessageDirection)
}

/// A tracker for whether the user is expecting choices, just responded, or just began a chat.
enum ResponseState {
    /// Friend is expecting an optional array of OutgoingMessage instances as response. If not nil, then ChatViewController should prompt the user for responses.
    case willPromptUserWith([OutgoingMessage]?)
    /// Friend will send an optional
    /// User completed a whole set of responses in a chat.
    case completed
}

/// Describes how a friend should begin a chat when being a new friend to the user.
enum ChatStartOption {
    /// Start chat by prompting user with some choices
    case promptUserWith([OutgoingMessage])
    /// Start chat by sending incoming message
    case sendIncomingMessage(IncomingMessage)
    /// Does not start chat
    case none
}


/// A tracker indicating what conditions will allow the user the execute the friend. Useful for controlling the state of the executeFriendButton.
enum ExecutionRestriction {
    /// No limitation. The friend can be executed at any time.
    case none
    /// The friend can only be executed at or above the level number given.
    case level(Int)
    /// The friend can never be executed.
    case never
}

// MARK: -

/**
 A class which holds information about a friend and the chat history with that friend.
 */
class Friend: Equatable {
    
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
    var image: UIImage
    /// The description displayed on FriendDetailViewController
    var description: String
    var loyalty: Percentage
    var powers: [Power]
    /// Describes what limitations the user must meet before executing a friend.
    var executionRestriction: ExecutionRestriction
    /// Describes how the friend should start a chat when startChat() is called
    var chatStartOption: ChatStartOption
    /// The object responsible for displaying the chat history, typically the ChatViewController.
    weak var chatDelegate: ChatDisplayDelegate?
    /// The object responsible for displaying the new message status of the friend, typically the MainViewController.
    weak var statusDisplayDelegate: FriendStatusDisplayDelegate?
    /// chatHistory records all ChatMessage send to and from the Friend. If the chatDelegate did not finish the delayed display of the chatHistory upon dismissal, chatHistory will be copied over to update the chatDelegate when presenting it.
    var chatHistory: [ChatMessage]
    /// This tracks the number of ChatMessages displayed by the chatDelegate. When the chatDelegate was dismissed, this resumes chat from the appropriate message.
    var displayedMessageCount: Int
    /// Used to show or hide the end chat cell.
    var hasNewMessage = false
    /// When set to false, the friend will update the chat history in the background.
    var isChatting = false
    
    // FIXME: To trigger the beginning of a chat differently, maybe we should use the response status wisely.
    ///  A tracker of the most recent response in the chat history, useful for smoothly resuming chat display in the chatDelegate.
    var responseState: ResponseState = .completed
    /// This tracks whether the chat has ended, useful for resuming chat display in the chatDelegate.
    var chatEndingState: ChatEndingState = .notEnded
    /// The data store for all messages that can be sent to and from a Friend.
    private var allPossibleMessages: [Int: IncomingMessage]
    /// The message sent by other friends which introduced the user to self
    var introductionMessageFromOthers: IncomingMessage
    
    // MARK: - Initializers
    
    /// Full intializer for a Friend, begins chat with sending incoming message.
    init(lastName: String, shortTitle: String, fullTitle: String, image: UIImage, description: String, loyalty: Percentage, powers: [Power], chatHistory: [ChatMessage], displayedMessageCount: Int, allPossibleMessages: [Int: IncomingMessage], executionRestriction: ExecutionRestriction, introductionMessage: IncomingMessage, startChatUsing chatStartOption: ChatStartOption) {
        self.lastName = lastName
        self.shortTitle = shortTitle
        self.fullTitle = fullTitle
        self.image = image
        self.description = description
        self.loyalty = loyalty
        self.powers = powers
        self.chatHistory = chatHistory
        self.displayedMessageCount = displayedMessageCount
        self.allPossibleMessages = allPossibleMessages
        self.executionRestriction = executionRestriction
        self.introductionMessageFromOthers = introductionMessage
        self.chatStartOption = chatStartOption
    }
    
    /// Full initializer for a Friend, begins chat with prompting the user with choices.
    init(lastName: String, shortTitle: String, fullTitle: String, image: UIImage, description: String, loyalty: Percentage, powers: [Power], chatHistory: [ChatMessage], displayedMessageCount: Int, allPossibleMessages: [Int: IncomingMessage], beginWithPromptingChoices choices: [OutgoingMessage], executionRestriction: ExecutionRestriction, introductionMessage: IncomingMessage, startChatUsing chatStartOption: ChatStartOption) {
        self.lastName = lastName
        self.shortTitle = shortTitle
        self.fullTitle = fullTitle
        self.image = image
        self.description = description
        self.loyalty = loyalty
        self.powers = powers
        self.chatHistory = chatHistory
        self.displayedMessageCount = displayedMessageCount
        self.allPossibleMessages = allPossibleMessages
        self.executionRestriction = executionRestriction
        self.introductionMessageFromOthers = introductionMessage
        self.chatStartOption = chatStartOption
    }
    
    
    // MARK: - Equatable
    
    static func == (lhs: Friend, rhs: Friend) -> Bool {
        return lhs.fullName == rhs.fullName && lhs.description == rhs.description
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
    
    /// Starts chat using the corresponding start chat option. This is called when 
    func startChat() {
        switch chatStartOption {
        case .sendIncomingMessage(let message):
            sendIncomingMessage(message)
            updateChatHistoryInBackground()
            hasNewMessage = true
            statusDisplayDelegate?.updateNewMessageStatusFor(self)
            responseState = .willPromptUserWith(message.responses)
        case .promptUserWith(let choices):
            responseState = .willPromptUserWith(choices)
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
        statusDisplayDelegate?.updateNewMessageStatusFor(self)
        
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
                self.statusDisplayDelegate?.updateNewMessageStatusFor(self)
                self.statusDisplayDelegate?.moveCellToTopFor(self)
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
        loyalty.progress = min(newProgress, loyalty.maximumProgress)
    }
    
    /// Applys all powers to user and self
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
            case .userEnergy:
                let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { (_) in
                    user.changeSupportBy(progress: power.strength)
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
            case .userEnergy:
                user.changeSupportBy(progress: power.strength)
            case .friendLoyalty:
                friend.changeLoyaltyBy(progress: power.strength)
            default:
                break
            }
        }
    }
    
    
    // MARK: - Static properties
    
    static var dyatlov = Friend(lastName: "Dytlov", shortTitle: "Engineer", fullTitle: "Deputy Chief Engineer", image: UIImage(named: "Dyatlov")!, description: "I hate Fomin.", loyalty: Percentage(progress: 50), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, allPossibleMessages: Friend.allTestMessages, executionRestriction: .level(10), introductionMessage: IncomingMessage(texts: "Good luck president Gorbachev.", consequences: [.endChatFrom(.incoming)], responses: nil), startChatUsing: .sendIncomingMessage(IncomingMessage(texts: "My President...", "Congratulations on becoming the new leader.", "Our country needs someone like you to guide us forward", "I will serve you with all of my loyalty.", consequences: [.changeLoyaltyProgressBy(5)], responses: [
        OutgoingMessage(text: "Who are you?", responseMessageId: 1, consequences: [.changeLevelProgressBy(-5)]),
        OutgoingMessage(text: "Introduce yourself.", responseMessageId: 1),
        OutgoingMessage(text: "Serve your country, not me.", responseMessageId: 2, consequences: [.changeLevelProgressBy(5)])
        ])))
    
    static var legasov = Friend(lastName: "Legasov", shortTitle: "Scientist", fullTitle: "Nuclear Expert", image: UIImage(named: "Legasov")!, description: "Science is the truth.", loyalty: Percentage(progress: 99), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, allPossibleMessages: Friend.allTestMessages, executionRestriction: .level(10), introductionMessage: IncomingMessage(texts: "Good luck president Gorbachev.", consequences: [.endChatFrom(.incoming)], responses: nil), startChatUsing: .sendIncomingMessage(IncomingMessage(texts: "My President...", "Congratulations on becoming the new leader.", "Our country needs someone like you to guide us forward", "I will serve you with all of my loyalty.", consequences: [.changeLoyaltyProgressBy(5)], responses: [
        OutgoingMessage(text: "Who are you?", responseMessageId: 1, consequences: [.changeLevelProgressBy(-5)]),
        OutgoingMessage(text: "Introduce yourself.", responseMessageId: 1),
        OutgoingMessage(text: "Serve your country, not me.", responseMessageId: 2, consequences: [.changeLevelProgressBy(5)])
        ])))
    static var fomin = Friend(lastName: "Fomin", shortTitle: "Engineer", fullTitle: "Chernobyl Chief Engineer", image: UIImage(named: "Fomin")!, description: "Promotion is on the way.", loyalty: Percentage(progress: 80), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, allPossibleMessages: Friend.allTestMessages, executionRestriction: .level(10), introductionMessage: IncomingMessage(texts: "Good luck president Gorbachev.", consequences: [.endChatFrom(.incoming)], responses: nil), startChatUsing: .promptUserWith([OutgoingMessage(text: "Who are you?", responseMessageId: 1, consequences: [.changeLevelProgressBy(-5)]),                                                                                      OutgoingMessage(text: "Introduce yourself.", responseMessageId: 1),
                         OutgoingMessage(text: "Serve your country, not me.", responseMessageId: 2, consequences: [.changeLevelProgressBy(5)])]))
    
    static var akimov = Friend(lastName: "Akimov", shortTitle: "Engineer", fullTitle: "Chernobyl Shift Leader", image: UIImage(named: "Akimov")!, description: "Love being a engineer.", loyalty: Percentage(progress: 98), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, allPossibleMessages: Friend.allTestMessages, executionRestriction: .level(7), introductionMessage: IncomingMessage(texts: "Good luck president Gorbachev.", consequences: [.endChatFrom(.incoming)], responses: nil), startChatUsing: .sendIncomingMessage(IncomingMessage(texts: "My President...", "Congratulations on becoming the new leader.", "Our country needs someone like you to guide us forward", "I will serve you with all of my loyalty.", consequences: [.changeLoyaltyProgressBy(5)], responses: [
        OutgoingMessage(text: "Who are you?", responseMessageId: 1, consequences: [.changeLevelProgressBy(-5)]),
        OutgoingMessage(text: "Introduce yourself.", responseMessageId: 1),
        OutgoingMessage(text: "Serve your country, not me.", responseMessageId: 2, consequences: [.changeLevelProgressBy(5)])
        ])))
    
    static var testNewFriend = Friend(lastName: "Dytlov", shortTitle: "Engineer", fullTitle: "Deputy Chief Engineer 2", image: UIImage(named: "Dyatlov")!, description: "I hate Fomin.", loyalty: Percentage(progress: 50), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, allPossibleMessages: Friend.newTestMessages, executionRestriction: .level(10), introductionMessage: IncomingMessage(texts: "Watch out.", consequences: [.endChatFrom(.incoming)], responses: nil), startChatUsing: .sendIncomingMessage(IncomingMessage(texts: "My President...", "Congratulations on becoming the new leader.", "Our country needs someone like you to guide us forward", "I will serve you with all of my loyalty.", consequences: [.changeLoyaltyProgressBy(5)], responses: [
        OutgoingMessage(text: "Who are you?", responseMessageId: 1, consequences: [.changeLevelProgressBy(-5)]),
        OutgoingMessage(text: "Introduce yourself.", responseMessageId: 1),
        OutgoingMessage(text: "Serve your country, not me.", responseMessageId: 2, consequences: [.changeLevelProgressBy(5)])
        ])))
    
    static var allPossibleFriends: [Friend] = [
        Friend.dyatlov,
        Friend.legasov,
        Friend.fomin,
        Friend.akimov
    ]
    
    // FIXME: Handle change loyalty progress
    static var allTestMessages: [Int: IncomingMessage] = [
        0: IncomingMessage(texts: "My President...", "Congratulations on becoming the new leader.", "Our country needs someone like you to guide us forward", "I will serve you with all of my loyalty.", consequences: [.changeLoyaltyProgressBy(5)], responses: [
                OutgoingMessage(text: "Who are you?", responseMessageId: 1, consequences: [.changeLevelProgressBy(-5)]),
                OutgoingMessage(text: "Introduce yourself.", responseMessageId: 1),
                OutgoingMessage(text: "Serve your country, not me.", responseMessageId: 2, consequences: [.changeLevelProgressBy(5)])
            ]),
        1: IncomingMessage(texts: "I work at the Chernobyl nuclear power plant", "this is my first year here", "I have to say that I really enjoy the job", responses: [
                OutgoingMessage(description: "Good", texts: "Good.", "I will check on your work later on", "It is an honor working on the job you have now", "people depend on your work", responseMessageId: 2),
                OutgoingMessage(description: "Wonderful", texts: "Wonderful.", responseMessageId: nil, consequences: [.makeNewFriend(Friend.testNewFriend)]),
                OutgoingMessage(description: "OK", texts: "OK.", "Keep it up.", responseMessageId: 3, consequences: [.changeLoyaltyProgressBy(-1)]),
            ]),
        2: IncomingMessage(texts: "Thank you, president Gorbachev.", consequences: [.changeSupportProgressBy(1), .changeLoyaltyProgressBy(2)], responses: [
                OutgoingMessage(description: "Leave Chat", consequences: [.endChatFrom(.outgoing)])
            ]),
        3: IncomingMessage(texts: "Certainly... Thank you president Gorbachev.", consequences: [.endChatFrom(.incoming)], responses: nil),
        
        
        
        
        
        100: IncomingMessage(texts: "Good luck President Gorbachev.", consequences: [.endChatFrom(.incoming)], responses: nil)
    ]
    
    
    static var newTestMessages: [Int: IncomingMessage] = [
        0: IncomingMessage(texts: "My President...", "Congratulations on becoming the new leader.", "Our country needs someone like you to guide us forward", "I will serve you with all of my loyalty.", consequences: [.changeLoyaltyProgressBy(5)], responses: [
            OutgoingMessage(text: "Who are you?", responseMessageId: 1, consequences: [.changeLevelProgressBy(-5)]),
            OutgoingMessage(text: "Introduce yourself.", responseMessageId: 1),
            OutgoingMessage(text: "Serve your country, not me.", responseMessageId: 2, consequences: [.changeLevelProgressBy(5)])
            ]),
        1: IncomingMessage(texts: "I work at the Chernobyl nuclear power plant", "this is my first year here", "I have to say that I really enjoy the job", responses: [
            OutgoingMessage(description: "Good", texts: "Good.", "I will check on your work later on", "It is an honor working on the job you have now", "people depend on your work", responseMessageId: 2),
            OutgoingMessage(description: "Wonderful", texts: "Wonderful.", responseMessageId: nil, consequences: nil),
            OutgoingMessage(description: "OK", texts: "OK.", "Keep it up.", responseMessageId: 3, consequences: [.changeLoyaltyProgressBy(-1)]),
            ]),
        2: IncomingMessage(texts: "Thank you, president Gorbachev.", consequences: [.changeSupportProgressBy(1), .changeLoyaltyProgressBy(2)], responses: [
            OutgoingMessage(description: "Leave Chat", consequences: [.endChatFrom(.outgoing)])
            ]),
        3: IncomingMessage(texts: "Certainly... Thank you president Gorbachev.", consequences: [.endChatFrom(.incoming)], responses: nil),
        
        
        
        
        
        100: IncomingMessage(texts: "Good luck President Gorbachev.", consequences: [.endChatFrom(.incoming)], responses: nil)
    ]
}
