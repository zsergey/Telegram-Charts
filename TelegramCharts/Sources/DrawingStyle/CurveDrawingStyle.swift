//
//  CurveDrawingStyle.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/14/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct CurveDrawingStyle: DrawingStyleProtocol {

    struct CurvedSegment {
        var controlPoint1: CGPoint
        var controlPoint2: CGPoint
    }

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
        
        var curveSegments: [CurvedSegment] = []
        curveSegments = controlPoints(from: dataPoints)
        
        for i in 1..<dataPoints.count {
            path.addCurve(to: dataPoints[i],
                          controlPoint1: curveSegments[i - 1].controlPoint1,
                          controlPoint2: curveSegments[i - 1].controlPoint2)
        }
        return path
    }
    
    private func controlPoints(from points: [CGPoint]) -> [CurvedSegment] {
        var result: [CurvedSegment] = []
        
        let delta: CGFloat = 0.3
        
        for i in 1..<points.count {
            let A = points[i - 1]
            let B = points[i]
            let controlPoint1 = CGPoint(x: A.x + delta * (B.x - A.x), y: A.y + delta * (B.y - A.y))
            let controlPoint2 = CGPoint(x: B.x - delta * (B.x - A.x), y: B.y - delta * (B.y - A.y))
            let curvedSegment = CurvedSegment(controlPoint1: controlPoint1, controlPoint2: controlPoint2)
            result.append(curvedSegment)
        }
        
        for i in 1..<points.count-1 {
            let M = result[i - 1].controlPoint2
            let N = result[i].controlPoint1
            let A = points[i]
            let MM = CGPoint(x: 2 * A.x - M.x, y: 2 * A.y - M.y)
            let NN = CGPoint(x: 2 * A.x - N.x, y: 2 * A.y - N.y)
            
            result[i].controlPoint1 = CGPoint(x: (MM.x + N.x) / 2, y: (MM.y + N.y) / 2)
            result[i - 1].controlPoint2 = CGPoint(x: (NN.x + M.x) / 2, y: (NN.y + M.y) / 2)
        }
        
        return result
    }
}
