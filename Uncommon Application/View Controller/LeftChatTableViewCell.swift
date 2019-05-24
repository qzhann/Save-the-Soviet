//
//  LeftChatTableViewCell.swift
//  Uncommon Application
//
//  Created by qizihan  on 1/14/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class LeftChatTableViewCell: UITableViewCell {

    @IBOutlet weak var friendImageView: UIImageView!
    @IBOutlet weak var leftMessageLabel: UILabel!
    @IBOutlet weak var leftMessageBackgroundView: UIView!
    
    /**
     - Parameters:
        * message: Message instance, used to set message content of the ChatTableViewCell
        * friend: Friend instance, used to set the image of the ChatTableViewCell
     */
    func configureUsing(_ message: ChatMessage, with friend: Friend) {
        
        // Configure round corners of the background views and friend image
        friendImageView.layer.cornerRadius = friendImageView.bounds.height / 2
        leftMessageBackgroundView.layer.cornerRadius = 22
        friendImageView.clipsToBounds = true
        leftMessageBackgroundView.clipsToBounds = true
                
        // Hide all views at initialization
        friendImageView.isHidden = true
        leftMessageLabel.isHidden = true
        leftMessageBackgroundView.isHidden = true
        
        // Set friend image view to display friend's image
        friendImageView.image = friend.image
        
        leftMessageLabel.text = message.text
        leftMessageLabel.isHidden = false
        leftMessageBackgroundView.isHidden = false
        friendImageView.isHidden = false
        
        if message == ChatMessage.incomingThinkingMessage {
            friendImageView.isHidden = true
        }
    }

}
