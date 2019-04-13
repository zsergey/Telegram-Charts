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
    
    static let lineWidth: CGFloat = 0.5
    
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
    
    let trailingSpace: CGFloat = 16
    
    let leadingSpace: CGFloat = 16

    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateColors(lineColor: UIColor, background: UIColor, textColor: UIColor?) {
        lineLayer?.strokeColor = lineColor.cgColor
        lineLayer?.fillColor = background.cgColor
        if let textColor = textColor {
            textLayer?.foregroundColor = textColor.cgColor
        }
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let height: CGFloat = 0
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: trailingSpace, y: height))
        path.addLine(to: CGPoint(x: frame.size.width - leadingSpace, y: height))
        
        let lineLayer = CAShapeLayer()
        lineLayer.path = path.cgPath
        lineLayer.fillColor = contentBackground.cgColor
        lineLayer.strokeColor = lineColor.cgColor
        lineLayer.lineWidth = ValueLayer.lineWidth
        addSublayer(lineLayer)
        self.lineLayer = lineLayer
        
        let textLayer = Painter.createText(textColor: textColor)
        textLayer.string = lineValue.format
        var x: CGFloat = trailingSpace
        if alignment == .right {
            x = frame.size.width - textLayer.preferredFrameSize().width - leadingSpace
        }
        textLayer.frame = CGRect(x: x, y: height - 18, width: 50, height: 16)
        addSublayer(textLayer)
        self.textLayer = textLayer
    }

}
