//
//  StandardDrawingStyle.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/14/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct StandardDrawingStyle: DrawingStyleProtocol {

    var minLineLength: CGFloat = 0

    var shortIndexes: [Int] = []

    var isCustomFillColor: Bool {
        return false
    }
    
    var lineCap: CAShapeLayerLineCap {
        return .round
    }
    
    var lineJoin: CAShapeLayerLineJoin {
        return .round
    }
    
    mutating func createPath(dataPoints: [CGPoint], lineGap: CGFloat,
                    viewSize: CGSize, isPreviewMode: Bool) -> CGPath? {
        if isPreviewMode {
            return createPathShort(dataPoints: dataPoints, lineGap: lineGap, viewSize: viewSize)
        } else {
            return createPathStandard(dataPoints: dataPoints, lineGap: lineGap, viewSize: viewSize)
        }
    }

    // TODO: Показать алгоритм Коле
    private func createPathShortSmooth(dataPoints: [CGPoint], lineGap: CGFloat, viewSize: CGSize) -> CGPath? {
        guard dataPoints.count > 0 else {
            return nil
        }
        let path = CGMutablePath()
        let startPoint = dataPoints[0]
        path.move(to: startPoint)
        
        var currentX = dataPoints[0].x
        var currentY = dataPoints[0].y
        var maxY: CGFloat = 0
        for i in 1..<dataPoints.count {
            let point = dataPoints[i]
            if truncf(Float(currentX)) == truncf(Float(point.x)) {
                if point.y > maxY {
                    maxY = point.y
                }
            } else {
                path.addLine(to: CGPoint(x: currentX, y: max(maxY, currentY)))
                maxY = 0
                currentX = point.x
                currentY = point.y
            }
        }
        return path
    }
    
    private func createPathStandard(dataPoints: [CGPoint], lineGap: CGFloat, viewSize: CGSize) -> CGPath? {
        guard dataPoints.count > 0 else {
            return nil
        }
        let path = CGMutablePath()
        path.move(to: dataPoints[0])
        
        for i in 1..<dataPoints.count {
            path.addLine(to: dataPoints[i])
        }
        return path
    }
    
    private mutating func createPathShort(dataPoints: [CGPoint], lineGap: CGFloat, viewSize: CGSize) -> CGPath? {
        guard dataPoints.count > 0 else {
            return nil
        }
        let path = CGMutablePath()
        var startPoint = dataPoints[0]
        path.move(to: startPoint)

        if shortIndexes.isEmpty {
            for i in 1..<dataPoints.count {
                let point = dataPoints[i]
                if Math.lenghtLine(from: startPoint, to: point) >= minLineLength {
                    path.addLine(to: point)
                    startPoint = point
                    shortIndexes.append(i)
                }
            }
        } else {
            for i in 0..<shortIndexes.count {
                let index = shortIndexes[i]
                path.addLine(to: dataPoints[index])
            }
        }
        return path
    }
    
    // Use for unreal big data.
    private func createPathSkipIndexes(dataPoints: [CGPoint], lineGap: CGFloat, viewSize: CGSize) -> CGMutablePath? {
        guard dataPoints.count > 0 else {
            return nil
        }
        let minimumGap: CGFloat = 4
        var deltaIndex = 1
        if lineGap < minimumGap {
            deltaIndex = Int(minimumGap / lineGap)
        }

        let path = CGMutablePath()
        path.move(to: dataPoints[0])

        var index = 1
        while index < dataPoints.count {
            path.addLine(to: dataPoints[index])
            index += deltaIndex
        }

        return path
    }

}
