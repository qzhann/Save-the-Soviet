//
//  NewFriendViewController.swift
//  Uncommon Application
//
//  Created by qizihan  on 6/26/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class NewFriendViewController: UIViewController {
    
    @IBOutlet weak var friendImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    
    unowned var friend: Friend!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    override func viewDidLayoutSubviews() {
        configureRoundCorners()
    }
    
    func configureRoundCorners() {
        friendImageView.layer.cornerRadius = friendImageView.frame.height / 2
        friendImageView.clipsToBounds = true
        confirmButton.layer.cornerRadius = 10
        confirmButton.clipsToBounds = true
    }
    
    func updateUI() {
        friendImageView.image = friend.image
        nameLabel.text = friend.name
        descriptionLabel.text = friend.description
        confirmButton.titleEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        nameLabel.clipsToBounds = false
    }
    
    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
