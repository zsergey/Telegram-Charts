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
    
    var lineValue: Int = 0 { didSet { setNeedsLayout() } }
    var lineColor: UIColor = .gray
    var textColor: UIColor = .black
    var alignment: Alignment = .left
    var contentBackground: UIColor = .white

    var lineLayer: CAShapeLayer?
    var textLayer: CATextLayer?

    override init() {
        super.init()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateColors(lineColor: UIColor, textColor: UIColor, background: UIColor) {
        lineLayer?.strokeColor = lineColor.cgColor
        lineLayer?.fillColor = background.cgColor
        textLayer?.foregroundColor = textColor.cgColor
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let height: CGFloat = 0
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: frame.size.width, y: height))
        
        let lineLayer = CAShapeLayer()
        lineLayer.path = path.cgPath
        lineLayer.fillColor = contentBackground.cgColor
        lineLayer.strokeColor = lineColor.cgColor
        lineLayer.lineWidth = 0.5
        addSublayer(lineLayer)
        self.lineLayer = lineLayer
        
        let textLayer = Painter.createText(textColor: textColor)
        textLayer.string = lineValue.format
        var x: CGFloat = 0
        if alignment == .right {
            x = frame.size.width - textLayer.preferredFrameSize().width
        }
        textLayer.frame = CGRect(x: x, y: height - 18, width: 50, height: 16)
        addSublayer(textLayer)
        self.textLayer = textLayer
    }

}
