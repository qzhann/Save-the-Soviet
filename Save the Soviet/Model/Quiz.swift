//
//  Quiz.swift
//  Uncommon Application
//
//  Created by qizihan  on 12/20/18.
//  Copyright © 2018 qzhann. All rights reserved.
//

import Foundation

/// Holds the QuizQuestions used during a quiz.
class Quiz {
    
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
    init(ofDifficulty difficulty: Int, category: QuizQuestionCategory? = nil) {
        // Difficulty does not go beyond range
        var currentDifficulty = difficulty
        if difficulty > QuizQuestion.allPossibleQuizQuestions.count - 1 {
            currentDifficulty = QuizQuestion.allPossibleQuizQuestions.count - 1
        }
        
        questions = []
        
        if let category = category {
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

enum QuizQuestionCategory: String, CaseIterable {
    /// Factutal questions
    case facts = "Facts"
    /// Historic questions
    case history = "History"
    /// Nuclear questions
    case nuclear = "Nuclear"
    /// Crisis handling questions
    case crisis = "Crisis"
    /// Questions that are in the form of making decisions.
    case decision = "Decision"
    
    static var random: QuizQuestionCategory {
        return self.allCases.randomElement()!
    }
}

// MARK: -

struct QuizQuestion {
    
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
        return (11 - level) * 5
    }
    /// Experience that will be subtracted from user level if question is answered wrongly
    var minusExperience: Int {
        return level * 2
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
    
    static var allPossibleQuizQuestions: [Int: [QuizQuestionCategory: [QuizQuestion]]] = [
        1: [
            .facts: [],
            .history: [],
            .nuclear: [],
            .crisis: [],
            .decision: []
        ],
        2: [
            .facts: [],
            .history: [],
            .nuclear: [],
            .crisis: [],
            .decision: []
        ],
        3: [
            .facts: [],
            .history: [],
            .nuclear: [],
            .crisis: [],
            .decision: []
        ],
    ]
}
