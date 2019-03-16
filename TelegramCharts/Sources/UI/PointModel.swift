//
//  PointModel.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/13/19.
//  Copyright © 2019 Sergey Zapuhlyak. All rights reserved.
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

struct ChartModel {
    let name: String
    let color: UIColor
    let isHidden: Bool = false
    let data: [PointModel]
}
