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
    var displayedChatHistory: [ChatMessage] = []
    var mostRecentOutgoingResponses: [OutgoingMessage]?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    // MARK: - Table View Data Source Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedChatHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = displayedChatHistory[indexPath.row]
        
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
        
    }
    
    // MARK: - Table View Delegate Methods
    
    // Configures the header that gives extra space above the first message
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableViewHeader
    }
    
    // Configures the header that gives extra space above the first message
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
    
    // MARK: - Chat Display Delegate Methods
    func didAddIncomingMessageWith(responses: [OutgoingMessage]?, consequences: [ChatConsequence]?) {
        // Update ChatTableView using the added messages
        let totalDelay = updateChatWithDelay(using: .left)
        
        // Handle responses and consequences
        let promptUserTimer = Timer.scheduledTimer(withTimeInterval: totalDelay, repeats: false) { (_) in
            if let responses = responses {
                self.promptUserWith(responses: responses)
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
        let totalDelay = updateChatWithDelay(using: .right)
        
        // Handle responses and consequences
        let addResponseTimer = Timer.scheduledTimer(withTimeInterval: totalDelay, repeats: false) { (_) in
            if let responseId = responseId {
                self.friend.sendIncomingMessageWithId(responseId)
            } else {
                // FIXME: prepare to end chat
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
    
    /*
    func endChat() {
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        UIView.animate(withDuration: 0.5) {
            self.chatTableView.contentInset = contentInsets
        }
        
        // Enable the back button when the chat has ended
        backButton.isEnabled = true
        
    }
    */
    
    // MARK: Chat Display Delegate Helper Methods
    func updateChatWithDelay(using animation: UITableView.RowAnimation) -> Double {
        let oldHistoryCount = displayedChatHistory.count
        let newHistoryCount = friend.chatHistory.count
        var totalDelay: Double = 0
        
        minimizeResponseTableViewHeight()
        
        for messageIndex in oldHistoryCount ..< newHistoryCount {
            // Get each new message and the delay
            let message = friend.chatHistory[messageIndex]
            let delay = message.delay
            totalDelay += delay
            
            // Add each new message with correct delay
            let messageAdditionTimer = Timer.scheduledTimer(withTimeInterval: totalDelay, repeats: false) { (_) in
                // Update the data model
                self.displayedChatHistory.append(message)
                // Update chatTableView and scroll to show addition
                self.chatTableView.insertRows(at: [IndexPath(row: messageIndex, section: 0)], with: animation)
                self.chatTableView.scrollToRow(at: IndexPath(row: self.displayedChatHistory.count - 1, section: 0), at: .top, animated: true)
            }
            
            // Save energy
            messageAdditionTimer.tolerance = 0.5
        }
        
        // If there is no new message, return a delay of 0.5 to allow time for the responseTableView to appear, otherwise return the correct totalDelay.
        return totalDelay == 0 ? 0.5 : totalDelay + 0.3
    }
    

    // MARK: - View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareUI()
        resumeChat()
    }
    
    // Scroll ChatTableView to bottom every time the view appears
    override func viewDidAppear(_ animated: Bool) {
        scrollChatTableViewToBottom()
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
        backButtonBackgroundView.layer.shadowRadius = 2
        backButtonBackgroundView.layer.shadowPath = UIBezierPath(roundedRect: backButtonBackgroundView.bounds, cornerRadius: backButtonBackgroundView.layer.cornerRadius).cgPath
        
        // Round corner for response buttons, and hide buttons
        let buttons = [responseButton1, responseButton2, responseButton3]
        for button in buttons {
            button?.layer.cornerRadius = 10
            button?.isEnabled = false
            button?.alpha = 0
        }
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
        
        // FIXME: need to update this
        
        // update the chat history using Friend's chatHistory
        displayedChatHistory = friend.chatHistory
        
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
        if displayedChatHistory.isEmpty == false {
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
