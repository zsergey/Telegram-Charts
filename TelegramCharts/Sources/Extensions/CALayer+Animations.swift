//
//  CALayer+Animations.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/18/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

extension CALayer {
    
    func moveTo(point: CGPoint, animationDuration: CFTimeInterval) {
        if animationDuration == 0 {
            self.position = point
        } else {
            let animation = CABasicAnimation(keyPath: "position")
            animation.fromValue = value(forKey: "position")
            animation.toValue = NSValue(cgPoint: point)
            animation.duration = animationDuration
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            add(animation, forKey: "position")
            self.position = point
        }
    }
    
    func changeOpacity(from fromValue: Float, to toValue: Float,
                       animationDuration: CFTimeInterval) {
        if animationDuration == 0 {
            self.opacity = toValue
        } else {
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = fromValue
            animation.toValue = toValue
            animation.duration = animationDuration
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.add(animation, forKey: "opacity")
            self.opacity = toValue
        }
    }

}


