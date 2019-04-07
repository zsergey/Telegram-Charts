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
    var drawingStyle: DrawingStyleProtocol

    init(dataSource: СoupleChartDataSource,
         colorScheme: ColorSchemeProtocol,
         drawingStyle: DrawingStyleProtocol) {
        self.dataSource = dataSource
        self.colorScheme = colorScheme
        self.drawingStyle = drawingStyle
        self.changeDrawingStyle(to: drawingStyle)
        self.createRows()
    }
    
    var onChangeDrawingStyle: (() -> ())?

    private enum `Type` {
        case section(String)
        case chart(ChartDataSource, ChartDataSource)
        case title(ChartModel)
        case drawingStyle(String)
        case button(String)
    }
    
    private var rows: [Type] = []
    
    private var titleDrawingStyleButton: String {
        var text = "Switch to "
        let nextStyle = drawingStyle is StandardDrawingStyle ? "Curve" : "Standard"
        text = text + nextStyle + " Drawing Style"
        return text
    }
    
    static var modelsForRegistration: [CellViewAnyModelType.Type] {
        return [ChartTableViewCellModel.self,
                TitleTableViewCellModel.self,
                SectionTableViewCellModel.self,
                ButtonTableViewCellModel.self]
    }
    
    private func createRows() {
        rows.removeAll()
        for index in 0..<dataSource.main.count {
            let main = dataSource.main[index]
            let preview = dataSource.preview[index]
            rows.append(.section(main.name))
            rows.append(.chart(main, preview))
            main.chartModels.forEach { rows.append(.title($0)) }
            rows.append(.section(""))
            // If you want to be able change drawing style uncomment this:
            // rows.append(.drawingStyle(titleDrawingStyleButton))
        }
    }
    
    func changeDrawingStyle(to drawingStyle: DrawingStyleProtocol) {
        dataSource.main.forEach { $0.drawingStyle = drawingStyle }
        dataSource.preview.forEach { $0.drawingStyle = drawingStyle }
    }
    
    func numberOfRows(in section: Int) -> Int {
        return rows.count
    }

    func separatorInset(for indexPath: IndexPath, view: UIView) -> UIEdgeInsets {
        var left = view.frame.size.width
        let type = rows[indexPath.row]
        switch type {
        case .section: left = 0
        case .chart: break
        case .title:
            switch rows[indexPath.row + 1] {
            case .title: left = 45
            default: left = 0
            }
        case .button, .drawingStyle: left = 0
        }
        return UIEdgeInsets(top: 0, left: left, bottom: 0, right: 0)
    }
    
    func accessoryType(for indexPath: IndexPath) -> UITableViewCell.AccessoryType {
        let type = rows[indexPath.row]
        switch type {
        case .title(let model): return model.isHidden ? .none : .checkmark
        default: return .none
        }
    }
    
    func updateButtonText(for indexPath: IndexPath, in cell: ButtonTableViewCell) {
        let type = rows[indexPath.row]
        switch type {
        case .drawingStyle:
            cell.label.text = titleDrawingStyleButton
        default: break
        }
    }
    
    func model(for indexPath: IndexPath) -> CellViewAnyModelType {
        let type = rows[indexPath.row]
        switch type {
        case .section(let name):
            return SectionTableViewCellModel(text: name, colorScheme: colorScheme)
        case .chart(let main, let preview):
            return ChartTableViewCellModel(chartDataSource: main,
                                           previewChartDataSource: preview,
                                           colorScheme: colorScheme, drawingStyle: drawingStyle)
        case .title(let model):
            return TitleTableViewCellModel(text: model.name, color: model.color, colorScheme: colorScheme)
        case .button(let text), .drawingStyle(let text):
            return ButtonTableViewCellModel(text: text, colorScheme: colorScheme)
        }
    }
    
    func height(for indexPath: IndexPath) -> CGFloat {
        let type = rows[indexPath.row]
        switch type {
        case .section(let name): return name.count > 0 ? 55 : 35
        case .chart: return 372
        case .title: return 45
        case .button, .drawingStyle: return 46
        }
    }
    
    func didSelect(indexPath: IndexPath) -> IndexPath? {
        let type = rows[indexPath.row]
        switch type {
        case .drawingStyle:
            FeedbackGenerator.impactOccurred(style: .medium)
            drawingStyle = drawingStyle is StandardDrawingStyle ? CurveDrawingStyle() : StandardDrawingStyle()
            createRows()
            changeDrawingStyle(to: drawingStyle)
            onChangeDrawingStyle?()
        case .title(let model):
            FeedbackGenerator.impactOccurred(style: .medium)
            model.isHidden = !model.isHidden
        default: break
        }

        var result: IndexPath?
        switch type {
        case .title:
            var row = indexPath.row
            while row > 0 {
                row -= 1
                let type = rows[row]
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
