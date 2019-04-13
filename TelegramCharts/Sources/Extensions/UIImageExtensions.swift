//
//  UIImageExtensions.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 4/13/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

extension UIImage {
    convenience init?(size: CGSize, gradientColor: [UIColor]) {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColor.map({ $0.cgColor }) as CFArray, locations: nil) else {
            return nil
        }
        
        context.drawLinearGradient(gradient, start: CGPoint.zero, end: CGPoint(x: 0, y: size.height), options: CGGradientDrawingOptions())
        guard let image = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else { return nil }
        self.init(cgImage: image)
        defer { UIGraphicsEndImageContext() }
    }
}
