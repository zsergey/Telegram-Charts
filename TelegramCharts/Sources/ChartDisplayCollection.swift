//
//  ChartDisplayCollection.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/22/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ChartDisplayCollection: DisplayCollection {
    
    var charts: [[ChartModel]] = []
    
    static var modelsForRegistration: [CellViewAnyModelType.Type] {
        return [ChartTableViewCellModel.self,
                TitleTableViewCellModel.self,
                ButtonTableViewCellModel.self]

    }
    
    func numberOfRows(in section: Int) -> Int {
        return charts.count
    }
    
    func model(for indexPath: IndexPath) -> CellViewAnyModelType {
        return ChartTableViewCellModel(chartModels: charts[indexPath.row])
    }
    
    func height(for indexPath: IndexPath) -> CGFloat {
        return 500
    }
}
