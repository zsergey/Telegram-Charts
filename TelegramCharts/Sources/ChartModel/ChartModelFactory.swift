//
//  ChartModelFactory.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/22/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct ChartModelFactory {
    
    static func make(fromResource name: String) -> [[ChartModel]] {
        var result: [[ChartModel]] = []
        
        if let data = DataChartModelFactory.make(fromResource: name) {
            let start = Date()
            for index in 0..<data.count {
                
                let chartData = data[index]
                var chartModels = [ChartModel]()
                
                var xlabel = ""
                var ylabels = [String]()
                for (label, type) in chartData.types {
                    if type == .x {
                        xlabel = label
                    } else {
                        ylabels.append(label)
                    }
                }
                ylabels = ylabels.sorted(by: { $0 < $1 })
                
                // Preparing sum values.
                var sumValues: [Int]? = nil
                if chartData.percentage {
                    sumValues = [Int]()
                    if let dataX = chartData.data[xlabel] {
                        for i in 0..<dataX.count {
                            var sumValue: Int = 0
                            for index in 0..<ylabels.count {
                                let ylabel = ylabels[index]
                                let dataY = chartData.data[ylabel] as! [Int]
                                sumValue += dataY[i]
                            }
                            sumValues!.append(sumValue)
                        }
                    }
                }
                
                for i in 0..<ylabels.count {
                    let ylabel = ylabels[i]
                    if let dataX = chartData.data[xlabel],
                        let dataY = chartData.data[ylabel],
                        let name = chartData.names[ylabel],
                        let color = chartData.colors[ylabel] {
                        
                        var pointModels: [PointModel] = []
                        let count = min(dataX.count, dataY.count)
                        for index in 0..<count {
                            if let date = dataX[index] as? Date,
                                let originalValue = dataY[index] as? Int {
                                var value = originalValue
                                if chartData.percentage {
                                    value = Int(100 * CGFloat(value) / CGFloat(sumValues![index]))
                                }
                                let pointModel = PointModel(value: value, date: date, originalValue: originalValue)
                                pointModels.append(pointModel)
                            }
                        }
                        // ["y0",200,400,1000],["y1",100,200,400],["y2",500,500,500]
                        let chartModel = ChartModel(name: name,
                                                    color: color,
                                                    data: pointModels,
                                                    yScaled: chartData.yScaled,
                                                    stacked: chartData.stacked,
                                                    singleBar: chartData.singleBar,
                                                    percentage: chartData.percentage)
                        chartModels.append(chartModel)
                    }
                }
                
                result.append(chartModels)
            }
            let end = Date()
            print("ChartModelFactory Total time is \(end.timeIntervalSince1970 - start.timeIntervalSince1970)")
        }
        
        return result
    }
}
