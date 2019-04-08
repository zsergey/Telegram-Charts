//
//  ChartModel.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/13/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct PointModel {
    let value: Int
    let date: Date
    
    var stringDate: String {
        return date.format
    }
    
    var dateDot: String {
        return date.formatDot
    }
    
    var year: String {
        return date.year
    }
}

extension PointModel: Comparable {
    static func <(lhs: PointModel, rhs: PointModel) -> Bool {
        return lhs.value < rhs.value
    }
    static func ==(lhs: PointModel, rhs: PointModel) -> Bool {
        return lhs.value == rhs.value
    }
}

func == (lhs: ChartModel, rhs: ChartModel) -> Bool {
    return lhs.name == rhs.name && lhs.color == rhs.color
}

class ChartModel {
    var name: String
    var color: UIColor
    var isHidden: Bool
    var yScaled: Bool
    var drawingStyle: DrawingStyleProtocol
    var data: [PointModel]
    var opacity: Float {
        return isHidden ? 0 : 1
    }
    
    init(name: String,
         color: UIColor,
         isHidden: Bool,
         drawingStyle: DrawingStyleProtocol,
         data: [PointModel],
         yScaled: Bool) {
        self.name = name
        self.color = color
        self.isHidden = isHidden
        self.drawingStyle = drawingStyle
        self.data = data
        self.yScaled = yScaled
    }
}

class IndexRange: CustomStringConvertible {
    var start: CGFloat
    var end: CGFloat
    
    init(start: CGFloat, end: CGFloat) {
        self.start = start
        self.end = end
    }
    
    var description: String {
        return "IndexRange [(\(start), \(end)])"
    }
}
