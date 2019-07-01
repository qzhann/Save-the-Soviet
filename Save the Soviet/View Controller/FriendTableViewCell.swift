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
    unowned var friend: Friend!
    
    @IBOutlet weak var friendImageView: UIImageView!
    @IBOutlet weak var friendImageBackgroundView: UIView!
    @IBOutlet weak var friendImageViewForegroundButton: UIButton!
    
    @IBOutlet weak var friendNameLabel: UILabel!
    @IBOutlet weak var newMessageIndicatorImageView: UIImageView!
    @IBOutlet weak var newMessageLabel: UILabel!
    @IBOutlet weak var newMessageIndicatorBadge: UIView!
    
    
    /**
     - Parameter friend: Friend instance used to set the image, the name, and the new message indications
     */
    func updateCell(with friend: Friend) {
        self.friend = friend
        
        // Set image and name label
        friendImageView.image = friend.image
        friendNameLabel.text = friend.shortName
        
        // Set new message indications. Empty unreadMessages means no new message.
        if friend.hasNewMessage {
            newMessageIndicatorImageView.image = UIImage(named: "NewMessage")
            newMessageLabel.text = "New message"
            newMessageIndicatorBadge.isHidden = false
        } else {
            newMessageIndicatorImageView.image = UIImage(named: "NoNewMessage")
            newMessageLabel.text = "Tap to chat"
            newMessageIndicatorBadge.isHidden = true
        }
        
        // Set the round corners
        friendImageView.layer.cornerRadius = friendImageView.frame.height / 2
        friendImageView.clipsToBounds = true
        friendImageViewForegroundButton.layer.cornerRadius = friendImageViewForegroundButton.frame.height / 2
        friendImageViewForegroundButton.clipsToBounds = true
        newMessageIndicatorBadge.layer.cornerRadius = newMessageIndicatorBadge.bounds.height / 2
        newMessageIndicatorBadge.clipsToBounds = true
        
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
        imageViewTapDelegate.imageTapped(for: friend)
    }
    
    
}
