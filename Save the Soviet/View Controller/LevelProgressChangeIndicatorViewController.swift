//
//  LevelProgressChangeIndicatorViewController.swift
//  Uncommon Application
//
//  Created by qizihan  on 6/29/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class LevelProgressChangeIndicatorViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func configureUsing(change: Int, style: ProgressChangeIndicatorDisplayStyle) {
        switch style {
        case .short:
            imageView.image = change >= 0 ? UIImage(named: "LevelIncrease")! : UIImage(named: "LevelDecrease")!
            label.text = "\(change)"
            label.textColor = UIColor(red: 130 / 255, green: 37 / 255, blue: 41 / 255, alpha: 1)
        case .long:
            imageView.image = change >= 0 ? UIImage(named: "LevelIncrease")! : UIImage(named: "LevelDecrease")!
            label.text = change >= 0 ? "Level +\(change)" : "Level \(change)"
            label.textColor = UIColor(red: 130 / 255, green: 37 / 255, blue: 41 / 255, alpha: 1)
        }
    }
    

}

enum ProgressChangeIndicatorDisplayStyle {
    case short, long
}
