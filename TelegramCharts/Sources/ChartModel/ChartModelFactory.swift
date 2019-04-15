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
                
                var countData: Int = 0
                for i in 0..<ylabels.count {
                    let ylabel = ylabels[i]
                    if let dataX = chartData.data[xlabel],
                        let dataY = chartData.data[ylabel],
                        let name = chartData.names[ylabel],
                        let color = chartData.colors[ylabel] {
                        
                        var pointModels: [PointModel] = []
                        countData = min(dataX.count, dataY.count)
                        for index in 0..<countData {
                            if let date = dataX[index] as? Date,
                                let value = dataY[index] as? Int {
                                DateCache.shared.shortFormat(for: date)
                                DateCache.shared.fullFormat(for: date)
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
                    prepareStackData(chartModels, countData: countData,
                                     percentage: chartData.percentage)
                }

                result.append(chartModels)
            }
            
        }
        
        return result
    }
    
    static func prepareStackData(_ chartModels: [ChartModel], countData: Int, percentage: Bool) {
        
        let fakeDate = Date()
        let zeroValue = PointModel(value: 0, date: fakeDate)
        var startStackData: [PointModel]?
        if !percentage {
            startStackData = [PointModel]()
            for _ in 0..<countData {
                startStackData!.append(zeroValue)
            }
        }

        let n = chartModels.count
        let countCombinations = Int(truncating: NSDecimalNumber(decimal: pow(2, n)))
        for index in 0..<countCombinations {
            let mapKey = makeBits(index, n)
            
            var allStackData: [PointModel]? = startStackData
            var lastVisibleIndex = 0
            for index in 0..<chartModels.count {
                let chartModel = chartModels[index]
                let isHidden = mapKey[index].boolValue
                if !isHidden {
                    lastVisibleIndex = index
                }
                
                var stackData = [PointModel]()
                for j in 0..<chartModel.data.count {
                    if isHidden {
                        stackData.append(zeroValue)
                    } else {
                        if percentage {
                            stackData.append(PointModel(value: chartModel.data[j].value, date: fakeDate))
                        } else {
                            let value = chartModel.data[j].value
                            let previousValue = allStackData![j].value
                            allStackData![j].value += value
                            stackData.append(PointModel(value: previousValue + value, date: fakeDate))
                        }
                    }
                }
                chartModels[index].stackData[mapKey] = stackData
            }
            
            // Calc all procenteges for all states.
            if percentage {
                for indexData in 0..<countData {
                    var totalValue = 0
                    for index in 0..<chartModels.count {
                        let value = chartModels[index].stackData[mapKey]![indexData].value
                        totalValue += value
                    }
                    var totalPercentage = 100
                    for index in 0..<chartModels.count {
                        var percentageValue = 0
                        let value = chartModels[index].stackData[mapKey]![indexData].value
                        if index == lastVisibleIndex {
                            percentageValue = value == 0 ? 0 : totalPercentage
                        } else if totalValue != 0 {
                            percentageValue = Int(round(CGFloat(value) * CGFloat(100) / CGFloat(totalValue)))
                        }
                        chartModels[index].stackData[mapKey]![indexData].value = percentageValue
                        totalPercentage -= percentageValue
                    }
                }
                
                // Make stack fro percentages.
                for indexData in 0..<countData {
                    var prevoiusValue = 0
                    for index in 0..<chartModels.count {
                        let value = chartModels[index].stackData[mapKey]![indexData].value
                        if value != 0 {
                            chartModels[index].stackData[mapKey]![indexData].value = value + prevoiusValue
                        }
                        prevoiusValue += value
                    }
                }
            }
        }
        
    }
    
    static func makeBits(_ index: Int, _ count: Int) -> String {
        var string = String(index, radix: 2)
        string = String(repeating: "0", count: count - string.count) + string
        return string
    }
}
