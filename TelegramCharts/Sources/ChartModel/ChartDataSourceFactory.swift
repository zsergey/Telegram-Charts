//
//  ChartDataSourceFactory.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/23/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import Foundation

struct ChartDataSourceFactory {
    
    static func make() -> СoupleChartDataSource {
        var chartDataSource = [ChartDataSource]()
        var previewChartDataSource = [ChartDataSource]()

        var charts = [[ChartModel]]()
        charts += ChartModelFactory.make(fromResource: "chart_data_1")
        charts += ChartModelFactory.make(fromResource: "chart_data_2")
        charts += ChartModelFactory.make(fromResource: "chart_data_3")
        charts += ChartModelFactory.make(fromResource: "chart_data_4")
        charts += ChartModelFactory.make(fromResource: "chart_data_5", minLineLength: 3)
        charts += ChartModelFactory.make(fromResource: "overview1", minLineLength: 2)
        charts += ChartModelFactory.make(fromResource: "overview2", minLineLength: 2)
        charts += ChartModelFactory.make(fromResource: "overview3")
        charts += ChartModelFactory.make(fromResource: "overview4")
        charts += ChartModelFactory.make(fromResource: "overview5")
        var names = Array(repeating: "FOLLOWERS", count: 4)
        names += ["CALLS", "FOLLOWERS", "INTERACTIONS", "MESSAGES", "VIEWS", "APPS"]
        let uniqueIdKey = "DataSource"
        for index in 0..<charts.count {
            let chartModels = charts[index]
            var name = ""
            if index < names.count {
                name = names[index]
            }
            
            let main = ChartDataSource(chartModels: chartModels, name: name)
            main.uniqueId = "Main" + uniqueIdKey + String(index)
            chartDataSource.append(main)
            
            let preview = ChartDataSource(chartModels: chartModels, name: name)
            preview.uniqueId = "Preview" + uniqueIdKey + String(index)
            preview.isPreviewMode = true
            previewChartDataSource.append(preview)
        }
        let result = СoupleChartDataSource(main: chartDataSource, preview: previewChartDataSource)
        return result
    }
}
