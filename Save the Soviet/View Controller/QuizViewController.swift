//
//  QuizViewController.swift
//  Uncommon Application
//
//  Created by qizihan  on 12/21/18.
//  Copyright © 2018 qzhann. All rights reserved.
//

import UIKit

class QuizViewController: UIViewController {
    
    // MARK: Instance variables
    
    var totalGrade: Int = 0
    var timer = Timer()
    var quiz: Quiz!
    var quizQuestionCategory: QuizQuestionCategory = .all
    var hasTimer = false
    var seconds = 5
    var user = User.currentUser
    unowned var levelProgressChangeIndicatorViewController: LevelProgressChangeIndicatorViewController!
    unowned var coinChangeIndicatorViewController: CoinChangeIndicatorViewController!
    var consequenceController: ConsequenceController!
    var progressChangeIndicatorController = ProgressChangeIndicatorController(withAnimationDistance: 5)
    
    /// The index of the button corresponding to the right answer of currentQuestion
    var correctButton = UIButton()
    var correctAnswerImageView = UIImageView()
    /// Store the original size of the background View
    var originalBackgroundFrames: CGRect?
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var coinChangeIndicatorView: UIView!
    @IBOutlet weak var curvedEdgeBackgroundView: UIView!
    
    @IBOutlet weak var questionCategoryLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var levelProgressChangeIndicatorView: UIView!
    
    @IBOutlet weak var answerButton1: UIButton!
    @IBOutlet weak var answerButton2: UIButton!
    @IBOutlet weak var answerButton3: UIButton!
    @IBOutlet weak var answerButton4: UIButton!
    
    @IBOutlet weak var answerCorrectnessImageView1: UIImageView!
    @IBOutlet weak var answerCorrectnessImageView2: UIImageView!
    @IBOutlet weak var answerCorrectnessImageView3: UIImageView!
    @IBOutlet weak var answerCorrectnessImageView4: UIImageView!
    
    
    // MARK: - Consequence visualization delegate
    
    func visualizeConsequence(_ consequence: Consequence) {
        switch consequence {
        case .changeUserLevelBy(let change):
            levelProgressChangeIndicatorViewController.configureUsing(change: change, style: .long)
            progressChangeIndicatorController.animate(view: levelProgressChangeIndicatorView, forChange: change)
        case .changeUserCoinsBy(let change):
            coinChangeIndicatorViewController.configureUsing(change: change, style: .longLight)
            progressChangeIndicatorController.animate(view: coinChangeIndicatorView, forChange: change)
        default:
            break
        }
    }
    
    
    // MARK: - View controller methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prepare the views
        configureRoundCorners()
        prepareUI()
        
        // Initialize consequence controller
        consequenceController = ConsequenceController(for: User.currentUser)
    }
    
    // Functions inside viewWillAppear will still operate the second time the view controller appears
    override func viewWillAppear(_ animated: Bool) {
        expandBackgroundView()
        
        // Initialize a quiz with quizLevel
        quiz = Quiz(ofDifficulty: user.level.levelNumber, category: quizQuestionCategory)
        
        // updateUI with animation
        updateUI()
    }
    
    
    // MARK: - Instance methods
    
    func configureRoundCorners() {
        // Background view round corners
        curvedEdgeBackgroundView.layer.cornerRadius = CGFloat(25)
        curvedEdgeBackgroundView.clipsToBounds = true
        curvedEdgeBackgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        // Answer button semi-circle corners
        let answerButtons = [answerButton1, answerButton2, answerButton3, answerButton4]
        for button in answerButtons {
            button?.layer.cornerRadius = 10
            button?.clipsToBounds = true
        }
        
        let imageViews = [answerCorrectnessImageView1, answerCorrectnessImageView2, answerCorrectnessImageView3, answerCorrectnessImageView4]
        for imageView in imageViews {
            imageView?.layer.cornerRadius = (imageView?.frame.height)! / 2
            imageView?.clipsToBounds = true
        }
        
    }
    
    func prepareUI() {
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
        
        // Hide question label and timer
        questionLabel.alpha = 0.0
        timerLabel.alpha = 0.0
        
        // Hide progress change indicators
        levelProgressChangeIndicatorView.alpha = 0
        coinChangeIndicatorView.alpha = 0
        
    }
    
    func updateUI() {
        let answerButtons = [answerButton1, answerButton2, answerButton3, answerButton4]
        let imageViews = [answerCorrectnessImageView1, answerCorrectnessImageView2, answerCorrectnessImageView3, answerCorrectnessImageView4]
        
        guard let question = quiz.currentQuestion else { return }
        
        // Reset UI
        prepareUI()
        
        // Set categoryString and question label
        questionCategoryLabel.text = question.categoryString
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
        
        animateLabelsAndButtons()
    }
    
    func nextQuestion() {
        timer.invalidate()
        seconds = 5
        hasTimer = false
        
        if quiz.currentQuestion != nil {
            updateUI()
        } else {
            foldBackgroundView()
        }
    }

    func animateLabelsAndButtons() {
        
        let answerButtons = [answerButton1, answerButton2, answerButton3, answerButton4]
        
    //: - Animate Category Label
        
        // Set categoryString label to the leftmost position
        let prepareCategoryLabel = CGAffineTransform(translationX: -70, y: 0)
        // Set categoryString label to the rightmost position
        let categoryLabelDisappear = CGAffineTransform(translationX: 100, y: 0)
        
        // Category Label Animation
        UIView.animate(withDuration: 0, delay: 0, options:[], animations: {
            // Prepare categoryString label
            self.questionCategoryLabel.transform = prepareCategoryLabel
            self.questionCategoryLabel.alpha = 0.0
        }) { (_) in
            // Reveal categoryString label
            UIView.animate(withDuration: 1, delay: 0.5, options: [], animations: {
                self.questionCategoryLabel.transform = .identity
                self.questionCategoryLabel.alpha = 1.0
            }, completion: { (_) in
                // Make categoryString label disappear
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
            self.seconds = self.quiz.currentQuestion!.responseTime
            self.timerLabel.text = "\(self.seconds)"
            self.runTimer()
            
            UIView.animate(withDuration: 0.3, delay: 0.8, options: [], animations: {
                self.timerLabel.alpha = 1
            }, completion: nil)
        }
    }
    
    func runTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (_) in
            self.updateTimer()
        }
        timer.tolerance = 0.2
    }
    
    func updateTimer() {
        if seconds == -1 {
            stopTimer()
            return
        }
        
        UIView.animate(withDuration: 0.15, animations: {
            self.timerLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { (_) in
            UIView.animate(withDuration: 0.15, animations: {
                self.timerLabel.transform = .identity
            }, completion: { (_) in
                
            })
        }
        timerLabel.text = "\(seconds)"
        seconds -= 1
    }
    
    func stopTimer() {
        timer.invalidate()
        
        let buttons = [answerButton1, answerButton2, answerButton3, answerButton4]
        
        UIView.animate(withDuration: 0.5, delay: 0.5, animations: {
            self.timerLabel.alpha = 0
            self.questionLabel.alpha = 0
            for button in buttons {
                button?.alpha = 0
                self.timerLabel.alpha = 0
            }
        }) { (_) in
            self.quiz.nextQuestion()
            self.nextQuestion()
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
            let chatViewController = self.presentingViewController as? ChatViewController
            // Performs segue after the animation completes
            self.dismiss(animated: true, completion: {
                chatViewController?.friend.startChat()
            })
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
        let timeRemaining = Int(timerLabel.text!)!
        let correctness = quiz.answeredCorrectly(with: sender.title(for: .normal)!, for: timeRemaining)
        var answerCorrectnessImageView = UIImageView()
        
        // Invalidate the timer
        timer.invalidate()
        UIView.animate(withDuration: 0.2, delay: 0.8, animations: {
            self.timerLabel.alpha = 0
        })
        
        let question = quiz.currentQuestion!
        
        // Visualize the consequence
        if correctness == true {
            // Handle the question consequences
            let answerConsequence: Consequence = .changeUserLevelBy(question.addExperience)
            let timeBonusConsequence: Consequence = .changeUserCoinsBy(timeRemaining)
            consequenceController.handle(answerConsequence)
            visualizeConsequence(answerConsequence)
            // Handle the time bonus consequences
            consequenceController.handle(timeBonusConsequence)
            visualizeConsequence(timeBonusConsequence)
        } else {
            // Handle the question consequences
            let answerConsequence: Consequence = .changeUserLevelBy(-question.minusExperience)
            consequenceController.handle(answerConsequence)
            visualizeConsequence(answerConsequence)
        }
        
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
            let shakeButtonLeft = CGAffineTransform(translationX: 5, y: 0)
            let shakeButtonRight = CGAffineTransform(translationX: -5, y: 0)
            UIView.animate(withDuration: 0.05, delay: 0, options:[], animations: {
                sender.transform = shakeButtonLeft
            }) { (_) in
                UIView.animate(withDuration: 0.05, animations: {
                    sender.transform = shakeButtonRight
                }) { (_) in
                    sender.transform = .identity
                }
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
        UIView.animate(withDuration: 0.5, delay: 1, options:[], animations: {
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
        if segue.identifier == "EmbedLevelProgressChangeIndicator" {
            let levelProgressChangeIndicatorViewController = segue.destination as! LevelProgressChangeIndicatorViewController
            self.levelProgressChangeIndicatorViewController = levelProgressChangeIndicatorViewController
        } else if segue.identifier == "EmbedCoinChangeIndicator" {
            let coinChangeIndicatorViewController = segue.destination as! CoinChangeIndicatorViewController
            self.coinChangeIndicatorViewController = coinChangeIndicatorViewController
        }
    }
    
    @IBAction func unwindToQuizViewController(unwindSegue: UIStoryboardSegue) {
    }


}
