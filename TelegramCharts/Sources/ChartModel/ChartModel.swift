//
//  ChartModel.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/13/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct PointModel {
    var value: Int
    var targetValue: Int
    var originalValue: Int
    var deltaToTargetValue: Int = 0
    let date: Date
    
    init(value: Int, date: Date, originalValue: Int) {
        self.value = value
        self.originalValue = originalValue
        self.targetValue = value
        self.date = date
    }
    
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
    
    enum TargetDirection {
        case toZero
        case toValue
    }
    
    var name: String
    var color: UIColor
    var isHidden: Bool
    var yScaled: Bool
    var stacked: Bool
    var singleBar: Bool
    var percentage: Bool
    var targetDirection = TargetDirection.toValue // by default all charts aren't hidden
    var runValueAnimation: Bool = false
    var drawingStyle: DrawingStyleProtocol
    var data: [PointModel]
    
    var opacity: Float {
        return isHidden ? 0 : 1
    }
    
    init(name: String, color: UIColor, data: [PointModel], yScaled: Bool,
         stacked: Bool, singleBar: Bool, percentage: Bool) {
        self.name = name
        self.color = color
        self.isHidden = false
        self.data = data
        self.yScaled = yScaled
        self.stacked = stacked
        self.singleBar = singleBar
        self.percentage = percentage

        if percentage {
            self.drawingStyle = PercentageDrawingStyle()
        } else if stacked || singleBar {
            self.drawingStyle = StackedDrawingStyle()
        } else {
            self.drawingStyle = StandardDrawingStyle()
        }
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
