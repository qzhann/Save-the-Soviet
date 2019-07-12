//
//  FriendDetailViewController.swift
//  Uncommon Application
//
//  Created by qizihan  on 5/14/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class FriendDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate, ConfirmationDelegate, FriendStatusDisplayDelegate, UserStatusDisplayDelegate, ConsequenceVisualizationDelegate {
    
    unowned var user = User.currentUser
    unowned var friend: Friend!
    weak var selectedPower: Power?
    var selectedIndexPath: IndexPath?
    var didConfirm = false
    var progressChangeIndicatorController = ProgressChangeIndicatorController(withAnimationDistance: 5)
    unowned var coinChangeIndicatorViewController: CoinChangeIndicatorViewController!
    unowned var loyaltyProgressChangeIndicatorViewController: SupportLoyaltyProgressChangeIndicatorViewController!

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var userCoinsLabel: UILabel!
    @IBOutlet weak var coinChangeIndicatorView: UIView!
    
    @IBOutlet weak var basicInfoBackgroundView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var loyaltyBackgroundView: UIView!
    @IBOutlet weak var loyaltyProgressView: UIProgressView!
    @IBOutlet weak var loyaltyProgressLabel: UILabel!
    @IBOutlet weak var loyaltyProgressChangeIndicatorView: UIView!
    
    @IBOutlet weak var powerTableView: UITableView!
    @IBOutlet weak var tableViewHeader: UIView!
    
    @IBOutlet weak var executeFriendButton: UIButton!
    @IBOutlet var lockLabel: UILabel!
    @IBOutlet var lockRestrictionLabel: UILabel!
    
    
    // MARK: - Friend status display delegate
    
    func updateFriendStatus() {
        updateProgressViewsAndLabels()
    }
    
    
    // MARK: - User status display delegate
    
    func updateUserStatus() {
        updateProgressViewsAndLabels()
    }
    
    
    // MARK: - Consequence visualization delegate
    
    func visualizeConsequence(_ consequence: Consequence) {
        switch consequence {
        case .changeUserCoinsBy(let change):
            coinChangeIndicatorViewController.configureUsing(change: change, style: .short)
            progressChangeIndicatorController.animate(view: coinChangeIndicatorView, forChange: change)
        case .changeFriendLoyaltyBy(let change):
            loyaltyProgressChangeIndicatorViewController.configureUsing(change: change, style: .loyaltyShort)
            progressChangeIndicatorController.animate(view: loyaltyProgressChangeIndicatorView, forChange: change)
        default:
            break
        }
    }
    
    
    // MARK: - Table view data source
    
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
        tableViewHeader.frame = CGRect(x: 0, y: 0, width: basicInfoBackgroundView.frame.width, height: 10)
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
        performSegue(withIdentifier: "UpgradePowerConfirmation", sender: nil)
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
            powerTableView.deselectRow(at: selectedIndexPath, animated: true)
        }
        user.statusDisplayDelegate = self
        user.visualizationDelegate = self
        friend.statusDisplayDelegate = self
        friend.visualizationDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Calls configure round corners again to ensure that round corners are rendered correctly after transition
        configureRoundCorners()
        updateProgressViewsAndLabels()
        updateUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        user.statusDisplayDelegate = nil
        user.visualizationDelegate = nil
        friend.statusDisplayDelegate = nil
        friend.visualizationDelegate = nil
    }
    
    
    // MARK: - Instance methods
    
    func configureRoundCorners() {
        // In friend basic info background view
        basicInfoBackgroundView.layer.cornerRadius = 10
        basicInfoBackgroundView.clipsToBounds = true
        imageView.layer.cornerRadius = imageView.bounds.height / 2
        imageView.clipsToBounds = true
        
        // In user level background view
        loyaltyBackgroundView.layer.cornerRadius = 10
        loyaltyBackgroundView.clipsToBounds = true
        loyaltyProgressView.layer.cornerRadius = 3
        loyaltyProgressView.clipsToBounds = true
        
        // In user power table view
        powerTableView.layer.cornerRadius = 10
        powerTableView.clipsToBounds = true
        
        // For progress views
        loyaltyProgressView.subviews[1].layer.cornerRadius = 3
        loyaltyProgressView.subviews[1].clipsToBounds = true
        
        // For delete friend button
        executeFriendButton.layer.cornerRadius = 10
        executeFriendButton.clipsToBounds = true
    }
    
    func prepareUI() {
        // Update user coins label
        userCoinsLabel.text = "\(user.coins) still left in your pocket."
        
        // Update friend info
        nameLabel.text = friend.fullName
        descriptionLabel.text = friend.description
        imageView.image = friend.image
        
        // Update level and support
        loyaltyProgressLabel.text = friend.loyalty.progressDescription
        loyaltyProgressView.setProgress(0.05, animated: false)
        
        // Update Execute friend button
        executeFriendButton.setTitle("Execute \(friend.lastName)", for: .normal)
        executeFriendButton.isEnabled = true
        lockLabel.alpha = 0
        lockRestrictionLabel.alpha = 0
        switch friend.executionRestriction {
        case .never:
            // Disable the execute friend button if friend can never be executed
            executeFriendButton.isEnabled = false
        case .level(let level):
            // Show restriction if level is lower, otherwise enable the button
            if user.level.levelNumber >= level {
                executeFriendButton.isEnabled = true
            } else {
                executeFriendButton.isEnabled = false
                lockLabel.alpha = 1
                lockRestrictionLabel.text = "Lv.\(level)"
                lockRestrictionLabel.alpha = 1
            }
        case .none:
            // No restriction, do nothing
            break
        }
        
        // Hide progress change indicators
        coinChangeIndicatorView.alpha = 0
        loyaltyProgressChangeIndicatorView.alpha = 0
    }
    
    func updateUI() {
        if let selectedIndexPath = selectedIndexPath, didConfirm == true {
            powerTableView.reloadRows(at: [selectedIndexPath], with: .left)
            didConfirm = false
        }
        userCoinsLabel.text = "\(user.coins) still left in your pocket."
    }
    
    func updateProgressViewsAndLabels() {
        let duration = 1.2
        let loyaltyProgress = friend.loyalty.normalizedProgress
        
        // Update labels
        loyaltyProgressLabel.text = friend.loyalty.progressDescription
        userCoinsLabel.text = "\(user.coins) still left in your pocket."
        
        // Animate progress view
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            self.loyaltyProgressView.setProgress(loyaltyProgress, animated: true)
        })
    }
    
    
    // MARK: - IB actions
    
    @IBAction func backgroundTapped(_ sender: UITapGestureRecognizer) {
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
        if segue.identifier == "UpgradePowerConfirmation" {
            let confirmationViewController = segue.destination as! ConfirmationViewController
            confirmationViewController.transitioningDelegate = self
            confirmationViewController.confirmationDelegate = self
            confirmationViewController.consequence = .upgradePower(selectedPower!)
            confirmationViewController.user = user
        } else if segue.identifier == "DeleteFriendConfirmation" {
            let confirmationViewController = segue.destination as! ConfirmationViewController
            confirmationViewController.transitioningDelegate = self
            confirmationViewController.consequence = .executeFriend(friend)
            confirmationViewController.user = user
        } else if segue.identifier == "EmbedCoinChangeIndicator" {
            let coinChangeIndicatorViewController = segue.destination as! CoinChangeIndicatorViewController
            self.coinChangeIndicatorViewController = coinChangeIndicatorViewController
        } else if segue.identifier == "EmbedLoyaltyProgressChangeIndicator" {
            let loyaltyProgressChangeIndicatorViewController = segue.destination as! SupportLoyaltyProgressChangeIndicatorViewController
            self.loyaltyProgressChangeIndicatorViewController = loyaltyProgressChangeIndicatorViewController
        }
    }
}
