//
//  CoinChangeIndicatorViewController.swift
//  Save the Soviet
//
//  Created by qizihan  on 7/12/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class CoinChangeIndicatorViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func configureUsing(change: Int, style: CoinChangeIndicatorDisplayStyle) {
        switch style {
        case .short:
            imageView.image = change >= 0 ? UIImage(named: "CoinIncrease")! : UIImage(named: "CoinDecrease")!
            label.text = "\(change)"
            label.textColor = UIColor(red: 223 / 255, green: 156 / 255, blue: 0 / 255, alpha: 1)
        case .long:
            imageView.image = change >= 0 ? UIImage(named: "CoinIncrease")! : UIImage(named: "CoinDecrease")!
            label.text = change >= 0 ? "Coins +\(change)" : "Coins \(change)"
            label.textColor = UIColor(red: 223 / 255, green: 156 / 255, blue: 0 / 255, alpha: 1)
        case .longLight:
            imageView.image = change >= 0 ? UIImage(named: "CoinIncreaseLight")! : UIImage(named: "CoinDecreaseLight")!
            label.text = change >= 0 ? "Coins +\(change)" : "Coins \(change)"
            label.textColor = UIColor(red: 254 / 255, green: 242 / 255, blue: 5 / 255, alpha: 1)
        }
    }
}

enum CoinChangeIndicatorDisplayStyle {
    case short, long, longLight
}
