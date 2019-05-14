//
//  Friend.swift
//  Uncommon Application
//
//  Created by qizihan  on 12/20/18.
//  Copyright © 2018 qzhann. All rights reserved.
//

import Foundation
import UIKit

protocol ChatResponsesDelegate {
    
    /**
     Called by Friend when the latest Message's next is nil.
     - Parameter responses: Optional response array of the latest Message.
     */
    func promptUserWith(responses: [Response])
    
    /**
     Called by Friend whenever a Message has been added to appearedMessages.
     - Parameter row: the row at which the table view should insert the new row at.
     */
    func updateTableView(at row: Int, remove: Bool, with: UITableView.RowAnimation)
    
    // FIXME: Need documentation
    func endChat()
    
}

/**
 ChatViewController will be passed a Friend class instance from MainViewController. We need not worry about passing Friend instance back because it is implemented as a class.
 
 ### Instance Properties
    * name
    * image
    * description: General description of the friend, shown when the user makes new friend and in the friend's description pop-up.
    * friendship
    * powers
    * delegate: ChatResponseDelegate, by default is the ChatViewController, will be passed the optional Response array from the latest Message.
    * isChatting: Automatically handles whether to use unreadMessages and call isTexting() or simply store it. Sets true when ChatViewController is appearing, and sets to false when ChatViewController segues to other view controllers.
    * appearedMessages: Message instances that have been displayed
    * unreadMessages: Message instances that are to be displayed with insertRow(:) method with animation when user enters chat with the friend. If not empty, MainViewController displays indications of new message with the friend. After user response, Message instances are first added here, then handled by willText() method to add to appearedMesssages.
    * allPossibleMessages: All messages the friend can possibly send
 
 ### Type Properties
    * testFriend: A Friend instance used for testing purposes
 
 ### Instance Methods
    * willText(id: Int): Pass in the id of the Message you wish to start a conversation with, and the Friend will handle the rest automatically. Internally, calls sendMessage() and informs it that delay is needed.
    * respondedWith(_ option: Int): Called by the ChatViewController that is displaying the chat contents of the Friend after the user chooses a response option from the UI. Calls willText(response: Response) on the corresponding Response of the last Message in appearedMessages.
 
 ### Initializer
    * Initialize with name, image, and description.
 
 - Important: Responses to a message is NOT in allMessages. When user selects a response, the Friend instance should create a Message instance
 */
class Friend {
    var name: String
    var image: UIImage
    var description: String
    var friendship = Friendship(progress: 0)
    var powers: [Power] = []
    var delegate: ChatResponsesDelegate!
    
    // When the chatting state has become active, he Friend should text all Message instances in unreadMessages
    var isChatting = true {
        didSet {
            if isChatting {
                isTexting()
            }
        }
    }
    
    // When unreadMessages is changed, the user is texting something.
    var unreadMessages: [Message] = [] {
        didSet {
            if isChatting {
                isTexting()
            }
        }
    }
    
    // Before appearedMessages is changed, the user did text something.
    var appearedMessages: [Message] = []
    
    // FIXME: Should be initialized properly
    private var allPossibleMessages: [Message] = Friend.allTestMessages
    
    var allPossibleResponses: [Response] = []
    
    // MARK: - Initializer
    
    /**
     Initialize a basic friend instance.
     - Parameters:
        - name: Name of the friend
        - image: Image of the friend
        - description: General description of the friend, shown when the user makes new friend
     */
    init(name: String, image: UIImage, description: String, allPossibleMessages: [Message]) {
        self.name = name
        self.image = image
        self.description = description
        self.allPossibleMessages = allPossibleMessages
    }
    
    /**
     Initializes a placeholder friend instace. Note that this is only useful for declaring instance properties for a view controller. Any property initialized using this initializer should be replaced by an actual Friend instance.
     */
    
    init() {
        self.name = "TestFriend"
        self.image = UIImage(named: "Lucia")!
        self.description = "This is a friend description."
    }
    
    // MARK: - Texting Status Control Methods
    
    /**
     Adds Message instance to unreadMessages. Accesses each Message using id. We only need to pass in the id of the first message needed to start a conversation, and the rest of the conversation will be automatically handled. This method also handles the addition and removal of "..." Message before the friend texts the acutal Message.
     - Parameter messages: ID of the next messages the Friend will text.
     */
    /**
     Called after the user selects a Response from UI. Initializing new Message instances and add to appearedMessages. Also call willText() on the next Message the Friend should send.
     */
    func respondedWith(_ option: Int) {
        // Fetch the corresponding response
        if let response = appearedMessages.last?.responses?[option] {
            // Initialize a Message instance using response and add call willText()
            willText(response: response)
        }
    }
    
    func willText(message: Int) {
        let currentMessage = getMessage(number: message)
        
        sendMessage(currentMessage, delay: true)
    }
    
    /**
     Sends each Message instance of a Response's contents to the Friend by calling sendMessage(_:, delay:).
     - Parameter response: the response whose content Message instances about to be sent by the user.
     */
    private func willText(response: Response) {
        
        // Send each Message in the response
        for index in response.contents.indices {
            let currentMessage = response.contents[index]
            
            switch index {
            case 0:
                sendMessage(currentMessage, delay: false)
            default:
                sendMessage(currentMessage, delay: true)
            }
            
        }
    }

    /**
     Adds Message instances from unreadMessages to appearedMessages. Calls didText(). This is function serves as the buffer function useful for transitioning betweeen an active / inactive chat state of a Friend.
     */
    private func isTexting() {
        guard unreadMessages.isEmpty == false else { return }
        let message = unreadMessages.removeFirst()
        appearedMessages.append(message)
        didText()
    }
    
    /**
     Calls the delegate to update table view content for each new message in appearedMessages. Determines whether to prompt for user response, initiate special incidents, or end chat.
     */
    private func didText() {
        // Guard there is a last message
        guard let newMessage = appearedMessages.last else {return}
        
        // Calls the delegate to update the message using correct animation
        if newMessage.direction == .from {
            delegate.updateTableView(at: appearedMessages.count - 1, remove: false, with: .left)
        } else {
            delegate.updateTableView(at: appearedMessages.count - 1, remove: false, with: .right)
        }
        
        // If there is a next Message, keep on texting
        if let nextMessageID = newMessage.next {
            willText(message: nextMessageID)
        } else if let responses = newMessage.responses {
        // If next is nil and responses is not nil, pass the Response data to the delegate
            delegate.promptUserWith(responses: responses)
        } else if newMessage.direction == .from {
        // If the next and responses are all nil of a received Message, end the chat
            delegate.endChat()
        }
        
        // If next and responses are all nil of a Message that is of direction .to, then do nothing and continue chatting
        
    }
    
    /**
     Called by willText(message: Int) and willText(response: Response), handles proper delay if asked to and handles the addtion and removal of the "..." typing indicator.
     */
    private func sendMessage(_ message: Message, delay: Bool) {
        // FIXME: The entire "..." addtion and removal might very likely to cause problems in the future. COME BACK if there is problem.
        
        guard delay == true else {
            unreadMessages.append(message)
            return
        }
        
        // Adds a "..." Message after a delay, before the friend texts the actual Message.
        let addIndicatorTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { (timer) in
            
            // If the User is not in the Chat View Controller, then the addtion of "..." is not executed.
            if self.isChatting == true {
                // Adds "..." Message and then calls the delegate to update the table view
                self.appearedMessages.append(Message("   ...   ", direction: message.direction))
                self.delegate.updateTableView(at: self.appearedMessages.count - 1, remove: false, with: .fade)
            }
            
        }
        
        // Saves energy usage
        addIndicatorTimer.tolerance = 0.5
        
        // Removes the ... Message after a delay, and then adds the acutal Message to unreadMessages
        let removeIndicatorTimer = Timer.scheduledTimer(withTimeInterval: message.delay, repeats: false) { (_) in
            
            // If the User is not in the Chat View Controller, then the removal of "..." is not executed.
            if self.isChatting == true {
                // Removes "..." from appearedMessages and then calls the delegate to update table view
                self.appearedMessages.remove(at: self.appearedMessages.count - 1)
                self.delegate.updateTableView(at: self.appearedMessages.count, remove: true, with: .fade)
            }
            
            self.unreadMessages.append(message)
        }
        
        // Saves energy usage
        removeIndicatorTimer.tolerance = 0.5
    }
    
    // MARK: - Helper Functions
    
    /**
     - returns: Message with the specified id from allPossibleMessages of the Friend.
     - Important: If id is smaller than 1000, will get the message using array index by looking up allPossibleMessages array. Otherwise return the id % 1000 to last Message.
     */
    private func getMessage(number id: Int) -> Message {
        if id < 1000 {
            return allPossibleMessages[id]
        } else {
            return allPossibleMessages[allPossibleMessages.count - 1 - (id % 1000)]
        }
    }
    
    // MARK: - Test Friend and Test Messages
    
    
    static var testFriend: Friend = Friend(name: "Lucia", image: UIImage(named: "Dog")!, description: "The sluttiest girl in the world.", allPossibleMessages: Friend.allTestMessages)
    
    static var allTestMessages: [Message] = [
        Message(id: 0, content: "Hey Handsome", next: nil, responses: [Response(title: "Hey babe", next: 1), Response(title: "What's up", next: 1), Response(title: "Yo Bitch", next: 2)]),
        Message(id: 1, content: "Do you want to get together?", next: nil, responses: [Response(title: "(Try to end chat)", next: 2), Response(title: "(Keep on flirting)", contents: ["Yea sure!", "Got any plans for tonight?"], next: 3), Response(title: "I'll consider that ;)", next: 4)]),
        Message(id: 2, content: "Nvm.", next: 1000, responses: nil),
        Message(id: 3, content: "Actually... I am going to a party tonight...", next: 4, responses: nil),
        Message(id: 4, content: "If we have something good to do, I'm down for you ;D", next: nil, responses: [Response(title: "How about... a movie night?", next: 5), Response(title: "Wanna netflix and chill?", next: 5), Response(title: "Well, you can suck my dick ;D", next: 6)]),
        
        Message(id: 5, content: "Sure~", next: 1000, responses: nil),
        Message(id: 6, content: "Fuck you pervert", next: nil, responses: [Response(title: "I love you.", next: 1000), Response(title: "I hate you!", next: 1000), Response(title: "I miss you.", next: 1000)]),
        
        Message(id: 1000, content: "Lucia has left chat.", next: nil, responses: nil),
    ]
    
}

// MARK: - Friendship struct

/**
 ### Instance Properties
    * progress: Progress of the friendship. Whenever updated, automatically updates levelNumber and currentUpperBound
    * levelNumber: Level Number displayed on UI
    * currentUpperBound: The maximum progress number to remain in the same levelNumber
    * upperBounds: The source of update for currentUpperBound
 
 ### Initializer
    * Initialize with progress.
 */
struct Friendship {
    
    var progress: Int {
        didSet {
            levelNumber = (progress / 10) + 1
            currentUpperBound = upperBounds[levelNumber - 1]
        }
    }
    var levelNumber: Int = 0
    var currentUpperBound: Int = 0
    var upperBounds = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110]
    
    /**
     - parameter progress: Progress of the friendship. Whenever updated, automatically updates levelNumber and currentUpperBound.
     */
    init(progress: Int) {
        self.progress = progress
    }
}
