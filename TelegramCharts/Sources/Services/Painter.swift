//
//  Painter.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/24/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct Painter {
    
    static func createRectPath(rect: CGRect, byRoundingCorners corners: UIRectCorner = [], cornerRadius: CGFloat = 0.0) -> UIBezierPath {
        let cornerRadii = CGSize(width: cornerRadius, height: cornerRadius)
        if corners == [] {
            let path = UIBezierPath(rect: rect)
            return path
        } else {
            let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: cornerRadii)
            return path
        }
    }
    
    @discardableResult
    static func createRect(rect: CGRect, byRoundingCorners corners: UIRectCorner = [],
                          strokeColor: UIColor = UIColor.clear, fillColor: UIColor = UIColor.clear,
                          lineWidth: CGFloat = 2.0, cornerRadius: CGFloat = 0.0) -> CAShapeLayer {
        let path = createRectPath(rect: rect, byRoundingCorners: corners, cornerRadius: cornerRadius)
        let rect = CAShapeLayer()
        rect.path = path.cgPath
        rect.strokeColor = strokeColor.cgColor
        rect.fillColor = fillColor.cgColor
        rect.lineWidth = lineWidth
        return rect
    }
    
    static func createText(textColor: UIColor, bold: Bool = false) -> CATextLayer{
        let textLayer = CATextLayer()
        textLayer.foregroundColor = textColor.cgColor
        textLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.contentsScale = UIScreen.main.scale
        let font = CTFontCreateWithName(UIFont.systemFont(ofSize: 0).fontName as CFString, 0, nil)
        if bold {
            let boldFont = CTFontCreateCopyWithSymbolicTraits(font, 0.0, nil, .boldTrait, .boldTrait)
            textLayer.font = boldFont
        } else {
            textLayer.font = font
        }
        textLayer.fontSize = 12
        return textLayer
    }
}
