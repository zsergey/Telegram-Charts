//
//  BgTextLayer.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 4/14/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class BgTextLayer: CATextLayer {
    override func draw(in ctx: CGContext) {
        if isOpaque, let bgCGColor = backgroundColor {
            ctx.setFillColor(bgCGColor)
            ctx.addRect(CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height))
            ctx.fillPath()
        }
        
        super.draw(in: ctx)
    }
    
    override var string: Any? {
        didSet {
            let width = preferredFrameSize().width
            frame = CGRect(x: frame.origin.x, y: frame.origin.y,
                           width: width, height: frame.size.height)
        }
    }
}
