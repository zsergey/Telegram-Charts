//
//  ButtonTableViewCellModel.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/22/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ButtonTableViewCellModel {
    var text: String
    var colorScheme: ColorSchemeProtocol
    
    init(text: String, colorScheme: ColorSchemeProtocol) {
        self.text = text
        self.colorScheme = colorScheme
    }
}

extension ButtonTableViewCellModel: CellViewModelType {
    
    func setup(on cell: ButtonTableViewCell) {
        cell.model = self
        cell.label.text = text
        cell.updateColors(animated: false)
    }
}
