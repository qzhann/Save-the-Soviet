//
//  ConfirmationViewController.swift
//  Uncommon Application
//
//  Created by qizihan  on 6/12/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class ConfirmationViewController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    unowned var user: User!
    var consequence: Consequence!
    var consequenceController: ConsequenceController!
    unowned var confirmationDelegate: ConfirmationDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        consequenceController = ConsequenceController(for: User.currentUser, confirmationViewController: self)
    }
    
    override func viewDidLayoutSubviews() {
        prepareUI()
    }
    
    // - MARK: Instance methods
    
    func prepareUI() {
        guard let consequence = consequence else { return }
        
        // Configure round corners
        backgroundView.layer.cornerRadius = 15
        backgroundView.clipsToBounds = true
        confirmButton.layer.cornerRadius = confirmButton.frame.height / 2
        confirmButton.clipsToBounds = true
        
        // Set texts
        switch consequence {
        case .upgradePower(let power):
            if consequenceController.canHandle(consequence) {
                textLabel.text = "Upgrade for \(power.coinsNeeded) coins?"
                confirmButton.setTitle("OK", for: .normal)
                cancelButton.setTitle("Cancel", for: .normal)
            } else {
                textLabel.text = "Not enough coins :("
                confirmButton.setTitle("OK...", for: .normal)
                cancelButton.setTitle("Cancel", for: .normal)
            }
        case .deleteFriend(let friend):
            textLabel.text = "Execute \(friend.shortName) ?"
            confirmButton.setTitle("Yes", for: .normal)
            cancelButton.setTitle("Maybe not.", for: .normal)
        default:
            break
        }
        
    }
    
    
    // MARK: - IB actions
    
    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        consequenceController.handle(consequence)
        confirmationDelegate?.didConfirm = true
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func backgroundTapped(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "UnwindToMain" {
            let mainViewController = segue.destination as! MainViewController
            mainViewController.deletedIndexPath = sender as? IndexPath
        }
    }

}
