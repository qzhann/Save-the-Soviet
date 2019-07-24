//
//  ConsequenceController.swift
//  Uncommon Application
//
//  Created by qizihan  on 6/13/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit
import UserNotifications

struct ConsequenceController {
    
    // MARK: Instance properties
    
    unowned let user: User
    unowned var confirmationController: ConfirmationViewController?
    unowned var chatViewController: ChatViewController?
    unowned var viewController: UIViewController?
    
    // MARK: - Initializers
    
    init(for user: User) {
        self.user = user
    }
    
    init(for user: User, confirmationViewController: ConfirmationViewController?) {
        self.user = user
        self.confirmationController = confirmationViewController
    }
    
    init(for user: User, chatViewController: ChatViewController?) {
        self.user = user
        self.chatViewController = chatViewController
    }
    
    
    func canHandle(_ consequence: Consequence) -> Bool {
        switch consequence {
        case .changeFriendLoyaltyBy(let change):
            if let chatViewController = chatViewController {
                return chatViewController.friend.loyalty.progress + change >= 0
            } else if let viewController = viewController as? FriendDetailViewController {
                return viewController.friend.loyalty.progress + change >= 0
            } else {
                return true
            }
        case .changeUserCoinsBy(let change):
            return user.coins + change >= 0
        case .upgradePower(let power):
            return user.coins >= power.coinsNeeded
        default:
            return true
        }
    }
    
    func handle(_ consequence: Consequence) {
        switch consequence {
        case .endChatFrom(let direction):
            if let chatViewController = chatViewController {
                chatViewController.endChatFrom(direction)
            }
        case .makeNewFriend(let friend):
            if let chatViewController = chatViewController {
                chatViewController.delayedConsequenceHandlingDelegate.delayedConsequences.append(consequence)
                chatViewController.newFriend = friend
                friend.startChat() 
                chatViewController.performSegue(withIdentifier: "ConfirmNewFriend", sender: nil)
            }
        case .executeFriend(let friend):
            let row = user.friends.firstIndex(of: friend)!
            user.friends.remove(at: row)
            let indexPath = IndexPath(row: row, section: 0)
            confirmationController?.performSegue(withIdentifier: "UnwindToMain", sender: indexPath)
            user.friendLoyaltyDidChange()
        case .changeUserLevelBy(let change):
            user.changeLevelBy(progress: change)
        case .changeUserSupportBy(let change):
            user.changeSupportBy(progress: change)
        case .changeUserCoinsBy(let change):
            user.changeCoinsBy(number: change)
        case .changeFriendLoyaltyBy(let change):
            if let chatViewController = chatViewController {
                chatViewController.friend.changeLoyaltyBy(progress: change)
                user.friendLoyaltyDidChange()
            } else if let viewController = viewController as? FriendDetailViewController {
                viewController.friend.changeLoyaltyBy(progress: change)
                user.friendLoyaltyDidChange()
            }
        case .upgradePower(let power):
            guard canHandle(consequence) == true else { return }
            user.upgradePower(power)
        case .startQuizOfCategory(let category):
            chatViewController?.quizQuestionCategory = category
            chatViewController?.performSegue(withIdentifier: "ShowQuiz", sender: nil)
        case .setChatStartOption(let option):
            chatViewController?.friend.chatStartOption = option
        case .upgradeFriendWithLastName(let lastName):
            if let friend = user.friendWithLastName(lastName) {
                friend.upgrade()
            }
        case .upgradeAndStartChatForFriendWithLastName(let lastName):
            if let friend = user.friendWithLastName(lastName) {
                friend.upgrade()
                friend.startChat()
            }
        case .startGame:
            if let chatViewController = chatViewController {
                chatViewController.startGame()
            }
        case .askForNotificationPermission:
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
                if error != nil { print("Something went wrong.") }
            }
        default:
            break
        }
    }
}
