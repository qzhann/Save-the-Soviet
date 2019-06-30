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
    
    func updateUsing(_ change: Int) {
        imageView.image = change >= 0 ? UIImage(named: "Increase")!  : UIImage(named: "Decrease")!
        label.text = "\(change)"
    }
    

}
