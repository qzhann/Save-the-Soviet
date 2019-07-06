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

protocol DelayConsequenceHandlingDelegate: AnyObject {
    var delayedConsequences: [Consequence] { get set }
}


class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate, FriendImageViewTapDelegate, FriendStatusDisplayDelegate, UserStatusDisplayDelegate, DelayConsequenceHandlingDelegate {
    
    @IBOutlet weak var userStatusBarView: UIView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var levelNumberLabel: UILabel!
    @IBOutlet weak var levelProgressView: UIProgressView!
    @IBOutlet weak var levelProgressLabel: UILabel!
    @IBOutlet weak var supportProgressView: UIProgressView!
    @IBOutlet weak var supportProgressLabel: UILabel!
    
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
    var delayedConsequences: [Consequence] = []
    
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
            levelProgressChangeIndicatorViewController.configureUsing(change: change, style: .short)
            animateLevelProgressChangeIndicatorFor(change: change)
        default:
            break
        }
    }
    
    
    // MARK: - View Controller Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // FIXME: This is commented, might cause problems.
        //user.applyAllPowers()
        consequenceController = ConsequenceController(for: User.currentUser)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        user.statusDisplayDelegate = self
        prepareUI()
        prepareProgressViewsAndLabels()
        handleDelayedConsequences()
    }
    
    // We call prepareUI in viewDidLayoutSubviews so that the dimentions of the subviews can be calculated correctly
    override func viewDidLayoutSubviews() {
        if didPrepareUI == false {
            prepareUI()
            didPrepareUI = true
        }
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
        // Setting the user image
        userImageView.image = user.image
        
        levelProgressView.layer.cornerRadius = 3
        levelProgressView.clipsToBounds = true
        supportProgressView.layer.cornerRadius = 3
        supportProgressView.clipsToBounds = true
        
        // Setting round corner for shop background view
        shopBackgroundView.layer.cornerRadius = shopBackgroundView.frame.height / 2
        
        // Setting round corner for friend table view
        friendTableView.layer.cornerRadius = 18
        friendTableView.clipsToBounds = true
        friendTableView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        // Setting round corner for progress views
        levelProgressView.subviews[1].layer.cornerRadius = 3
        levelProgressView.subviews[1].clipsToBounds = true
        supportProgressView.subviews[1].layer.cornerRadius = 3
        supportProgressView.subviews[1].clipsToBounds = true
        
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
    
    func prepareProgressViewsAndLabels() {
        levelProgressChangeIndicatorView.alpha = 0
        
        // Prepare progress views and labels
        let levelProgress = user.level.normalizedProgress
        let energyProgress = user.support.normalizedProgress
        levelProgressView.setProgress(levelProgress, animated: false)
        supportProgressView.setProgress(energyProgress, animated: false)
        levelNumberLabel.text = "\(user.level.levelNumber)"
        levelProgressLabel.text = user.level.progressDescription
        supportProgressLabel.text = user.support.progressDescription
    }
    
    func animateProgressViewsAndLabels() {
        let duration = 1.5
        let levelProgress = user.level.normalizedProgress
        let energyProgress = user.support.normalizedProgress
        
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
        
        // Animate the progress change indicator if change is not zero
        if levelProgressDifference != 0 {
            visualizeConsequence(.changeLevelProgressBy(levelProgressDifference))
            Timer.scheduledTimer(withTimeInterval: duration / abs(Double(levelProgressDifference)), repeats: true) { (timer) in
                if displayProgress >= self.user.level.progress {
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
        
        
        
        
        // Animate support progress view
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            self.supportProgressView.setProgress(energyProgress, animated: true)
        })
        
        
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
    
    /// Handles delayed consequences, particularly used for makeNewFriend.
    private func handleDelayedConsequences() {
        for consequence in delayedConsequences {
            switch consequence {
            case .makeNewFriend(let friend):
                friendTableView.beginUpdates()
                user.makeNewFriend(friend: friend)
                friendTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                friendTableView.endUpdates()
            default:
                break
            }
        }
        delayedConsequences = []
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
            chatViewController.delayedConsequenceHandlingDelegate = self
            friendTableView.deselectRow(at: friendTableView.indexPathForSelectedRow!, animated: true)
        } else if segue.identifier == "EmbedLevelProgressChangeIndicator" {
            let levelProgressChangeIndicatorViewController = segue.destination as! LevelProgressChangeIndicatorViewController
            self.levelProgressChangeIndicatorViewController = levelProgressChangeIndicatorViewController
        } else if segue.identifier == "ShowNewFriend" {
            let newFriendViewController = segue.destination as! NewFriendViewController
            newFriendViewController.friend = user.friends.last
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
            if let deletedPath = self.deletedIndexPath {
                self.friendTableView.deleteRows(at: [deletedPath], with: .top)
            }
        }
    }

}
