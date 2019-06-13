//
//  FriendDetailViewController.swift
//  Uncommon Application
//
//  Created by qizihan  on 5/14/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class FriendDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate {
    
    unowned var user = User.currentUser
    unowned var friend: Friend!
    weak var selectedPower: Power?
    var selectedIndexPath: IndexPath?

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var userCoinsLabel: UILabel!
    
    @IBOutlet weak var friendBasicInfoBackgroundView: UIView!
    @IBOutlet weak var friendImageView: UIImageView!
    @IBOutlet weak var friendNameLabel: UILabel!
    @IBOutlet weak var friendDescriptionLabel: UILabel!
    
    @IBOutlet weak var friendshipLevelBackgroundView: UIView!
    @IBOutlet weak var friendshipLevelLabel: UILabel!
    @IBOutlet weak var friendshipLevelProgressView: UIProgressView!
    @IBOutlet weak var friendshipLevelProgressLabel: UILabel!
    
    @IBOutlet weak var friendPowerTableView: UITableView!
    @IBOutlet weak var tableViewHeader: UIView!
    
    @IBOutlet weak var deleteFriendButton: UIButton!
    
    
    // MARK: - Table View Data Source Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friend.powers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PowerCell", for: indexPath) as! PowerTableViewCell
        let power = friend.powers[indexPath.row]
        cell.updateWith(power: power)
        return cell
    }
    
    
    // MARK: - Table View Delegate Methods
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        tableViewHeader.frame = CGRect(x: 0, y: 0, width: friendBasicInfoBackgroundView.frame.width, height: 10)
        return tableViewHeader
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let power = friend.powers[indexPath.row]
        return power.hasUpgrade
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        selectedPower = friend.powers[indexPath.row]
        performSegue(withIdentifier: "ShowConfirmation", sender: nil)
    }
    
    
    // MARK: - View Controller Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        prepareUI()
        // Calls configure round corners to show round corners during transition
        configureRoundCorners()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let selectedIndexPath = selectedIndexPath {
            friendPowerTableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Calls configure round corners again to ensure that round corners are rendered correctly after transition
        configureRoundCorners()
        animateProgressViews()
        updateUI()
    }
    
    
    // MARK: - Instance methods
    
    func configureRoundCorners() {
        // In friend basic info background view
        friendBasicInfoBackgroundView.layer.cornerRadius = 10
        friendBasicInfoBackgroundView.clipsToBounds = true
        friendImageView.layer.cornerRadius = friendImageView.bounds.height / 2
        friendImageView.clipsToBounds = true
        
        // In user level background view
        friendshipLevelBackgroundView.layer.cornerRadius = 10
        friendshipLevelBackgroundView.clipsToBounds = true
        friendshipLevelProgressView.layer.cornerRadius = 3
        friendshipLevelProgressView.clipsToBounds = true
        
        // In user power table view
        friendPowerTableView.layer.cornerRadius = 10
        friendPowerTableView.clipsToBounds = true
        
        // For progress views
        friendshipLevelProgressView.subviews[1].layer.cornerRadius = 3
        friendshipLevelProgressView.subviews[1].clipsToBounds = true
        
        // For delete friend button
        deleteFriendButton.layer.cornerRadius = 10
        deleteFriendButton.clipsToBounds = true
    }
    
    func prepareUI() {
        // Update user coins label
        userCoinsLabel.text = "\(user.coins) still left in your pocket."
        
        // Update friend info
        friendNameLabel.text = friend.name
        friendDescriptionLabel.text = friend.description
        friendImageView.image = friend.image
        
        // Update level and energy
        friendshipLevelLabel.text = "Friendship Lv \(friend.friendship.levelNumber)"
        friendshipLevelProgressLabel.text = "\(friend.friendship.progress)/\(friend.friendship.currentUpperBound)"
        friendshipLevelProgressView.progress = 0
    }
    
    func updateUI() {
        if let selectedIndexPath = selectedIndexPath, friend.powers[selectedIndexPath.row].didUpgrade == true {
            friend.powers[selectedIndexPath.row].didUpgrade = false
            friendPowerTableView.reloadRows(at: [selectedIndexPath], with: .left)
        }
        userCoinsLabel.text = "\(user.coins) still left in your pocket."
    }
    
    func animateProgressViews() {
        // Animate the progress of progress views
        UIView.animate(withDuration: 1.5, delay: 0, options: .curveEaseInOut, animations: {
            self.friendshipLevelProgressView.setProgress(self.friend.friendship.normalizedProgress, animated: true)
        }, completion: nil)
    }
    
    @IBAction func friendDetailViewControllerBackgroundTapped(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - View controller transitioning delegate
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is ConfirmationViewController {
            return PageSheetModalPresentationAnimationController(darkenBy: 0.8)
        } else {
            return nil
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is ConfirmationViewController {
            return PageSheetModalDismissalAnimationController(darkenBy: 0.8)
        } else {
            return nil
        }
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowConfirmation" {
            let confirmationViewController = segue.destination as! ConfirmationViewController
            confirmationViewController.transitioningDelegate = self
            confirmationViewController.consequence = .upgradeFriendPower(selectedPower!)
            confirmationViewController.user = user
        }
    }
}
