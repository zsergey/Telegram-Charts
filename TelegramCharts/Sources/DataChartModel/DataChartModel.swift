//
//  DataChartModel.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/11/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

enum ColumnType: String {
    case x
    case line
}

struct DataChartModel {
    var labels = [String]()
    var types = [String: ColumnType]()
    var names = [String: String]()
    var colors = [String: UIColor]()
    var data = [String: [Any]]()
}
