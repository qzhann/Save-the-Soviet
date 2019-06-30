//
//  PageSheetModalDismissalAnimationController.swift
//  Uncommon Application
//
//  Created by qizihan  on 5/14/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class PageSheetModalDismissalAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    var darkenEffect: CGFloat
    
    init(darkenBy darkenEffect: CGFloat) {
        self.darkenEffect = darkenEffect
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let sourceViewController = transitionContext.viewController(forKey: .from), let destinationViewController = transitionContext.viewController(forKey: .to) else { return }
        
        // Add a dark blur effect view to the destinationViewController's view, intially blurred and dark
        let blurEffect = UIBlurEffect(style: .dark)
        let darkBlurEffectView = UIVisualEffectView(effect: blurEffect)
        darkBlurEffectView.frame = destinationViewController.view.frame
        darkBlurEffectView.backgroundColor = UIColor.black.withAlphaComponent(darkenEffect)
        destinationViewController.view.addSubview(darkBlurEffectView)
        
        // Insert destinationViewController's view to the container at the bottom
        transitionContext.containerView.insertSubview(destinationViewController.view, at: 0)
        
        // Remove the blurred background of the snapshot of the destinationViewController added during presentation transition
        sourceViewController.view.subviews[0].removeFromSuperview()
        
        
        let duration = transitionDuration(using: transitionContext)
        
        // Create a UIViewPropertyAnimator to animate the disappearance of the dark blur effect
        let darkBlurEffectAnimator = UIViewPropertyAnimator(duration: 0.25, curve: .easeOut) {
            darkBlurEffectView.effect = nil
            darkBlurEffectView.backgroundColor = UIColor.black.withAlphaComponent(0)
        }
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            
            // Shift the sourceViewController's view outside the screen, making it invisible
            sourceViewController.view.transform = CGAffineTransform(translationX: 0, y: sourceViewController.view.frame.height)
            sourceViewController.view.alpha = 0
            
            // Make the dark blur effect disappear
            darkBlurEffectAnimator.startAnimation()
        }) { (_) in
            
            // Remove sourceViewController's view from the container
            sourceViewController.view.removeFromSuperview()
            
            // Remove the darkBlurEffectView from destinationViewController's view
            darkBlurEffectView.removeFromSuperview()
            
            // Inform the transition context to complete the transition
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
}
