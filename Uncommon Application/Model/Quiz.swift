//
//  Quiz.swift
//  Uncommon Application
//
//  Created by qizihan  on 12/20/18.
//  Copyright © 2018 qzhann. All rights reserved.
//

import Foundation

class Quiz {
// Instance properties
    var questions: [QuizQuestion] = []
    var currentQuestion: QuizQuestion? {
        return questions.first
    }
    
    var correct: Double = 0
    
    var responseBonus: Int = 0
    
    var addGrade: Int = 0
    
// Initializers
    // Default initializer
    init() {}
    
    init(ofDifficulty: Int) {
        // If ofDiffculty exceeds the bounds of the array, set it to highest difficulty
        let difficulty = ofDifficulty > QuizQuestion.allQuizQuestions.count - 1 ? QuizQuestion.allQuizQuestions.count - 1 : ofDifficulty
        
        // Add random questions of this difficulty to questions array
        for index in 0 ..< 5 {
            questions.append(QuizQuestion.allQuizQuestions[difficulty].randomElement()!)
            questions[index].answers.shuffle()
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
    func answeredCorrectly(with answer: String) -> Bool {
        guard currentQuestion != nil else { return false }
        if currentQuestion!.correctAnswer == answer {
            correct += 1
            addGrade += currentQuestion!.addGrade
            responseBonus += Int(currentQuestion!.remainingTime)
            return true
        } else {
            addGrade -= currentQuestion!.minusGrade
        }
        
        return false
    }
    
}

// TODO: Remember to implement the countdown in each QuizQuestion

struct QuizQuestion {
// Instance properties
    var difficultyLevel: Int = 0
    
    var category: String = "Default"
    var text: String = "Default Question"
    var answers: [String] = ["Default1", "Default2", "Default3", "Default4"]
    var correctAnswer: String = "Default1"
    
    var remainingTime: TimeInterval = 10.0
    var addGrade: Int = 10
    var minusGrade: Int = 0
    
// Initializer
    init(difficultyLevel: Int, category: String, text: String, answers: [String], correctAnswer: String, remainingTime: TimeInterval, addGrade: Int) {
        self.difficultyLevel = difficultyLevel
        self.category = category
        self.text = text
        self.answers = answers
        self.correctAnswer = correctAnswer
        self.remainingTime = remainingTime
        self.addGrade = addGrade
    }
    
// Type variable
    static var allQuizQuestions: [[QuizQuestion]] = questions // Need to implement!
}

// FIXME: Temporary code

let level0Questions: [QuizQuestion] = [
    QuizQuestion(difficultyLevel: 0, category: "Mathematics", text: "How much is cos(2π)?", answers: ["1/2", "-1/2", "1", "-1"], correctAnswer: "1", remainingTime: 5.0, addGrade: 10),
    QuizQuestion(difficultyLevel: 0, category: "Mathematics", text: "How much is sin(2π)?", answers: ["1/2", "-1/2", "0", "-1"], correctAnswer: "0", remainingTime: 5.0, addGrade: 10),
    QuizQuestion(difficultyLevel: 0, category: "Mathematics", text: "How much is cos(π)?", answers: ["1/2", "-1/2", "1", "-1"], correctAnswer: "-1", remainingTime: 5.0, addGrade: 10),
    QuizQuestion(difficultyLevel: 0, category: "Mathematics", text: "How much is sin(π)?", answers: ["1/2", "0", "1", "-1"], correctAnswer: "0", remainingTime: 5.0, addGrade: 10),
    QuizQuestion(difficultyLevel: 0, category: "Mathematics", text: "How much is cos(π/2)?", answers: ["1/2", "-1/2", "1", "0"], correctAnswer: "0", remainingTime: 5.0, addGrade: 10),
    QuizQuestion(difficultyLevel: 0, category: "Mathematics", text: "How much is sin(π/2)?", answers: ["1/2", "-1/2", "1", "-1"], correctAnswer: "1", remainingTime: 5.0, addGrade: 10),
]

let level1Questions: [QuizQuestion] = [
    QuizQuestion(difficultyLevel: 1, category: "History", text: "Who is the 1st president of the US?", answers: ["George Washington", "John Adams", "Thomas Jefferson", "James Madison"], correctAnswer: "George Washington", remainingTime: 2.0, addGrade: 10),
    QuizQuestion(difficultyLevel: 1, category: "History", text: "Who is the 2nd president of the US?", answers: ["George Washington", "John Adams", "Thomas Jefferson", "James Madison"], correctAnswer: "John Adams", remainingTime: 2.0, addGrade: 10),
    QuizQuestion(difficultyLevel: 1, category: "History", text: "Who is the 3rd president of the US?", answers: ["George Washington", "John Adams", "Thomas Jefferson", "James Madison"], correctAnswer: "Thomas Jefferson", remainingTime: 2.0, addGrade: 10),
    QuizQuestion(difficultyLevel: 1, category: "History", text: "Who is the 4th president of the US?", answers: ["George Washington", "John Adams", "Thomas Jefferson", "James Madison"], correctAnswer: "James Madison", remainingTime: 2.0, addGrade: 10),
]

let level2Questions: [QuizQuestion] = [
    QuizQuestion(difficultyLevel: 2, category: "Chemistry", text: "What is the 1st element on the periodic table?", answers: ["Hydrogen", "Helium", "Lithium", "Beryllium"], correctAnswer: "Hydrogen", remainingTime: 3.0, addGrade: 10),
    QuizQuestion(difficultyLevel: 2, category: "Chemistry", text: "What is the 2nd element on the periodic table?", answers: ["Hydrogen", "Helium", "Lithium", "Beryllium"], correctAnswer: "Helium", remainingTime: 3.0, addGrade: 10),
    QuizQuestion(difficultyLevel: 2, category: "Chemistry", text: "What is the 3rd element on the periodic table?", answers: ["Hydrogen", "Helium", "Lithium", "Beryllium"], correctAnswer: "Lithium", remainingTime: 3.0, addGrade: 10),
    QuizQuestion(difficultyLevel: 2, category: "Chemistry", text: "What is the 4th element on the periodic table?", answers: ["Hydrogen", "Helium", "Lithium", "Beryllium"], correctAnswer: "Beryllium", remainingTime: 3.0, addGrade: 10),
]

let questions = [level0Questions, level1Questions, level2Questions]
