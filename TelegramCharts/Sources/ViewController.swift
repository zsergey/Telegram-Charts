//
//  ViewController.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/11/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var chartView: ChartView!
    @IBOutlet var previewChartView: ChartView!
    @IBOutlet var sliderView: SliderView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let chartModels = generateChartModels()
        sliderView.chartModels = chartModels
        sliderView.onChangeRange = { [weak self] range in
            self?.chartView.range = range
            self?.chartView.setNeedsLayout()
        }
        
        chartView.chartModels = chartModels
        chartView.range = sliderView.currentRange
        
        previewChartView.chartModels = chartModels
        previewChartView.isPreviewMode = true
        
        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .current, forMode: .common)
    }
    
    @objc func update() {
        chartView.update()
        previewChartView.update()
    }

    func changeIsHidden(for index: Int, sender: UISwitch) {
        if var chartModels = chartView.chartModels {
            chartModels[index].isHidden = !sender.isOn
            chartView.setNeedsLayout()
            previewChartView.setNeedsLayout()
        }
    }
    
    @IBAction func chartSwicth1Changed(_ sender: UISwitch) {
        changeIsHidden(for: 0, sender: sender)
    }
    
    @IBAction func chartSwicth2Changed(_ sender: UISwitch) {
        changeIsHidden(for: 1, sender: sender)
    }
    
    private func generateChartModels() -> [ChartModel] {
        var result: [ChartModel] = []

        if let data = DataChartModelFactory.fetchCharts() { // TODO: fromResource: "chart_data_copy"
            // пока заполним первым массивом.
            let firstChart = data[0]
            
            var xlabel = ""
            var ylabels = [String]()
            for (label, type) in firstChart.types {
                if type == .x {
                    xlabel = label
                } else {
                    ylabels.append(label)
                }
            }
            
            for ylabel in ylabels {
                if let dataX = firstChart.data[xlabel],
                    let dataY = firstChart.data[ylabel],
                    let name = firstChart.names[ylabel],
                    let color = firstChart.colors[ylabel] {

                    var pointModels: [PointModel] = []
                    let count = min(dataX.count, dataY.count)
                    for index in 0..<count {
                        if let date = dataX[index] as? Date,
                            let value = dataY[index] as? Int {
                            let pointModel = PointModel(value: value, date: date.format)
                            pointModels.append(pointModel)
                        }
                    }
                    
                    let chartModel = ChartModel(name: name, color: color, isHidden: false, data: pointModels)
                    result.append(chartModel)
                }
            }
        }
        
        return result
    }

}

