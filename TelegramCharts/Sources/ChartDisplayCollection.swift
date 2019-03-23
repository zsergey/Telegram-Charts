//
//  ChartDisplayCollection.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/22/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ChartDisplayCollection: DisplayCollection {

    var onChangeDataSource: (() -> ())?
    var colorScheme: ColorSchemeProtocol
    var drawingStyle: DrawingStyleProtocol

    init(colorScheme: ColorSchemeProtocol, drawingStyle: DrawingStyleProtocol) {
        self.colorScheme = colorScheme
        self.drawingStyle = drawingStyle
    }
    
    private enum `Type` {
        case section(String)
        case chart([ChartModel])
        case title(ChartModel)
        case colorScheme(String)
        case drawingStyle(String)
        case button(String)
    }
    
    private var dataSource: [Type] = []
    
    var titleColorSchemeButton: String {
        var text = "Switch to "
        let nextMode = colorScheme is DayScheme ? "Night" : "Day"
        text = text + nextMode + " Mode"
        return  text
    }

    var titleDrawingStyleButton: String {
        var text = "Switch to "
        let nextStyle = drawingStyle is StandardDrawingStyle ? "Curve" : "Standard"
        text = text + nextStyle + " Drawing Style"
        return  text
    }

    var charts: [[ChartModel]] = [] {
        didSet {
            createDataSource()
        }
    }
    
    static var modelsForRegistration: [CellViewAnyModelType.Type] {
        return [ChartTableViewCellModel.self,
                TitleTableViewCellModel.self,
                SectionTableViewCellModel.self,
                ButtonTableViewCellModel.self]
    }
    
    private func createDataSource() {
        dataSource.removeAll()
        for index in 0..<charts.count {
            let chart = charts[index]
            dataSource.append(.section("FOLLOWERS"))
            dataSource.append(.chart(chart))
            _ = chart.map { dataSource.append(.title($0)) }
            dataSource.append(.section(""))
            dataSource.append(.colorScheme(titleColorSchemeButton))
            dataSource.append(.drawingStyle(titleDrawingStyleButton))
        }
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
            case .title: left = 44
            default: left = 0
            }
        case .button, .colorScheme, .drawingStyle: left = 0
        }
        return UIEdgeInsets(top: 0, left: left, bottom: 0, right: 0)
    }
    
    func accessoryType(for indexPath: IndexPath) -> UITableViewCell.AccessoryType {
        let type = dataSource[indexPath.row]
        switch type {
        case .title(let model): return model.isHidden ? .none : .checkmark
        default: return .none
        }
    }
    
    func model(for indexPath: IndexPath) -> CellViewAnyModelType {
        let type = dataSource[indexPath.row]
        switch type {
        case .section(let name):
            return SectionTableViewCellModel(text: name, colorScheme: colorScheme)
        case .chart(let models):
            return ChartTableViewCellModel(chartModels: models, colorScheme: colorScheme, drawingStyle: drawingStyle)
        case .title(let model):
            return TitleTableViewCellModel(text: model.name, color: model.color, colorScheme: colorScheme)
        case .button(let text), .colorScheme(let text), .drawingStyle(let text):
            return ButtonTableViewCellModel(text: text, colorScheme: colorScheme)
        }
    }
    
    func height(for indexPath: IndexPath) -> CGFloat {
        let type = dataSource[indexPath.row]
        switch type {
        case .section(let name): return name.count > 0 ? 55 : 35
        case .chart: return 370
        case .title: return 45
        case .button, .colorScheme, .drawingStyle: return 50
        }
    }
    
    func didSelect(indexPath: IndexPath) -> IndexPath? {
        var result: IndexPath?
        let type = dataSource[indexPath.row]
        switch type {
        case .colorScheme:
            colorScheme = colorScheme is DayScheme ? NightScheme() : DayScheme()
            createDataSource()
            onChangeDataSource?()
        case .drawingStyle:
            drawingStyle = drawingStyle is StandardDrawingStyle ? CurveDrawingStyle() : StandardDrawingStyle()
            createDataSource()
            onChangeDataSource?()
        case .title(let model):
            FeedbackGenerator.impactOccurred(style: .medium)
            model.isHidden = !model.isHidden
            var row = indexPath.row
            while row > 0 {
                row -= 1
                let type = dataSource[row]
                switch type {
                case .chart:
                    result = IndexPath(row: row, section: indexPath.section)
                    return result
                default: break
                }
            }
        default: break
        }
        return result
    }

}
