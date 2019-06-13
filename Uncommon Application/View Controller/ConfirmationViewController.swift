//
//  ConfirmationViewController.swift
//  Uncommon Application
//
//  Created by qizihan  on 6/12/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class ConfirmationViewController: UIViewController {
    
    @IBOutlet weak var roundedBackgroundView: UIView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    unowned var user: User!
    var consequence: Consequence!
    var consequenceController: ConsequenceController!

    override func viewDidLoad() {
        super.viewDidLoad()
        consequenceController = ConsequenceController(for: user, confirmationViewController: self)
    }
    
    override func viewDidLayoutSubviews() {
        prepareUI()
    }
    
    // - MARK: Instance methods
    
    func prepareUI() {
        guard let consequence = consequence else { return }
        
        // Configure round corners
        roundedBackgroundView.layer.cornerRadius = 15
        roundedBackgroundView.clipsToBounds = true
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
            textLabel.text = "Delete \(friend.name) ?"
            confirmButton.setTitle("Yes", for: .normal)
            cancelButton.setTitle("Maybe not.", for: .normal)
        default:
            break
        }
        
    }
    
    
    // MARK: - IB actions
    
    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        consequenceController.handle(consequence)
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func backgroundTapped(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Navigation
    
    /*

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
