//
//  FadeAnimationController.swift
//  Save the Soviet
//
//  Created by qizihan  on 7/16/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class FadeAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    var transitionDuration: TimeInterval
    
    init(withDuration duration: TimeInterval) {
        transitionDuration = duration
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let sourceView = transitionContext.view(forKey: .from), let destinationView = transitionContext.view(forKey: .to) else { return }
        
        let containerView = transitionContext.containerView
        
        // Add sourceView and destinationView to the container
        containerView.addSubview(sourceView)
        containerView.addSubview(destinationView)
        destinationView.alpha = 0
        
        let duration = transitionDuration(using: transitionContext)
        
        // Fade the views
        let fadeAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
            sourceView.alpha = 0
            destinationView.alpha = 1
        }
        
        // Restore the views and complete the transition
        fadeAnimator.addCompletion { (_) in
            sourceView.alpha = 1
            sourceView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        fadeAnimator.startAnimation()
    }
}
