//
//  EndChatTableViewCell.swift
//  Uncommon Application
//
//  Created by qizihan  on 6/16/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class EndChatTableViewCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!
    
    func configureUsing(text: String) {
        label.text = text
    }

}
