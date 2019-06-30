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
    var indexPath: IndexPath!
    unowned var responseDelegate: ResponseDelegate!
    
    func configureUsing(_ message: OutgoingMessage, at indexPath: IndexPath) {
        // Configure the round corners
        responseButton.layer.cornerRadius = 10
        responseButton.clipsToBounds = true
        
        // Set the text and indexPath
        responseButton.setTitle(message.description, for: .normal)
        self.indexPath = indexPath
    }
    
    @IBAction func responseButtonTapped(_ sender: UIButton) {
        responseDelegate.respondedAt(indexPath: indexPath)
    }
    

}
