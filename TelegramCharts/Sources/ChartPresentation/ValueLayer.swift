//
//  ValueLayer.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/18/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ValueLayer: CALayer {
    
    enum Alignment {
        case left
        case right
    }
    
    var fixedTextColor: Bool = false

    var isZeroLine: Bool = false

    var lineValue: Int = 0 { didSet { setNeedsLayout() } }
    var lineColor: UIColor = .gray
    var textColor: UIColor = .black
    var alignment: Alignment = .left
    var contentBackground: UIColor = .white

    var textLayer: CATextLayer?
    
    let trailingSpace: CGFloat = 16
    
    let leadingSpace: CGFloat = 16

    override init() {
        super.init()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateColors(lineColor: UIColor, background: UIColor, textColor: UIColor) {
        backgroundColor = lineColor.cgColor
        if !fixedTextColor {
            textLayer?.foregroundColor = textColor.cgColor
        }
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        
        backgroundColor = lineColor.cgColor

        if let textLayer = textLayer {
            if lineValue == 0, !isZeroLine {
                textLayer.string = ""
            } else {
                textLayer.string = lineValue.format
            }
        } else {
            let textLayer = Painter.createText(textColor: textColor)
            textLayer.string = lineValue.format
            var x: CGFloat = 0
            if alignment == .right {
                x = frame.size.width - textLayer.preferredFrameSize().width
            }
            let height: CGFloat = 0
            textLayer.frame = CGRect(x: x, y: height - 18, width: 50, height: 16)
            addSublayer(textLayer)
            self.textLayer = textLayer
        }
        
    }
}
