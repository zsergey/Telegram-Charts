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
    
    func createPath(dataPoints: [CGPoint], lineGap: CGFloat,
                    viewSize: CGSize, isPreviewMode: Bool) -> UIBezierPath? {
        if isPreviewMode {
            return createPathShort(dataPoints: dataPoints, lineGap: lineGap, viewSize: viewSize)
        } else {
            return createPathStandard(dataPoints: dataPoints, lineGap: lineGap, viewSize: viewSize)
        }
    }
    
    private func createPathStandard(dataPoints: [CGPoint], lineGap: CGFloat, viewSize: CGSize) -> UIBezierPath? {
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
    
    private func createPathShort(dataPoints: [CGPoint], lineGap: CGFloat, viewSize: CGSize) -> UIBezierPath? {
        guard dataPoints.count > 0 else {
            return nil
        }
        let path = UIBezierPath()
        var startPoint = dataPoints[0]
        path.move(to: startPoint)
        for i in 1..<dataPoints.count {
            let point = dataPoints[i]
            if Math.lenghtLine(from: startPoint, to: point) >= 3 {
                path.addLine(to: point)
                startPoint = point
            }
        }
        return path
    }
    
    // Use for unreal big data.
    private func createPathSkipIndexes(dataPoints: [CGPoint], lineGap: CGFloat, viewSize: CGSize) -> UIBezierPath? {
        guard dataPoints.count > 0 else {
            return nil
        }
        let minimumGap: CGFloat = 4
        var deltaIndex = 1
        if lineGap < minimumGap {
            deltaIndex = Int(minimumGap / lineGap)
        }

        let path = UIBezierPath()
        path.move(to: dataPoints[0])

        var index = 1
        while index < dataPoints.count {
            path.addLine(to: dataPoints[index])
            index += deltaIndex
        }

        return path
    }

}
