//
//  ChartTableViewCellModel.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 21/03/2019.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ChartTableViewCellModel {
    var chartDataSource: ChartDataSource
    var previewChartDataSource: ChartDataSource
    
    var colorScheme: ColorSchemeProtocol
    var drawingStyle: DrawingStyleProtocol
    
    init(chartDataSource: ChartDataSource,
         previewChartDataSource: ChartDataSource,
         colorScheme: ColorSchemeProtocol,
         drawingStyle: DrawingStyleProtocol) {
        self.chartDataSource = chartDataSource
        self.previewChartDataSource = previewChartDataSource
        self.colorScheme = colorScheme
        self.drawingStyle = drawingStyle
    }
}

extension ChartTableViewCellModel: CellViewModelType {
    
    func setup(on cell: ChartTableViewCell) {
        
        cell.model = self
        
        setupSliderView(on: cell)
        setupChartView(on: cell)
        setupPreviewChartView(on: cell)
        setupColors(on: cell)
    }
    
    func setupChartView(on cell: ChartTableViewCell) {
        cell.chartView.dataSource = chartDataSource
        
        chartDataSource.onChangeMaxValue = {
            self.calcProperties(of: self.chartDataSource, for: cell.chartView)
        }
        chartDataSource.onSetNewTargetMaxValue = {
            DispatchQueue.main.async {
                cell.chartView.drawHorizontalLines(animated: true)
            }
        }
    }
    
    func setupPreviewChartView(on cell: ChartTableViewCell) {
        cell.previewChartView.dataSource = previewChartDataSource
        
        previewChartDataSource.onChangeMaxValue = {
            self.calcProperties(of: self.previewChartDataSource, for: cell.previewChartView)
        }
        previewChartDataSource.onSetNewTargetMaxValue = {
            cell.previewChartView.drawHorizontalLines(animated: true)
        }
    }
    
    func setupSliderView(on cell: ChartTableViewCell) {
        cell.sliderView.chartModels = chartDataSource.chartModels
        cell.sliderView.sliderWidth = chartDataSource.sliderWidth
        cell.sliderView.currentRange.start = chartDataSource.range.start
        cell.sliderView.currentRange.end = chartDataSource.range.end
        cell.sliderView.setNeedsLayout()
        
        cell.sliderView.onChangeRange = { range, sliderWidth in
            self.chartDataSource.range.start = range.start
            self.chartDataSource.range.end = range.end
            self.chartDataSource.sliderWidth = sliderWidth

            self.previewChartDataSource.range.start = range.start
            self.previewChartDataSource.range.end = range.end
            self.previewChartDataSource.sliderWidth = sliderWidth

            self.calcProperties(of: self.chartDataSource, for: cell.chartView)
        }
        cell.sliderView.onBeganTouch = { sliderDirection in
            cell.chartView.sliderDirection = sliderDirection
            cell.chartView.setNeedsLayout()
        }
        cell.sliderView.onEndTouch = { sliderDirection in
            cell.chartView.sliderDirection = sliderDirection
            cell.chartView.setNeedsLayout()
        }
    }
    
    func setupColors(on cell: ChartTableViewCell) {
        cell.updateColors(animated: false)
    }
    
    func calcProperties(of dataSource: ChartDataSource, for view: UIView) {
        DispatchQueue.global(qos: .background).async {
            dataSource.calcProperties()
            DispatchQueue.main.async {
                view.setNeedsLayout()
            }
        }
    }
}
