//
//  ChatViewController.swift
//  Uncommon Application
//
//  Created by qizihan  on 1/31/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ChatResponsesDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeader: UIView!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var responseButton1: UIButton!
    @IBOutlet weak var responseButton2: UIButton!
    @IBOutlet weak var responseButton3: UIButton!
    
    var friend: Friend!
    
    // MARK: - Table View Data Source Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friend.appearedMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatTableViewCell
        let message = friend.appearedMessages[indexPath.row]
        cell.update(message: message, with: friend)
        cell.selectionStyle = .none
        
        return cell
    }
    
    // MARK: - Table View Delegate Methods
    
    // Header that gives extra space above the first message
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableViewHeader
    }
    
    // Header that gives extra space above the first message
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
    
    // MARK: - Chat Responses Delegate Methods
    
    func promptUserWith(responses: [Response]) {
        
        let buttons = [responseButton1, responseButton2, responseButton3]
        
        for index in buttons.indices {
            buttons[index]?.setTitle(responses[index].title, for: .normal)
        }
            
        showResponseButtons()
    }
    
    func updateTableView(at row: Int, remove: Bool, with animation: UITableView.RowAnimation) {
        if remove == true {
            tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: animation)
        } else {
            tableView.insertRows(at: [IndexPath(row: row, section: 0)], with: animation)
        }
    }
    
    
    func endChat() {
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        UIView.animate(withDuration: 0.5) {
            self.tableView.contentInset = contentInsets
        }
        
        // Enable the back button when the chat has ended
        backButton.isEnabled = true
        
    }
    

    // MARK: - View Controller Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        friend.delegate = self
        prepareUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Trigger the start of a chat using willText on the first message
        //friend.willText(message: 0)
    }
    
    // MARK: - Instance Methods
    
    func prepareUI() {
        
        // Hide scroll indicator for table view
        tableView.showsVerticalScrollIndicator = false
        
        // Setting round corner, opacity, and enabling back button
        backButton.layer.cornerRadius = backButton.frame.height / 2
        backButton.clipsToBounds = true
        backButton.isEnabled = true
        
        // Round corner for response buttons, and hide buttons
        let buttons = [responseButton1, responseButton2, responseButton3]
        for button in buttons {
            button?.layer.cornerRadius = 10
            button?.isEnabled = false
            button?.alpha = 0
        }
        
    }
    
    func hideResponseButtons() {
        
        // Disable the back button when the friend is typing
        backButton.isEnabled = false
        
        let buttons = [responseButton1, responseButton2, responseButton3]
        
        UIView.animate(withDuration: 0.5) {
            for button in buttons {
                button?.isEnabled = false
                button?.alpha = 0
            }
        }
    }
    
    func showResponseButtons() {
        
        // Enable the back button when the friend finished typing
        backButton.isEnabled = true
        
        let buttons = [responseButton1, responseButton2, responseButton3]
        
        UIView.animate(withDuration: 0.5) {
            for button in buttons {
                button?.isEnabled = true
                button?.alpha = 1
            }
        }
        
        // Make table view scroll and inset correctly to avoid buttons blocking content
        let buttonsStackHeight = responseButton1.frame.height * 3 + 36
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: buttonsStackHeight, right: 0)
        
        tableView.contentInset = contentInsets
        
        tableView.scrollToRow(at: IndexPath(row: friend.appearedMessages.count - 1, section: 0), at: .top, animated: true)

    }
    
    // MARK: - IBAction
    
    @IBAction func responseButtonTapped(_ sender: UIButton) {
        hideResponseButtons()
        
        switch sender {
        case responseButton1:
            friend.respondedWith(0)
        case responseButton2:
            friend.respondedWith(1)
        default:
            friend.respondedWith(2)
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
