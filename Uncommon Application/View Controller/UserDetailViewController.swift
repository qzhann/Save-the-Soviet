//
//  UserDetailViewController.swift
//  Uncommon Application
//
//  Created by qizihan  on 3/30/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

protocol ConfirmationDelegate: AnyObject {
    var didConfirm: Bool { get set }
}

class UserDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate, ConfirmationDelegate, UserStatusDisplayDelegate {
    
    unowned var user = User.currentUser
    weak var selectedPower: Power?
    var selectedIndexPath: IndexPath?
    var didConfirm = false
    
    @IBOutlet weak var backgroundView: UIView!
    
    @IBOutlet weak var userCoinsLabel: UILabel!
    @IBOutlet weak var userBasicInfoBackgroundView: UIView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userDescriptionLabel: UILabel!
    
    @IBOutlet weak var userLevelBackgroundView: UIView!
    @IBOutlet weak var userLevelLabel: UILabel!
    @IBOutlet weak var userLevelProgressView: UIProgressView!
    @IBOutlet weak var userLevelProgressLabel: UILabel!
    
    @IBOutlet weak var userEnergyBackgroundView: UIView!
    @IBOutlet weak var userEnergyProgressView: UIProgressView!
    @IBOutlet weak var userEnergyProgressLabel: UILabel!
    
    @IBOutlet weak var userPowerTableView: UITableView!
    @IBOutlet weak var tableViewHeader: UIView!
    
    // MARK: - User status display delegate
    
    func updateUserStatus() {
        animateProgressViewsAndLabels()
    }
    
    // MARK: - Table View Data Source Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return user.powers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PowerCell", for: indexPath) as! PowerTableViewCell
        let power = user.powers[indexPath.row]
        cell.updateWith(power: power)
        return cell
    }
    
    // MARK: - Table View Delegate Methods
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        tableViewHeader.frame = CGRect(x: 0, y: 0, width: userBasicInfoBackgroundView.frame.width, height: 10)
        return tableViewHeader
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let power = user.powers[indexPath.row]
        return power.hasUpgrade
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        selectedPower = user.powers[indexPath.row]
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
        // Deselect selected row of the power table view
        if let selectedIndexPath = selectedIndexPath {
            userPowerTableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    // Overriding view did appear correctly configures round corners and animates the progress of progress views
    override func viewDidAppear(_ animated: Bool) {
        
        // Calls configure round corners again to ensure that round corners are rendered correctly after transition
        configureRoundCorners()
        animateProgressViewsAndLabels()
        updatePowerTableView()
    }
    
    // MARK: -
    
    func configureRoundCorners() {
        // In user basic info background view
        userBasicInfoBackgroundView.layer.cornerRadius = 10
        userBasicInfoBackgroundView.clipsToBounds = true
        userImageView.layer.cornerRadius = userImageView.bounds.height / 2
        userImageView.clipsToBounds = true
        
        // In user level background view
        userLevelBackgroundView.layer.cornerRadius = 10
        userLevelBackgroundView.clipsToBounds = true
        userLevelProgressView.layer.cornerRadius = 3
        userLevelProgressView.clipsToBounds = true
        
        // In user energy background view
        userEnergyBackgroundView.layer.cornerRadius = 10
        userEnergyBackgroundView.clipsToBounds = true
        userEnergyProgressView.layer.cornerRadius = 3
        userEnergyProgressView.clipsToBounds = true
        
        // In user power table view
        userPowerTableView.layer.cornerRadius = 10
        userPowerTableView.clipsToBounds = true
        
        // For progress views
        userLevelProgressView.subviews[1].layer.cornerRadius = 3
        userLevelProgressView.subviews[1].clipsToBounds = true
        userEnergyProgressView.subviews[1].layer.cornerRadius = 3
        userEnergyProgressView.subviews[1].clipsToBounds = true
    }
    
    func prepareUI() {
        // Prepare User Info
        userNameLabel.text = user.name
        userDescriptionLabel.text = user.description
        userCoinsLabel.text = "\(user.coins) still left in your pocket."
        userLevelLabel.text = "Level \(user.level.levelNumber)"
        userLevelProgressLabel.text = "\(user.level.previousProgress)/\(self.user.level.currentUpperBound)"
        userEnergyProgressLabel.text = "\(user.energy.progress)/\(user.energy.maximum)"
        
        // Prepare progress views
        userLevelProgressView.setProgress(0.05, animated: false)
        userEnergyProgressView.setProgress(0.05, animated: false)
    }
    
    func updatePowerTableView() {
        if let selectedIndexPath = selectedIndexPath, didConfirm == true {
            userPowerTableView.reloadRows(at: [selectedIndexPath], with: .left)
            didConfirm = false
        }
        userCoinsLabel.text = "\(user.coins) still left in your pocket."
    }
    
    func animateProgressViewsAndLabels(withDuration duration: Double = 1.5) {
        let levelProgress = self.user.level.normalizedProgress
        let energyProgress = self.user.energy.normalizedProgress
        
        // Animate level progress view
        
        // FIXME: This will be useful for the small animations of consequenceController
        switch self.user.level.levelNumberChangeStatus {
        case .increased:
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                self.userLevelProgressView.setProgress(levelProgress, animated: true)
            })
        case .decreased:
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                self.userLevelProgressView.setProgress(levelProgress, animated: true)
            })
        case .noChange:
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                self.userLevelProgressView.setProgress(levelProgress, animated: true)
            })
        }
        
        // Animate energy progress view
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            self.userEnergyProgressView.setProgress(energyProgress, animated: true)
        })
        
        // Animate the text changes
        userLevelLabel.text = "Level \(user.level.levelNumber)"
        
        let progressDifference = user.level.progress - user.level.previousProgress
        var displayProgress = user.level.previousProgress
        if progressDifference != 0 {
            Timer.scheduledTimer(withTimeInterval: duration / Double(progressDifference), repeats: true) { (timer) in
                if displayProgress == self.user.level.progress {
                    timer.invalidate()
                }
                
                self.userLevelProgressLabel.text = "\(displayProgress)/\(self.user.level.currentUpperBound)"
                displayProgress += 1
            }
        }
        
        
        userEnergyProgressLabel.text = "\(user.energy.progress)/\(user.energy.maximum)"
    }
    
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UpgradePowerConfirmation" {
            let confirmationViewController = segue.destination as! ConfirmationViewController
            confirmationViewController.transitioningDelegate = self
            confirmationViewController.confirmationDelegate = self
            confirmationViewController.consequence = .upgradePower(selectedPower!)
            confirmationViewController.user = user
        }
    }

}
