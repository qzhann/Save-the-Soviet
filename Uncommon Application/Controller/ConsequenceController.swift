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
    
    // MARK: - Initializers
    init(for user: User) {
        self.user = user
    }
    
    func canHandle(_ consequence: Consequence) -> Bool {
        switch consequence {
        case .upgradeFriendPower(let power), .upgradeUserPower(let power):
            return user.coins >= power.coinsNeeded
        default:
            return false
        }
    }
    
    func handle(_ consequence: Consequence) {
        switch consequence {
        case .upgradeFriendPower(let power), .upgradeUserPower(let power):
            guard canHandle(consequence) == true else { return }
            user.upgradePower(power)
        default:
            break
        }
    }
}
