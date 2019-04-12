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
                
                if chartData.stacked {
                    chartModels = preparedStackData(chartModels)
                }
                
                result.append(chartModels)
            }
        }
        
        return result
    }
    
    // TODO
    // ["y0",1000,2000,3000,4000,5000],
    // ["y1",300,400,500,600,700],
    // ["y2",100,200,300,400,500]]
    static func preparedStackData(_ chartModels: [ChartModel]) -> [ChartModel] {
        let count = chartModels.map { $0.data.count }.max() ?? 0
        for i in 0..<count {
            var value = 0
            for index in 0..<chartModels.count {
                let chartModel = chartModels[index]
                var poinModel = chartModel.data[i]
                let toAddValue = chartModel.isHidden ? 0 : poinModel.originalValue
                poinModel.value = value + toAddValue
                chartModels[index].data[i] = poinModel
                value = value + toAddValue
            }
        }
        return chartModels
    }
}
