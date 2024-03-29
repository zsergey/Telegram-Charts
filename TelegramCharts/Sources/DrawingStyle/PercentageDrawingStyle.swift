//
//  PercentageDrawingStyle.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 4/9/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct PercentageDrawingStyle: DrawingStyleProtocol {
    
    var minLineLength: CGFloat = 0

    var shortIndexes: [Int] = []

    var isCustomFillColor: Bool {
        return true
    }

    var lineCap: CAShapeLayerLineCap {
        return .round
    }
    
    var lineJoin: CAShapeLayerLineJoin {
        return .round
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
        path.move(to: dataPoints[0])
        
        for i in 1..<dataPoints.count {
            path.addLine(to: dataPoints[i])
        }
        
        path.addLine(to: CGPoint(x: finishPoint.x, y: viewSize.height))
        path.addLine(to: CGPoint(x: startPoint.x, y: viewSize.height))
        
        return path
    }

}
