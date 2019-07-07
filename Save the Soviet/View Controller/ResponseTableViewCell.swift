//
//  ResponseTableViewCell.swift
//  Uncommon Application
//
//  Created by qizihan  on 6/4/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class ResponseTableViewCell: UITableViewCell {

    @IBOutlet weak var responseButton: UIButton!
    @IBOutlet weak var levelRestrictionLabel: UILabel!
    
    var indexPath: IndexPath!
    unowned var responseDelegate: ResponseDelegate!
    
    func configureUsing(_ message: OutgoingMessage, at indexPath: IndexPath, for user: User) {
        // Configure the round corners
        responseButton.layer.cornerRadius = 10
        responseButton.clipsToBounds = true
        
        // Set the text and indexPath
        responseButton.setTitle(message.description, for: .normal)
        self.indexPath = indexPath
        
        // Hide level restriction label and enable response button by default
        levelRestrictionLabel.alpha = 0
        responseButton.isEnabled = true
        responseButton.backgroundColor = UIColor(red: 130 / 255, green: 37 / 255, blue: 41 / 255, alpha: 1)
        
        // If the message has level restriction and the user is lower than that restriction, configure the level restriction label and the alpha
        if let levelRestriction = message.levelRestriction, user.level.levelNumber < levelRestriction {
            levelRestrictionLabel.text = "Lv.\(levelRestriction)"
            levelRestrictionLabel.alpha = 1
            responseButton.isEnabled = false
            responseButton.backgroundColor = UIColor(red: 95 / 255, green: 95 / 255, blue: 95 / 255, alpha: 1)
        }
    }
    
    @IBAction func responseButtonTapped(_ sender: UIButton) {
        responseDelegate.respondedAt(indexPath: indexPath)
    }
    

}
