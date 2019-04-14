//
//  StackedDrawingStyle.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 4/9/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct StackedDrawingStyle: DrawingStyleProtocol {
    
    var minLineLength: CGFloat = 0

    var shortIndexes: [Int] = []

    var isCustomFillColor: Bool {
        return true
    }

    var lineCap: CAShapeLayerLineCap {
        return .butt
    }
    
    var lineJoin: CAShapeLayerLineJoin {
        return .miter
    }

    mutating func createPath(dataPoints: [CGPoint], lineGap: CGFloat,
                             viewSize: CGSize, isPreviewMode: Bool) -> CGPath? {
        return createPathStandard(dataPoints: dataPoints, lineGap: lineGap, viewSize: viewSize)
    }
    
    private func createPathStandard(dataPoints: [CGPoint], lineGap: CGFloat, viewSize: CGSize) -> CGPath? {
        guard dataPoints.count > 0 else {
            return nil
        }
        let path = CGMutablePath()
        let startPoint = dataPoints[0]
        let finishPoint = dataPoints[dataPoints.count - 1]
        
        path.move(to: CGPoint(x: startPoint.x, y: viewSize.height))
        path.addLine(to: startPoint)
        path.addLine(to: CGPoint(x: startPoint.x + lineGap, y: startPoint.y))
        
        for i in 1..<dataPoints.count {
            let point = dataPoints[i]
            path.addLine(to: point)
            path.addLine(to: CGPoint(x: point.x + lineGap, y: point.y))
        }
        
        path.addLine(to: CGPoint(x: finishPoint.x + lineGap, y: viewSize.height))
        path.addLine(to: CGPoint(x: startPoint.x, y: viewSize.height))

        return path
    }

}
