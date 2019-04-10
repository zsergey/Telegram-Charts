//
//  SectionTableViewCellModel.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 22/03/2019.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class SectionTableViewCellModel {
    var text: String
    var colorScheme: ColorSchemeProtocol

    init(text: String, colorScheme: ColorSchemeProtocol) {
        self.text = text
        self.colorScheme = colorScheme
    }
}

extension SectionTableViewCellModel: CellViewModelType {

    func setup(on cell: SectionTableViewCell) {
        cell.model = self
        cell.label.text = text
        cell.updateColors(changeColorScheme: false)
    }
}
