//
//  StandardDrawingStyle.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/14/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct StandardDrawingStyle: DrawingStyleProtocol {
    
    var isCustomFillColor: Bool {
        return false
    }
    
    var lineCap: CAShapeLayerLineCap {
        return .round
    }
    
    var lineJoin: CAShapeLayerLineJoin {
        return .round
    }

    func createPath(dataPoints: [CGPoint], lineGap: CGFloat, viewSize: CGSize) -> UIBezierPath? {
        guard dataPoints.count > 0 else {
            return nil
        }
        let path = UIBezierPath()
        path.move(to: dataPoints[0])
        
        for i in 1..<dataPoints.count {
            path.addLine(to: dataPoints[i])
        }
        return path
    }
}
