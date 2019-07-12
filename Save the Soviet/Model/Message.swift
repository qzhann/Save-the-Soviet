//
//  Message.swift
//  Uncommon Application
//
//  Created by qizihan  on 12/20/18.
//  Copyright © 2018 qzhann. All rights reserved.
//

import Foundation


enum MessageDirection {
    /// ChatMessage sent by the User.
    case outgoing
    /// ChatMessage sent by a Friend.
    case incoming
}

// MARK: -


/// The data model held by a Friend in its chatHistory.
class ChatMessage: Equatable, CustomStringConvertible {
    
    // MARK: Equatable
    static func ==(lhs: ChatMessage, rhs: ChatMessage) -> Bool{
        return lhs.text == rhs.text && lhs.direction == rhs.direction
    }
    
    // MARK: - Custom String Covertible
    var description: String {
        let messageDirectionString = direction == .incoming ? "Incoming: " : "Outgoing: "
        return messageDirectionString + text
    }
    
    
    // MARK: - Instance properties
    
    /// The text displayed on the chat table view.
    var text: String
    /// The direction of the message
    var direction: MessageDirection
    /// The time for a ChatMessage in the chatHistory to be displayed.
    var delay: Double
    
    
    // MARK: - Initializers
    
    /// Initializes a ChatMessage using text and direction. Calculates delay using the length of the text.
    init(text: String, direction: MessageDirection) {
        self.text = text.count <= 3 ? "  \(text)  " : text
        self.direction = direction
        self.delay = 1.2 + Double(text.count) / 20
    }
    
    
    /// Initializes a ChatMessage using text and direction, manually set the delay.
    init(text: String, direction: MessageDirection, delay: Double) {
        self.text = text.count <= 3 ? "  \(text)  " : text
        self.direction = direction
        self.delay = delay
    }
    
    // MARK: - Static properties
    
    static let incomingThinkingMessage = ChatMessage(text: "...", direction: .incoming, delay: 0)
    static let outgoingThinkingMessage = ChatMessage(text: "...", direction: .outgoing, delay: 0)
}

// MARK: -


/**
 A struct that holds texts, optional OutgoingMessage array as responses, and optional Consequence array as consequences.
 */
struct IncomingMessage {
    // MARK: Instance properties
    /// An array of String that will be texted in sequence by a Friend when sending the IncomingMessage.
    var texts: [String]
    /// An optional array of OutgoingMessage. If not nil, the user will be prompted to choose from the responses, otherwise the IncomingMessage should trigger the end of a chat.
    var responses: [OutgoingMessage]?
    /// An optional array of ChatConsequences. If not nil, the chatDelegate of the friend should be responsible for delivering the consequences.
    var consequences: [Consequence]?
    /// A get-only property that returns the corresponding ChatMessages using texts.
    var chatMessages: [ChatMessage] {
        get {
            var currentMessages: [ChatMessage] = []
            for text in texts {
                currentMessages.append(ChatMessage(text: text, direction: .incoming))
            }
            return currentMessages
        }
    }
    
    
    // MARK: - Initializers
    
    /// Full initializer. Responses and consequences can be nil.
    init(texts: String..., consequences: [Consequence]? = nil, responses: [OutgoingMessage]? = nil) {
        self.texts = texts
        self.consequences = consequences
        self.responses = responses
    }
}

// MARK: -

/**
 A struct that holds description, texts, optional Int useful for the response IncomingMessage, and optional Consequence array as consequences. Different from IncomingMessage, OutgoingMessage has an additional optional levelRestriction.
 */
struct OutgoingMessage {
    // MARK: Instance properties
    /// The String displayed for each response choice.
    var description: String
    /// An array of String that will be texted in sequence by the User when sending the OutgoingMessage.
    var texts: [String]
    /// If not nil, the Friend will send a IncomingMessage using the responseMessageId, otherwise the OutgoingMessage should trigger the end of a chat.
    var responseMessageId: Int?
    /// If not nil, the OutgoingMessage will be disabled as an option if the User's level is lower than levelRestriction.
    var levelRestriction: Int?
    /// An optional array of ChatConsequences. If not nil, the chatDelegate of the friend should be responsible for delivering the consequences.
    var consequences: [Consequence]?
    /// A get-only property that returns the corresponding ChatMessages using texts.
    var chatMessages: [ChatMessage] {
        get {
            var currentMessages: [ChatMessage] = []
            for text in texts {
                if text == texts.first {
                    // The first ougoing ChatMessage does not delay
                    currentMessages.append(ChatMessage(text: text, direction: .outgoing, delay: 0))
                } else {
                    currentMessages.append(ChatMessage(text: text, direction: .outgoing))
                }
            }
            return currentMessages
        }
    }
    
    
    // MARK: - Initializers
    
    /// Full initializer. responseMessageId, levelRestriction, and consequences can be nil.
    init(description: String, texts: String..., responseMessageId: Int?, levelRestriction: Int? = nil, consequences: [Consequence]? = nil) {
        self.description = description
        self.texts = texts
        self.responseMessageId = responseMessageId
        self.levelRestriction = levelRestriction
        self.consequences = consequences
    }
    
    
    /// Initializes a single-text OutgoingMessage. The description is set t obe equal to the text.
    init(text: String, responseMessageId: Int?, levelRestriction: Int? = nil, consequences: [Consequence]? = nil) {
        self.description = text
        self.texts = [text]
        self.responseMessageId = responseMessageId
        self.levelRestriction = levelRestriction
        self.consequences = consequences
    }
    
    /**
     Initializes a chat action which triggers some ChatConsequences without sending any message. This is typically useful for an end chat consequence.
     */
    init(description: String, consequences: [Consequence], levelRestriction: Int? = nil) {
        self.description = description
        self.texts = []
        self.levelRestriction = levelRestriction
        self.consequences = consequences
    }

}

// MARK: -

/// Consequences of a IncomingMessage or an OutgoingMessage, represented with enums.
enum Consequence {
    case endChatFrom(MessageDirection)
    case makeNewFriend(Friend)
    case executeFriend(Friend)
    case changeUserLevelBy(Int)
    case changeUserSupportBy(Int)
    case changeUserCoinsBy(Int)
    case changeFriendLoyaltyBy(Int)
    case upgradePower(Power)
    case startQuizOfCategory(QuizQuestionCategory?)
    case setChatStartOption(ChatStartOption)
}
