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
    
    @IBOutlet var chartView: ChartView!
    @IBOutlet var previewChartView: ChartView!
    @IBOutlet var sliderView: SliderView!

    override func prepareForReuse() {
        super.prepareForReuse()
        
        chartView.prepareForReuse()
        previewChartView.prepareForReuse()
        sliderView.prepareForReuse()
    }
    
    func calcProperties() {
        if let model = model {
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
        }
    }
    
    override func layoutSubviews() {
        if let model = model {
            if model.chartDataSource.viewSize != chartView.frame.size ||
                model.previewChartDataSource.viewSize != previewChartView.frame.size {
                
                model.chartDataSource.viewSize = self.chartView.frame.size
                model.previewChartDataSource.viewSize = self.previewChartView.frame.size
                
                calcProperties()
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
    
    func updateColors(animated: Bool) {
        if let model = model {
            if animated {
                model.colorScheme = model.colorScheme.next()
            }
            let animations = {
                self.backgroundColor = model.colorScheme.chart.background
                self.selectedBackgroundView = model.colorScheme.selectedCellView
            }
            self.chartView.colorScheme = model.colorScheme
            self.previewChartView.colorScheme = model.colorScheme
            self.sliderView.colorScheme = model.colorScheme
            
            if animated {
                UIView.animateEaseInOut(with: UIView.animationDuration, animations: animations)
            } else {
                animations()
            }
        }
    }
}
