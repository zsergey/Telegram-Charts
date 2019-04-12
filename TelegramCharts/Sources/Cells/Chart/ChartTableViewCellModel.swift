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
    
    init(chartDataSource: ChartDataSource,
         previewChartDataSource: ChartDataSource,
         colorScheme: ColorSchemeProtocol) {
        self.chartDataSource = chartDataSource
        self.previewChartDataSource = previewChartDataSource
        self.colorScheme = colorScheme
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
    
    func setupFilterButtons(on cell: ChartTableViewCell) {
        guard cell.filterButtons.isEmpty, chartDataSource.chartModels.count > 1 else {
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
                cell.calcProperties(animateMaxValue: true, changedIsHidden: true)
                cell.hideViewsIfNeeded(animated: true)
            }
            button.onLongTapButton = { model, processedLongPressGesture in
                var needsUpdate = false
                self.chartDataSource.chartModels.forEach {
                    if $0 == model {
                        if $0.isHidden == true {
                            needsUpdate = needsUpdate || true
                        }
                        $0.isHidden = false
                    } else {
                        if $0.isHidden == false {
                            needsUpdate = needsUpdate || true
                        }
                        $0.isHidden = true
                    }
                }
                if needsUpdate {
                    if !processedLongPressGesture {
                        FeedbackGenerator.impactOccurred(style: .heavy)
                    }
                    cell.filterButtons.forEach { $0.style = .unChecked }
                    button.style = .checked
                    cell.model?.chartDataSource.selectedIndex = nil
                    cell.chartView.cleanDots()
                    cell.calcProperties(animateMaxValue: true, changedIsHidden: true)
                    cell.hideViewsIfNeeded(animated: true)
                } else {
                    if !processedLongPressGesture {
                        FeedbackGenerator.notificationOccurred(.warning)
                    }
                }
            }
            cell.addSubview(button)
            if x > cell.frame.size.width - trailingSpace - button.frame.size.width {
                y += button.frame.size.height + leadingSpace / 2
                x = leadingSpace
            }
            button.center = CGPoint(x: x + button.frame.size.width / 2,
                                    y: y + button.frame.size.height / 2)
            
            x += button.frame.size.width + leadingSpace / 2
            
            cell.filterButtons.append(button)
        }
    }
    
    func setupChartView(on cell: ChartTableViewCell) {
        cell.chartView.dataSource = chartDataSource
        self.chartDataSource.selectedIndex = nil
        cell.chartView.cleanDots()
        cell.hideViewsIfNeeded(animated: false)
        
        chartDataSource.onChangeMaxValue = {
            self.calcProperties(of: self.chartDataSource, for: cell.chartView, shouldCalcMaxValue: false)
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
            self.calcProperties(of: self.previewChartDataSource, for: cell.previewChartView, shouldCalcMaxValue: false)
        }
    }
    
    func setupSliderView(on cell: ChartTableViewCell) {
        // TODO: Don't forget about reusing cells.
        cell.sliderView.chartModels = chartDataSource.chartModels
        cell.sliderView.sliderWidth = chartDataSource.sliderWidth
        cell.sliderView.startX = chartDataSource.startX
        cell.sliderView.currentRange = chartDataSource.range
        cell.sliderView.setNeedsLayout()
        
        cell.sliderView.onChangeRange = { range, sliderWidth, startX, value in
            self.chartDataSource.range = range
            self.chartDataSource.sliderWidth = sliderWidth
            self.chartDataSource.startX = startX
            self.chartDataSource.selectedIndex = nil
            cell.chartView.cleanDots()
            
            self.calcProperties(of: self.chartDataSource, for: cell.chartView, animateMaxValue: value)
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
        cell.updateColors(changeColorScheme: false)
    }
    
    func calcProperties(of dataSource: ChartDataSource,
                        for view: ChartContentView,
                        shouldCalcMaxValue: Bool = true,
                        animateMaxValue: Bool = true) {
        // TODO: Calc in background.
        /*if view.isScrolling {
            DispatchQueue.global(qos: .background).async {
                dataSource.calcProperties()
                DispatchQueue.main.async {
                    view.setNeedsLayout()
                }
            }
        } else { */
            dataSource.calcProperties(shouldCalcMaxValue: shouldCalcMaxValue,
                                      animateMaxValue: animateMaxValue,
                                      changedIsHidden: false)
            view.setNeedsLayout()
        /*} */
    }
}
