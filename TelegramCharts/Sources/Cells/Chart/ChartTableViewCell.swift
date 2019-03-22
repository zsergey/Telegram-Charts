//
//  ChartTableViewCell.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 21/03/2019.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ChartTableViewCell: UITableViewCell {

    @IBOutlet var chartView: ChartView!
    @IBOutlet var previewChartView: ChartView!
    @IBOutlet var sliderView: SliderView!

    override func prepareForReuse() {
        super.prepareForReuse()
        
        chartView.prepareForReuse()
        previewChartView.prepareForReuse()
        sliderView.prepareForReuse()
    }
}

extension ChartTableViewCell: Updatable {

    func update() {
        chartView.update()
        previewChartView.update()
    }
}
