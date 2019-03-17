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
    static func fetchCharts() -> [DataChartModel]? {
        return fetchCharts(fromResource: "chart_data")
    }
    
    @discardableResult
    static func fetchCharts(fromResource name: String) -> [DataChartModel]? {
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
        
        for dictionary in array {
            guard let columns = dictionary["columns"] as? [[Any]],
                let types = dictionary["types"] as? [String: Any],
                let names = dictionary["names"] as? [String: Any],
                let colors = dictionary["colors"] as? [String: Any] else {
                    continue
            }
            
            var chartModel = DataChartModel()
            for column in columns {
                readColumn(column, to: &chartModel, types, names, colors)
            }
            chartModels.append(chartModel)
        }
        
        return chartModels
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
