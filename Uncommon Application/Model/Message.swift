//
//  ChatMessages.swift
//  Uncommon Application
//
//  Created by qizihan  on 12/20/18.
//  Copyright © 2018 qzhann. All rights reserved.
//

import Foundation

// FIXME: Update comments
/**
 ### Instance Properties
    * id: ID of a Message instance. Each ID is unique in allPossibleMessages array of a Friend instance. Functions should use this property to trigger corresponding special events.
    * next: ID of the next message to display shortly after. If nil, Friend will call pausedSpeaking() method to pass responses.
    * content: The content String of the Message.
    * delay: Optional delay when displaying the message. Default to be content.count / 20 + 2
    * direction: .to or .from. ChatViewController will use this property to decide which side the chat bubble should appear.
    * responses: Default as nil. If a Message should trigger user responses, set responses to proper Response instances.
 */
struct Message {
    
    enum MessageDirection {
        case to
        case from
    }
    
    var id: Int
    var next: Int?
    var content: String
    var delay: Double {
        return Double(content.count) / 20 + 2
    }
    
    var direction: MessageDirection
    var responses: [Response]?
    
    // FIXME: Implementations of the 2 restrictions may need to change
    var energyNeeded: Double?
    var levelRestriction: Int?
    
    
    // MARK: - Initializers
    
    /**
     - parameters:
        - id: The ID for each message of a Friend instance. ID is unique for all Message instances of a Friend
        - next: The ID of the next message to display. If no message directly follows, set it to nil.
        - responses: Optional array of Response instances corresponding to the message. If no response should be prompted to the user, set it to nil.
        - content: Content String of the Message.
     
    - returns:
        - A Message instance
     */
    init(id: Int, content: String, next: Int?, responses: [Response]?) {
        self.id = id
        self.next = next
        self.direction = .from
        self.content = content
        self.responses = responses
    }
    
    /**
     Use this initializer to create a temporary "..." Message instance. Typically called by willText() method a Friend to display placeholder "..." message.
     - Parameter content: The content string of the Message, typically "..."
     */
    init(_ content: String, direction: MessageDirection) {
        self.id = -2
        self.responses = nil
        self.direction = direction
        self.content = content
        self.next = nil
    }
    
    // FIXME: Documentation
    init(response: String) {
        self.id = -1
        self.responses = nil
        self.direction = .to
        self.content = response
        self.next = nil
    }
    
    // FIXME: Documentation
    init(lastResponse: String, next: Int) {
        self.id = -1
        self.responses = nil
        self.direction = .to
        self.content = lastResponse
        self.next = next
    }

}

struct Response {
    var title: String
    var contents: [Message]
    var next: Int
    
    // FIXME: Need an init statement which takes in strings and then automatically intializes these strings into title and content Messages with .to direction.
    init(title: String, contents: [String], next: Int) {
        self.title = title
        
        var finalContents: [Message] = []
        
        for content in contents {
            if content == contents.last {
                finalContents.append(Message(lastResponse: content, next: next))
            } else {
                finalContents.append(Message(response: content))
            }
        }
        
        self.contents = finalContents
        self.next = next
        
    }
    
    // FIXME: Documentation
    init(title: String, next: Int) {
        self.title = title
        self.contents = [Message(lastResponse: title, next: next)]
        self.next = next
    }
}

