//
//  ValueLayer.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/18/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ValueLayer: CALayer {
    
    var lineValue: Int = 0 { didSet { setNeedsLayout() } }
    var lineColor: UIColor = .gray { didSet { setNeedsLayout() } }
    var textColor: UIColor = .black { didSet { setNeedsLayout() } }
    
    override init() {
        super.init()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.strokeColor = lineColor.cgColor
        lineLayer.lineWidth = 0.5
        addSublayer(lineLayer)
        
        let textLayer = CATextLayer()
        textLayer.frame = CGRect(x: 4, y: height - 16, width: 50, height: 16)
        textLayer.foregroundColor = textColor.cgColor
        textLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.font = CTFontCreateWithName(UIFont.systemFont(ofSize: 0).fontName as CFString, 0, nil)
        textLayer.fontSize = 12
        textLayer.string = lineValue.format
        addSublayer(textLayer)
    }

}
