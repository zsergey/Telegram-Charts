//
//  DrawingStyleProtocol.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/14/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

protocol DrawingStyleProtocol {
    var minLineLength: CGFloat { get set }
    var shortIndexes: [Int] { get set }
    var isCustomFillColor: Bool { get }
    var lineCap: CAShapeLayerLineCap { get }
    var lineJoin: CAShapeLayerLineJoin { get }
    mutating func createPath(dataPoints: [CGPoint], lineGap: CGFloat,
                             viewSize: CGSize, isPreviewMode: Bool) -> CGPath?
}
