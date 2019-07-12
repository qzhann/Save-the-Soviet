//
//  SupportLoyaltyProgressChangeIndicatorViewController.swift
//  Save the Soviet
//
//  Created by qizihan  on 7/10/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class SupportLoyaltyProgressChangeIndicatorViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func configureUsing(change: Int, style: SupportLoyaltyChangeIndicatorDisplayStyle) {
        switch style {
        case .support, .loyaltyShort:
            imageView.image = change >= 0 ? UIImage(named: "SupportLoyaltyIncrease")! : UIImage(named: "SupportLoyaltyDecrease")!
            label.text = "\(change)%"
            imageView.image = change >= 0 ? UIImage(named: "SupportLoyaltyIncrease")! : UIImage(named: "SupportLoyaltyDecrease")!
            label.text = "\(change)%"
        case .loyaltyLong:
            imageView.image = change >= 0 ? UIImage(named: "SupportLoyaltyIncrease")! : UIImage(named: "SupportLoyaltyDecrease")!
            label.text = change >= 0 ? "Loyalty +\(change)%" : "Loyalty \(change)%"
        }
        
    }

}

enum SupportLoyaltyChangeIndicatorDisplayStyle {
    case support, loyaltyShort, loyaltyLong
}
