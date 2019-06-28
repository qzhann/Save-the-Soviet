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
// MARK: -

/**
 The data model held by a Friend in its chatHistory.
 */
class ChatMessage: Equatable, CustomStringConvertible {
    // MARK: Equatable protocol stub
    static func ==(lhs: ChatMessage, rhs: ChatMessage) -> Bool{
        return lhs.text == rhs.text && lhs.direction == rhs.direction
    }
    
    // MARK: - CustomStringCovertible stub
    var description: String {
        let messageDirectionString = direction == .incoming ? "Incoming: " : "Outgoing: "
        return messageDirectionString + text
    }
    
    
    // MARK: - Instance properties
    var text: String
    var direction: MessageDirection
    /// The time for a ChatMessage in the chatHistory to be displayed.
    var delay: Double
    
    
    // MARK: - Initializers
    /**
     Initializes a ChatMessage using text and direction. Calculates delay using the length of the text.
     */
    init(text: String, direction: MessageDirection) {
        self.text = text.count <= 3 ? "  \(text)  " : text
        self.direction = direction
        self.delay = 1.2 + Double(text.count) / 20
    }
    
    /**
     Initializes a ChatMessage using text and direction. Calculates delay using the length of the text.
     */
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
// MARK: -


/**
 A struct that holds texts, optional OutgoingMessage array as responses, and optional Consequence array as consequences, marked by a unique id for quick retrieval.
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
    /**
     Initializes an IncomingMessage.
     - Parameters:
        - id: The unique identifier for the IncomingMessage. This should always be the same as the IncomingMessage's index in allPossibleMessages.
        - texts: A variadic parameter that takes in Strings to be texted in sequence by a Friend when sending the IncomingMessage.
        - responses: An optional array of OutgoingMessage. If not nil, the user will be prompted to choose from the responses, otherwise the IncomingMessage should trigger the end of a chat.
        - consequences: An optional array of ChatConsequences. If not nil, the chatDelegate of the friend should be responsible for delivering the consequences.
     */
    init(texts: String..., responses: [OutgoingMessage]? = nil, consequences: [Consequence]? = nil) {
        self.texts = texts
        self.responses = responses
        self.consequences = consequences
    }
}

// MARK: -
// MARK: -

/**
 A struct that holds description, texts, optional Int as the Id for the response IncomingMessage, and optional Consequence array as consequences. Different from IncomingMessage, OutgoingMessage has an additional optional levelRestriction.
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
    /**
     Initializes an IncomingMessage whose description and texts are different.
     - Parameters:
        - description: The String displayed for each response choice.
        - texts: A variadic parameter that takes in Strings to be texted in sequence by the User when sending the OutgoingMessage.
        - responseMessageId: If not nil, the Friend will send a IncomingMessage using the responseMessageId, otherwise the OutgoingMessage should trigger the end of a chat.
        - levelRestriction: If not nil, the OutgoingMessage will be disabled as an option if the User's level is lower than levelRestriction.
        - consequences: An optional array of ChatConsequences. If not nil, the chatDelegate of the friend should be responsible for delivering the consequences.
     */
    init(description: String, texts: String..., responseMessageId: Int?, levelRestriction: Int? = nil, consequences: [Consequence]? = nil) {
        self.description = description
        self.texts = texts
        self.responseMessageId = responseMessageId
        self.levelRestriction = levelRestriction
        self.consequences = consequences
    }
    
    /**
     Initializes a single-text OutgoingMessage.
     - Parameters:
        - text: The only string that will be texted by the User when sending the OutgoingMessage.The OutgoingMessage's description is initialized using this parameter.
        - responseMessageId: If not nil, the Friend will send a IncomingMessage using the responseMessageId, otherwise the OutgoingMessage should trigger the end of a chat.
        - levelRestriction: If not nil, the OutgoingMessage will be disabled as an option if the User's level is lower than levelRestriction.
        - consequences: An optional array of ChatConsequences. If not nil, the chatDelegate of the friend should be responsible for delivering the consequences.
     */
    init(text: String, responseMessageId: Int?, levelRestriction: Int? = nil, consequences: [Consequence]? = nil) {
        self.description = text
        self.texts = [text]
        self.responseMessageId = responseMessageId
        self.levelRestriction = levelRestriction
        self.consequences = consequences
    }
    
    /**
     Initializes a chat action which triggers some ChatConsequences but does not send messages
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
    case deleteFriend(Friend)
    case changeLevelProgressBy(Int)
    case changeEnergyProgressBy(Int)
    case changeFriendshipProgressBy(Int, for: Friend)
    case upgradePower(Power)
    case startQuiz
}

// FIXME: handle make new friends
// FIXME: Handle change level progress, energy progress, and friendship progress by creating small animations on the recorded view controller
