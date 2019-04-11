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
        if isPreviewMode {
            return createPathShort(dataPoints: dataPoints, lineGap: lineGap, viewSize: viewSize)
        } else {
            return createPathStandard(dataPoints: dataPoints, lineGap: lineGap, viewSize: viewSize)
        }
    }
    
    private mutating func createPathShort(dataPoints: [CGPoint], lineGap: CGFloat, viewSize: CGSize) -> CGPath? {
        // TODO: здесь сделать на подобии стандартного шорта
        guard dataPoints.count > 0 else {
            return nil
        }
        let minimumGap: CGFloat = minLineLength
        var deltaIndex = 1
        if lineGap < minimumGap {
            deltaIndex = Int(minimumGap / lineGap)
        }
        
        let path = CGMutablePath()
        let startPoint = dataPoints[0]
        let finishPoint = dataPoints[dataPoints.count - 1]
        
        path.move(to: CGPoint(x: startPoint.x, y: viewSize.height))
        path.addLine(to: startPoint)
        var lastLine = startPoint
        
        if shortIndexes.isEmpty {
            var index = deltaIndex
            while index < dataPoints.count {
                let point = dataPoints[index]
                
                path.addLine(to: CGPoint(x: point.x, y: lastLine.y))
                path.addLine(to: point)
                lastLine = point
                shortIndexes.append(index)
                index += deltaIndex
            }
        } else {
            for i in 0..<shortIndexes.count {
                let index = shortIndexes[i]
                let point = dataPoints[index]
                path.addLine(to: CGPoint(x: point.x, y: lastLine.y))
                path.addLine(to: point)
                lastLine = point
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
