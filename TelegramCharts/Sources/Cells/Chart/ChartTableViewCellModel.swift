//
//  ChartTableViewCellModel.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 21/03/2019.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import Foundation

struct ChartTableViewCellModel {
    var chartModels: [ChartModel]?
}

extension ChartTableViewCellModel: CellViewModelType {
    
    func setup(on cell: ChartTableViewCell) {
        if let chartModels = chartModels {
            
            cell.sliderView.chartModels = chartModels
            cell.sliderView.onChangeRange = { range in
                cell.chartView.range = range
                cell.chartView.setNeedsLayout()
            }
            cell.sliderView.onBeganTouch = { sliderDirection in
                cell.chartView.sliderDirection = sliderDirection
                cell.chartView.setNeedsLayout()
            }
            cell.sliderView.onEndTouch = { sliderDirection in
                cell.chartView.sliderDirection = sliderDirection
                cell.chartView.setNeedsLayout()
            }
            
            cell.chartView.chartModels = chartModels
            cell.chartView.range = cell.sliderView.currentRange
            
            cell.previewChartView.chartModels = chartModels
            cell.previewChartView.isPreviewMode = true
            if cell.previewChartView.isReused {
                // TODO: на старте анимация, не очень хорошо
                cell.previewChartView.setNeedsLayout()
            }
        }
    }
}
