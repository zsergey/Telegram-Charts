//
//  UIColorExtensions.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/11/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

extension UIColor {
    
    convenience init?(hex: String, alpha: CGFloat = 1.0) {
        var string = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if string.hasPrefix("#") {
            string.remove(at: string.startIndex)
        }
        
        if string.count != 6 {
            return nil
        }
        
        var rgbValue: UInt32 = 0
        Scanner(string: string).scanHexInt32(&rgbValue)
        
        let redValue = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let greenValue = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blueValue = CGFloat(rgbValue & 0x0000FF) / 255.0
        self.init(red: redValue, green: greenValue, blue: blueValue, alpha: alpha)
    }
    
    func gradient(to color: UIColor, step: CGFloat) -> UIColor {
        var red1: CGFloat = 0
        var green1: CGFloat = 0
        var blue1: CGFloat = 0
        var alpha1: CGFloat = 0
        getRed(&red1, green: &green1, blue: &blue1, alpha: &alpha1)
        
        var red2: CGFloat = 0
        var green2: CGFloat = 0
        var blue2: CGFloat = 0
        var alpha2: CGFloat = 0
        color.getRed(&red2, green: &green2, blue: &blue2, alpha: &alpha2)
        
        let red3 = red1 - (red1 - red2) * step
        let green3 = green1 - (green1 - green2) * step
        let blue3 = blue1 - (blue1 - blue2) * step
        return UIColor(red: red3, green: green3, blue: blue3, alpha: 1)
    }
    
    var blackShadow: UIColor {
        return gradient(to: .black, step: 0.15)
    }
    
    var whiteShadow: UIColor {
        return gradient(to: .white, step: 0.15)
    }

}
