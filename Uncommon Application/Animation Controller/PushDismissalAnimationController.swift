//
//  PushDismissalAnimationController.swift
//  Uncommon Application
//
//  Created by qizihan  on 5/16/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class PushDismissalAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let sourceView = transitionContext.view(forKey: .from), let destinationView = transitionContext.view(forKey: .to) else { return }
        
        let container = transitionContext.containerView
        
        // Insert destinationView to the container, intially shifted to the right
        container.insertSubview(destinationView, at: 0)
        destinationView.transform = CGAffineTransform(translationX: -destinationView.frame.width / 3, y: 0)
        
        // Add sourceView to the container
        container.addSubview(sourceView)
        
        let duration = transitionDuration(using: transitionContext)
        
        // Add shadow for sourceView
        sourceView.layer.shadowColor = UIColor.black.cgColor
        sourceView.layer.shadowOpacity = 0.8
        sourceView.layer.shadowOffset = .zero
        sourceView.layer.shadowRadius = 4
        
        // Animate the shadow on sourceView during transition
        let shadowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        shadowAnimation.fromValue = 0.8
        shadowAnimation.toValue = 0.1
        shadowAnimation.duration = duration
        sourceView.layer.add(shadowAnimation, forKey: shadowAnimation.keyPath)
        
        // Animate the shift of both sourceView and destinationView using the system springTimingParameters
        let springTimingProvider: UITimingCurveProvider = UISpringTimingParameters()
        
        let horizontalTranslationAnimation = UIViewPropertyAnimator(duration: duration, timingParameters: springTimingProvider)
        
        horizontalTranslationAnimation.addAnimations {
            sourceView.transform = CGAffineTransform(translationX: sourceView.frame.width, y: 0)
            destinationView.transform = .identity
        }
        
        //  Remove the sourceView from the container upon animation completion
        horizontalTranslationAnimation.addCompletion { (_) in
            sourceView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        horizontalTranslationAnimation.startAnimation()
    }
}
