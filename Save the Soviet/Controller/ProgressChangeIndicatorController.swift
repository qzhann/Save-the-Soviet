//
//  ProgressChangeIndicatorController.swift
//  Save the Soviet
//
//  Created by qizihan  on 7/12/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

/// Helps manage progress change indicators.
struct ProgressChangeIndicatorController {
    
    // MARK: Instance properties
    var animationDistance: CGFloat
    
    // MARK: - Initializers
    init(withAnimationDistance distance: CGFloat) {
        self.animationDistance = distance
    }
    
    // MARK: - Instance methods
    
    /// Animates the designated progress change indicator view for some distance.
    func animate(view: UIView, forChange change: Int) {
        var animation: CGAffineTransform!
        if change > 0 {
            // Make it rise from the bar
            view.transform = CGAffineTransform(translationX: 0, y: animationDistance)
            animation = CGAffineTransform(translationX: 0, y: -animationDistance)
        } else if change < 0 {
            animation = CGAffineTransform(translationX: 0, y: animationDistance)
        } else {
            animation = CGAffineTransform(translationX: 0, y: 0)
        }
        
        let appearAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .linear) {
            view.alpha = 1
        }
        let translateAnimator = UIViewPropertyAnimator(duration: 1, curve: .easeOut) {
            view.transform = animation
        }
        let disappearAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .linear) {
            view.alpha = 0
        }
        translateAnimator.addCompletion { (_) in
            disappearAnimator.startAnimation()
        }
        
        disappearAnimator.addCompletion { (_) in
            view.transform = .identity
        }
        
        appearAnimator.startAnimation()
        translateAnimator.startAnimation()
    }
}
