//
//  LoyaltyProgressChangeIndicatorViewController.swift
//  Save the Soviet
//
//  Created by qizihan  on 7/10/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class LoyaltyProgressChangeIndicatorViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func configureUsing(change: Int) {
        imageView.image = change >= 0 ? UIImage(named: "LoyaltyIncrease")! : UIImage(named: "LoyaltyDecrease")!
        label.text = change >= 0 ? "Loyalty +\(change)" : "Loyalty \(change)"
    }

}
