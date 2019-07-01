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
enum ChatEndingStatus {
    case notEnded
    case endedFrom(MessageDirection)
}

/// A tracker for whether the user is expecting choices, just responded, or just began a chat.
enum ResponseStatus {
    /// Friend is expecting an optional array of OutgoingMessage instances as response. If not nil, then ChatViewController should prompt the user for responses.
    case willPromptUserWith([OutgoingMessage]?)
    /// User completed a whole set of responses in a chat.
    case completed
    /// Chat will begin for the first time using an array of OutgoingMessages to prompt user as choices.
    case willBeginChatWith([OutgoingMessage])
    /// Chat will begin for the first time by sending an IncomingMessage from friend.
    case willBeginChatWithIncomingMessageId(Int)
}

// MARK: -

/**
 A class which holds information about a friend and the chat history with that friend.
 */
class Friend: Equatable {
    
    // MARK: Instance properties
    
    var shortName: String
    var fullName: String
    var image: UIImage
    /// The description displayed on FriendDetailViewController
    var description: String
    var loyalty: Percentage
    var powers: [Power]
    /// The object responsible for displaying the chat history, typically the ChatViewController.
    weak var chatDelegate: ChatDisplayDelegate?
    /// The object responsible for displaying the new message status of the friend, typically the MainViewController.
    weak var statusDisplayDelegate: FriendStatusDisplayDelegate?
    /// chatHistory records all ChatMessage send to and from the Friend. If the chatDelegate did not finish the delayed display of the chatHistory upon dismissal, chatHistory will be copied over to update the chatDelegate when presenting it.
    var chatHistory: [ChatMessage]
    /// This tracks the number of ChatMessages displayed by the chatDelegate. When the chatDelegate was dismissed, this resumes chat from the appropriate message.
    var displayedMessageCount = 0
    /// Used to show or hide the end chat cell.
    var hasNewMessage = false
    /// When set to false, the friend will update the chat history in the background.
    var isChatting = false
    
    // FIXME: To trigger the beginning of a chat differently, maybe we should use the response status wisely.
    ///  A tracker of the most recent response in the chat history, useful for smoothly resuming chat display in the chatDelegate.
    var responseStatus: ResponseStatus
    /// This tracks whether the chat has ended, useful for resuming chat display in the chatDelegate.
    var chatEndingStatus: ChatEndingStatus = .notEnded
    /// The data store for all messages that can be sent to and from a Friend.
    private var allPossibleMessages: [Int: IncomingMessage]
    
    // MARK: - Initializers
    
    /// Full intializer for a Friend, begins chat with sending incoming message.
    init(shortName: String, fullName: String, image: UIImage, description: String, loyalty: Percentage, powers: [Power], chatHistory: [ChatMessage], displayedMessageCount: Int, allPossibleMessages: [Int: IncomingMessage], beginWithIncomingMessageId id: Int) {
        self.shortName = shortName
        self.fullName = fullName
        self.image = image
        self.description = description
        self.loyalty = loyalty
        self.powers = powers
        self.chatHistory = chatHistory
        self.displayedMessageCount = displayedMessageCount
        self.allPossibleMessages = allPossibleMessages
        self.responseStatus = .willBeginChatWithIncomingMessageId(id)
    }
    
    /// Full initializer for a Friend, begins chat with prompting the user with choices.
    init(shortName: String, fullName: String, image: UIImage, description: String, loyalty: Percentage, powers: [Power], chatHistory: [ChatMessage], displayedMessageCount: Int, allPossibleMessages: [Int: IncomingMessage], beginWithPromptingChoices choices: [OutgoingMessage]) {
        self.shortName = shortName
        self.fullName = fullName
        self.image = image
        self.description = description
        self.loyalty = loyalty
        self.powers = powers
        self.chatHistory = chatHistory
        self.displayedMessageCount = displayedMessageCount
        self.allPossibleMessages = allPossibleMessages
        self.responseStatus = .willBeginChatWith(choices)
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
        guard number >= 0 && number < allPossibleMessages.count else { return nil }
        return allPossibleMessages[number]
    }
    
    /**
     Sends IncomingMessage with the corresponding index number in allPossibleMessages. Generates ChatMessages from the IncomingMessage and append to the chat history. Notifies chatDelegate of the addition. Records the IncomingMessage's responses to set the responseStatus, if responses is nil,
     */
    func sendIncomingMessageNumbered(_ number: Int) {
        guard let incomingMessage = incomingMessageNumbered(number) else { return }
        chatEndingStatus = .notEnded
        chatHistory.append(contentsOf: incomingMessage.chatMessages)
        chatDelegate?.didAddIncomingMessageWith(responses: incomingMessage.responses, consequences: incomingMessage.consequences)
        responseStatus = .willPromptUserWith(incomingMessage.responses)
    }

    /**
     Sends OutgoingMessage chosen by the user. Generates ChatMessages from the OutgoingMessage and appends to chatHistory. Notifies chatDelegate of the addition. Records the responseStatus as completed.
     */
    func respondedWith(_ outgoingMessage: OutgoingMessage) {
        chatHistory.append(contentsOf: outgoingMessage.chatMessages)
        chatDelegate?.didAddOutgoingMessageWith(responseId: outgoingMessage.responseMessageId, consequences: outgoingMessage.consequences)
        responseStatus = .completed
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
    
    static var dyatlov = Friend(shortName: "Engineer Dytlov", fullName: "Deputy Chief Engineer Dyatlov", image: UIImage(named: "Dyatlov")!, description: "I hate Fomin.", loyalty: Percentage(progress: 50), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, allPossibleMessages: Friend.allTestMessages, beginWithIncomingMessageId: 0)
    static var legasov = Friend(shortName: "Scientist Legasov", fullName: "Nuclear Scientist Legasov", image: UIImage(named: "Legasov")!, description: "Science is the truth.", loyalty: Percentage(progress: 99), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, allPossibleMessages: Friend.allTestMessages, beginWithIncomingMessageId: 0)
    static var fomin = Friend(shortName: "Engineer Fomin", fullName: "Chief Engineer Fomin", image: UIImage(named: "Fomin")!, description: "Promotion is on the way.", loyalty: Percentage(progress: 80), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, allPossibleMessages: Friend.allTestMessages, beginWithPromptingChoices: Friend.allTestMessages[0]!.responses!)
    static var akimov = Friend(shortName: "Engineer Akimov", fullName: "Chernobyl Shift Leader Akimov", image: UIImage(named: "Akimov")!, description: "Love being a engineer.", loyalty: Percentage(progress: 98), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, allPossibleMessages: Friend.allTestMessages, beginWithIncomingMessageId: 0)
    
    static var testNewFriend = Friend(shortName: "Engineer Dytlov 2", fullName: "Deputy Chief Engineer Dyatlov 2", image: UIImage(named: "Dyatlov")!, description: "I hate Fomin.", loyalty: Percentage(progress: 50), powers: Power.testPowers, chatHistory: [], displayedMessageCount: 0, allPossibleMessages: [:], beginWithIncomingMessageId: 0)
    
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
                OutgoingMessage(description: "Wonderful", texts: "Wonderful.", "It is great that our country has diligent people like you.", responseMessageId: 2, consequences: [.makeNewFriend(Friend.testNewFriend)]),
                OutgoingMessage(description: "OK", texts: "OK.", "Keep it up.", responseMessageId: 3, consequences: [.changeLoyaltyProgressBy(-1)]),
            ]),
        2: IncomingMessage(texts: "Thank you, president Gorbachev.", consequences: [.changeSupportProgressBy(1), .changeLoyaltyProgressBy(2)], responses: [
                OutgoingMessage(description: "Leave Chat", consequences: [.endChatFrom(.outgoing)])
            ]),
        3: IncomingMessage(texts: "Certainly... Thank you president Gorbachev.", consequences: [.endChatFrom(.incoming)], responses: nil)
    ]
}
