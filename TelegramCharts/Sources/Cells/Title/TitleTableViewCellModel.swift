//
//  TitleTableViewCellModel.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/22/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class TitleTableViewCellModel {
    var text: String
    var color: UIColor
    var colorScheme: ColorSchemeProtocol
    
    init(text: String, color: UIColor, colorScheme: ColorSchemeProtocol) {
        self.text = text
        self.color = color
        self.colorScheme = colorScheme
    }
}

extension TitleTableViewCellModel: CellViewModelType {
    
    func setup(on cell: TitleTableViewCell) {
        cell.model = self
        cell.label.text = text
        cell.iconView.layer.cornerRadius = 3
        cell.iconView.layer.backgroundColor = color.cgColor
        cell.updateColors(animated: false)
    }
}
