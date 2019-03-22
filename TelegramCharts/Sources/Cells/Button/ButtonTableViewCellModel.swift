//
//  ButtonTableViewCellModel.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/22/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import Foundation

struct ButtonTableViewCellModel {
    var text: String
    var colorScheme: ColorSchemeProtocol
}

extension ButtonTableViewCellModel: CellViewModelType {
    
    func setup(on cell: ButtonTableViewCell) {
        cell.button.setTitle(text, for: .normal)
        cell.button.setTitleColor(colorScheme.button.normal, for: .normal)
        cell.button.setTitleColor(colorScheme.button.selected, for: .selected)
        cell.backgroundColor = colorScheme.chart.background
    }
}
