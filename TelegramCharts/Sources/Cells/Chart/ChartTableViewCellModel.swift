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
        self.chartDataSource.selectedIndex = nil
        cell.chartView.cleanDots()

        chartDataSource.onChangeMaxValue = {
            self.calcProperties(of: self.chartDataSource, for: cell.chartView)
             self.chartDataSource.selectedIndex = nil
             cell.chartView.cleanDots()
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
    }
    
    func setupSliderView(on cell: ChartTableViewCell) {
        cell.sliderView.chartModels = chartDataSource.chartModels
        cell.sliderView.sliderWidth = chartDataSource.sliderWidth
        cell.sliderView.startX = chartDataSource.startX
        cell.sliderView.currentRange = chartDataSource.range
        cell.sliderView.setNeedsLayout()
        
        cell.sliderView.onChangeRange = { range, sliderWidth, startX in
            self.chartDataSource.range = range
            self.chartDataSource.sliderWidth = sliderWidth
            self.chartDataSource.startX = startX
            self.chartDataSource.selectedIndex = nil
            cell.chartView.cleanDots()
            
            self.calcProperties(of: self.chartDataSource, for: cell.chartView)
        }
        cell.sliderView.onBeganTouch = { sliderDirection in
            cell.chartView.sliderDirection = sliderDirection
            cell.chartView.setNeedsLayout()
        }
        cell.sliderView.onEndTouch = { sliderDirection in
            cell.chartView.sliderDirection = sliderDirection
            cell.chartView.setNeedsLayout()
            
            self.calcProperties(of: self.chartDataSource, for: cell.chartView)
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
