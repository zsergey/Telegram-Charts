//
//  ChartTableViewCell.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 21/03/2019.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ChartTableViewCell: UITableViewCell {

    weak var model: ChartTableViewCellModel?
    
    @IBOutlet var chartView: ChartContentView!
    @IBOutlet var previewChartView: ChartContentView!
    @IBOutlet var sliderView: SliderView!
    @IBOutlet var chartNoDataLabel: UILabel! {
        didSet {
            chartNoDataLabel.alpha = 0
        }
    }
    
    @IBOutlet var zoomOutButton: BackButton!
    @IBOutlet var dateLabel: UILabel!

    var filterButtons: [CheckButton] = []

    override func prepareForReuse() {
        super.prepareForReuse()
        
        chartView.prepareForReuse()
        previewChartView.prepareForReuse()
        sliderView.prepareForReuse()
        
        filterButtons.forEach { $0.removeFromSuperview() }
        filterButtons.removeAll()
    }
        
    func hideViewsIfNeeded(animated: Bool) {
        if let model = model {
            let alphaViews: CGFloat = model.chartDataSource.isAllChartsHidden ? 0 : 1
            
            if !model.chartDataSource.isDetailedView {
                zoomOutButton.alpha = 0
            }
            
            let alphaNoDataLabel: CGFloat = 1 - alphaViews
            let animation = {
                self.chartView.alpha = alphaViews
                self.previewChartView.alpha = alphaViews
                self.sliderView.alpha = alphaViews
                self.dateLabel.alpha = alphaViews
                if model.chartDataSource.isDetailedView {
                    self.zoomOutButton.alpha = alphaViews
                }
                
                self.chartNoDataLabel.alpha = alphaNoDataLabel
            }
            if animated {
                UIView.animateEaseInOut(with: UIView.animationDuration) {
                    animation()
                }
            } else {
                animation()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let model = model {
            
            model.setupFilterButtons(on: self)
            
            if model.chartDataSource.viewSize != chartView.frame.size ||
                model.previewChartDataSource.viewSize != previewChartView.frame.size {
                
                model.chartDataSource.viewSize = self.chartView.frame.size
                model.previewChartDataSource.viewSize = self.previewChartView.frame.size
                
                model.calcProperties(of: model.chartDataSource, for: chartView, animateMaxValue: false, changedIsHidden: false)
                model.calcProperties(of: model.previewChartDataSource, for: previewChartView, animateMaxValue: false, changedIsHidden: false)
                self.setNeedsLayout()
            } else {
                self.chartView.drawView()
                self.previewChartView.drawView()
            }
        }
    }

    func drawSelectedValuesIfNeeded() {
        if model?.chartDataSource.selectedIndex != nil {
            chartView.drawSelectedValues()
        }
    }
    
    func drawViews() {
        chartView.drawView()
        previewChartView.drawView()
        chartView.drawHorizontalLines(animated: false)
    }
        
    @IBAction func tapZoomOutButton(_ sender: Any) {
    }
}

extension ChartTableViewCell: Updatable {

    func update() {
        chartView.update()
        previewChartView.update()
    }
}

extension ChartTableViewCell: ColorUpdatable {
    
    func updateColors(changeColorScheme: Bool) {
        if let model = model {
            if changeColorScheme {
                model.colorScheme = model.colorScheme.next()
            }
            self.backgroundColor = model.colorScheme.chart.background
            self.selectedBackgroundView = model.colorScheme.selectedCellView
            self.chartNoDataLabel.textColor = model.colorScheme.chart.text
            self.filterButtons.forEach {
                $0.unCheckedBackgroundColor = model.colorScheme.chart.background
            }
            self.dateLabel.textColor = model.colorScheme.title
            self.chartView.colorScheme = model.colorScheme
            self.previewChartView.colorScheme = model.colorScheme
            self.sliderView.colorScheme = model.colorScheme
            self.dateLabel.backgroundColor = model.colorScheme.chart.background
        }
    }
}
