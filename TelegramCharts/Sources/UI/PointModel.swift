//
//  PointModel.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/13/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct PointModel {
    let value: Int
    let label: String
}

extension PointModel: Comparable {
    static func <(lhs: PointModel, rhs: PointModel) -> Bool {
        return lhs.value < rhs.value
    }
    static func ==(lhs: PointModel, rhs: PointModel) -> Bool {
        return lhs.value == rhs.value
    }
}

class ChartModel {
    var name: String
    var color: UIColor
    var isHidden: Bool
    var data: [PointModel]
    var opacity: Float {
        return isHidden ? 0 : 1
    }
    
    init(name: String, color: UIColor, isHidden: Bool, data: [PointModel]) {
        self.name = name
        self.color = color
        self.isHidden = isHidden
        self.data = data
    }
}

typealias IndexRange = (start: CGFloat, end: CGFloat)
