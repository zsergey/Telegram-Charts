//
//  UIImageExtensions.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 4/13/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

extension UIImage {    
    static func from(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
