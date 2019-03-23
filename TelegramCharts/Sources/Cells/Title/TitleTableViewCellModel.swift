//
//  TitleTableViewCellModel.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/22/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct TitleTableViewCellModel {
    var text: String
    var color: UIColor
    var colorScheme: ColorSchemeProtocol
}

extension TitleTableViewCellModel: CellViewModelType {
    
    func setup(on cell: TitleTableViewCell) {
        cell.label.text = text
        cell.label.textColor = colorScheme.title
        cell.iconView.layer.cornerRadius = 3
        cell.iconView.layer.backgroundColor = color.cgColor
        cell.backgroundColor = colorScheme.chart.background
        cell.selectedBackgroundView = colorScheme.selectedCellView
    }
}
