//
//  ConsequenceController.swift
//  Uncommon Application
//
//  Created by qizihan  on 6/13/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import Foundation

struct ConsequenceController {
    
    // MARK: Instance properties
    
    unowned let user: User
    unowned var confirmationController: ConfirmationViewController?
    
    
    // MARK: - Initializers
    
    init(for user: User, confirmationViewController: ConfirmationViewController? = nil) {
        self.user = user
        self.confirmationController = confirmationViewController
    }
    
    func canHandle(_ consequence: Consequence) -> Bool {
        switch consequence {
        case .upgradePower(let power):
            return user.coins >= power.coinsNeeded
        case .deleteFriend(_):
            return true
        default:
            return false
        }
    }
    
    func handle(_ consequence: Consequence) {
        switch consequence {
        case .upgradePower(let power):
            guard canHandle(consequence) == true else { return }
            user.upgradePower(power)
            confirmationController?.dismiss(animated: true, completion: nil)
        case .deleteFriend(let friend):
            user.friends.removeAll { $0 === friend }
            confirmationController?.performSegue(withIdentifier: "UnwindToMain", sender: nil)
        default:
            break
        }
    }
}
