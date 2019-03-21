//
//  ViewController.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/11/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    @IBOutlet var chartView: ChartView!
    @IBOutlet var previewChartView: ChartView!
    @IBOutlet var sliderView: SliderView!

    var colorScheme: ColorSchemeProtocol! {
        didSet {
            
//            navigationController?.navigationBar.barTintColor = colorScheme.background
//            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: colorScheme.title]
//            (navigationController as? NavigationViewController)?.colorScheme = colorScheme
//
//            view.backgroundColor = colorScheme.background
//            chartView.colorScheme = colorScheme
//            previewChartView.colorScheme = colorScheme
//            sliderView.colorScheme = colorScheme
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        navigationController?.navigationBar.isTranslucent = false
//
//        colorScheme = NightScheme()
//        let chartModels = generateChartModels()
//        sliderView.chartModels = chartModels
//        sliderView.onChangeRange = { [weak self] range in
//            guard let self = self else {
//                return
//            }
//            self.chartView.range = range
//            self.chartView.setNeedsLayout()
//        }
//        sliderView.onBeganTouch = { [weak self] sliderDirection in
//            guard let self = self else {
//                return
//            }
//            self.chartView.sliderDirection = sliderDirection
//            self.chartView.setNeedsLayout()
//        }
//        sliderView.onEndTouch = { [weak self] sliderDirection in
//            guard let self = self else {
//                return
//            }
//            self.chartView.sliderDirection = sliderDirection
//            self.chartView.setNeedsLayout()
//        }
//
//        chartView.chartModels = chartModels
//        chartView.range = sliderView.currentRange
//
//        previewChartView.chartModels = chartModels
//        previewChartView.isPreviewMode = true
//
//        let displayLink = CADisplayLink(target: self, selector: #selector(update))
//        displayLink.add(to: .current, forMode: .common)
    }
    
    @objc func update() {
        chartView.update()
        previewChartView.update()
    }

    func changeIsHidden(for index: Int, sender: UISwitch) {
        if var chartModels = chartView.chartModels {
            chartModels[index].isHidden = !sender.isOn
            chartView.chartModels = chartModels
            previewChartView.chartModels = chartModels
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

extension ViewController: UITableViewDelegate {
    
}

extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
}
