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
    
    var filterButtons: [CheckButton] = []

    override func prepareForReuse() {
        super.prepareForReuse()
        
        chartView.prepareForReuse()
        previewChartView.prepareForReuse()
        sliderView.prepareForReuse()
        
        filterButtons.forEach { $0.removeFromSuperview() }
        filterButtons.removeAll()
    }
        
    func hideViewsIfNeeded() {
        if let model = model {
            let alphaViews: CGFloat = model.chartDataSource.isAllChartsHidden ? 0 : 1
            let alphaLabels: CGFloat = 1 - alphaViews
            UIView.animateEaseInOut(with: UIView.animationDuration) {
                self.chartView.alpha = alphaViews
                self.previewChartView.alpha = alphaViews
                self.sliderView.alpha = alphaViews
                self.chartNoDataLabel.alpha = alphaLabels
            }
        }
    }
    
    func calcProperties(animateMaxValue: Bool, changedIsHidden: Bool) {
        if let model = model {
            // TODO: Calc in background.
            /* if chartView.isScrolling || previewChartView.isScrolling {
                DispatchQueue.global(qos: .background).async {
                    model.chartDataSource.calcProperties()
                    model.previewChartDataSource.calcProperties()
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.setNeedsLayout()
                        self.chartView.setNeedsLayout()
                        self.previewChartView.setNeedsLayout()
                    }
                }
            } else {*/
                model.chartDataSource.calcProperties(animateMaxValue: animateMaxValue,
                                                     changedIsHidden: changedIsHidden)
                model.previewChartDataSource.calcProperties(animateMaxValue: animateMaxValue,
                                                            changedIsHidden: changedIsHidden)
                self.setNeedsLayout()
                self.chartView.setNeedsLayout()
                self.previewChartView.setNeedsLayout()
            /*} */
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
                
                calcProperties(animateMaxValue: false, changedIsHidden: false)
            }
        }
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
            self.chartView.colorScheme = model.colorScheme
            self.previewChartView.colorScheme = model.colorScheme
            self.sliderView.colorScheme = model.colorScheme
        }
    }
}
