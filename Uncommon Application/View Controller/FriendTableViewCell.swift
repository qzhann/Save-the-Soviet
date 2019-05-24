//
//  FriendTableViewCell.swift
//  Uncommon Application
//
//  Created by qizihan  on 3/21/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class FriendTableViewCell: UITableViewCell {
    
    weak var imageViewTapDelegate: FriendImageViewTapDelegate!
    var indexPath: IndexPath!
    
    @IBOutlet weak var friendImageView: UIImageView!
    @IBOutlet weak var friendImageBackgroundView: UIView!
    @IBOutlet weak var friendImageViewForegroundButton: UIButton!
    
    @IBOutlet weak var friendNameLabel: UILabel!
    @IBOutlet weak var newMessageIndicatorImageView: UIImageView!
    @IBOutlet weak var newMessageLabel: UILabel!
    
    
    /**
     - Parameter friend: Friend instance used to set the image, the name, and the new message indications
     */
    func updateCell(with friend: Friend) {
        
        // Set image and name label
        friendImageView.image = friend.image
        friendNameLabel.text = friend.name
        
        // Set new message indications. Empty unreadMessages means no new message.
        if friend.chatHistory.isEmpty {
            newMessageIndicatorImageView.image = UIImage(named: "NoNewMessage")
            newMessageLabel.text = "Tap to chat"
        } else {
            newMessageIndicatorImageView.image = UIImage(named: "NewMessage")
            newMessageLabel.text = "New message"
        }
        
        // Set the round corner for the friendImageView
        friendImageView.layer.cornerRadius = friendImageView.frame.height / 2
        friendImageView.clipsToBounds = true
        
        // Set the round corner for friendImageViewForegroundButton
        friendImageViewForegroundButton.layer.cornerRadius = friendImageViewForegroundButton.frame.height / 2
        friendImageViewForegroundButton.clipsToBounds = true
        
        // Set the shadow for friend image background view
        friendImageBackgroundView.layer.masksToBounds = false;
        friendImageBackgroundView.layer.shadowColor = UIColor.black.cgColor
        friendImageBackgroundView.layer.shadowOpacity = 0.4
        friendImageBackgroundView.layer.shadowRadius = 2
        friendImageBackgroundView.layer.shadowOffset = .zero
        friendImageBackgroundView.layer.shadowPath = UIBezierPath(roundedRect: friendImageView.bounds, cornerRadius: friendImageView.layer.cornerRadius).cgPath
        friendImageBackgroundView.backgroundColor = UIColor.clear
    }
    
    @IBAction func friendImageViewForegroundButtonTapped(_ sender: UIButton) {
        imageViewTapDelegate.imageTapped(at: indexPath)
    }
    
    
}
