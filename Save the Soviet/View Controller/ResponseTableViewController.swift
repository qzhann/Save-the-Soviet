//
//  ResponseTableViewController.swift
//  Uncommon Application
//
//  Created by qizihan  on 6/4/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

protocol ResponseDelegate: AnyObject {
    var responseChoices: [OutgoingMessage] { get set }
    func respondedAt(indexPath: IndexPath)
}

class ResponseTableViewController: UITableViewController, ResponseDelegate {
    
    unowned var chatViewController: ChatViewController!
    var footerHeight: CGFloat!
    unowned var user = User.currentUser

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollTableViewToBottom()
    }
    
    var responseChoices: [OutgoingMessage] = [] {
        didSet {
            tableView.reloadData()
            scrollTableViewToBottom()
        }
    }
    
    func respondedAt(indexPath: IndexPath) {
        chatViewController.userRespondedWith(responseChoices[indexPath.row])
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return responseChoices.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResponseCell", for: indexPath) as! ResponseTableViewCell
        let choice = responseChoices[indexPath.row]
        cell.configureUsing(choice, at: indexPath, for: user)
        cell.responseDelegate = self
        cell.selectionStyle = .none

        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UITableViewHeaderFooterView()
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let footerView = view as? UITableViewHeaderFooterView {
            footerView.contentView.backgroundColor = .white
        }
    }
    
    
    
    // MARK: - Instance methods
    
    func scrollTableViewToBottom() {
        guard responseChoices.isEmpty == false else { return }
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
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
