//
//  Quiz.swift
//  Uncommon Application
//
//  Created by qizihan  on 12/20/18.
//  Copyright © 2018 qzhann. All rights reserved.
//

import Foundation

/// Holds the QuizQuestions used during a quiz.
class Quiz: Codable {
    
    // MARK: Instance properties
    
    /// Questions left to answer
    var questions: [QuizQuestion]
    /// The question about to be answered. Quiz session should end when this turns nil.
    var currentQuestion: QuizQuestion? {
        get {
            return questions.first
        }
        
    }
    /// Tracks the number of correctly answered questions
    var correct: Double = 0
    /// Tracks the response bonuses of the correctly answered questions
    var responseBonus: Int = 0
    /// Tracks the grade that should be added
    var experienceChange: Int = 0
    
    // MARK: - Initializers
    
    /// Initialize a Quiz using difficulty and category. If category is nil, randomly select category and questions inside the categories from that difficulty.
    init(ofDifficulty difficulty: Int, category: QuizQuestionCategory) {
        // Difficulty does not go beyond range
        var currentDifficulty = difficulty
        if difficulty > QuizQuestion.allPossibleQuizQuestions.count - 1 {
            currentDifficulty = QuizQuestion.allPossibleQuizQuestions.count - 1
        }
        
        questions = []
        
        if category != .all {
            // Add random questions of the category at current difficulty
            for index in 0 ..< 5 {
                questions.append((QuizQuestion.allPossibleQuizQuestions[currentDifficulty]?[category]?.randomElement())!)
                questions[index].answers.shuffle()
            }
        } else {
            // Add random questions of random category at current difficulty
            for index in 0 ..< 5 {
                questions.append((QuizQuestion.allPossibleQuizQuestions[currentDifficulty]?[QuizQuestionCategory.random]?.randomElement())!)
                questions[index].answers.shuffle()
            }
        }
        
        
    }
    
    // Instance methods
    func nextQuestion() {
        if questions.isEmpty == false {
             questions.removeFirst()
        }
    }
    

    // Check if selected answer is correct. If correct, add one to count.
    // For updateUI, check if we answered correctly and update the indication images on the choice buttons. DO NOT add to correct AGAIN.
    func answeredCorrectly(with answer: String, for time: Int) -> Bool {
        guard currentQuestion != nil else { return false }
        if currentQuestion!.correctAnswer == answer {
            correct += 1
            experienceChange += currentQuestion!.addExperience
            responseBonus += time
            return true
        } else {
            experienceChange -= currentQuestion!.minusExperience
        }
        
        return false
    }
    
    
    
}

// MARK: -

enum QuizQuestionCategory: String, CaseIterable, Codable {
    /// Factutal questions
    case facts = "Facts"
    /// Nuclear questions
    case nuclear = "Nuclear"
    /// Crisis handling questions
    case crisis = "Crisis"
    /// Questions from all categories, generated randomly
    case all = "All"
    
    static var random: QuizQuestionCategory {
        return [.facts, .nuclear, .crisis].randomElement()!
    }
}

// MARK: -

struct QuizQuestion: Codable {
    
    // MARK: Instance properties
    
    /// Level of the question, ranging from 1 to 10, inclusive, corresponding to the user's level
    var level: Int
    /// The category of the question
    var category: QuizQuestionCategory
    /// The category of the question represented in string, used to display before each question appears.
    var categoryString: String {
        return category.rawValue
    }
    /// The text string of the question
    var text: String
    /// The multiple choices of answers to the question
    var answers: [String]
    /// The correct answer string to the question
    var correctAnswer: String
    /// Experience that will be added to user level if question is answered correctly
    var addExperience: Int {
        return (11 - level)
    }
    /// Experience that will be subtracted from user level if question is answered wrongly
    var minusExperience: Int {
        return level
    }
    /// The time for the user to respond
    var responseTime: Int
    
    
    // MARK: - Initializers
    
    /// Full initializer
    init(level: Int, category: QuizQuestionCategory, text: String, answers: [String], correctAnswer: String, responseTime: Int) {
        self.level = level
        self.category = category
        self.text = text
        self.answers = answers
        self.correctAnswer = correctAnswer
        self.responseTime = responseTime
    }
    
    // MARK: - Static properties
    static var testQuizQuestion = QuizQuestion(level: 1, category: .facts, text: "Yo", answers: ["Yo1", "Yo2", "Yo3", "Yo4"], correctAnswer: "Yo1", responseTime: 5)
    
    static var allPossibleQuizQuestions: [Int: [QuizQuestionCategory: [QuizQuestion]]] = [
        1: [
            .facts: [
                QuizQuestion(level: 1, category: .facts, text: "Which title corresponds to the job of Boris Shcherbina?", answers: ["Minister of Energy", "Minister of Oil", "Head of Energy Department", "Minister of Energy and Oil"], correctAnswer: "Minister of Energy and Oil", responseTime: 5),
                QuizQuestion(level: 1, category: .facts, text: "The core technology in RBMK nuclear reactor is devised by whom?", answers: ["Boris Shcherbina", "Soviet Scientists", "American Scientists", "German Scientists",], correctAnswer: "Soviet Scientists", responseTime: 5),
                QuizQuestion(level: 1, category: .facts, text: "What happened to the energy production in USSR in the last few years?", answers: ["Increased Drastically", "Increased Steadily", "Decreased Drastically", "No Change"], correctAnswer: "Increased Steadily", responseTime: 5),
                QuizQuestion(level: 1, category: .facts, text: "What does Minister Shcherbina say about the safety of RBMK reactors?", answers: ["Very safe", "Unsure", "Dangerous", "Moderate"], correctAnswer: "Very safe", responseTime: 5),
                QuizQuestion(level: 1, category: .facts, text: "How is your support calculated?", answers: ["Averages loyalty of everyone", "Calculated independently", "Proportional to the level progress", "Randomized"], correctAnswer: "Averages loyalty of everyone", responseTime: 8)
            ],
            .nuclear: [
                QuizQuestion(level: 1, category: .nuclear, text: "How many nuclear power plants does Soviet Union have?", answers: ["5", "10", "20", "30"], correctAnswer: "20", responseTime: 5),
                QuizQuestion(level: 1, category: .nuclear, text: "Which nuclear power plant is the oldest?", answers: ["Armenian Plant", "Leningrad Plant", "F-1", "Kola Plant"], correctAnswer: "F-1", responseTime: 5),
                QuizQuestion(level: 1, category: .nuclear, text: "What type of reactors are constructed in Vladimir Llyich Lenin Nuclear Power Plant?", answers: ["RBMK-1000", "RBMK-2000", "RBMK-3000", "RBMK-1989"], correctAnswer: "RBMK-1000", responseTime: 5),
                QuizQuestion(level: 1, category: .nuclear, text: "Did any accident occur in any nuclear power plants in USSR?", answers: ["Yes, and we addressed all of them safely.", "Yes, and we covered all of them up.", "No, because they are all really safe.", "No, because regulations prevented them."], correctAnswer: "Yes, and we covered all of them up.", responseTime: 5),
                QuizQuestion(level: 1, category: .nuclear, text: "The nuclear power plant in the city of Pripyat is also known as?", answers: ["Chernobyl", "RBMK-1000", "Kursk", "F-1"], correctAnswer: "Chernobyl", responseTime: 5),
            ],
            .crisis: [QuizQuestion.testQuizQuestion],
        ],
        2: [
            .facts: [QuizQuestion.testQuizQuestion],
            .nuclear: [QuizQuestion.testQuizQuestion],
            .crisis: [QuizQuestion.testQuizQuestion],
        ],
        3: [
            .facts: [QuizQuestion.testQuizQuestion],
            .nuclear: [QuizQuestion.testQuizQuestion],
            .crisis: [QuizQuestion.testQuizQuestion],
        ],
    ]
}
