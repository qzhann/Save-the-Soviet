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

protocol FriendMessageStatusDisplayDelegate: AnyObject {
    func updateNewMessageStatusFor(_ friend: Friend)
    func moveCellToTopFor(_ friend: Friend)
}

protocol FriendStatusDisplayDelegate: AnyObject {
    func updateFriendStatus()
}

protocol UserStatusDisplayDelegate: AnyObject {
    func updateUserStatus()
}

protocol ConsequenceVisualizationDelegate: AnyObject {
    func visualizeConsequence(_ consequence: Consequence)
}

protocol DelayConsequenceHandlingDelegate: AnyObject {
    var delayedConsequences: [Consequence] { get set }
}

protocol LevelUpHandlingDelegate: AnyObject {
    func userLevelIncreasedTo(_ level: Int)
}

protocol RestartGameHandlingDelegate: AnyObject {
    func restartGameWith(winState win: Bool)
}


class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate, FriendImageViewTapDelegate, FriendMessageStatusDisplayDelegate, UserStatusDisplayDelegate, ConsequenceVisualizationDelegate, DelayConsequenceHandlingDelegate, LevelUpHandlingDelegate, RestartGameHandlingDelegate {
    
    // MARK: Instance properties
    
    var user: User!
    var currentFriend: Friend!
    var deletedIndexPath: IndexPath?
    weak var executedFriend: Friend?
    var consequenceController: ConsequenceController!
    unowned var levelProgressChangeIndicatorViewController: LevelProgressChangeIndicatorViewController!
    unowned var supportProgressChangeIndicatorViewController: SupportLoyaltyProgressChangeIndicatorViewController!
    var progressChangeIndicatorController = ProgressChangeIndicatorController(withAnimationDistance: 5)
    private var didPrepareUI = false
    var delayedConsequences: [Consequence] = []
    var isDisplaying = false
    var newLevel: Int?
    var win: Bool?
    
    @IBOutlet weak var userStatusBarView: UIView!
    @IBOutlet weak var userImageView: UIImageView!
    
    @IBOutlet weak var levelNumberLabel: UILabel!
    @IBOutlet weak var levelProgressView: UIProgressView!
    @IBOutlet weak var levelProgressLabel: UILabel!
    @IBOutlet weak var levelProgressChangeIndicatorView: UIView!
    
    @IBOutlet weak var supportProgressView: UIProgressView!
    @IBOutlet weak var supportProgressLabel: UILabel!
    @IBOutlet weak var supportProgressChangeIndicatorView: UIView!
    
    @IBOutlet weak var friendTableView: UITableView!
    
    @IBOutlet weak var shopBackgroundView: UIView!
    @IBOutlet weak var coinImageView: UIImageView!
    @IBOutlet weak var shopButton: UIButton!
    
    
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
        updateProgressViewsAndLabels()
    }
    
    
    // MARK: - Consequence visualization delegate
    
    func visualizeConsequence(_ consequence: Consequence) {
        switch consequence {
        case .changeUserLevelBy(let change):
            levelProgressChangeIndicatorViewController.configureUsing(change: change, style: .short)
            progressChangeIndicatorController.animate(view: levelProgressChangeIndicatorView, forChange: change)
        case .changeUserSupportBy(let change):
            supportProgressChangeIndicatorViewController.configureUsing(change: change, style: .support)
            progressChangeIndicatorController.animate(view: supportProgressChangeIndicatorView, forChange: change)
        default:
            break
        }
    }
    
    // MARK: - Level up handling delegate
    
    func userLevelIncreasedTo(_ level: Int) {
        // If there is already new level on record, update if needed. Otherwise set the new level
        if let newLevel = newLevel {
            if level > newLevel {
                self.newLevel = level
                handleNewLevel()
            }
        } else {
            self.newLevel = level
            handleNewLevel()
        }
        
    }
    
    func handleNewLevel() {
        if newLevel != nil && isDisplaying == true {
            performSegue(withIdentifier: "ConfirmLevelUp", sender: nil)
        }
    }
    
    
    // MARK: - Restart game handling delegate
    
    func restartGameWith(winState win: Bool) {
        self.win = win
        handleRestartGame()
    }
    
    func handleRestartGame() {
        if win != nil && isDisplaying == true {
            performSegue(withIdentifier: "EndGame", sender: nil)
        }
    }
    
    
    // MARK: - View Controller Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        user = User.currentUser
        consequenceController = ConsequenceController(for: user)
        user.levelUpHandlingDelegate = self
        user.restartGameHandlingDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Setting delegates
        user.statusDisplayDelegate = self
        user.visualizationDelegate = self
        // Preparing UI
        isDisplaying = true
        prepareUI()
    }
    
    // We call prepareUI in viewDidLayoutSubviews so that the dimensions of the subviews can be calculated correctly
    override func viewDidLayoutSubviews() {
        if didPrepareUI == false {
            prepareUI()
            didPrepareUI = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if user.isNewUser {
            startTutorial()
        }
        updateProgressViewsAndLabels()
        handleNewLevel()
        
        if user.support.progress == user.support.maximumProgress {
            win = true
        } else if user.support.progress == 0 {
            win = false
        }
        handleRestartGame()
        handleDelayedConsequences()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        user.statusDisplayDelegate = nil
        user.visualizationDelegate = nil
        isDisplaying = false
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
        friend.messageStatusDisplayDelegate = self
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
        
        // Hide progress change indicators
        levelProgressChangeIndicatorView.alpha = 0
        supportProgressChangeIndicatorView.alpha = 0
    }
    
    func updateProgressViewsAndLabels() {
        let duration = 1.2
        let levelProgress = user.level.normalizedProgress
        let energyProgress = user.support.normalizedProgress
        
        // Animate the text changes
        levelNumberLabel.text = "\(user.level.levelNumber)"
        levelProgressLabel.text = user.level.progressDescription
        supportProgressLabel.text = user.support.progressDescription
        
        if user.level.progressDescription == "MAX" {
            scaleProgressLabelForMax(levelProgressLabel)
        }
        if user.support.progressDescription == "MAX" {
            scaleProgressLabelForMax(supportProgressLabel)
        }
        
        // Animate progress view
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            self.levelProgressView.setProgress(levelProgress, animated: true)
            self.supportProgressView.setProgress(energyProgress, animated: true)
        })
    }
    
    /// At maximum progress, scale the progress labels.
    private func scaleProgressLabelForMax(_ label: UILabel) {
        let scaleLarge = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
        let scaleAnimator = UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut) {
            label.transform = scaleLarge
        }
        scaleAnimator.addAnimations({
            label.transform = .identity
        }, delayFactor: 0.25)
        
        scaleAnimator.startAnimation()
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
                user.friendLoyaltyDidChange()
            case .userLevelIncreasedTo(let level):
                newLevel = level
                performSegue(withIdentifier: "ConfirmLevelUp", sender: nil)
            default:
                break
            }
        }
        delayedConsequences = []
    }
    
    
    /// Starts tutorial if the user is new user.
    func startTutorial() {
        guard user.isNewUser == true else { return }
        performSegue(withIdentifier: "ShowTutorial", sender: nil)
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
            chatViewController.user = user
            chatViewController.transitioningDelegate = self
            currentFriend.isChatting = true
            chatViewController.friend = currentFriend
            chatViewController.delayedConsequenceHandlingDelegate = self
            friendTableView.deselectRow(at: friendTableView.indexPathForSelectedRow!, animated: true)
        } else if segue.identifier == "EmbedLevelProgressChangeIndicator" {
            let levelProgressChangeIndicatorViewController = segue.destination as! LevelProgressChangeIndicatorViewController
            self.levelProgressChangeIndicatorViewController = levelProgressChangeIndicatorViewController
        } else if segue.identifier == "EmbedSupportProgressChangeIndicator" {
            let supportProgressChangeIndicatorViewController = segue.destination as! SupportLoyaltyProgressChangeIndicatorViewController
            self.supportProgressChangeIndicatorViewController = supportProgressChangeIndicatorViewController
        } else if segue.identifier == "ConfirmLevelUp" {
            let confirmationViewController = segue.destination as! ConfirmationViewController
            confirmationViewController.user = user
            confirmationViewController.consequence = .userLevelIncreasedTo(newLevel!)
            confirmationViewController.transitioningDelegate = self
            newLevel = nil
        } else if segue.identifier == "ConfirmExecuteFriend" {
            let confirmationViewController = segue.destination as! ConfirmationViewController
            confirmationViewController.user = user
            confirmationViewController.consequence = .friendIsExecuted(executedFriend!)
            confirmationViewController.transitioningDelegate = self
            executedFriend = nil
        } else if segue.identifier == "EndGame" {
            let restartGameViewController = segue.destination as! RestartGameViewController
            restartGameViewController.win = win!
            restartGameViewController.transitioningDelegate = self
            win = nil
        } else if segue.identifier == "ShowTutorial" {
            let chatViewController = segue.destination as! ChatViewController
            chatViewController.user = user
            chatViewController.friend = user.friendWithLastName(Friend.oldPartyMember.lastName)
            chatViewController.transitioningDelegate = self
            chatViewController.friend.startChat()
        }
    }
    
    
    // MARK: - View Controller Transitioning Delegate Methods
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is UserDetailViewController || presented is FriendDetailViewController || presented is ConfirmationViewController {
            return PageSheetModalPresentationAnimationController(darkenBy: 0.8)
        } else if presented is ChatViewController {
            return PushPresentationAnimationController()
        } else if presented is RestartGameViewController {
            return FadeAnimationController(withDuration: 2.5)
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
                self.performSegue(withIdentifier: "ConfirmExecuteFriend", sender: nil)
            }
        }
    }

}
