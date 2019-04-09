//
//  PercentageDrawingStyle.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 4/9/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct PercentageDrawingStyle: DrawingStyleProtocol {
    
    func createPath(dataPoints: [CGPoint], lineGap: CGFloat, viewSize: CGSize) -> UIBezierPath? {
        guard dataPoints.count > 0 else {
            return nil
        }
        let path = UIBezierPath()
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
