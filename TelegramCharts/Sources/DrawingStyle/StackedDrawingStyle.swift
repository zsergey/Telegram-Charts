//
//  StackedDrawingStyle.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 4/9/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct StackedDrawingStyle: DrawingStyleProtocol {
    
    var isCustomFillColor: Bool {
        return true
    }

    var lineCap: CAShapeLayerLineCap {
        return .butt
    }
    
    var lineJoin: CAShapeLayerLineJoin {
        return .miter
    }

    func createPath(dataPoints: [CGPoint], lineGap: CGFloat,
                    viewSize: CGSize, isPreviewMode: Bool) -> UIBezierPath? {
        if isPreviewMode {
            return createPathShort(dataPoints: dataPoints, lineGap: lineGap, viewSize: viewSize)
        } else {
            return createPathStandard(dataPoints: dataPoints, lineGap: lineGap, viewSize: viewSize)
        }
    }
    
    private func createPathShort(dataPoints: [CGPoint], lineGap: CGFloat, viewSize: CGSize) -> UIBezierPath? {
        
        guard dataPoints.count > 0 else {
            return nil
        }
        let path = UIBezierPath()
        let startPoint = dataPoints[0]
        let finishPoint = dataPoints[dataPoints.count - 1]
        
        path.move(to: CGPoint(x: startPoint.x, y: viewSize.height))
        path.addLine(to: startPoint)
        let secondPoint = CGPoint(x: startPoint.x + lineGap, y: startPoint.y)
        path.addLine(to: secondPoint)
        var lastPoint = secondPoint
        for i in 1..<dataPoints.count {
            let point = dataPoints[i]
            if Math.lenghtLine(from: point, to: lastPoint) >= 3 {
                path.addLine(to: point)
                path.addLine(to: CGPoint(x: point.x + lineGap, y: point.y))
                lastPoint = point
            }
        }

        path.addLine(to: CGPoint(x: finishPoint.x, y: viewSize.height))
        path.addLine(to: CGPoint(x: startPoint.x, y: viewSize.height))
        
        return path
    }

    private func createPathStandard(dataPoints: [CGPoint], lineGap: CGFloat, viewSize: CGSize) -> UIBezierPath? {
        guard dataPoints.count > 0 else {
            return nil
        }
        let path = UIBezierPath()
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
        
        path.addLine(to: CGPoint(x: finishPoint.x, y: viewSize.height))
        path.addLine(to: CGPoint(x: startPoint.x, y: viewSize.height))
        
        return path
    }

}
