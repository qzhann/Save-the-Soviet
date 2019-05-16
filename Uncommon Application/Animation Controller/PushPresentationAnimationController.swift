//
//  PushPresentationAnimationController.swift
//  Uncommon Application
//
//  Created by qizihan  on 5/15/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class PushPresentationAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let sourceView = transitionContext.view(forKey: .from), let destinationView = transitionContext.view(forKey: .to) else { return }
        
        let containerView = transitionContext.containerView
        
        // Add sourceView to the container
        containerView.addSubview(sourceView)
        
        // Add destinationView to the container, intially outside the screen to the right
        containerView.addSubview(destinationView)
        destinationView.transform = CGAffineTransform(translationX: destinationView.frame.width, y: 0)
        
        // Add shadow for destinationView
        destinationView.layer.shadowColor = UIColor.black.cgColor
        destinationView.layer.shadowOpacity = 0.1
        destinationView.layer.shadowOffset = .zero
        destinationView.layer.shadowRadius = 4
        
        let duration = transitionDuration(using: transitionContext)
        
        // Animate the shadow on destinationView during transition
        let shadowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        shadowAnimation.fromValue = 0.1
        shadowAnimation.toValue = 0.8
        shadowAnimation.duration = duration
        destinationView.layer.add(shadowAnimation, forKey: shadowAnimation.keyPath)
        
        // Animate the shift of both destinationView and sourceView using the system springTimingParameters
        let springTimingProvider: UITimingCurveProvider = UISpringTimingParameters()
        
        let horizontalTranslationAnimator = UIViewPropertyAnimator(duration: duration, timingParameters: springTimingProvider)
        
        horizontalTranslationAnimator.addAnimations {
            destinationView.transform = .identity
            sourceView.transform = CGAffineTransform(translationX: -sourceView.frame.width / 3, y: 0)
        }
        
        // Shift the sourceView back in place and remove it from the container upon animation completion
        horizontalTranslationAnimator.addCompletion { (_) in
            // Rmoeve sourceView from the container
            sourceView.transform = .identity
            sourceView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        horizontalTranslationAnimator.startAnimation()
    }
    
}
