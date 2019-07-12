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

class UserDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate, ConfirmationDelegate, UserStatusDisplayDelegate, ConsequenceVisualizationDelegate {
    
    unowned var user = User.currentUser
    weak var selectedPower: Power?
    var selectedIndexPath: IndexPath?
    var didConfirm = false
    var consequenceController: ConsequenceController!
    unowned var levelProgressChangeIndicatorViewController: LevelProgressChangeIndicatorViewController!
    unowned var supportProgressChangeIndicatorViewController: SupportLoyaltyProgressChangeIndicatorViewController!
    var progressChangeIndicatorController = ProgressChangeIndicatorController(withAnimationDistance: 5)
    
    @IBOutlet weak var backgroundView: UIView!
    
    @IBOutlet weak var userCoinsLabel: UILabel!
    @IBOutlet weak var basicInfoBackgroundView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var levelBackgroundView: UIView!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var levelProgressView: UIProgressView!
    @IBOutlet weak var levelProgressLabel: UILabel!
    @IBOutlet weak var levelProgressChangeIndicatorView: UIView!
    
    @IBOutlet weak var supportBackgroundView: UIView!
    @IBOutlet weak var supportProgressView: UIProgressView!
    @IBOutlet weak var supportProgressLabel: UILabel!
    @IBOutlet weak var supportProgressChangeIndicatorView: UIView!
    
    @IBOutlet weak var powerTableView: UITableView!
    @IBOutlet weak var tableViewHeader: UIView!
    
    // MARK: - User status display delegate
    
    func updateUserStatus() {
        updateProgressViewsAndLabels()
    }
    
    // MARK: - Consequence visualization delegate
    
    func visualizeConsequence(_ consequence: Consequence) {
        switch consequence {
        case .changeUserLevelBy(let change):
            levelProgressChangeIndicatorViewController.configureUsing(change: change, style: .short)
            progressChangeIndicatorController.animateProgressChangeIndicator(view: levelProgressChangeIndicatorView, forChange: change)
        case .changeUserSupportBy(let change):
            supportProgressChangeIndicatorViewController.configureUsing(change: change, style: .support)
            progressChangeIndicatorController.animateProgressChangeIndicator(view: supportProgressChangeIndicatorView, forChange: change)
        default:
            break
        }
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
        consequenceController = ConsequenceController(for: user)
        
        prepareUI()
        // Calls configure round corners to show round corners during transition
        configureRoundCorners()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Set the delegate
        user.statusDisplayDelegate = self
        user.visualizationDelegate = self
        
        // Deselect selected row of the power table view
        if let selectedIndexPath = selectedIndexPath {
            powerTableView.deselectRow(at: selectedIndexPath, animated: true)
        }
        
    }
    
    // Overriding view did appear correctly configures round corners and animates the progress of progress views
    override func viewDidAppear(_ animated: Bool) {
        
        // Calls configure round corners again to ensure that round corners are rendered correctly after transition
        configureRoundCorners()
        updateProgressViewsAndLabels()
        updatePowerTableView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        user.statusDisplayDelegate = nil
        user.visualizationDelegate = nil
    }
    
    // MARK: -
    
    func configureRoundCorners() {
        // In user basic info background view
        basicInfoBackgroundView.layer.cornerRadius = 10
        basicInfoBackgroundView.clipsToBounds = true
        imageView.layer.cornerRadius = imageView.bounds.height / 2
        imageView.clipsToBounds = true
        
        // In user level background view
        levelBackgroundView.layer.cornerRadius = 10
        levelBackgroundView.clipsToBounds = true
        levelProgressView.layer.cornerRadius = 3
        levelProgressView.clipsToBounds = true
        
        // In user support background view
        supportBackgroundView.layer.cornerRadius = 10
        supportBackgroundView.clipsToBounds = true
        supportProgressView.layer.cornerRadius = 3
        supportProgressView.clipsToBounds = true
        
        // In user power table view
        powerTableView.layer.cornerRadius = 10
        powerTableView.clipsToBounds = true
        
        // For progress views
        levelProgressView.subviews[1].layer.cornerRadius = 3
        levelProgressView.subviews[1].clipsToBounds = true
        supportProgressView.subviews[1].layer.cornerRadius = 3
        supportProgressView.subviews[1].clipsToBounds = true
    }
    
    func prepareUI() {
        // Prepare User Info
        nameLabel.text = user.name
        descriptionLabel.text = user.description
        userCoinsLabel.text = "\(user.coins) still left in your pocket."
        levelLabel.text = "Level \(user.level.levelNumber)"
        levelProgressLabel.text = user.level.progressDescription
        supportProgressLabel.text = user.support.progressDescription
        imageView.image = user.image
        
        // Prepare progress views
        levelProgressView.setProgress(0.05, animated: false)
        supportProgressView.setProgress(0.05, animated: false)
        
        levelProgressChangeIndicatorView.alpha = 0
        supportProgressChangeIndicatorView.alpha = 0
    }
    
    func updatePowerTableView() {
        if let selectedIndexPath = selectedIndexPath, didConfirm == true {
            powerTableView.reloadRows(at: [selectedIndexPath], with: .left)
            didConfirm = false
        }
        userCoinsLabel.text = "\(user.coins) still left in your pocket."
    }
    
    func updateProgressViewsAndLabels() {
        let duration = 1.5
        let levelProgress = user.level.normalizedProgress
        let energyProgress = user.support.normalizedProgress
        
        // Animate the text changes
        levelProgressLabel.text = user.level.progressDescription
        supportProgressLabel.text = user.support.progressDescription
        
        // Animate progress view
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            self.levelProgressView.setProgress(levelProgress, animated: true)
            self.supportProgressView.setProgress(energyProgress, animated: true)
        })
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
        } else if segue.identifier == "EmbedLevelProgressChangeIndicator" {
            self.levelProgressChangeIndicatorViewController = segue.destination as? LevelProgressChangeIndicatorViewController
        } else if segue.identifier == "EmbedSupportProgressChangeIndicator" {
            let supportProgressChangeIndicatorViewController = segue.destination as! SupportLoyaltyProgressChangeIndicatorViewController
            self.supportProgressChangeIndicatorViewController = supportProgressChangeIndicatorViewController
        }
    }

}
