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
    /// Questions from all categories, generated randomly
    case all = "All"
    
    static var random: QuizQuestionCategory {
        return [.facts, .nuclear].randomElement()!
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
    var responseTime: Int {
        let time = text.count / 20
        if time < 5 {
            return 5
        } else {
            return time
        }
    }
    
    
    // MARK: - Initializers
    
    /// Full initializer
    init(level: Int, category: QuizQuestionCategory, text: String, answers: [String], correctAnswer: String) {
        self.level = level
        self.category = category
        self.text = text
        self.answers = answers
        self.correctAnswer = correctAnswer
    }
    
    // MARK: - Static properties
    static func allFactsQuestions(ofLevel level: Int) -> [QuizQuestion] {
        return [
            QuizQuestion(level: level, category: .facts, text: "Of the following countries, which one is NOT a permanent member of the United Nations Security Council?", answers: ["Great Britain", "USA", "France", "Israel"], correctAnswer: "Israel"),
            QuizQuestion(level: level, category: .facts, text: "What is the main goal of the Truman Doctrine?", answers: ["to send financial aid to Europe", "to expand trade with Europe", "to limit nuclear weapons", "to stop the spread of communism"], correctAnswer: "to stop the spread of communism"),
            QuizQuestion(level: level, category: .facts, text: "Where is the city of Berlin?", answers: ["USSR", "East Germany", "West Germany", "a neutral zone"], correctAnswer: "East Germany"),
            QuizQuestion(level: level, category: .facts, text: "Which of the following alliances was formed to block communism in Europe?", answers: ["the Warsaw Pact", "SEATO", "NATO", "CENTO"], correctAnswer: "NATO"),
            QuizQuestion(level: level, category: .facts, text: "Which of the following organizations is a trade organization?", answers: ["EEC", "CENTO", "SEATO", "NATO"], correctAnswer: "EEC"),
            QuizQuestion(level: level, category: .facts, text: "What launch started the space race between the U.S. and the Soviet Union?", answers: ["Vostok", "Sputnik I", "Telstar", "Apollo II"], correctAnswer: "Sputnik I"),
            QuizQuestion(level: level, category: .facts, text: "Who wanted to use atomic bombs to end the Korean War?", answers: ["Dwight D. Eisenhower", "Douglas MacArthur", "George Marshall", "Harry S Truman"], correctAnswer: "Douglas MacArthur"),
            QuizQuestion(level: level, category: .facts, text: "What was the outcome of the Korean War?", answers: ["deadlock, or draw", "atomic destruction of Chinese bases", "victory for the United States", "victory for North Korea"], correctAnswer: "deadlock, or draw"),
            QuizQuestion(level: level, category: .facts, text: "Who controlled North Vietnam after the Geneva Accords?", answers: ["Mao Zedong", "Ho Chi Minh", "Deng Xiaoping", "Chiang Kai-shek"], correctAnswer: "Ho Chi Minh"),
            QuizQuestion(level: level, category: .facts, text: "Who is the leader of Cuba?", answers: ["Richard M. Nixon", "Fidel Castro", "John F. Kennedy", "You, Mikhail Gorbachev"], correctAnswer: "Fidel Castro"),
            QuizQuestion(level: level, category: .facts, text: "Which of the following words is a term for an administrative subdivision within the Soviet Union?", answers: ["Alley", "Oblast", "Ruble", "Izvestiya"], correctAnswer: "Alley"),
            QuizQuestion(level: level, category: .facts, text: "At which location in Moscow does USSR showcase military might with massive parades?", answers: ["Nevsky Prospekt", "Ulitsa Sezam", "Red Square", "Gorky Park"], correctAnswer: "Red Square"),
            QuizQuestion(level: level, category: .facts, text: "What was the name of the group of communists who founded the Soviet Union?", answers: ["Samizdat", "Spetsnaz", "Boksheviks", "Mensheviks"], correctAnswer: "Boksheviks"),
            QuizQuestion(level: level, category: .facts, text: "What term is used in the Soviet Union for a communist party bureaucrat?", answers: ["Hooligan", "Apparatchik", "Kulak", "Okhrana"], correctAnswer: "Apparatchik"),
            QuizQuestion(level: level, category: .facts, text: "What is the meaning of the word Tovarishch?", answers: ["Senator", "Cossack", "Lord", "Comerade"], correctAnswer: "Comerade"),
            QuizQuestion(level: level, category: .facts, text: "What symbol appears on the flag of the Soviet Union?", answers: ["Hammer and sickle", "Arm and hammer", "Rising sun", "Crescent moon"], correctAnswer: "Hammer and sickle"),
            QuizQuestion(level: level, category: .facts, text: "What is the main focus of the Soviet Five Year Plans?", answers: ["Imperialism", "Economic development", "Ethnic assimilation", "Communist indoctrination"], correctAnswer: "Economic development"),
            QuizQuestion(level: level, category: .facts, text: "Which Soviet woman was the first woman in space?", answers: ["Valentina Tereshkova", "Ekaterina Gordeeva", "Faina Melnyk", "Vera Figner"], correctAnswer: "Valentina Tereshkova"),
        ]
    }
    
    static func allNuclearQuestions(ofLevel level: Int) -> [QuizQuestion] {
        return [
            QuizQuestion(level: level, category: .nuclear, text: "According to The Standard Model, all that exists is composed of two varieties of fundamental particles. What are the commonplace, prosaic names given to these two categories of particles?", answers: ["Matter particles and force particles", "Leptons and Bosons", "Pions and Muons", "Quarks and electrons"], correctAnswer: "Matter particles and force particles"),
            QuizQuestion(level: level, category: .nuclear, text: "There are six quarks, and they have been named up, down, top, bottom, charm and strange. What do we call the particles that quarks combine to form?", answers: ["Muons", "Bosons", "Hadrons", "Neutrinos"], correctAnswer: "Hadrons"),
            QuizQuestion(level: level, category: .nuclear, text: "The six leptons come in two kinds, charged and uncharged. There are three varieties of charged leptons, each with a corresponding neutrino. Which of the following is not a charged lepton?", answers: ["Neutron", "Muon", "Tau", "Electron"], correctAnswer: "Neutron"),
            QuizQuestion(level: level, category: .nuclear, text: "According to The Standard Model, all the forces in nature result from some combination of three types of interactions. Which of the following is not one of the three fundamental interaction types?", answers: ["Gravity", "Electroweak", "Strong", "Friction"], correctAnswer: "Friction"),
            QuizQuestion(level: level, category: .nuclear, text: " The Standard Model accounts for particle interactions on the basis of exchanges of force particles. In the case of electromagnetic interactions, which force particle is exchanged?", answers: ["Photon", "Neutrino", "Electron", "Gluon"], correctAnswer: "Photon"),
            QuizQuestion(level: level, category: .nuclear, text: "The positive charges of the quarks within protons in atomic nuclei repel one another, and yet the strong force glues them together. What is the force particle exchanged in strong force interactions within the proton?", answers: ["Graviton", "Pion", "Meson", "Gluon"], correctAnswer: "Gluon"),
            QuizQuestion(level: level, category: .nuclear, text: "When particles decay, it is the electroweak force that is involved. Which of the following particles is not a mediator of the electroweak force?", answers: ["Z", "Z+", "W+", "W-"], correctAnswer: "Z+"),
            QuizQuestion(level: level, category: .nuclear, text: "How many nuclear power plants does Soviet Union have?", answers: ["5", "10", "20", "30"], correctAnswer: "20"),
            QuizQuestion(level: level, category: .nuclear, text: "Which nuclear power plant is the oldest?", answers: ["Armenian Plant", "Leningrad Plant", "F-1", "Kola Plant"], correctAnswer: "F-1"),
            QuizQuestion(level: level, category: .nuclear, text: "What type of reactors are constructed in Vladimir Llyich Lenin Nuclear Power Plant?", answers: ["RBMK-1000", "RBMK-2000", "RBMK-3000", "RBMK-1989"], correctAnswer: "RBMK-1000"),
            QuizQuestion(level: level, category: .nuclear, text: "Did any accident occur in any nuclear power plants in USSR?", answers: ["Yes, and we addressed all of them safely.", "Yes, and we covered all of them up.", "No, because they are all really safe.", "No, because regulations prevented them."], correctAnswer: "Yes, and we covered all of them up."),
            QuizQuestion(level: level, category: .nuclear, text: "The nuclear power plant in the city of Pripyat is also known as?", answers: ["Chernobyl", "RBMK-1000", "Kursk", "F-1"], correctAnswer: "Chernobyl"),
        ]
    }
    
    static var allPossibleQuizQuestions: [Int: [QuizQuestionCategory: [QuizQuestion]]] = [
        1: [
            .facts: [
                QuizQuestion(level: 1, category: .facts, text: "Which title corresponds to the job of Boris Shcherbina?", answers: ["Minister of Energy", "Minister of Oil", "Head of Energy Department", "Minister of Energy and Oil"], correctAnswer: "Minister of Energy and Oil"),
                QuizQuestion(level: 1, category: .facts, text: "The core technology in RBMK nuclear reactor is devised by whom?", answers: ["Boris Shcherbina", "Soviet Scientists", "American Scientists", "German Scientists",], correctAnswer: "Soviet Scientists"),
                QuizQuestion(level: 1, category: .facts, text: "What happened to the energy production in USSR in the last few years?", answers: ["Increased Drastically", "Increased Steadily", "Decreased Drastically", "No Change"], correctAnswer: "Increased Steadily"),
                QuizQuestion(level: 1, category: .facts, text: "What does Minister Shcherbina say about the safety of RBMK reactors?", answers: ["Very safe", "Unsure", "Dangerous", "Moderate"], correctAnswer: "Very safe"),
                QuizQuestion(level: 1, category: .facts, text: "How is your support calculated?", answers: ["Averages loyalty of everyone", "Calculated independently", "Proportional to the level progress", "Randomized"], correctAnswer: "Averages loyalty of everyone")
            ],
            .nuclear: [
                QuizQuestion(level: 1, category: .nuclear, text: "How many nuclear power plants does Soviet Union have?", answers: ["5", "10", "20", "30"], correctAnswer: "20"),
                QuizQuestion(level: 1, category: .nuclear, text: "Which nuclear power plant is the oldest?", answers: ["Armenian Plant", "Leningrad Plant", "F-1", "Kola Plant"], correctAnswer: "F-1"),
                QuizQuestion(level: 1, category: .nuclear, text: "What type of reactors are constructed in Vladimir Llyich Lenin Nuclear Power Plant?", answers: ["RBMK-1000", "RBMK-2000", "RBMK-3000", "RBMK-1989"], correctAnswer: "RBMK-1000"),
                QuizQuestion(level: 1, category: .nuclear, text: "The nuclear power plant in the city of Pripyat is also known as?", answers: ["Chernobyl", "RBMK-1000", "Kursk", "F-1"], correctAnswer: "Chernobyl"),
                QuizQuestion(level: 1, category: .nuclear, text: "According to The Standard Model, all that exists is composed of two varieties of fundamental particles. What are the commonplace, prosaic names given to these two categories of particles?", answers: ["Matter particles and force particles", "Leptons and Bosons", "Pions and Muons", "Quarks and electrons"], correctAnswer: "Matter particles and force particles"),
                QuizQuestion(level: 1, category: .nuclear, text: "There are six quarks, and they have been named up, down, top, bottom, charm and strange. What do we call the particles that quarks combine to form?", answers: ["Muons", "Bosons", "Hadrons", "Neutrinos"], correctAnswer: "Hadrons"),
                QuizQuestion(level: 1, category: .nuclear, text: "The six leptons come in two kinds, charged and uncharged. There are three varieties of charged leptons, each with a corresponding neutrino. Which of the following is not a charged lepton?", answers: ["Neutron", "Muon", "Tau", "Electron"], correctAnswer: "Neutron"),
                QuizQuestion(level: 1, category: .nuclear, text: "According to The Standard Model, all the forces in nature result from some combination of three types of interactions. Which of the following is not one of the three fundamental interaction types?", answers: ["Gravity", "Electroweak", "Strong", "Friction"], correctAnswer: "Friction"),
                QuizQuestion(level: 1, category: .nuclear, text: " The Standard Model accounts for particle interactions on the basis of exchanges of force particles. In the case of electromagnetic interactions, which force particle is exchanged?", answers: ["Photon", "Neutrino", "Electron", "Gluon"], correctAnswer: "Photon"),
                QuizQuestion(level: 1, category: .nuclear, text: "The positive charges of the quarks within protons in atomic nuclei repel one another, and yet the strong force glues them together. What is the force particle exchanged in strong force interactions within the proton?", answers: ["Graviton", "Pion", "Meson", "Gluon"], correctAnswer: "Gluon"),
                QuizQuestion(level: 1, category: .nuclear, text: "When particles decay, it is the electroweak force that is involved. Which of the following particles is not a mediator of the electroweak force?", answers: ["Z", "Z+", "W+", "W-"], correctAnswer: "Z+"),
                QuizQuestion(level: 1, category: .nuclear, text: "How many nuclear power plants does Soviet Union have?", answers: ["5", "10", "20", "30"], correctAnswer: "20"),
                QuizQuestion(level: 1, category: .nuclear, text: "Which nuclear power plant is the oldest?", answers: ["Armenian Plant", "Leningrad Plant", "F-1", "Kola Plant"], correctAnswer: "F-1"),
                QuizQuestion(level: 1, category: .nuclear, text: "What type of reactors are constructed in Vladimir Llyich Lenin Nuclear Power Plant?", answers: ["RBMK-1000", "RBMK-2000", "RBMK-3000", "RBMK-1989"], correctAnswer: "RBMK-1000"),
                QuizQuestion(level: 1, category: .nuclear, text: "The nuclear power plant in the city of Pripyat is also known as?", answers: ["Chernobyl", "RBMK-1000", "Kursk", "F-1"], correctAnswer: "Chernobyl")
            ]
        ],
        2: [
            .facts: QuizQuestion.allFactsQuestions(ofLevel: 2),
            .nuclear: QuizQuestion.allNuclearQuestions(ofLevel: 2)
        ],
        3: [
            .facts: QuizQuestion.allFactsQuestions(ofLevel: 3),
            .nuclear: QuizQuestion.allNuclearQuestions(ofLevel: 3)
        ],
        4: [
            .facts: QuizQuestion.allFactsQuestions(ofLevel: 4),
            .nuclear: QuizQuestion.allNuclearQuestions(ofLevel: 4)
        ],
        5: [
            .facts: QuizQuestion.allFactsQuestions(ofLevel: 5),
            .nuclear: QuizQuestion.allNuclearQuestions(ofLevel: 5)
        ],
        6: [
            .facts: QuizQuestion.allFactsQuestions(ofLevel: 6),
            .nuclear: QuizQuestion.allNuclearQuestions(ofLevel: 6)
        ],
        7: [
            .facts: QuizQuestion.allFactsQuestions(ofLevel: 7),
            .nuclear: QuizQuestion.allNuclearQuestions(ofLevel: 7)
        ],
        8: [
            .facts: QuizQuestion.allFactsQuestions(ofLevel: 8),
            .nuclear: QuizQuestion.allNuclearQuestions(ofLevel: 8)
        ],
        9: [
            .facts: QuizQuestion.allFactsQuestions(ofLevel: 9),
            .nuclear: QuizQuestion.allNuclearQuestions(ofLevel: 9)
        ],
        10: [
            .facts: QuizQuestion.allFactsQuestions(ofLevel: 10),
            .nuclear: QuizQuestion.allNuclearQuestions(ofLevel: 10)
        ]
    ]
}
