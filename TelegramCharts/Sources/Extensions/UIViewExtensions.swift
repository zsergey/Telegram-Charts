//
//  UIViewExtensions.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/24/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

extension UIView {

    static var animationDuration: CFTimeInterval = 0.3

    static func animateEaseInOut(with duration: CFTimeInterval,
                                 animations: @escaping () -> ()) {
        UIView.animate(withDuration: duration, delay: 0,
                       options: [.curveEaseInOut],
                       animations: animations, completion: nil)
    }

}
