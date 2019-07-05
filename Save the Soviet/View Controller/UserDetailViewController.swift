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
    var consequenceController: ConsequenceController!
    unowned var levelProgressChangeIndicatorViewController: LevelProgressChangeIndicatorViewController!
    
    
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
    
    @IBOutlet weak var powerTableView: UITableView!
    @IBOutlet weak var tableViewHeader: UIView!
    
    // MARK: - User status display delegate
    
    func updateUserStatus() {
        animateProgressViewsAndLabels()
    }
    
    // MARK: - Consequence visualization delegate
    func visualizeConsequence(_ consequence: Consequence) {
        switch consequence {
        case .changeLevelProgressBy(let change):
            levelProgressChangeIndicatorViewController.configureUsing(change: change, style: .short)
            animateLevelProgressChangeIndicatorFor(change: change)
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
        // Deselect selected row of the power table view
        if let selectedIndexPath = selectedIndexPath {
            powerTableView.deselectRow(at: selectedIndexPath, animated: true)
        }
        levelProgressChangeIndicatorView.alpha = 0
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
    }
    
    func updatePowerTableView() {
        if let selectedIndexPath = selectedIndexPath, didConfirm == true {
            powerTableView.reloadRows(at: [selectedIndexPath], with: .left)
            didConfirm = false
        }
        userCoinsLabel.text = "\(user.coins) still left in your pocket."
    }
    
    func animateProgressViewsAndLabels() {
        let duration = 1.5
        let levelProgress = self.user.level.normalizedProgress
        let energyProgress = self.user.support.normalizedProgress
        
        // Animate level progress view
        
        // FIXME: This will be useful for the small animations of consequenceController
        switch self.user.level.levelNumberChangeStatus {
        case .increased:
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                self.levelProgressView.setProgress(levelProgress, animated: true)
            })
        case .decreased:
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                self.levelProgressView.setProgress(levelProgress, animated: true)
            })
        case .noChange:
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                self.levelProgressView.setProgress(levelProgress, animated: true)
            })
        }
        
        // Animate support progress view
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            self.supportProgressView.setProgress(energyProgress, animated: true)
        })
        
        // Animate the text changes
        levelLabel.text = "Level \(user.level.levelNumber)"
        
        let levelProgressDifference = user.level.progress - user.level.previousProgress
        var displayProgress = user.level.previousProgress
        if levelProgressDifference != 0 {
            visualizeConsequence(.changeLevelProgressBy(levelProgressDifference))
            Timer.scheduledTimer(withTimeInterval: duration / abs(Double(levelProgressDifference)), repeats: true) { (timer) in
                if displayProgress == self.user.level.progress {
                    timer.invalidate()
                }
                
                self.levelProgressLabel.text = "\(displayProgress)/\(self.user.level.currentUpperBound)"
                if displayProgress == self.user.level.progress {
                    self.levelProgressLabel.text = self.user.level.progressDescription
                }
                if levelProgressDifference > 0 {
                    displayProgress += 1
                } else {
                    displayProgress -= 1
                }
                
            }
        }
        
        
        supportProgressLabel.text = user.support.progressDescription
    }
    
    private func animateLevelProgressChangeIndicatorFor(change: Int) {
        var animation: CGAffineTransform!
        if change > 0 {
            // Make it rise from the bar
            levelProgressChangeIndicatorView.transform = CGAffineTransform(translationX: 0, y: 5)
            animation = CGAffineTransform(translationX: 0, y: -5)
        } else if change < 0 {
            animation = CGAffineTransform(translationX: 0, y: 5)
        } else {
            animation = CGAffineTransform(translationX: 0, y: 0)
        }
        
        
        let appearAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .linear) {
            self.levelProgressChangeIndicatorView.alpha = 1
        }
        let translateAnimator = UIViewPropertyAnimator(duration: 1, curve: .easeOut) {
            self.levelProgressChangeIndicatorView.transform = animation
        }
        let disappearAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .linear) {
            self.levelProgressChangeIndicatorView.alpha = 0
        }
        translateAnimator.addCompletion { (_) in
            disappearAnimator.startAnimation()
        }
        
        disappearAnimator.addCompletion { (_) in
            self.levelProgressChangeIndicatorView.transform = .identity
        }
        
        appearAnimator.startAnimation()
        translateAnimator.startAnimation()
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
        }
    }

}
