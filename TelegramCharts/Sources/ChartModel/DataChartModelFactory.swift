//
//  DataChartModelFactory.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/11/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct DataChartModelFactory {
    
    @discardableResult
    static func make(fromResource name: String) -> [DataChartModel]? {
        guard let path = Bundle.main.path(forResource: name, ofType: "json") else {
            return nil
        }
        
        let url = URL(fileURLWithPath: path)
        
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
            let jsonResult = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
            let array = jsonResult as? [[String: Any]] else {
                return nil
        }
        
        return readArray(array)
    }
    
    private static func readArray(_ array: [[String : Any]]) -> [DataChartModel]? {
        var chartModels = [DataChartModel]()
        
        for index in 0..<array.count {
            let dictionary = array[index]
            guard let columns = dictionary["columns"] as? [[Any]],
                let types = dictionary["types"] as? [String: Any],
                let names = dictionary["names"] as? [String: Any],
                let colors = dictionary["colors"] as? [String: Any] else {
                    continue
            }
            
            var chartModel = DataChartModel()
            readTypeChart(from: dictionary, to: &chartModel, types: types)
            
            for column in columns {
                readColumn(column, to: &chartModel, types, names, colors)
            }
            chartModels.append(chartModel)
        }
        
        return chartModels
    }
    
    private static func readTypeChart(from dictionary: [String : Any],
                                      to chartModel: inout DataChartModel,
                                      types: [String : Any]) {
        if let value = dictionary["y_scaled"] as? Bool {
            chartModel.yScaled = value
        }
        if let value = dictionary["stacked"] as? Bool {
            chartModel.stacked = value
        }
        if types.count == 2, types["x"] != nil, let y = types["y0"] as? String,
            let type = ColumnType(rawValue: y), type == .bar {
            chartModel.singleBar = true
        }
        if let value = dictionary["percentage"] as? Bool {
            chartModel.percentage = value
        }
    }

    private static func readColumn(_ column: [Any], to chartModel: inout DataChartModel,
                                   _ types: [String : Any],
                                   _ names: [String : Any],
                                   _ colors: [String : Any]) {
        
        guard column.count > 0, let label = column[0] as? String,
            let typeRawValue = types[label] as? String,
            let type = ColumnType(rawValue: typeRawValue) else {
                return
        }
        
        chartModel.labels.append(label)
        chartModel.types[label] = type
        
        if let name = names[label] as? String {
            chartModel.names[label] = name
        }
        
        if let hexValue = colors[label] as? String,
            let color = UIColor(hex: hexValue) {
            chartModel.colors[label] = color
        }
        
        chartModel.data[label] = readData(with: type, from: column)
    }
    
    private static func readData(with type: ColumnType, from column: [Any]) -> [Any] {
        var data = [Any]()
        let startIndex = 1
        guard column.count > startIndex else { return data }
        for index in startIndex..<column.count {
            let columnData = column[index]
            if type == .x {
                if let timeInterval = columnData as? TimeInterval {
                    let date = Date(timeIntervalSince1970: timeInterval / 1000)
                    data.append(date)
                }
            } else if let intValue = columnData as? Int {
                data.append(intValue)
            }
        }
        return data
    }
}
