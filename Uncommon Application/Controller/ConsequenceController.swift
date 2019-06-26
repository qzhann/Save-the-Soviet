//
//  ConsequenceController.swift
//  Uncommon Application
//
//  Created by qizihan  on 6/13/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

struct ConsequenceController {
    
    // MARK: Instance properties
    
    unowned let user: User
    unowned var confirmationController: ConfirmationViewController?
    unowned var viewController: UIViewController?
    
    
    // MARK: - Initializers
    
    init(for user: User = User.currentUser, viewController: UIViewController? = nil) {
        self.user = user
        self.viewController = viewController
    }
    
    init(for user: User = User.currentUser, confirmationViewController: ConfirmationViewController? = nil) {
        self.user = user
        self.confirmationController = confirmationViewController
    }
    
    
    func canHandle(_ consequence: Consequence) -> Bool {
        switch consequence {
        case .upgradePower(let power):
            return user.coins >= power.coinsNeeded
        default:
            return true
        }
    }
    
    func handle(_ consequence: Consequence) {
        switch consequence {
        case .endChatFrom(let direction):
            if let chatViewController = viewController as? ChatViewController {
                chatViewController.endChatFrom(direction, withDelay: 0)
            }
        case .makeNewFriend(let friend):
            break
        case .deleteFriend(let friend):
            let row = user.friends.firstIndex(of: friend)!
            user.friends.remove(at: row)
            let indexPath = IndexPath(row: row, section: 0)
            confirmationController?.performSegue(withIdentifier: "UnwindToMain", sender: indexPath)
        case .changeLevelProgressBy(let change):
            user.changeLevelProgressBy(change)
        case .changeEnergyProgressBy(let change):
            user.changeEnergyProgressBy(change)
        case .changeFriendshipProgressBy(let change, for: let friend):
            friend.changeFriendshipProgressBy(change)
        case .upgradePower(let power):
            guard canHandle(consequence) == true else { return }
            user.upgradePower(power)
            confirmationController?.dismiss(animated: true, completion: nil)
        
        case .startQuiz:
            if let chatViewController = viewController as? ChatViewController {
                chatViewController.performSegue(withIdentifier: "StartQuiz", sender: nil)
            }
        default:
            break
        }
    }
}
