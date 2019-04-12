//
//  ChartModelFactory.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/22/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct ChartModelFactory {
    
    static func make(fromResource name: String, minLineLength: CGFloat = 0) -> [[ChartModel]] {
        var result: [[ChartModel]] = []
        
        if let data = DataChartModelFactory.make(fromResource: name) {
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
                                let value = dataY[index] as? Int {
                                let pointModel = PointModel(value: value, date: date)
                                pointModels.append(pointModel)
                            }
                        }
                        let chartModel = ChartModel(name: name,
                                                    color: color,
                                                    data: pointModels,
                                                    yScaled: chartData.yScaled,
                                                    stacked: chartData.stacked,
                                                    singleBar: chartData.singleBar,
                                                    percentage: chartData.percentage,
                                                    minLineLength: minLineLength)
                        chartModels.append(chartModel)
                    }
                }
                
                result.append(chartModels)
            }
        }
        
        return result
    }
}
