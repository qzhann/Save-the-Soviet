//
//  ChatViewController.swift
//  Uncommon Application
//
//  Created by qizihan  on 1/31/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ChatDisplayDelegate {
    // MARK: IB Outlets
    
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var tableViewHeader: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var backButtonBackgroundView: UIView!
    
    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var responseButton1: UIButton!
    @IBOutlet weak var responseButton2: UIButton!
    @IBOutlet weak var responseButton3: UIButton!
    
    // MARK: - Instance properties
    unowned var friend: Friend!
    /// The data source used to display the chat history.
    var displayedChatHistory: [ChatMessage] = []
    /// This is updated each time a user is prompted for a response in order to correctly notify the Friend which OutgoingMessage is chosen.
    var mostRecentOutgoingResponses: [OutgoingMessage]?
    /// This tracks the thinking status of the User and the Friend, used to insert and remove the thinking cells in ChatTableView.
    var thinkingStatus: ThinkingStatus = .completed
    enum ThinkingStatus {
        case incoming
        case outgoing
        case completed
    }
    /// This tracks whether the chat has ended, also serving the data source for the end chat cell section.
    var chatEndingStatus: ChatEndingStatus = .notEnded
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    // MARK: - Table View Data Source Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: // Chat Cells
            return displayedChatHistory.count
        case 1: // Thinking Cells
            if thinkingStatus == .completed {
                return 0
            } else {
                return 1
            }
        case 2: // End Chat Cells
            switch chatEndingStatus {
            case .endedFrom(_):
                return 1
            default:
                return 0
            }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: // Chat Cells
            // Fetch the message to display
            let message = displayedChatHistory[indexPath.row]
            // Configure and return the cell
            if message.direction == .incoming {
                let cell = tableView.dequeueReusableCell(withIdentifier: "LeftChatCell", for: indexPath) as! LeftChatTableViewCell
                cell.configureUsing(message, with: friend)
                cell.selectionStyle = .none
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RightChatCell", for: indexPath) as! RightChatTableViewCell
                cell.configureUsing(message, with: friend)
                cell.selectionStyle = .none
                return cell
            }
        case 1: // Thinking Cells
            if thinkingStatus == .incoming {
                let cell = tableView.dequeueReusableCell(withIdentifier: "LeftChatCell", for: indexPath) as! LeftChatTableViewCell
                cell.configureUsing(ChatMessage.incomingThinkingMessage, with: nil)
                cell.selectionStyle = .none
                return cell
            } else if thinkingStatus == .outgoing {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RightChatCell", for: indexPath) as! RightChatTableViewCell
                cell.configureUsing(ChatMessage.incomingThinkingMessage, with: nil)
                cell.selectionStyle = .none
                return cell
            } else {
                return UITableViewCell()
            }
        case 2: // End Chat Cells
            switch chatEndingStatus {
            case .endedFrom(let direction):
                if direction == .incoming {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "LeftChatCell", for: indexPath) as! LeftChatTableViewCell
                    let endChatMessage = ChatMessage(text: "\(friend.name) has left chat.", direction: direction)
                    cell.configureUsing(endChatMessage, with: friend)
                    cell.selectionStyle = .none
                    return cell
                } else if direction == .outgoing {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "RightChatCell", for: indexPath) as! RightChatTableViewCell
                    let endChatMessage = ChatMessage(text: "You have left chat.", direction: direction)
                    cell.configureUsing(endChatMessage, with: friend)
                    cell.selectionStyle = .none
                    return cell
                } else {
                    return UITableViewCell()
                }
            default:
                return UITableViewCell()
            }
        default:
            return UITableViewCell()
        }
    }
    
    // MARK: - Table View Delegate Methods
    
    // Configures the header that gives extra space above the first message
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableViewHeader
    }
    
    // Configures the header that gives extra space above the first message
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 35 : 0
    }
    
    
    // MARK: - Chat Display Delegate Methods
    func didAddIncomingMessageWith(responses: [OutgoingMessage]?, consequences: [ChatConsequence]?) {
        // Update ChatTableView using the added messages
        let totalDelay = updateChatWithDelay()
        
        // Handle responses and consequences
        let promptUserTimer = Timer.scheduledTimer(withTimeInterval: totalDelay, repeats: false) { (_) in
            if let responses = responses {
                self.promptUserWith(responses: responses)
            } else {
                self.endChatUsing(.incoming)
            }
            /*
             if let consequences = consequences {
             // FIXME: Do something according to the consequences given
             }
             */
        }
        
        // Save energy
        promptUserTimer.tolerance = 0.5
    }
    
    func didAddOutgoingMessageWith(responseId: Int?, consequences: [ChatConsequence]?) {
        // Update ChatTableView using the added messages
        let totalDelay = updateChatWithDelay()
        
        // Handle responses and consequences
        let addResponseTimer = Timer.scheduledTimer(withTimeInterval: totalDelay, repeats: false) { (_) in
            if let responseId = responseId {
                self.friend.sendIncomingMessageWithId(responseId)
            } else {
                self.endChatUsing(.outgoing)
            }
            /*
             if let consequences = consequences {
             // FIXME: Do something according to the consequences given
             }
             */
        }
        // Save energy
        addResponseTimer.tolerance = 0.5
    }
    
    // MARK: Chat Display Delegate Helper Methods
    func updateChatWithDelay() -> Double {
        let oldHistoryCount = displayedChatHistory.count
        let newHistoryCount = friend.chatHistory.count
        var totalDelay: Double = 0
        
        minimizeResponseTableViewHeight()
        
        for messageIndex in oldHistoryCount ..< newHistoryCount {
            // Get each new message and the delay
            let message = friend.chatHistory[messageIndex]
            var animation = UITableView.RowAnimation.automatic
            if message.direction == .incoming {
                animation = .left
            } else {
                animation = .right
            }
            
            totalDelay += message.delay
            
            // Calculate the addition / removal time for thinking and message
            let messageAdditionTime = totalDelay
            let thinkingAdditonTime = messageAdditionTime - message.delay + 0.5
            let thinkingRemovalTime = messageAdditionTime - 0.1
            
            let thinkingAdditionTimer = Timer(timeInterval: thinkingAdditonTime, repeats: false) { (_) in
                // Do not add the thinking cell if the message if the first OutgoingMessage
                guard message.delay != 0 else { return }
                // Update the thinking status and insert the row for thinking cell
                switch message.direction {
                case .incoming:
                    self.thinkingStatus = .incoming
                    self.chatTableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .left)
                case .outgoing:
                    self.thinkingStatus = .outgoing
                    self.chatTableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .right)
                }
                self.scrollChatTableViewToBottom()
            }
            
            let messageAdditionTimer = Timer(timeInterval: messageAdditionTime, repeats: false) { (_) in
                // Update the data model
                self.displayedChatHistory.append(message)
                // Update chatTableView and scroll to show addition
                self.chatTableView.insertRows(at: [IndexPath(row: messageIndex, section: 0)], with: animation)
                self.scrollChatTableViewToBottom()
            }
            
            let thinkingRemovalTimer = Timer(timeInterval: thinkingRemovalTime, repeats: false) { (_) in
                // Do not delete the thinking cell if the message if the first OutgoingMessage
                guard message.delay != 0 else { return }
                // Update the thinking status and delete the row for the thinking cell
                self.thinkingStatus = .completed
                self.chatTableView.deleteRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
            }
            
            // Save energy
            thinkingAdditionTimer.tolerance = 0.5
            messageAdditionTimer.tolerance = 0.5
            thinkingRemovalTimer.tolerance = 0.5
            
            // Manually add the timers for common RunLoop mode
            RunLoop.current.add(thinkingAdditionTimer, forMode: .common)
            RunLoop.current.add(messageAdditionTimer, forMode: .common)
            RunLoop.current.add(thinkingRemovalTimer, forMode: .common)
        }
        
        // If there is no new message, return a delay of 0.5 to allow time for the responseTableView to appear, otherwise return the correct totalDelay.
        return totalDelay == 0 ? 0.5 : totalDelay + 0.3
    }
    
    func endChatUsing(_ direction: MessageDirection) {
        var animation = UITableView.RowAnimation.automatic
        if direction == .incoming {
            animation = .left
        } else {
            animation = .right
        }
        let endChatTime = 0.5
        
        let endChatTimer = Timer(timeInterval: endChatTime, repeats: false) { (_) in
            self.chatEndingStatus = .endedFrom(direction)
            self.friend.chatEndingStatus = .endedFrom(direction)
            self.friend.mostRecentResponse = .completed
            self.chatTableView.insertRows(at: [IndexPath(row: 0, section: 2)], with: animation)
            self.scrollChatTableViewToBottom()
        }
        
        // Save energy
        endChatTimer.tolerance = 0.5
        
        // Manually add the timers for common RunLoop mode
        RunLoop.current.add(endChatTimer, forMode: .common)
    }
    

    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareUI()
        resumeChat()
    }
    
    
    // MARK: - Instance Methods
    func prepareUI() {
        // Hide scroll indicator for table view
        chatTableView.showsVerticalScrollIndicator = false
        
        // Setting round corner, opacity, and shadow for backButton
        backButton.layer.cornerRadius = backButton.frame.height / 2
        backButton.clipsToBounds = true
        backButtonBackgroundView.layer.cornerRadius = backButtonBackgroundView.frame.height / 2
        backButtonBackgroundView.layer.shadowColor = UIColor.black.cgColor
        backButtonBackgroundView.layer.shadowOpacity = 0.5
        backButtonBackgroundView.layer.shadowOffset = .zero
        backButtonBackgroundView.layer.shadowRadius = 1
        backButtonBackgroundView.layer.shadowPath = UIBezierPath(roundedRect: backButtonBackgroundView.bounds, cornerRadius: backButtonBackgroundView.layer.cornerRadius).cgPath
        
        // Round corner for response buttons, and hide buttons
        let buttons = [responseButton1, responseButton2, responseButton3]
        for button in buttons {
            button?.layer.cornerRadius = 10
            button?.isEnabled = false
            button?.alpha = 0
        }
        buttonsStackView.isHidden = true
    }
    
    func hideResponseButtons() {
        // Hide each response button
        let buttons = [responseButton1, responseButton2, responseButton3]
        UIView.animate(withDuration: 0.5, animations: {
            for button in buttons {
                button?.isEnabled = false
                button?.alpha = 0
            }
        }) { (_) in
            // Hide the entire button stack so that the stackView is not blocking user interaction with ChatTableView
            self.buttonsStackView.isHidden = true
        }
    }
    
    func showResponseButtons() {
        // Show the button stack
        self.buttonsStackView.isHidden = false
        
        // Show each response button
        let buttons = [responseButton1, responseButton2, responseButton3]
        UIView.animate(withDuration: 0.5) {
            for button in buttons {
                button?.isEnabled = true
                button?.alpha = 1
            }
        }
        // Make table view scroll and inset correctly to avoid buttons blocking content
        maximizeResponseTableViewHeight()

    }
    
    func promptUserWith(responses: [OutgoingMessage]) {
        // Set titles correctly on each response button
        let buttons = [responseButton1, responseButton2, responseButton3]
        for index in buttons.indices {
            buttons[index]?.setTitle(responses[index].description, for: .normal)
        }
        
        // Keep track of the array of OutgoingMessage and show the response buttons
        mostRecentOutgoingResponses = responses
        showResponseButtons()
    }
    
    // FIXME: ChatViewController should set friend.mostRecentResponse to completed when calling endChat()
    func resumeChat() {
        // Set the chatDelegate for the Friend
        friend.chatDelegate = self
        
        // update the chat history starting from the appropriate place
        copyChatHistoryUntilChatMessage(count: friend.displayedMessageCount)
        
        // update the chatEndingStatus
        chatEndingStatus = friend.chatEndingStatus

        // Resume chat status using Friend's mostRecentResponse
        switch friend.mostRecentResponse {
        // If the Friend recorded unresponded IncomingMessage with OutgoingMessages as the most recent response
        case .outgoingMessages(let outgoingMessages):
            didAddIncomingMessageWith(responses: outgoingMessages, consequences: nil)
        // If the Friend had no record of most recent response, begin a chat.
        case .none:
            friend.sendIncomingMessageWithId(0)
        // If the Friend completed a response to an IncomingMessage, do nothing
        default:
            break
        }
        
        // Scroll ChatTableView to bottom
        scrollChatTableViewToBottom()
    }
    
    func copyChatHistoryUntilChatMessage(count historyCount: Int) {
        // copy over the chat hisotry and remove ones not yet displayed
        displayedChatHistory = friend.chatHistory
        for _ in 0 ..< friend.chatHistory.count - friend.displayedMessageCount {
            displayedChatHistory.removeLast()
        }
    }
    
    func minimizeResponseTableViewHeight() {
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        UIView.animate(withDuration: 0.5) {
            self.chatTableView.contentInset = contentInsets
        }
        
        scrollChatTableViewToBottom()
    }
    
    func maximizeResponseTableViewHeight() {
        let buttonsStackHeight = responseButton1.frame.height * 3 + 36
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: buttonsStackHeight, right: 0)
        chatTableView.contentInset = contentInsets
        
        scrollChatTableViewToBottom()
    }
    
    func scrollChatTableViewToBottom() {
        
        switch chatEndingStatus {
        case .endedFrom(_):
            chatTableView.scrollToRow(at: IndexPath(row: 0, section: 2), at: .top, animated: true)
            return
        default:
            break
        }
        
        if thinkingStatus != .completed {
            chatTableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
        } else if displayedChatHistory.isEmpty == false {
            chatTableView.scrollToRow(at: IndexPath(row: displayedChatHistory.count - 1, section: 0), at: .top, animated: true)
        }
    }
    
    // MARK: - IB Actions
    
    @IBAction func responseButtonTapped(_ sender: UIButton) {
        hideResponseButtons()
        
        switch sender {
        case responseButton1:
            friend.respondedWith(mostRecentOutgoingResponses![0])
        case responseButton2:
            friend.respondedWith(mostRecentOutgoingResponses![1])
        default:
            friend.respondedWith(mostRecentOutgoingResponses![2])
        }
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        friend.displayedMessageCount = displayedChatHistory.count
        dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
