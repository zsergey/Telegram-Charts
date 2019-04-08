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
    
    func setupButtons(on cell: ChartTableViewCell) {
        guard cell.buttons.isEmpty else {
            return
        }

        let leadingSpace: CGFloat = 16
        let trailingSpace: CGFloat = 16
        let topSpace = cell.sliderView.frame.origin.y + cell.sliderView.frame.size.height + 17

        var x = leadingSpace
        var y = topSpace
        for i in 0..<chartDataSource.chartModels.count {
            let chartModel = chartDataSource.chartModels[i]
            let button = CheckButton(color: chartModel.color)
            button.unCheckedBackgroundColor = colorScheme.chart.background
            button.chartModel = chartModel
            button.title = chartModel.name
            button.style = chartModel.isHidden ? .unChecked : .checked
            button.onTapButton = { model in
                FeedbackGenerator.impactOccurred(style: .medium)
                model.isHidden = !model.isHidden
                cell.model?.chartDataSource.selectedIndex = nil
                cell.chartView.cleanDots()
                cell.calcProperties()
            }
            button.onLongTapButton = { model in
                FeedbackGenerator.impactOccurred(style: .heavy)
                self.chartDataSource.chartModels.forEach { $0.isHidden = true }
                cell.buttons.forEach { $0.style = .unChecked }
                model.isHidden = false
                button.style = .checked
                cell.model?.chartDataSource.selectedIndex = nil
                cell.chartView.cleanDots()
                cell.calcProperties()
            }
            cell.addSubview(button)
            if x > cell.frame.size.width - trailingSpace - button.frame.size.width {
                y += button.frame.size.height + leadingSpace / 2
                x = leadingSpace
            }
            button.center = CGPoint(x: x + button.frame.size.width / 2,
                                    y: y + button.frame.size.height / 2)
            
            x += button.frame.size.width + leadingSpace / 2
            
            cell.buttons.append(button)
        }
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
    
    func calcProperties(of dataSource: ChartDataSource, for view: ChartView) {
        // TODO: Calc in background.
        /*if view.isScrolling {
            DispatchQueue.global(qos: .background).async {
                dataSource.calcProperties()
                DispatchQueue.main.async {
                    view.setNeedsLayout()
                }
            }
        } else { */
            dataSource.calcProperties()
            view.setNeedsLayout()
        /*} */
    }
}
