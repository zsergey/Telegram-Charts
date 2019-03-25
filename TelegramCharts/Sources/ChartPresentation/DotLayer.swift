//
//  DotLayer.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/11/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class DotLayer: CALayer {

    var innerRadius: CGFloat = 6
    var dotInnerColor = UIColor.black { didSet { setNeedsLayout() } }

    private var innerDotLayer: CALayer?
    
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
        
        let inset = self.bounds.size.width - innerRadius
        let dotFrame = self.bounds.insetBy(dx: inset / 2, dy: inset / 2)
        
        if let innerDotLayer = self.innerDotLayer {
            innerDotLayer.frame = dotFrame
            innerDotLayer.backgroundColor = dotInnerColor.cgColor
            innerDotLayer.cornerRadius = innerRadius / 2
        } else {
            let innerDotLayer = CALayer()
            innerDotLayer.frame = dotFrame
            innerDotLayer.backgroundColor = dotInnerColor.cgColor
            innerDotLayer.cornerRadius = innerRadius / 2
            self.addSublayer(innerDotLayer)
            self.innerDotLayer = innerDotLayer
        }
    }

}
