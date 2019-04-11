//
//  PercentageDrawingStyle.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 4/9/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct PercentageDrawingStyle: DrawingStyleProtocol {
    
    var isCustomFillColor: Bool {
        return true
    }

    var lineCap: CAShapeLayerLineCap {
        return .round
    }
    
    var lineJoin: CAShapeLayerLineJoin {
        return .round
    }

    func createPath(dataPoints: [CGPoint], lineGap: CGFloat,
                    viewSize: CGSize, isPreviewMode: Bool) -> CGPath? {
        if isPreviewMode {
            return createPathShort(dataPoints: dataPoints, lineGap: lineGap, viewSize: viewSize)
        } else {
            return createPathStandard(dataPoints: dataPoints, lineGap: lineGap, viewSize: viewSize)
        }
    }
    
    private func createPathShort(dataPoints: [CGPoint], lineGap: CGFloat, viewSize: CGSize) -> CGPath? {
        guard dataPoints.count > 0 else {
            return nil
        }
        let path = CGMutablePath()
        let startPoint = dataPoints[0]
        let finishPoint = dataPoints[dataPoints.count - 1]
        
        path.move(to: CGPoint(x: startPoint.x, y: viewSize.height))
        path.move(to: startPoint)
        var lastPoint = startPoint
        for i in 1..<dataPoints.count {
            let point = dataPoints[i]
            if Math.lenghtLine(from: point, to: lastPoint) >= 3 {
                path.addLine(to: point)
                lastPoint = point
            }
        }
        
        path.addLine(to: CGPoint(x: finishPoint.x, y: viewSize.height))
        path.addLine(to: CGPoint(x: startPoint.x, y: viewSize.height))
        
        return path

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
