//
//  MainViewController.swift
//  Uncommon Application
//
//  Created by qizihan  on 3/21/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

protocol FriendImageViewTapDelegate: UIViewController {
    func imageTapped(for friend: Friend)
}

protocol FriendStatusDisplayDelegate: AnyObject {
    func updateNewMessageStatusFor(_ friend: Friend)
    func moveCellToTopFor(_ friend: Friend)
}

protocol UserStatusDisplayDelegate: AnyObject {
    func updateUserStatus()
}


class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate, FriendImageViewTapDelegate, FriendStatusDisplayDelegate, UserStatusDisplayDelegate, ConsequenceVisualizationDelegate {
    
    @IBOutlet weak var userStatusBarView: UIView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var levelNumberLabel: UILabel!
    @IBOutlet weak var levelProgressView: UIProgressView!
    @IBOutlet weak var levelProgressLabel: UILabel!
    @IBOutlet weak var energyProgressView: UIProgressView!
    @IBOutlet weak var energyProgressLabel: UILabel!
    
    @IBOutlet weak var levelProgressChangeIndicatorView: UIView!
    
    
    @IBOutlet weak var friendTableView: UITableView!
    
    @IBOutlet weak var shopBackgroundView: UIView!
    @IBOutlet weak var coinImageView: UIImageView!
    @IBOutlet weak var shopButton: UIButton!
    
    unowned var user: User = User.currentUser
    var currentFriend: Friend!
    var deletedIndexPath: IndexPath?
    var consequenceController: ConsequenceController!
    unowned var levelProgressChangeIndicatorViewController: LevelProgressChangeIndicatorViewController!
    private var didPrepareUI = false
    
    // MARK: - Friend Image View Tap Delegate Method
    
    func imageTapped(for friend: Friend) {
        currentFriend = friend
        performSegue(withIdentifier: "ShowFriendDetail", sender: nil)
    }
    
    // MARK: - Friend status display delegate
    
    func updateNewMessageStatusFor(_ friend: Friend) {
        let friendIndex = user.friends.firstIndex { $0 === friend }!
        friendTableView.reloadRows(at: [IndexPath(row: friendIndex, section: 0)], with: .none)
    }
    
    func moveCellToTopFor(_ friend: Friend) {
        let friendIndex = user.friends.firstIndex { $0 === friend }!
        friendTableView.beginUpdates()
        let friend = user.friends.remove(at: friendIndex)
        user.friends.insert(friend, at: 0)
        friendTableView.moveRow(at: IndexPath(row: friendIndex, section: 0), to: IndexPath(row: 0, section: 0))
        friendTableView.endUpdates()
    }
    
    
    // MARK: - User status display delegate
    
    func updateUserStatus() {
        animateProgressViewsAndLabels()
    }
    
    // MARK: - Consequence visualization delegate
    func visualizeConsequence(_ consequence: Consequence) {
        switch consequence {
        case .changeLevelProgressBy(let change):
            levelProgressChangeIndicatorViewController.updateUsing(change)
            animateLevelProgressChangeIndicatorFor(change: change)
        default:
            break
        }
    }
    
    
    // MARK: - View Controller Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        user.applyAllPowers()
        consequenceController = ConsequenceController(for: User.currentUser)
        consequenceController.delegate = self
        prepareUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        user.statusDisplayDelegate = self
        levelProgressChangeIndicatorView.alpha = 0
    }
    
    // We call prepareUI in viewDidLayoutSubviews so that the dimentions of the subviews can be calculated correctly
    override func viewDidLayoutSubviews() {
        if didPrepareUI == false {
            prepareUI()
            didPrepareUI = true
        }
    }
    
    // Animate the progressViews once the views have occured
    override func viewDidAppear(_ animated: Bool) {
        animateProgressViewsAndLabels()
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
        friend.statusDisplayDelegate = self
        cell.updateCell(with: friend)
        
        // Configure image view tap delegate
        cell.imageViewTapDelegate = self
        
        return cell
    }
    
    // MARK: - Table View Delegate Methods
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentFriend = user.friends[indexPath.row]
        performSegue(withIdentifier: "ShowChat", sender: nil)
    }
    
    
    // MARK: - Instance methods
    
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
        
        // Prepare progress views and labels
        let levelProgress = user.level.normalizedProgress
        let energyProgress = user.energy.normalizedProgress
        levelProgressView.setProgress(levelProgress, animated: true)
        energyProgressView.setProgress(energyProgress, animated: true)
        levelNumberLabel.text = "\(user.level.levelNumber)"
        levelProgressLabel.text = "\(user.level.progress)/\(user.level.currentUpperBound)"
        energyProgressLabel.text = "\(user.energy.progress)/\(user.energy.maximum)"
    }
    
    func animateProgressViewsAndLabels() {
        let duration = 1.5
        let levelProgress = user.level.normalizedProgress
        let energyProgress = user.energy.normalizedProgress
        
        // Animate level progress view
        
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
        
        // Animate the text changes
        levelNumberLabel.text = "\(user.level.levelNumber)"
        
        let levelProgressDifference = user.level.progress - user.level.previousProgress
        var displayProgress = user.level.previousProgress
        if levelProgressDifference != 0 {
            consequenceController.visualize(.changeLevelProgressBy(levelProgressDifference))
            Timer.scheduledTimer(withTimeInterval: duration / abs(Double(levelProgressDifference)), repeats: true) { (timer) in
                if displayProgress == self.user.level.progress {
                    timer.invalidate()
                }
                
                self.levelProgressLabel.text = "\(displayProgress)/\(self.user.level.currentUpperBound)"
                if levelProgressDifference > 0 {
                    displayProgress += 1
                } else {
                    displayProgress -= 1
                }
                
            }
        }
        
        
        
        
        // Animate energy progress view
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            self.energyProgressView.setProgress(energyProgress, animated: true)
        })
        
        
        energyProgressLabel.text = "\(user.energy.progress)/\(user.energy.maximum)"
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
    
    // MARK: - IB Actions
    
    @IBAction func statusBarViewTapped(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "ShowUserDetail", sender: nil)
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
            user.statusDisplayDelegate = userDetailViewController as UserStatusDisplayDelegate
        } else if segue.identifier == "ShowFriendDetail" {
            let friendDetailViewController = segue.destination as! FriendDetailViewController
            friendDetailViewController.transitioningDelegate = self
            friendDetailViewController.friend = currentFriend
        } else if segue.identifier == "ShowChat" {
            let chatViewController = segue.destination as! ChatViewController
            chatViewController.transitioningDelegate = self
            currentFriend.isChatting = true
            chatViewController.friend = currentFriend
            friendTableView.deselectRow(at: friendTableView.indexPathForSelectedRow!, animated: true)
        } else if segue.identifier == "EmbedLevelProgressChangeIndicator" {
            let levelProgressChangeIndicatorViewController = segue.destination as! LevelProgressChangeIndicatorViewController
            self.levelProgressChangeIndicatorViewController = levelProgressChangeIndicatorViewController
        }
    }
    
    
    // MARK: - View Controller Transitioning Delegate Methods
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is UserDetailViewController || presented is FriendDetailViewController {
            return PageSheetModalPresentationAnimationController(darkenBy: 0.8)
        } else if presented is ChatViewController {
            return PushPresentationAnimationController()
        } else {
            return nil
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is UserDetailViewController || dismissed is FriendDetailViewController || dismissed is ConfirmationViewController {
            return PageSheetModalDismissalAnimationController(darkenBy: 0.8)
        } else if dismissed is ChatViewController {
            return PushDismissalAnimationController()
        } else {
            return nil
        }
    }
    
    
    // MARK: - Unwind segue
    
    @IBAction func unwindToMainViewController(unwindSegue: UIStoryboardSegue) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.friendTableView.deleteRows(at: [self.deletedIndexPath!], with: .top)
        }
    }

}
