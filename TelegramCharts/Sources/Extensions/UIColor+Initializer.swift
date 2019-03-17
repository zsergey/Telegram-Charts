//
//  UIColor+Initializer.swift
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
    
}
