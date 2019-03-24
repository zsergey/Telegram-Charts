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

        let charts = ChartModelFactory.make()
        for index in 0..<charts.count {
            let chartModels = charts[index]

            let main = ChartDataSource(chartModels: chartModels)
            let maxCount = chartModels.map { $0.data.count }.max() ?? 0
            main.changeMaxValueOnChangeRange = maxCount <= 150
            chartDataSource.append(main)
            
            let preview = ChartDataSource(chartModels: chartModels)
            preview.isPreviewMode = true
            previewChartDataSource.append(preview)
        }
        let result = СoupleChartDataSource(main: chartDataSource, preview: previewChartDataSource)
        return result
    }
}
