//
//  QuizResultViewController.swift
//  Uncommon Application
//
//  Created by 祁子涵 on 2018/12/28.
//  Copyright © 2018 qzhann. All rights reserved.
//

import UIKit

class QuizResultViewController: UIViewController {
    
    @IBOutlet weak var correctnessLabel: UILabel!
    @IBOutlet weak var plusSignLabel: UILabel!
    @IBOutlet weak var responseLabel: UILabel!
    @IBOutlet weak var equalSignLabel: UILabel!
    @IBOutlet weak var gradeLabel: UILabel!
    @IBOutlet weak var againButton: UIButton!
    @IBOutlet weak var nextTimeButton: UIButton!
    @IBOutlet weak var againImageView: UIImageView!
    
    // Need to be passed by segue, and quizLevel needs to be configured on the fly
    var progressChange: Int = 20
    var correct: Double = 4
    var responseBonus: Int = 50
    let total: Double = 5
    var consequenceController: ConsequenceController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        consequenceController = ConsequenceController(for: User.currentUser)

        // Prepare the views
        configureRoundCorners()
        resetAllViews()
        
        // updateUI with animation
        updateUI()

        // Handle grades
        handleGrades()
        
    }
    
    func configureRoundCorners() {
        againButton.layer.cornerRadius = againButton.frame.height / 2
        nextTimeButton.layer.cornerRadius = nextTimeButton.frame.height / 2
        againImageView.layer.cornerRadius = againImageView.frame.height / 2
        againButton.clipsToBounds = true
        nextTimeButton.clipsToBounds = true
        againImageView.clipsToBounds = true
        
        // Set the inset of the title labels to the center
        againButton.titleEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 0,right: 0)
        nextTimeButton.titleEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0,right: 0)
    }
    
    func resetAllViews() {
        let labels = [correctnessLabel, plusSignLabel, responseLabel, equalSignLabel, gradeLabel]
        
        // Hide labels
        for label in labels {
            label?.alpha = 0.0
        }
        
        // Hide Buttons and imageView
        againButton.isHidden = true
        nextTimeButton.isHidden = true
        againButton.alpha = 0.0
        nextTimeButton.alpha = 0.0
        againImageView.alpha = 0.0
    }
    
    func updateUI() {
        
        // Set correct contents
        correctnessLabel.text = "\(Int((correct / total) * 100))% Correctness"
        responseLabel.text = "Bonus + \(responseBonus)"
        
        let finalAddExperience = progressChange + responseBonus
        
        if finalAddExperience > 0 {
            gradeLabel.text = "Level + \(finalAddExperience) :)"
        } else if finalAddExperience < 0 {
            gradeLabel.text = "Level - \(abs(finalAddExperience)) :("
        } else {
            gradeLabel.text = "Level remained :|"
        }
        
        // AnimateUI
        animateLabelsAndButtons()
        
    }
    
    func handleGrades() {
        consequenceController.handle(.changeLevelProgressBy(progressChange + responseBonus))
    }
    
    func animateLabelsAndButtons() {
        
        let scale3x = CGAffineTransform(scaleX: 3, y: 3)

        // Prepare Grade Label
        gradeLabel.transform = scale3x

        // Animate Labels
        UIView.animate(withDuration: 0.8, delay: 1, animations: {
            self.correctnessLabel.alpha = 1.0
        }) { (_) in
            UIView.animate(withDuration: 0.8, animations: {
                self.plusSignLabel.alpha = 1.0
            }) { (_) in
                UIView.animate(withDuration: 0.8, animations: {
                    self.responseLabel.alpha = 1.0
                }) { (_) in
                    UIView.animate(withDuration: 0.8, animations: {
                        self.equalSignLabel.alpha = 1.0
                    }) { (_) in
                        UIView.animate(withDuration: 0.5, animations: {
                            self.gradeLabel.alpha = 1.0
                            self.gradeLabel.transform = .identity
                        }) { (_) in
                            
                            // Show buttons and imageView
                            UIView.animate(withDuration: 1.0, delay: 1.0, animations: {
                                self.againButton.isHidden = false
                                self.nextTimeButton.isHidden = false
                                
                                self.againButton.alpha = 1.0
                                self.againImageView.alpha = 1.0
                                self.nextTimeButton.alpha = 1.0
                            })

                        }
                    }
                }
            }
        }
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
