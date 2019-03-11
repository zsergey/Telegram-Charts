//
//  ChartModel.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/11/19.
//  Copyright © 2019 Sergey Zapuhlyak. All rights reserved.
//

import UIKit

enum ColumnType: String {
    case x
    case line
}

struct ChartModel {
    var labels = [String]()
    var types = [String: ColumnType]()
    var names = [String: String]()
    var colors = [String: UIColor]()
    var data = [String: [Any]]()
}
