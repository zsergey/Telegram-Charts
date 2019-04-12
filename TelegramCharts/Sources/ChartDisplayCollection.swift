//
//  ChartDisplayCollection.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/22/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ChartDisplayCollection: DisplayCollection {
    
    var dataSource: СoupleChartDataSource
    var colorScheme: ColorSchemeProtocol

    init(dataSource: СoupleChartDataSource,
         colorScheme: ColorSchemeProtocol) {
        self.dataSource = dataSource
        self.colorScheme = colorScheme
        self.createRows()
        self.calcChartHeights()
    }
    
    private enum `Type` {
        case section(String)
        case chart(ChartDataSource, ChartDataSource, Int)
    }
    
    private var rows: [Type] = []
    private var chartHeights: [CGFloat] = []
    
    static var modelsForRegistration: [CellViewAnyModelType.Type] {
        return [ChartTableViewCellModel.self,
                SectionTableViewCellModel.self]
    }
    
    private func createRows() {
        rows.removeAll()
        for index in 0..<dataSource.main.count {
            let main = dataSource.main[index]
            let preview = dataSource.preview[index]
            rows.append(.section(main.name))
            rows.append(.chart(main, preview, index))
        }
    }
    
    func numberOfRows(in section: Int) -> Int {
        return rows.count
    }

    func separatorInset(for indexPath: IndexPath, view: UIView) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func fetchModel(for indexPath: IndexPath) -> CellViewAnyModelType {
        let type = rows[indexPath.row]
        switch type {
        case .section(let name):
            return SectionTableViewCellModel(text: name, colorScheme: colorScheme)
        case .chart(let main, let preview, _):
            return ChartTableViewCellModel(chartDataSource: main,
                                           previewChartDataSource: preview,
                                           colorScheme: colorScheme)
        }
    }
    
    func height(for indexPath: IndexPath) -> CGFloat {
        let type = rows[indexPath.row]
        switch type {
        case .section(let name): return name.count > 0 ? 55 : 35
        case .chart(_, _, let index): return chartHeights[index]
        }
    }
}

private extension ChartDisplayCollection {
    
    func calcChartHeights() {
        chartHeights.removeAll()
        for index in 0..<dataSource.main.count {
            let main = dataSource.main[index]
            let height = calcChartHeight(dataSource: main)
            chartHeights.append(height)
        }
    }
    
    func calcChartHeight(dataSource: ChartDataSource) -> CGFloat {
        let titleHeight: CGFloat = 20
        let mainHeight: CGFloat = 380
        let oneLineHeight: CGFloat = 41
        let additionalHeight: CGFloat = 4
        let leadingSpace: CGFloat = 16
        let trailingSpace: CGFloat = 16
        var x = leadingSpace
        var y: CGFloat = 0
        
        var countLines: CGFloat = dataSource.chartModels.count > 1 ? 1 : 0
        if countLines > 0 {
            for i in 0..<dataSource.chartModels.count {
                let chartModel = dataSource.chartModels[i]
                let button = CheckButton(color: chartModel.color)
                button.title = chartModel.name
                if x > UIScreen.main.bounds.size.width - trailingSpace - button.frame.size.width {
                    countLines += 1
                    y += button.frame.size.height + leadingSpace / 2
                    x = leadingSpace
                }
                x += button.frame.size.width + leadingSpace / 2
            }
        }
        
        return mainHeight + countLines * oneLineHeight + additionalHeight + titleHeight
    }
}
