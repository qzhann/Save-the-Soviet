//
//  RightChatTableViewCell.swift
//  Uncommon Application
//
//  Created by qizihan  on 5/19/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class RightChatTableViewCell: UITableViewCell {

    @IBOutlet weak var rightMessageBackgroundView: UIView!
    @IBOutlet weak var rightMessageLabel: UILabel!
    
    /**
     - Parameters:
     * message: Message instance, used to set message content of the ChatTableViewCell
     * friend: Friend instance, used to set the image of the ChatTableViewCell
     */
    func configureUsing(_ message: ChatMessage, with friend: Friend) {
        
        // Configure round corners of the background views
        rightMessageBackgroundView.layer.cornerRadius = 22
        rightMessageBackgroundView.clipsToBounds = true
        
        // Hide all views at initialization
        rightMessageLabel.isHidden = true
        rightMessageBackgroundView.isHidden = true
        
        rightMessageLabel.text = message.text
        rightMessageLabel.isHidden = false
        rightMessageBackgroundView.isHidden = false
    }

}
