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
        charts += ChartModelFactory.make(fromResource: "overview1")
        charts += ChartModelFactory.make(fromResource: "overview2")
        charts += ChartModelFactory.make(fromResource: "overview3")
        charts += ChartModelFactory.make(fromResource: "overview4")
//        charts += ChartModelFactory.make(fromResource: "overview5")
        var names = ["FOLLOWERS", "INTERACTIONS", "MESSAGES", "VIEWS", "APPS"]
        
        for index in 0..<charts.count {
            let chartModels = charts[index]
            var name = ""
            if index < names.count {
                name = names[index]
            }
            
            let main = ChartDataSource(chartModels: chartModels, name: name)
            chartDataSource.append(main)
            
            let preview = ChartDataSource(chartModels: chartModels, name: name)
            preview.isPreviewMode = true
            previewChartDataSource.append(preview)
        }
        
        let result = СoupleChartDataSource(main: chartDataSource, preview: previewChartDataSource)
        return result
    }
}
