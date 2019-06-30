//
//  UserPowerTableViewCell.swift
//  Uncommon Application
//
//  Created by qizihan  on 4/5/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class PowerTableViewCell: UITableViewCell {

    @IBOutlet weak var powerImageView: UIImageView!
    @IBOutlet weak var powerNameLabel: UILabel!
    @IBOutlet weak var powerDescriptionLabel: UILabel!
    
    @IBOutlet weak var upgradeStackView: UIStackView!
    @IBOutlet weak var coinImageView: UIImageView!
    @IBOutlet weak var coinsNeededLabel: UILabel!
    
    func updateWith(power: Power) {
        powerImageView.image = power.image
        powerNameLabel.text = power.name
        powerDescriptionLabel.text = power.description
        
        // Reset the layout of coins needed label
        coinsNeededLabel.transform = CGAffineTransform.identity
        
        if power.hasUpgrade == false {
            // If no more available upgrades for the power, it is the max
            coinImageView.isHidden = true
            coinsNeededLabel.text = "MAX"
            
            // Adjust the layout a bit
            accessoryType = .none
            coinsNeededLabel.transform = CGAffineTransform(translationX: 5, y: 0)
        } else {
            // If upgrades are available, show how much coins is needed for an upgrade
            coinsNeededLabel.text = "\(power.coinsNeeded)"
            
        }
    }
    
}
