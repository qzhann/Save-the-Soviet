//
//  ChatTableViewCell.swift
//  Uncommon Application
//
//  Created by qizihan  on 1/14/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class ChatTableViewCell: UITableViewCell {

    @IBOutlet weak var friendImageView: UIImageView!
    @IBOutlet weak var leftMessageLabel: UILabel!
    @IBOutlet weak var rightMessageLabel: UILabel!
    @IBOutlet weak var leftMessageBackgroundView: UIView!
    @IBOutlet weak var rightMessageBackgroundView: UIView!
    
    /**
     - Parameters:
        * message: Message instance, used to set message content of the ChatTableViewCell
        * friend: Friend instance, used to set the image of the ChatTableViewCell
     */
    func update(message: Message, with friend: Friend) {
        
        // Configure round corners of the background views and friend image
        friendImageView.layer.cornerRadius = friendImageView.bounds.height / 2
        leftMessageBackgroundView.layer.cornerRadius = 22
        rightMessageBackgroundView.layer.cornerRadius = 22
        friendImageView.clipsToBounds = true
        leftMessageBackgroundView.clipsToBounds = true
        rightMessageBackgroundView.clipsToBounds = true
        
                
        // Hide all views at initialization
        friendImageView.isHidden = true
        leftMessageLabel.isHidden = true
        rightMessageLabel.isHidden = true
        leftMessageBackgroundView.isHidden = true
        rightMessageBackgroundView.isHidden = true
        
        // Set friend image view to display friend's image
        friendImageView.image = friend.image
        
        // Check message's direction
        if message.direction == .from {
        // If incoming message, set left message label and show label with friend image
            leftMessageLabel.text = message.content
            leftMessageLabel.isHidden = false
            leftMessageBackgroundView.isHidden = false
            friendImageView.isHidden = false
            
            // If message is "...", hide the image view
            if message.id == -2 {
                friendImageView.isHidden = true
            }
            
        } else if message.direction == .to {
        // If outgoing message, set right message label
            rightMessageLabel.text = message.content
            rightMessageLabel.isHidden = false
            rightMessageBackgroundView.isHidden = false
        }
    }

}
