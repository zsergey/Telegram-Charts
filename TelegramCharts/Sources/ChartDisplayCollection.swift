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
            // If you want to be able change drawing style uncomment this:
            // rows.append(.drawingStyle(titleDrawingStyleButton))
            // rows.append(.section(""))
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
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
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
        case .button(let text), .drawingStyle(let text):
            return ButtonTableViewCellModel(text: text, colorScheme: colorScheme)
        }
    }
    
    func height(for indexPath: IndexPath) -> CGFloat {
        let type = rows[indexPath.row]
        switch type {
        case .section(let name): return name.count > 0 ? 55 : 35
        case .chart(let main, _): return calcChartHeight(dataSource: main)
        case .button, .drawingStyle: return 46
        }
    }
    
    func calcChartHeight(dataSource: ChartDataSource) -> CGFloat {
        let mainHeight: CGFloat = 400
        let oneLineHeight: CGFloat = 41
        let additionalHeight: CGFloat = 4
        var countLines: CGFloat = 1
        let leadingSpace: CGFloat = 16
        let trailingSpace: CGFloat = 16
        var x = leadingSpace
        var y: CGFloat = 0
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
        return mainHeight + countLines * oneLineHeight + additionalHeight
    }
    
    func didSelect(indexPath: IndexPath) {
        let type = rows[indexPath.row]
        switch type {
        case .drawingStyle:
            FeedbackGenerator.impactOccurred(style: .medium)
            drawingStyle = drawingStyle is StandardDrawingStyle ? CurveDrawingStyle() : StandardDrawingStyle()
            createRows()
            changeDrawingStyle(to: drawingStyle)
            onChangeDrawingStyle?()
        default: break
        }
    }

}
