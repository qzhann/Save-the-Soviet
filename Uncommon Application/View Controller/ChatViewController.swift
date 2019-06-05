//
//  ChatViewController.swift
//  Uncommon Application
//
//  Created by qizihan  on 1/31/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

struct ChatController {
    unowned var friend: Friend!
    /// The data source used to display the chat history.
    var displayedChatHistory: [ChatMessage] = []
    /// This tracks the thinking status of the User and the Friend, used to insert and remove the thinking cells in ChatTableView.
    var thinkingStatus: ThinkingStatus = .completed
    enum ThinkingStatus {
        case incoming
        case outgoing
        case completed
    }
    /// This tracks whether the chat has ended, also serving the data source for the end chat cell section.
    var chatEndingStatus: ChatEndingStatus = .notEnded
    
    var didMaximizeResponseContainerViewHeight = false {
        didSet {
            contentOffsetCount = 0
        }
    }
    var verticalContentOffset: CGFloat = -20 {
        didSet {
            if contentOffsetCount != 0 {
                self.verticalContentOffset = oldValue
            }
            contentOffsetCount += 1
        }
    }
    private var contentOffsetCount = 0
}

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ChatDisplayDelegate {
    // MARK: IB Outlets
    
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var tableViewHeader: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var backButtonBackgroundView: UIView!
    @IBOutlet weak var responseContainerView: UIView!
    
    // MARK: - Instance properties
    
    /// The TableViewController responsible for handling the display and selection of response choices
    unowned var responseTableViewController: ResponseTableViewController!
    
    var chatController = ChatController()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    let hairlineView = UIView()
    
    
    // MARK: - View Controller Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareUI()
        resumeChat()

        hairlineView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        hairlineView.alpha = 0
        self.view.addSubview(hairlineView)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        hairlineView.removeFromSuperview()
    }
    
    
    // MARK: - Scroll View delegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if chatController.didMaximizeResponseContainerViewHeight == true {
            var alpha = (chatController.verticalContentOffset - scrollView.contentOffset.y) / 8
            if alpha > 1 {
                alpha = 1
            } else if alpha < 0 {
                alpha = 0
            }
            hairlineView.alpha = alpha
        } else {
            hairlineView.alpha = 0
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        chatController.verticalContentOffset = scrollView.contentOffset.y
    }
    
    // MARK: - Table View Data Source Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: // Chat Cells
            return chatController.displayedChatHistory.count
        case 1: // Thinking Cells
            if chatController.thinkingStatus == .completed {
                return 0
            } else {
                return 1
            }
        case 2: // End Chat Cells
            switch chatController.chatEndingStatus {
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
            let message = chatController.displayedChatHistory[indexPath.row]
            // Configure and return the cell
            if message.direction == .incoming {
                let cell = tableView.dequeueReusableCell(withIdentifier: "LeftChatCell", for: indexPath) as! LeftChatTableViewCell
                cell.configureUsing(message, with: chatController.friend)
                cell.selectionStyle = .none
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RightChatCell", for: indexPath) as! RightChatTableViewCell
                cell.configureUsing(message, with: chatController.friend)
                cell.selectionStyle = .none
                return cell
            }
        case 1: // Thinking Cells
            if chatController.thinkingStatus == .incoming {
                let cell = tableView.dequeueReusableCell(withIdentifier: "LeftChatCell", for: indexPath) as! LeftChatTableViewCell
                cell.configureUsing(ChatMessage.incomingThinkingMessage, with: nil)
                cell.selectionStyle = .none
                return cell
            } else if chatController.thinkingStatus == .outgoing {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RightChatCell", for: indexPath) as! RightChatTableViewCell
                cell.configureUsing(ChatMessage.incomingThinkingMessage, with: nil)
                cell.selectionStyle = .none
                return cell
            } else {
                return UITableViewCell()
            }
        case 2: // End Chat Cells
            switch chatController.chatEndingStatus {
            case .endedFrom(let direction):
                if direction == .incoming {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "LeftChatCell", for: indexPath) as! LeftChatTableViewCell
                    let endChatMessage = ChatMessage(text: "\(chatController.friend.name) has left chat.", direction: direction)
                    cell.configureUsing(endChatMessage, with: chatController.friend)
                    cell.selectionStyle = .none
                    return cell
                } else if direction == .outgoing {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "RightChatCell", for: indexPath) as! RightChatTableViewCell
                    let endChatMessage = ChatMessage(text: "You have left chat.", direction: direction)
                    cell.configureUsing(endChatMessage, with: chatController.friend)
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
                self.endChatFrom(.incoming)
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
            // Note that we don't want to automatically end chat. This is handled as a consequence
            if let consequences = consequences {
                for consequence in consequences {
                    switch consequence {
                    case .endChatFrom(let direction):
                        self.endChatFrom(direction, withDelay: 0)
                    default:
                        break
                    }
                }
            }
            
            if let responseId = responseId {
                self.chatController.friend.sendIncomingMessageWithId(responseId)
            }
            
        }
        // Save energy
        addResponseTimer.tolerance = 0.5
    }
    
    // MARK: Chat Display Delegate Helper Methods
    func updateChatWithDelay() -> Double {
        let oldHistoryCount = chatController.displayedChatHistory.count
        let newHistoryCount = chatController.friend.chatHistory.count
        var totalDelay: Double = 0
        
        //minimizeResponseContainerViewHeight()
        
        for messageIndex in oldHistoryCount ..< newHistoryCount {
            // Get each new message and the delay
            let message = chatController.friend.chatHistory[messageIndex]
            var animation = UITableView.RowAnimation.automatic
            if message.direction == .incoming {
                animation = .left
            } else {
                animation = .right
            }
            
            totalDelay += message.delay
            
            // Calculate the addition / removal time for thinking and message
            let messageAdditionTime = totalDelay
            let thinkingAdditionTime = messageAdditionTime - message.delay + 0.5
            let thinkingRemovalTime = messageAdditionTime - 0.1
            
            let thinkingAdditionTimer = Timer(timeInterval: thinkingAdditionTime, repeats: false) { (_) in
                // Do not add the thinking cell if the message if the first OutgoingMessage
                guard message.delay != 0 else { return }
                // Update the thinking status and insert the row for thinking cell
                switch message.direction {
                case .incoming:
                    self.chatController.thinkingStatus = .incoming
                    self.chatTableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .left)
                case .outgoing:
                    self.chatController.thinkingStatus = .outgoing
                    self.chatTableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .right)
                }
                self.scrollChatTableViewToBottom()
            }
            
            let messageAdditionTimer = Timer(timeInterval: messageAdditionTime, repeats: false) { (_) in
                // Update the data model
                self.chatController.displayedChatHistory.append(message)
                // Update chatTableView and scroll to show addition
                self.chatTableView.insertRows(at: [IndexPath(row: messageIndex, section: 0)], with: animation)
                self.scrollChatTableViewToBottom()
            }
            
            let thinkingRemovalTimer = Timer(timeInterval: thinkingRemovalTime, repeats: false) { (_) in
                // Do not delete the thinking cell if the message if the first OutgoingMessage
                guard message.delay != 0 else { return }
                // Update the thinking status and delete the row for the thinking cell
                self.chatController.thinkingStatus = .completed
                self.chatTableView.deleteRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
            }
            
            // Save energy
            thinkingAdditionTimer.tolerance = 0.5
            messageAdditionTimer.tolerance = 0.5
            thinkingRemovalTimer.tolerance = 0.3
            
            // Manually add the timers for common RunLoop mode
            RunLoop.current.add(thinkingAdditionTimer, forMode: .common)
            RunLoop.current.add(messageAdditionTimer, forMode: .common)
            RunLoop.current.add(thinkingRemovalTimer, forMode: .common)
        }
        
        // If there is no new message, return a delay of 0.5 to allow time for the responseTableView to appear, otherwise return the correct totalDelay.
        return totalDelay == 0 ? 0.5 : totalDelay + 0.3
    }
    
    func endChatFrom(_ direction: MessageDirection, withDelay endChatTime: Double = 0.5) {
        var animation = UITableView.RowAnimation.automatic
        if direction == .incoming {
            animation = .left
        } else {
            animation = .right
        }
        
        let endChatTimer = Timer(timeInterval: endChatTime, repeats: false) { (_) in
            self.chatController.chatEndingStatus = .endedFrom(direction)
            self.chatController.friend.chatEndingStatus = .endedFrom(direction)
            self.chatController.friend.responseStatus = .completed
            self.chatTableView.insertRows(at: [IndexPath(row: 0, section: 2)], with: animation)
            self.scrollChatTableViewToBottom()
        }
        
        // Save energy
        endChatTimer.tolerance = 0.5
        
        // Manually add the timers for common RunLoop mode
        RunLoop.current.add(endChatTimer, forMode: .common)
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
        
        responseContainerView.isHidden = true
        responseContainerView.alpha = 0
    }
    
    func resumeChat() {
        // Set the chatDelegate for the Friend
        chatController.friend.chatDelegate = self
        
        // update the chat history starting from the appropriate place
        copyChatHistoryUntilChatMessage(count: chatController.friend.displayedMessageCount)
        
        // update the chatEndingStatus
        chatController.chatEndingStatus = chatController.friend.chatEndingStatus
        
        // Resume chat status using Friend's mostRecentResponse
        switch chatController.friend.responseStatus {
        // If the Friend recorded unresponded IncomingMessage with OutgoingMessages as the most recent response
        case .willPromptUserWith(let outgoingMessages):
            didAddIncomingMessageWith(responses: outgoingMessages, consequences: nil)
        // If the Friend had no record of most recent response, begin a chat.
        case .noRecord:
            chatController.friend.sendIncomingMessageWithId(0)
        // If the Friend has completed the chat, do nothing
        case .completed:
            break
        }
        
        // Scroll ChatTableView to bottom
        minimizeResponseContainerViewHeight()
        scrollChatTableViewToBottom()
    }
    
    func copyChatHistoryUntilChatMessage(count historyCount: Int) {
        // copy over the chat hisotry and remove ones not yet displayed
        chatController.displayedChatHistory = chatController.friend.chatHistory
        for _ in 0 ..< chatController.friend.chatHistory.count - chatController.friend.displayedMessageCount {
            chatController.displayedChatHistory.removeLast()
        }
    }
    
    func promptUserWith(responses: [OutgoingMessage]) {
        // Keep track of the array of OutgoingMessage and show the response container view
        responseTableViewController.responseChoices = responses
        showResponseContainerView()
    }
    
    func userRespondedWith(_ outgoingMessage: OutgoingMessage) {
        hideResponseContainerView()
        chatController.friend.respondedWith(outgoingMessage)
    }
    
    func showResponseContainerView() {
        responseContainerView.isHidden = false
        
        UIView.animate(withDuration: 0.5) {
            self.responseContainerView.alpha = 1
        }
        
        // Make table view scroll and inset correctly to avoid buttons blocking content
        maximizeResponseContainerViewHeight()
        
    }
    
    func hideResponseContainerView() {
        UIView.animate(withDuration: 0.5, animations: {
            self.responseContainerView.alpha = 0
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
            self.chatTableView.contentInset = contentInsets
        }) { (_) in
            self.responseContainerView.isHidden = true
            self.minimizeResponseContainerViewHeight()
        }
    }
    
    func maximizeResponseContainerViewHeight() {
        let responseTableViewFooterHeight = 30
        let responseCellHeight = 70
        let height = CGFloat(responseTableViewController.responseChoices.count * responseCellHeight + responseTableViewFooterHeight)
        
        // Configure the height anchor of the responseContainerView
        responseContainerView.frame = CGRect(x: 0, y: self.view.bounds.height - height, width: self.view.frame.width, height: height)
        hairlineView.frame = CGRect(x: 0, y: responseContainerView.frame.minY, width: responseContainerView.frame.width, height: 0.7)
        
        // Inset chatTableView
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: height, right: 0)
        chatTableView.contentInset = contentInsets
        
        scrollChatTableViewToBottom()
        chatController.didMaximizeResponseContainerViewHeight = true
    }
    
    func minimizeResponseContainerViewHeight() {
        // Configure the bounds of the responseContainerView
        responseContainerView.bounds = CGRect(x: 0, y: 0, width: 0, height: 0)
        
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        
        UIView.animate(withDuration: 0.1) {
            self.chatTableView.contentInset = contentInsets
        }
        chatController.didMaximizeResponseContainerViewHeight = false
        
        scrollChatTableViewToBottom()
    }
    
    func scrollChatTableViewToBottom() {
        
        switch chatController.chatEndingStatus {
        case .endedFrom(_):
            chatTableView.scrollToRow(at: IndexPath(row: 0, section: 2), at: .top, animated: true)
            return
        default:
            break
        }
        
        if chatController.thinkingStatus != .completed {
            chatTableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
        } else if chatController.displayedChatHistory.isEmpty == false {
            chatTableView.scrollToRow(at: IndexPath(row: chatController.displayedChatHistory.count - 1, section: 0), at: .top, animated: true)
        }
    }
    
    // MARK: - IB Actions
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        chatController.friend.displayedMessageCount = chatController.displayedChatHistory.count
        dismiss(animated: true, completion: nil)
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "EmbedResponseTableViewController" {
            let responseTableViewController = segue.destination as! ResponseTableViewController
            responseTableViewController.chatViewController = self
            self.responseTableViewController = responseTableViewController
        }
    }

}
