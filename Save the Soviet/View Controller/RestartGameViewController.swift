//
//  RestartGameViewController.swift
//  Uncommon Application
//
//  Created by qizihan  on 6/26/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class RestartGameViewController: UIViewController {
    
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var starImageView: UIImageView!
    @IBOutlet weak var restartButton: UIButton!
    
    var win = false

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    override func viewDidLayoutSubviews() {
        configureRoundCorners()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        animateStarImageView()
    }
    
    func configureRoundCorners() {
        imageView.layer.cornerRadius = imageView.frame.height / 2
        imageView.clipsToBounds = true
        restartButton.layer.cornerRadius = 10
        restartButton.clipsToBounds = true
    }
    
    func updateUI() {
        restartButton.titleEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        
        if win == true {
            textLabel.text = "The Soviet Union is saved under your leadership."
            imageView.image = UIImage(named: "GameWin")
            restartButton.setTitle("Play Again!", for: .normal)
            starImageView.alpha = 0
            starImageView.transform = CGAffineTransform(translationX: 0, y: 20)
        } else {
            textLabel.text = "The Soviet Union collapsed."
            imageView.image = UIImage(named: "GameOver")
            restartButton.setTitle("Try Again", for: .normal)
            starImageView.alpha = 1
        }
    }
    
    func animateStarImageView() {
        if win == true {
            UIView.animate(withDuration: 3, delay: 0, options: .curveEaseInOut, animations: {
                self.starImageView.transform = .identity
                self.starImageView.alpha = 1
            })
        } else {
            UIView.animate(withDuration: 3, delay: 0, options: .curveEaseInOut, animations: {
                self.starImageView.transform = CGAffineTransform(translationX: 0, y: 20)
                self.starImageView.alpha = 0
            })
        }
    }
    
    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        // FIXME: Restart the game.
        dismiss(animated: true, completion: nil)
    }

}
