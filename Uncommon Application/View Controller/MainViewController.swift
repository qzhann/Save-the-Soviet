//
//  MainViewController.swift
//  Uncommon Application
//
//  Created by qizihan  on 3/21/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

protocol FriendImageViewTapDelegate: UIViewController {
    func imageTapped(at indexPath: IndexPath)
}

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate, FriendImageViewTapDelegate {
    
    @IBOutlet weak var userStatusBarView: UIView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var levelNumberLabel: UILabel!
    @IBOutlet weak var levelProgressView: UIProgressView!
    @IBOutlet weak var levelProgressLabel: UILabel!
    @IBOutlet weak var energyProgressView: UIProgressView!
    @IBOutlet weak var energyProgressLabel: UILabel!
    
    @IBOutlet weak var friendTableView: UITableView!
    
    @IBOutlet weak var shopBackgroundView: UIView!
    @IBOutlet weak var coinImageView: UIImageView!
    @IBOutlet weak var shopButton: UIButton!
    
    var user: User = User.testUser // FIXME: Need to be replaced with the actual user
    
    // MARK: - Friend Image View Tap Delegate Method
    
    func imageTapped(at indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowFriendDetail", sender: nil)
    }
    
    // MARK: - Table View Data Source Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return user.friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Configure cell data and appearance
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath) as! FriendTableViewCell
        let friend = user.friends[indexPath.row]
        cell.updateCell(with: friend)
        cell.selectionStyle = .none
        
        // Configure image view tap delegate
        cell.imageViewTapDelegate = self
        cell.indexPath = indexPath
        
        return cell
    }
    
    // MARK: - Table View Delegate Methods
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    
    // MARK: - View Controller Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserInfo()
    }
    
    // We call prepareUI in viewDidLayoutSubviews so that the dimentions of the subviews can be calculated correctly
    override func viewDidLayoutSubviews() {
        prepareUI()
        
    }
    
    // Animate the progressViews once the views have occured
    override func viewDidAppear(_ animated: Bool) {
        animateProgressViews()
    }
    
    func prepareUI() {
        
        // Setting round corner for user status bar view
        userStatusBarView.layer.cornerRadius = 15
        
        // Setting round corner for views in User Status View
        userImageView.layer.cornerRadius = 10
        userImageView.clipsToBounds = true
        
        levelProgressView.layer.cornerRadius = 3
        levelProgressView.clipsToBounds = true
        energyProgressView.layer.cornerRadius = 3
        energyProgressView.clipsToBounds = true
        
        // Setting round corner for shop background view
        shopBackgroundView.layer.cornerRadius = shopBackgroundView.frame.height / 2
        
        // Setting round corner for friend table view
        friendTableView.layer.cornerRadius = 18
        friendTableView.clipsToBounds = true
        friendTableView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        // Setting round corner for progress views
        levelProgressView.subviews[1].layer.cornerRadius = 3
        levelProgressView.subviews[1].clipsToBounds = true
        energyProgressView.subviews[1].layer.cornerRadius = 3
        energyProgressView.subviews[1].clipsToBounds = true
        
        // Setting shadow for user status bar view
        userStatusBarView.layer.masksToBounds = false
        userStatusBarView.layer.shadowColor = UIColor.black.cgColor
        userStatusBarView.layer.shadowOpacity = 0.5
        userStatusBarView.layer.shadowOffset = CGSize.zero
        userStatusBarView.layer.shadowRadius = 15
        userStatusBarView.layer.shadowPath = UIBezierPath(roundedRect: userStatusBarView.bounds, cornerRadius: userStatusBarView.layer.cornerRadius).cgPath
        
        // Setting shadow for shop background view
        shopBackgroundView.layer.shadowColor = UIColor.black.cgColor
        shopBackgroundView.layer.shadowOpacity = 0.5
        shopBackgroundView.layer.shadowOffset = CGSize.zero
        shopBackgroundView.layer.shadowRadius = 3
        shopBackgroundView.layer.shadowPath = UIBezierPath(roundedRect: shopBackgroundView.bounds, cornerRadius: shopBackgroundView.layer.cornerRadius).cgPath
        
        // Reset coin image view
        coinImageView.alpha = 1
    }
    
    func updateUserInfo() {
        // Update the User info
        levelNumberLabel.text = "\(user.level.levelNumber)"
        levelProgressLabel.text = "\(user.level.progress)/\(user.level.currentUpperBound)"
        energyProgressLabel.text = "\(user.energy.progress)/\(user.energy.maximum)"
    }
    
    func animateProgressViews() {
        // Animate the progress of progress view
        // FIXME: Animate only from an old value to a new value, but not from 0 to the new value. Transition would be useful if the user returned from other view controllers, or triggered events that changed the values.
        UIView.animate(withDuration: 1.5, delay: 0, options: [.curveEaseInOut], animations: {
            self.levelProgressView.setProgress(self.user.level.normalizedProgress, animated: true)
            self.energyProgressView.setProgress(self.user.energy.normalizedProgress, animated: true)
        }, completion: nil)
    }
    
    // MARK: - IB Actions
    
    @IBAction func statusBarViewTapped(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "ShowUserDetail", sender: nil)
    }
    
    @IBAction func friendImageViewTapped(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "ShowFriendDetail", sender: nil)
    }

    
    // Handling the change in transparency of coin image view when the user touched shop button
    
    @IBAction func shopButtonTouchedDown(_ sender: UIButton) {
        coinImageView.alpha = 0.3
    }
    
    @IBAction func shopButtonTouchedUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2) {
            self.coinImageView.alpha = 1
        }
    }
    
    @IBAction func shopButtonTouchedUpOutside(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2) {
            self.coinImageView.alpha = 1
        }
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "ShowUserDetail" {
            let userDetailViewController = segue.destination as! UserDetailViewController
            userDetailViewController.transitioningDelegate = self
        } else if segue.identifier == "ShowFriendDetail" {
            let friendDetailViewController = segue.destination as! FriendDetailViewController
            friendDetailViewController.transitioningDelegate = self
        }
    }
    
    
    // MARK: - View Controller Animated Transitioning Delegate Methods
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PageSheetModalPresentationAnimationController()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PageSheetModalDismissalAnimationController()
    }

}
