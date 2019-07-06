//
//  ChatViewController.swift
//  Uncommon Application
//
//  Created by qizihan  on 1/31/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

/**
 Display chat history with a Friend.
 */
protocol ChatDisplayDelegate: AnyObject {
    /// Called when Friend adds incoming ChatMessage to chatHistory.
    func didAddIncomingMessageWith(responses: [OutgoingMessage]?, consequences: [Consequence]?)
    /// Called when Friend adds outgoing ChatMessage to chatHistory.
    func didAddOutgoingMessageWith(responseId: Int?, consequences: [Consequence]?)
}

struct ChatController {
    /// The data source used to display the chat history.
    var displayedChatHistory: [ChatMessage] = []
    /// This tracks the thinking status of the User and the Friend, used to insert and remove the thinking cells in ChatTableView.
    var thinkingState: ThinkingState = .completed
    enum ThinkingState {
        case incoming
        case outgoing
        case completed
    }
    /// This tracks whether the chat has ended, also serving the data source for the end chat cell section.
    var chatEndingState: ChatEndingState = .notEnded
    
    var didMaximizeResponseContainerViewHeight = false {
        didSet {
            didRecordcontentOffset = false
        }
    }
    var verticalContentOffset: CGFloat = -20 {
        didSet {
            if didMaximizeResponseContainerViewHeight {
                if didRecordcontentOffset {
                    self.verticalContentOffset = oldValue
                } else {
                    didRecordcontentOffset = true
                }
            }
        }
    }
    private var didRecordcontentOffset = false
}

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ChatDisplayDelegate, UIViewControllerTransitioningDelegate {
    
    
    // MARK: - IB Outlets
    
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var backButtonBackgroundView: UIView!
    @IBOutlet weak var responseContainerView: UIView!
    @IBOutlet weak var levelProgressChangeIndicatorView: UIView!
    
    // MARK: Instance properties
    unowned var user = User.currentUser
    unowned var friend: Friend!
    var chatController = ChatController()
    /// The TableViewController responsible for handling the display and selection of response choices
    unowned var responseTableViewController: ResponseTableViewController!
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    var newFriend: Friend?
    var consequenceController: ConsequenceController!
    unowned var levelProgressChangeIndicatorViewController: LevelProgressChangeIndicatorViewController!
    unowned var delayedConsequenceHandlingDelegate: DelayConsequenceHandlingDelegate!
    
    let hairlineView = UIView()
    
    // MARK: - Consequence visualization delegate
    
    func visualizeConsequence(_ consequence: Consequence) {
        switch consequence {
        case .changeLevelProgressBy(let change):
            levelProgressChangeIndicatorViewController.configureUsing(change: change, style: .long)
            animateLevelProgressChangeIndicatorFor(change: change)
        default:
            break
        }
    }
    
    
    // MARK: - View Controller Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        consequenceController = ConsequenceController(for: User.currentUser, chatViewController: self)
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
            var alpha = (chatController.verticalContentOffset - scrollView.contentOffset.y) / 4
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
            if chatController.thinkingState == .completed {
                return 0
            } else {
                return 1
            }
        case 2: // End Chat Cells
            switch chatController.chatEndingState {
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
            if chatController.thinkingState == .incoming {
                let cell = tableView.dequeueReusableCell(withIdentifier: "LeftThinkingCell", for: indexPath) as! LeftThinkingChatTableViewCell
                cell.selectionStyle = .none
                cell.thinkingImage.startAnimating()
                return cell
            } else if chatController.thinkingState == .outgoing {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RightThinkingCell", for: indexPath) as! RightThinkingChatTableViewCell
                cell.selectionStyle = .none
                cell.thinkingImage.startAnimating()
                return cell
            } else {
                return UITableViewCell()
            }
        case 2: // End Chat Cells
            switch chatController.chatEndingState {
            case .endedFrom(let direction):
                let cell = tableView.dequeueReusableCell(withIdentifier: "EndChatCell", for: indexPath) as! EndChatTableViewCell
                cell.selectionStyle = .none
                switch direction {
                case .incoming:
                    cell.configureUsing(text: "\(friend.shortName) has left chat.")
                case .outgoing:
                    cell.configureUsing(text: "You have left chat.")
                }
                
                return cell
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
        if section == 0 {
            return UITableViewHeaderFooterView()
        } else {
            return nil
        }
    }
    
    // Configures the header that gives extra space above the first message
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 70
        } else {
            return CGFloat.leastNormalMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 1:
            return 44
        case 2:
            return 44
        default:
            return UITableView.automaticDimension
        }
    }
    
    
    // MARK: - Chat Display Delegate Methods
    
    func didAddIncomingMessageWith(responses: [OutgoingMessage]?, consequences: [Consequence]?) {
        
        // Update ChatTableView using the added messages
        let totalDelay = updateChatWithDelay()
        
        // Handle responses and consequences
        let promptUserTimer = Timer.scheduledTimer(withTimeInterval: totalDelay, repeats: false) { (_) in
            // Note that we don't want to automatically end chat. This is handled as a consequence
            
            if let consequences = consequences {
                self.handleConsequences(consequences)
            }
            
            if let responses = responses {
                self.promptUserWith(responses: responses)
            }
        }
        
        // Save energy
        promptUserTimer.tolerance = 0.5
    }
    
    func didAddOutgoingMessageWith(responseId: Int?, consequences: [Consequence]?) {
        
        // Update ChatTableView using the added messages
        let totalDelay = updateChatWithDelay()
        
        // We handle the consequences for outgoing messages first
        if let consequences = consequences {
            self.handleConsequences(consequences)
        }
        
        // Handle responses and consequences
        let addResponseTimer = Timer.scheduledTimer(withTimeInterval: totalDelay, repeats: false) { (_) in
            // Note that we don't want to automatically end chat. This is handled as a consequence
            
            if let responseId = responseId {
                self.friend.sendIncomingMessageNumbered(responseId)
            }
            
        }
        // Save energy
        addResponseTimer.tolerance = 0.5
    }
    
    // MARK: Chat helper methods

    func updateChatWithDelay() -> Double {
        let oldHistoryCount = chatController.displayedChatHistory.count
        let newHistoryCount = friend.chatHistory.count
        var totalDelay: Double = 0
        
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
            let thinkingAdditionTime = messageAdditionTime - message.delay + 0.6
            
            let thinkingAdditionTimer = Timer(timeInterval: thinkingAdditionTime, repeats: false) { (_) in
                // Do not add the thinking cell if the message if the first OutgoingMessage
                guard message.delay != 0 else { return }
                
                // Update the thinking status and insert the row for thinking cell
                switch message.direction {
                case .incoming:
                    self.chatController.thinkingState = .incoming
                    self.chatTableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .top)
                case .outgoing:
                    self.chatController.thinkingState = .outgoing
                    self.chatTableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .top)
                }
                self.scrollChatTableViewToBottom()
            }
            
            let messageAdditionTimer = Timer(timeInterval: messageAdditionTime, repeats: false) { (_) in
                
                // If the thinking cell was not added
                if self.chatController.thinkingState == .completed {
                    self.chatController.displayedChatHistory.append(message)
                    self.chatTableView.insertRows(at: [IndexPath(row: messageIndex, section: 0)], with: animation)
                    self.scrollChatTableViewToBottom()
                } else {
                    self.chatTableView.performBatchUpdates({
                        self.chatController.thinkingState = .completed
                        self.chatTableView.deleteRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
                        self.chatController.displayedChatHistory.append(message)
                        self.chatTableView.insertRows(at: [IndexPath(row: messageIndex, section: 0)], with: animation)
                    }) { (_) in
                        self.view.layoutIfNeeded()
                        self.chatTableView.layoutIfNeeded()
                        self.scrollChatTableViewToBottom()
                    }
                }
            }
            
            // Save energy
            thinkingAdditionTimer.tolerance = 0.5
            messageAdditionTimer.tolerance = 0.5
            
            // Manually add the timers for common RunLoop mode
            RunLoop.current.add(thinkingAdditionTimer, forMode: .common)
            RunLoop.current.add(messageAdditionTimer, forMode: .common)
        }
        
        // If there is no new message, return a delay of 0.5 to allow time for the responseTableView to appear, otherwise return the correct totalDelay.
        return totalDelay == 0 ? 0.5 : totalDelay
    }
    
    func endChatFrom(_ direction: MessageDirection, withDelay endChatTime: Double = 0.3) {
        
        let endChatTimer = Timer(timeInterval: endChatTime, repeats: false) { (_) in
            self.chatController.chatEndingState = .endedFrom(direction)
            self.friend.chatEndingState = .endedFrom(direction)
            self.friend.responseState = .completed
            self.chatTableView.insertRows(at: [IndexPath(row: 0, section: 2)], with: .top)
            self.scrollChatTableViewToBottom()
        }
        
        // Save energy
        endChatTimer.tolerance = 0.5
        
        // Manually add the timers for common RunLoop mode
        RunLoop.current.add(endChatTimer, forMode: .common)
    }
    
    func handleConsequences(_ consequences: [Consequence]) {
        for consequence in consequences {
            if consequenceController.canHandle(consequence) {
                consequenceController.handle(consequence)
                visualizeConsequence(consequence)
            }
        }
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
        
        // Hide progress change indicators
        levelProgressChangeIndicatorView.alpha = 0
    }
    
    func resumeChat() {
        // Set the chatDelegate for the Friend
        friend.chatDelegate = self
        
        // update the chat history starting from the appropriate place
        copyChatHistoryUntilChatMessage(count: friend.displayedMessageCount)
        
        // update the chatEndingStatus
        chatController.chatEndingState = friend.chatEndingState
        
        // Resume chat status using Friend's mostRecentResponse
        switch friend.responseState {
        // If the Friend recorded unresponded IncomingMessage with OutgoingMessages as the most recent response
        case .willPromptUserWith(let outgoingMessages):
            didAddIncomingMessageWith(responses: outgoingMessages, consequences: nil)
        // If the Friend will begin chat with an incoming message, send it.
        case .willBeginChatWithIncomingMessageId(let id):
            friend.sendIncomingMessageNumbered(id)
        // If the Friend will begin chat by prompting user with choices, prompt it.
        case .willBeginChatWith(let choices):
            didAddIncomingMessageWith(responses: choices, consequences: nil)
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
        chatController.displayedChatHistory = friend.chatHistory
        guard friend.chatHistory.count - friend.displayedMessageCount > 0 else { return }
        for _ in 0 ..< friend.chatHistory.count - friend.displayedMessageCount {
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
        friend.respondedWith(outgoingMessage)
    }
    
    func showResponseContainerView() {
        responseContainerView.isHidden = false
        
        UIView.animate(withDuration: 0.5) {
            self.responseContainerView.alpha = 1
            self.hairlineView.isHidden = false
        }
        
        // Make table view scroll and inset correctly to avoid buttons blocking content
        maximizeResponseContainerViewHeight()
        
    }
    
    func hideResponseContainerView() {
        UIView.animate(withDuration: 0.5, animations: {
            self.responseContainerView.alpha = 0
            self.hairlineView.isHidden = true
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
            self.chatTableView.contentInset = contentInsets
        }) { (_) in
            self.responseContainerView.isHidden = true
            self.minimizeResponseContainerViewHeight()
        }
    }
    
    func maximizeResponseContainerViewHeight() {
        let responseTableViewFooterHeight = 40
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
        
    }
    
    func scrollChatTableViewToBottom() {
        
        switch chatController.chatEndingState {
        case .endedFrom(_):
            chatTableView.scrollToRow(at: IndexPath(row: 0, section: 2), at: .top, animated: true)
            return
        default:
            break
        }
        
        if chatController.thinkingState != .completed {
            chatTableView.scrollToRow(at: IndexPath(row: 0, section: 1), at: .top, animated: true)
        } else if chatController.displayedChatHistory.isEmpty == false {
            chatTableView.scrollToRow(at: IndexPath(row: chatController.displayedChatHistory.count - 1, section: 0), at: .top, animated: true)
        }
    }
    
    private func animateLevelProgressChangeIndicatorFor(change: Int) {
        var animation: CGAffineTransform!
        if change > 0 {
            // Make it rise from the bar
            levelProgressChangeIndicatorView.transform = CGAffineTransform(translationX: 0, y: 8)
            animation = CGAffineTransform(translationX: 0, y: -8)
        } else if change < 0 {
            animation = CGAffineTransform(translationX: 0, y: 8)
        } else {
            animation = CGAffineTransform(translationX: 0, y: 0)
        }
        
        
        let appearAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .linear) {
            self.levelProgressChangeIndicatorView.alpha = 1
        }
        let translateAnimator = UIViewPropertyAnimator(duration: 1, curve: .easeOut) {
            self.levelProgressChangeIndicatorView.transform = animation
        }
        let disappearAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .linear) {
            self.levelProgressChangeIndicatorView.alpha = 0
        }
        translateAnimator.addCompletion { (_) in
            disappearAnimator.startAnimation()
        }
        
        disappearAnimator.addCompletion { (_) in
            self.levelProgressChangeIndicatorView.transform = .identity
        }
        
        appearAnimator.startAnimation()
        translateAnimator.startAnimation()
    }
    
    
    // MARK: - IB Actions
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        friend.willDismissChatDelegateWithChatHistoryCount(chatController.displayedChatHistory.count)
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
        } else if segue.identifier == "ShowQuiz" {
            let quizViewController = segue.destination as! QuizViewController
            quizViewController.transitioningDelegate = self
        } else if segue.identifier == "ShowNewFriend" {
            let newFriendViewController = segue.destination as! NewFriendViewController
            newFriendViewController.friend = self.newFriend
        } else if segue.identifier == "EmbedLevelProgressChangeIndicator" {
            let levelProgressChangeIndicatorViewController = segue.destination as! LevelProgressChangeIndicatorViewController
            self.levelProgressChangeIndicatorViewController = levelProgressChangeIndicatorViewController
        }
    }
    
    // MARK: - View controller transitioning delegate
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is QuizViewController {
            return PushPresentationAnimationController()
        }
        
        return nil
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is QuizViewController {
            return PushDismissalAnimationController()
        }
        
        return nil
    }
    
    // MARK: - Unwind Segue
    
    // FIXME: This needs better implementation.
    /// present the user with some choices after a quiz is done
    @IBAction func unwindToChatViewControllerAfterQuiz(unwindSegue: UIStoryboardSegue) {
        didAddIncomingMessageWith(responses: [OutgoingMessage(text: "How did I do?", responseMessageId: 5)], consequences: nil)
        
    }
    
    // After a new friend is made, to avoid crashing, we tell the friend to start sending the message the new friend has stored.
    @IBAction func unwindToChatViewControllerAfterNewFriend(unwindSegue: UIStoryboardSegue) {
        let newFriendViewController = unwindSegue.source as! NewFriendViewController
        let newFriend = newFriendViewController.friend
        friend.sendIncomingMessage(newFriend!.introductionMessageFromOthers)
    }
    
}
