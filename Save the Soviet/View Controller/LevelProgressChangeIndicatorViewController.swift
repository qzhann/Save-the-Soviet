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
    
    func configureUsing(change: Int, style: LevelProgressChangeIndicatorDisplayStyle) {
        switch style {
        case .short:
            imageView.image = change >= 0 ? UIImage(named: "LevelIncrease")! : UIImage(named: "LevelDecrease")!
            label.text = "\(change)"
        case .long:
            imageView.image = change >= 0 ? UIImage(named: "LevelIncrease")! : UIImage(named: "LevelDecrease")!
            label.text = change >= 0 ? "Level +\(change)" : "Level \(change)"
        }
    }
    

}

enum LevelProgressChangeIndicatorDisplayStyle {
    case short, long
}
