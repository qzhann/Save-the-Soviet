//
//  QuizViewController.swift
//  Uncommon Application
//
//  Created by qizihan  on 12/21/18.
//  Copyright © 2018 qzhann. All rights reserved.
//

import UIKit

class QuizViewController: UIViewController {
    
    @IBOutlet weak var curvedEdgeBackgroundView: UIView!
    
    @IBOutlet weak var questionCategoryLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    
    @IBOutlet weak var answerButton1: UIButton!
    @IBOutlet weak var answerButton2: UIButton!
    @IBOutlet weak var answerButton3: UIButton!
    @IBOutlet weak var answerButton4: UIButton!
    
    @IBOutlet weak var answerCorrectnessImageView1: UIImageView!
    @IBOutlet weak var answerCorrectnessImageView2: UIImageView!
    @IBOutlet weak var answerCorrectnessImageView3: UIImageView!
    @IBOutlet weak var answerCorrectnessImageView4: UIImageView!
    
    // Need to be passed by segue
    var quizLevel: Int = 0
    var totalGrade: Int = 0
    
    var quiz = Quiz()
    
    // The index of the button corresponding to the right answer of currentQuestion
    var correctButton = UIButton()
    var correctAnswerImageView = UIImageView()
    
    // Store the original size of the background View
    var originalBackgroundFrames: CGRect?
    
    // Functions inside viewWillAppear will still operate the second time the view controller appears
    override func viewWillAppear(_ animated: Bool) {
        
        // Initialize a quiz with quizLevel
        quiz = Quiz(ofDifficulty: quizLevel)
        expandBackgroundView()
        updateUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prepare the views
        configureRoundCorners()
        resetAllViews()
        
        // updateUI with animation
        updateUI()
        
        
        
    }
    
    func configureRoundCorners() {
        // Background view round corners
        curvedEdgeBackgroundView.layer.cornerRadius = CGFloat(25)
        curvedEdgeBackgroundView.clipsToBounds = true
        curvedEdgeBackgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        // Answer button semi-circle corners
        let answerButtons = [answerButton1, answerButton2, answerButton3, answerButton4]
        for button in answerButtons {
            button?.layer.cornerRadius = (button?.frame.height)! / 2
            button?.clipsToBounds = true
        }
        
        let imageViews = [answerCorrectnessImageView1, answerCorrectnessImageView2, answerCorrectnessImageView3, answerCorrectnessImageView4]
        for imageView in imageViews {
            imageView?.layer.cornerRadius = (imageView?.frame.height)! / 2
            imageView?.clipsToBounds = true
        }
        
    }
    
    func resetAllViews() {
        let answerButtons = [answerButton1, answerButton2, answerButton3, answerButton4]
        let imageViews = [answerCorrectnessImageView1, answerCorrectnessImageView2, answerCorrectnessImageView3, answerCorrectnessImageView4]
        
        // Hide buttons
        for button in answerButtons {
            button?.isHidden = true
            button?.alpha = 0.0
            button?.isEnabled = false
        }
        
        // Hide Answer Correctness Image View
        for imageView in imageViews {
            imageView?.isHidden = true
        }
        
        // Hide question label
        questionLabel.alpha = 0.0
    }
    
    func updateUI() {
        let answerButtons = [answerButton1, answerButton2, answerButton3, answerButton4]
        let imageViews = [answerCorrectnessImageView1, answerCorrectnessImageView2, answerCorrectnessImageView3, answerCorrectnessImageView4]
        
        guard let question = quiz.currentQuestion else { return }
        
        // Reset UI
        resetAllViews()
        
        // Set category and question label
        questionCategoryLabel.text = question.category
        questionLabel.text = question.text
        
        // Set Answer button titles
        for index in answerButtons.indices {
            let answerText = question.answers[index]
            answerButtons[index]?.setTitle(answerText, for: .normal)
            
            // Set correctButton
            if answerText == question.correctAnswer {
                correctButton = answerButtons[index]!
                correctAnswerImageView = imageViews[index]!
            }
            
        }
        
        // Animate UI
        animateLabelsAndButtons()
        
    }
    
    func nextQuestion() {
        if quiz.currentQuestion != nil {
            updateUI()
        } else {
            foldBackgroundView()
        }
    }

    func animateLabelsAndButtons() {
        
        let answerButtons = [answerButton1, answerButton2, answerButton3, answerButton4]
        
    //: - Animate Category Label
        
        // Set category label to the leftmost position
        let prepareCategoryLabel = CGAffineTransform(translationX: -70, y: 0)
        // Set category label to the rightmost position
        let categoryLabelDisappear = CGAffineTransform(translationX: 100, y: 0)
        
        // Category Label Animation
        UIView.animate(withDuration: 0, delay: 0, options:[], animations: {
            // Prepare category label
            self.questionCategoryLabel.transform = prepareCategoryLabel
            self.questionCategoryLabel.alpha = 0.0
        }) { (_) in
            // Reveal category label
            UIView.animate(withDuration: 1, delay: 0.5, options: [], animations: {
                self.questionCategoryLabel.transform = .identity
                self.questionCategoryLabel.alpha = 1.0
            }, completion: { (_) in
                // Make category label disappear
                UIView.animate(withDuration: 1, delay: 0.5, options:[], animations: {
                    self.questionCategoryLabel.transform = categoryLabelDisappear
                    self.questionCategoryLabel.alpha = 0.0
                }, completion: nil)
            })
        }
        
    //: - Animate Question Label
        
        UIView.animate(withDuration: 0.5, delay: 3.0, options: [], animations: {
            self.questionLabel.alpha = 1.0
        }, completion: nil)
        
    //: - Animate Answer Buttons
        
        UIView.animate(withDuration: 0.5, delay: 4.0, options: [], animations: {
            for button in answerButtons {
                button?.isHidden = false
                button?.alpha = 1.0
            }
        }) { (_) in
            for button in answerButtons {
                button?.isEnabled = true
            }
        }

    }
    
    func foldBackgroundView() {
        
        // Set the frame the backgroundView should change into
        let backgroundX = curvedEdgeBackgroundView.frame.minX
        let backgroundY = curvedEdgeBackgroundView.frame.minY
        let backgroundWidth = curvedEdgeBackgroundView.frame.width
        let backgroundHeight = curvedEdgeBackgroundView.frame.height
        let screenHeight = self.view.bounds.height
        
        let frameZero = CGRect(x: backgroundX, y: screenHeight, width: backgroundWidth, height: 0)
        originalBackgroundFrames = CGRect(x: backgroundX, y: backgroundY, width: backgroundWidth, height: backgroundHeight)
        
        // Animate the change
        UIView.animate(withDuration: 1.0, animations: {
            self.curvedEdgeBackgroundView.frame = frameZero
        }) { (_) in
            // MARK: Performs segue after the animation completes
            self.performSegue(withIdentifier: "ShowQuizResults", sender: nil)
        }
    }
    
    func expandBackgroundView() {
        guard let originalBackgroundFrames = originalBackgroundFrames else { return }
        
        UIView.animate(withDuration: 1.0) {
            self.curvedEdgeBackgroundView.frame = originalBackgroundFrames
        }
    }
    
    @IBAction func answerButtonTapped(_ sender: UIButton) {

        let answerButtons = [answerButton1, answerButton2, answerButton3, answerButton4]
        var unusedButtons = [UIButton]()
        var usedButtons = [UIButton]()
        let correctness = quiz.answeredCorrectly(with: sender.title(for: .normal)!)
        var answerCorrectnessImageView = UIImageView()
        
        // Set the selected answerCorrectness Image View
        switch sender {
        case answerButton1:
            answerCorrectnessImageView = answerCorrectnessImageView1
        case answerButton2:
            answerCorrectnessImageView = answerCorrectnessImageView2
        case answerButton3:
            answerCorrectnessImageView = answerCorrectnessImageView3
        default:
            answerCorrectnessImageView = answerCorrectnessImageView4
        }
        
        // Reveal Answer Correctness Image for chosen button
        answerCorrectnessImageView.isHidden = false
        answerCorrectnessImageView.alpha = 1.0
        answerCorrectnessImageView.image =  correctness ? UIImage(named: "AnswerCorrect") : UIImage(named: "AnswerWrong")
        
        // Reveal Answer Correctness image for correct button
        if sender != self.correctButton {
            correctAnswerImageView.isHidden = false
            correctAnswerImageView.alpha = 1.0
            correctAnswerImageView.image = UIImage(named: "AnswerCorrect")
            
            // Shake Wrong Answer Button
            let shakeButtonRight = CGAffineTransform(translationX: -5, y: 0)
            UIView.animate(withDuration: 0.1, delay: 0, options:[], animations: {
                sender.transform = shakeButtonRight
            }) { (_) in
                sender.transform = .identity
            }
        }
        
        // Check which buttons should disappear first
        for button in answerButtons {
            if (button != sender) && (button != correctButton) {
                unusedButtons.append(button!)
            } else {
                usedButtons.append(button!)
            }
        }
        
        // Make unused buttons and image views disappear
        UIView.animate(withDuration: 0.5, animations: {
            for button in unusedButtons {
                button.alpha = 0.0
            }
        }, completion: nil)
        
        // Make used buttons disapppear after a short delay
        UIView.animate(withDuration: 1.0, delay: 1.0, options:[], animations: {
            for button in usedButtons {
                button.alpha = 0.0
                answerCorrectnessImageView.alpha = 0.0
                self.correctAnswerImageView.alpha = 0.0
                self.questionLabel.alpha = 0.0
            }
        }) { (_) in
            self.quiz.nextQuestion()
            self.nextQuestion()
        }
        
        
        
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        // Pass information to QuizResultViewController
        if segue.identifier == "ShowQuizResults" {
            let quizResultViewController = segue.destination as! QuizResultViewController
            quizResultViewController.quizLevel = quizLevel
            quizResultViewController.totalGrade = totalGrade
            quizResultViewController.addGrade = quiz.addGrade
            quizResultViewController.correct = quiz.correct
            quizResultViewController.responseBonus = quiz.responseBonus
        }
    }
    
    @IBAction func unwindToQuizViewController(unwindSegue: UIStoryboardSegue) {
        
        // Pass information back to self
        if unwindSegue.identifier == "UnwindToQuiz" {
            let quizResultViewController = unwindSegue.source as! QuizResultViewController
            quizLevel = quizResultViewController.quizLevel
            totalGrade = quizResultViewController.quizLevel
        }
    }


}