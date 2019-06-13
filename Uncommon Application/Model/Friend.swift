//
//  Friend.swift
//  Uncommon Application
//
//  Created by qizihan  on 12/20/18.
//  Copyright © 2018 qzhann. All rights reserved.
//

import Foundation
import UIKit

/**
 Adopted by ChatViewController to display chat history with a Friend.
 */
protocol ChatDisplayDelegate: AnyObject {
    /// Called when Friend adds incoming ChatMessage to chatHistory.
    func didAddIncomingMessageWith(responses: [OutgoingMessage]?, consequences: [Consequence]?)
    /// Called when Friend adds outgoing ChatMessage to chatHistory.
    func didAddOutgoingMessageWith(responseId: Int?, consequences: [Consequence]?)
}

protocol FriendStatusDisplayDelegate: AnyObject {
    func updateNewMessageStatusFor(_ friend: Friend)
    func moveCellToTopFor(_ friend: Friend)
}

// MARK: -
// MARK: -

/// A tracker for whether the chat has ended, useful for resuming chat display in the chatDelegate.
enum ChatEndingStatus {
    case notEnded
    case endedFrom(MessageDirection)
}

// MARK: -
// MARK: -

/**
 A class which holds information about a friend and the chat history with that friend.
 */
class Friend {
    // MARK: Instance properties
    var name: String
    var image: UIImage
    var description: String
    var friendship: Friendship
    var powers: [Power]
    /// The object responsible for displaying the chat history, typically the ChatViewController.
    weak var chatDelegate: ChatDisplayDelegate?
    weak var statusDisplayDelegate: FriendStatusDisplayDelegate?
    /// chatHistory records all ChatMessage send to and from the Friend. If the chatDelegate did not finish the delayed display of the chatHistory upon dismissal, chatHistory will be copied over to update the chatDelegate when presenting it.
    var chatHistory: [ChatMessage] = []
    /// This tracks the number of ChatMessages displayed by the chatDelegate. When the chatDelegate was dismissed, this resumes chat from the appropriate message.
    var displayedMessageCount = 0
    
    var hasNewMessage = false
    
    var isChatting = false
    ///  A tracker of the most recent response in the chat history, useful for smoothly resuming chat display in the chatDelegate.
    var responseStatus: ResponseStatus = .noRecord
    enum ResponseStatus {
        /// Friend is expecting an optional array of OutgoingMessage instances as response. If not nil, then ChatViewController should prompt the user for responses, otherwise this should end chat.
        case willPromptUserWith([OutgoingMessage]?)
        /// User completed a whole set of responses in a chat
        case completed
        /// No response is recorded, this triggers the beginning of a chat.
        case noRecord
    }
    /// This tracks whether the chat has ended, useful for resuming chat display in the chatDelegate.
    var chatEndingStatus: ChatEndingStatus = .notEnded
    
    /// The data store for all messages that can be sent to and from a Friend, accessed by the chat status control instance methods.
    private var allPossibleMessages: [Int: IncomingMessage]
    
    // MARK: - Initializers
    /**
     Full initializer for a Friend.
     */
    init(name: String, image: UIImage, description: String, friendship: Friendship, powers: [Power], displayedMessageCount: Int, allPossibleMessages: [Int: IncomingMessage]) {
        self.name = name
        self.image = image
        self.description = description
        self.friendship = friendship
        self.powers = powers
        self.displayedMessageCount = displayedMessageCount
        self.allPossibleMessages = allPossibleMessages
    }
    
    
    // MARK: - Chat Status Control Methods
    
    /**
     Helper method to retrieve an IncomingMessage from allPossibleMessages using id as array index.
     - returns: Optional IncomingMessage whose index in allPossibleMessages is the parameter id, nil if id is an invalid index.
     */
    private func incomingMessageWithId(_ id: Int) -> IncomingMessage? {
        guard id >= 0 && id < allPossibleMessages.count else { return nil }
        return allPossibleMessages[id]
    }
    
    /**
     Sends IncomingMessage with the id as index in allPossibleMessages. Generates ChatMessages from the IncomingMessage and append to the chat history. Notifies chatDelegate of the addition. Records the IncomingMessage's responses as the mostRecentResponse, if responses is nil,
     */
    func sendIncomingMessageWithId(_ id: Int) {
        guard let incomingMessage = incomingMessageWithId(id) else { return }
        chatHistory.append(contentsOf: incomingMessage.chatMessages)
        chatDelegate?.didAddIncomingMessageWith(responses: incomingMessage.responses, consequences: incomingMessage.consequences)
        responseStatus = .willPromptUserWith(incomingMessage.responses)
    }

    /**
     Sends OutgoingMessage chosen by the user. Generates ChatMessages from the OutgoingMessage and appends to chatHistory. Notifies chatDelegate of the addition. Records the mostRecentResponse as completed.
     */
    func respondedWith(_ outgoingMessage: OutgoingMessage) {
        chatHistory.append(contentsOf: outgoingMessage.chatMessages)
        chatDelegate?.didAddOutgoingMessageWith(responseId: outgoingMessage.responseMessageId, consequences: outgoingMessage.consequences)
        responseStatus = .completed
    }
    
    
    // MARK: - Instance methods
    
    func updateChatHistoryInBackground() {
        var messageAdditionTime: Double = 0
        
        // Every time we update chat history in background, we start with a state of no new message
        hasNewMessage = false
        statusDisplayDelegate?.updateNewMessageStatusFor(self)
        
        hasNewMessage = chatHistory.count - displayedMessageCount != 0
        
        for messageIndex in displayedMessageCount ..< chatHistory.count {
            let message = chatHistory[messageIndex]
            guard message.direction == .incoming else { continue }
            
            messageAdditionTime += message.delay
            let messageBackgroundAdditionTimer = Timer(timeInterval: messageAdditionTime, repeats: false) { (timer) in
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
    
    func willDismissChatDelegateWithChatHistoryCount(_ count: Int) {
        displayedMessageCount = count
        isChatting = false
        updateChatHistoryInBackground()
    }
    
    
    
    // MARK: - Test Friend and Test Messages
    static var testFriend: Friend = Friend(name: "Lucia", image: UIImage(named: "Dog")!, description: "The most beautiful girl in the world.", friendship: Friendship(progress: 6), powers: Power.testPowers, displayedMessageCount: 0, allPossibleMessages: Friend.allTestMessages)
    
    static var testFriends: [Friend] = [
        Friend(name: "Rishabh", image: UIImage(named: "AnswerCorrect")!, description: "The other guy who stays in his room forever.", friendship: Friendship(progress: 6),
            powers: [Power(name: "Healer", image: UIImage(named: "HeartPowerLevel3")!, description: "5 Energy recovered per minute."),
                     Power(name: "Lucky Dog", image: UIImage(named: "GiftPowerLevel3")!, description: "Receives some gifts from a friend every 30 mins.", coinsNeeded: 30,  upgrades: [Power(name: "Lucky Dog", image: UIImage(named: "GiftPowerLevel3")!, description: "Receives a gift from a friend every 30 mins.", coinsNeeded: 50)]),
                     Power(name: "Amatuer Cheater", image: UIImage(named: "Dog")!, description: "Cheat once every 5 quizzes.")
            ],
            displayedMessageCount: 0, allPossibleMessages: Friend.allTestMessages),
        Friend(name: "Han", image: UIImage(named: "AnswerWrong")!, description: "The third guy who stays in his room till the world ends.", friendship: Friendship(progress: 6),
               powers: [Power(name: "Healer", image: UIImage(named: "HeartPowerLevel3")!, description: "5 Energy recovered per minute."),
                        Power(name: "Lucky Dog", image: UIImage(named: "GiftPowerLevel3")!, description: "Receives some gifts from a friend every 30 mins.", coinsNeeded: 30,  upgrades: [Power(name: "Lucky Dog", image: UIImage(named: "GiftPowerLevel3")!, description: "Receives a gift from a friend every 30 mins.", coinsNeeded: 50)]),
                        Power(name: "Amatuer Cheater", image: UIImage(named: "Dog")!, description: "Cheat once every 5 quizzes.")
            ],
               displayedMessageCount: 0, allPossibleMessages: Friend.allTestMessages),
        Friend(name: "Zane", image: UIImage(named: "Coin")!, description: "The guy who masturbates all day.", friendship: Friendship(progress: 6),
               powers: [Power(name: "Healer", image: UIImage(named: "HeartPowerLevel3")!, description: "5 Energy recovered per minute."),
                        Power(name: "Lucky Dog", image: UIImage(named: "GiftPowerLevel3")!, description: "Receives some gifts from a friend every 30 mins.", coinsNeeded: 30,  upgrades: [Power(name: "Lucky Dog", image: UIImage(named: "GiftPowerLevel3")!, description: "Receives a gift from a friend every 30 mins.", coinsNeeded: 50)]),
                        Power(name: "Amatuer Cheater", image: UIImage(named: "Dog")!, description: "Cheat once every 5 quizzes.")
            ],
               displayedMessageCount: 0, allPossibleMessages: Friend.allTestMessages),
        Friend(name: "Lucia", image: UIImage(named: "Dog")!, description: "The most beautiful girl in the world.", friendship: Friendship(progress: 6),
               powers: [Power(name: "Healer", image: UIImage(named: "HeartPowerLevel3")!, description: "5 Energy recovered per minute."),
                        Power(name: "Lucky Dog", image: UIImage(named: "GiftPowerLevel3")!, description: "Receives some gifts from a friend every 30 mins.", coinsNeeded: 30,  upgrades: [Power(name: "Lucky Dog", image: UIImage(named: "GiftPowerLevel3")!, description: "Receives a gift from a friend every 30 mins.", coinsNeeded: 50)]),
                        Power(name: "Amatuer Cheater", image: UIImage(named: "Dog")!, description: "Cheat once every 5 quizzes.")
            ],
               displayedMessageCount: 0, allPossibleMessages: Friend.allTestMessages)
    ]
    
    static var allTestMessages: [Int: IncomingMessage] = [
        0: IncomingMessage(texts: "Hey Honey", responses: [OutgoingMessage(text: "Hey Babe", responseMessageId: 1), OutgoingMessage(text: "Whats up", responseMessageId: 1), OutgoingMessage(text: "Yooooooo", responseMessageId: 2)]),
        1: IncomingMessage(texts: "I couldn't figure out the answer to the coding problem...", "Could you plz help me?", "Love to have you help me here.", "I'm for real.", "Not lying to you.", "yea for real...", responses: [OutgoingMessage(text: "Yea", responseMessageId: 3), OutgoingMessage(text: "Sure~", responseMessageId: 4), OutgoingMessage(text: "Sorry... Can't help you.", responseMessageId: 5)]),
        2: IncomingMessage(texts: "?", responses: [OutgoingMessage(text: "What you want?", responseMessageId: 5), OutgoingMessage(text: "Don't be a jerk to me", responseMessageId: 5), OutgoingMessage(text: "??", responseMessageId: 6)]),
        3: IncomingMessage(texts: "Actually... I was wondering if you wanna come over to my room tonight", "Might be better if you could come over and teach me how to fix the problem ;)", responses: [OutgoingMessage(description: "Accept her invitation", texts: "Definitely", "I'll be there in a minute.", "Do I need to bring anything with me?", responseMessageId: 8), OutgoingMessage(description: "Confirm what she means", texts: "Um...", "Anyone else in your room?", responseMessageId: 9), OutgoingMessage(description: "Refuse her invitation", texts: "I have a girlfriend already", "Don't wanna cheat on her", "Sorry.", responseMessageId: 10)]),
        4: IncomingMessage(texts: "Actually... I was wondering if you wanna come over to my room tonight", "Might be better if you could come over and teach me how to fix the problem ;)", responses: [OutgoingMessage(description: "Accept her invitation", texts: "Definitely", "I'll be there in a minute.", "Do I need to bring anything with me?", responseMessageId: 8), OutgoingMessage(description: "Confirm what she means", texts: "Um...", "Anyone else in your room?", responseMessageId: 9), OutgoingMessage(description: "Refuse her invitation", texts: "I have a girlfriend already", "Don't wanna cheat on her", "Sorry.", responseMessageId: 10)]),
        5: IncomingMessage(texts: "Nvm.", responses: nil),
        6: IncomingMessage(texts: "???", responses: [OutgoingMessage(text: "????", responseMessageId: 5), OutgoingMessage(text: "?????", responseMessageId: 5), OutgoingMessage(text: "??????", responseMessageId: 5), OutgoingMessage(text: "???????", responseMessageId: 5)]),
        7: IncomingMessage(texts: "Yea sure!", responses: nil),
        8: IncomingMessage(texts: "Just come over and we'll see~", responses: [OutgoingMessage(description: "Accept her invitation", texts: "Definitely", "I'll be there in a minute.", responseMessageId: nil), OutgoingMessage(description: "Confirm what she means", texts: "Um...", "Anyone else in your room?", responseMessageId: 9), OutgoingMessage(description: "Refuse her invitation", texts: "I have a girlfriend already", "Don't wanna cheat on her", "Sorry.", responseMessageId: 10)]),
        9: IncomingMessage(texts: "There won't be if you come", responses: [OutgoingMessage(description: "Accept her invitation", texts: "Definitely", "I'll be there in a minute.", "Do I need to bring anything with me?", responseMessageId: 8), OutgoingMessage(description: "Refuse her invitation", texts: "I have a girlfriend already", "Don't wanna cheat on her", "Sorry.", responseMessageId: 10)]),
        10: IncomingMessage(texts: "It's okay.", "You don't have to apologize", responses: [OutgoingMessage(description: "(End Chat)", consequences: [.endChatFrom(.outgoing)])])
    ]
}

// MARK: -
// MARK: -

/**
 A struct to hold information about the Friendship with a Friend.
 */
struct Friendship {
    // MARK: Instance properties
    var progress: Int {
        didSet {
            levelNumber = (progress / 10) + 1
            currentUpperBound = upperBounds[levelNumber]
            previousUpperBound = upperBounds[levelNumber - 1]
            normalizedProgress = Float((progress - previousUpperBound) / (currentUpperBound - previousUpperBound))
        }
    }
    var normalizedProgress: Float = 0
    var levelNumber: Int = 0
    var currentUpperBound: Int = 10
    private var previousUpperBound: Int = 0
    private var upperBounds = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110]
    
    // MARK: - Initializers
    /**
     Initializes a Friendship using progress.
     */
    init(progress: Int) {
        self.progress = progress
        levelNumber = (progress / 10) + 1
        currentUpperBound = upperBounds[levelNumber]
        previousUpperBound = upperBounds[levelNumber - 1]
        normalizedProgress = Float(progress - previousUpperBound) / Float(currentUpperBound - previousUpperBound)
    }
}
