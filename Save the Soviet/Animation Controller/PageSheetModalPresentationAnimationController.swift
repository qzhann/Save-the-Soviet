//
//  PageSheetModalPresentationAnimationController.swift
//  Uncommon Application
//
//  Created by qizihan  on 5/14/19.
//  Copyright © 2019 qzhann. All rights reserved.
//

import UIKit

class PageSheetModalPresentationAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    var darkenEffect: CGFloat
    
    init(darkenBy darkenEffect: CGFloat) {
        self.darkenEffect = darkenEffect
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let sourceViewController = transitionContext.viewController(forKey: .from), let destinationViewController = transitionContext.viewController(forKey: .to), let sourceVCSnapshot = sourceViewController.view.snapshotView(afterScreenUpdates: false) else { return }
        
        // Add a blur effect view to sourceVCSnapshot, initially no blur and clear color
        let darkBlurEffectView = UIVisualEffectView(effect: nil)
        darkBlurEffectView.frame = sourceVCSnapshot.frame
        darkBlurEffectView.backgroundColor = UIColor.black.withAlphaComponent(0)
        sourceVCSnapshot.addSubview(darkBlurEffectView)
        
        // Add sourceVCSnapshot to the container
        transitionContext.containerView.addSubview(sourceVCSnapshot)
        
        // Add destinationViewController's view to the container, initially invisible
        transitionContext.containerView.addSubview(destinationViewController.view)
        
        // Shift the destinationViewController's view outside the screen before the transition, initially invisible
        destinationViewController.view.transform = CGAffineTransform(translationX: 0, y: destinationViewController.view.frame.height)
        destinationViewController.view.alpha = 0
        
        
        let duration = transitionDuration(using: transitionContext)
        
        // Create a UIViewPropertyAnimator which animates the dark blur effect
        let darkBlurEffectAnimator = UIViewPropertyAnimator(duration: 0.28, curve: .easeIn) {
            darkBlurEffectView.effect = UIBlurEffect(style: .dark)
            darkBlurEffectView.backgroundColor = UIColor.black.withAlphaComponent(self.darkenEffect)
        }
        
        // Animate the transition
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 5, options: .curveEaseOut, animations: {
            
            // Transform destinationViewController's view to the center and make it visible
            destinationViewController.view.transform = .identity
            destinationViewController.view.alpha = 1
            
            // Animate the dark blur effect
            darkBlurEffectAnimator.startAnimation()
        }) { (_) in
            
            // Remove sourceVCSnapshot from the container
            sourceVCSnapshot.removeFromSuperview()
            
            // Insert the sourceVCSnapshot as the background view of destinationViewController
            destinationViewController.view.insertSubview(sourceVCSnapshot, at: 0)
            
            // Inform the transition context to complete the transition
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
    }
    
}
