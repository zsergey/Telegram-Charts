//
//  ChartDisplayCollection.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/22/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ChartDisplayCollection: DisplayCollection {

    var colorScheme: ColorSchemeProtocol
    
    init(colorScheme: ColorSchemeProtocol) {
        self.colorScheme = colorScheme
    }
    
    private enum `Type` {
        case section(String)
        case chart([ChartModel])
        case title(String)
        case button(String)
    }
    
    private var dataSource: [Type] = []
    
    var charts: [[ChartModel]] = [] {
        didSet {
            dataSource.removeAll()
            for index in 0..<charts.count {
                let chart = charts[index]
                dataSource.append(.section("FOLLOWERS"))
                dataSource.append(.chart(chart))
                _ = chart.map { dataSource.append(.title($0.name)) }
                dataSource.append(.section(""))
                dataSource.append(.button("Switch to Night Mode"))
            }
        }
    }
    
    static var modelsForRegistration: [CellViewAnyModelType.Type] {
        return [ChartTableViewCellModel.self,
                TitleTableViewCellModel.self,
                SectionTableViewCellModel.self,
                ButtonTableViewCellModel.self]
    }
    
    func numberOfRows(in section: Int) -> Int {
        return dataSource.count
    }

    func separatorInset(for indexPath: IndexPath, view: UIView) -> UIEdgeInsets {
        var left = view.frame.size.width
        let type = dataSource[indexPath.row]
        switch type {
        case .section: left = 0
        case .chart: break
        case .title:
            switch dataSource[indexPath.row + 1] {
            case .title: left = 60
            default: left = 0
            }
        case .button: left = 0
        }
        return UIEdgeInsets(top: 0, left: left, bottom: 0, right: 0)
    }

    func model(for indexPath: IndexPath) -> CellViewAnyModelType {
        let type = dataSource[indexPath.row]
        switch type {
        case .section(let name): return SectionTableViewCellModel(text: name, colorScheme: colorScheme)
        case .chart(let models): return ChartTableViewCellModel(chartModels: models)
        case .title: return TitleTableViewCellModel()
        case .button(let text): return ButtonTableViewCellModel(text: text, colorScheme: colorScheme)
        }
    }
    
    func height(for indexPath: IndexPath) -> CGFloat {
        let type = dataSource[indexPath.row]
        switch type {
        case .section(let name): return name.count > 0 ? 55 : 35
        case .chart: return 370
        case .title: return 45
        case .button: return 50
        }
    }
}
