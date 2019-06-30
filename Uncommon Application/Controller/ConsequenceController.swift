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
                chatViewController.performSegue(withIdentifier: "ShowNewFriend", sender: nil)
            }
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
            chatViewController?.performSegue(withIdentifier: "ShowQuiz", sender: nil)
        default:
            break
        }
    }
}
