//
//  SectionTableViewCellModel.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 22/03/2019.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import Foundation

struct SectionTableViewCellModel {
    var text: String
    var colorScheme: ColorSchemeProtocol
}

extension SectionTableViewCellModel: CellViewModelType {
    
    func setup(on cell: SectionTableViewCell) {
        cell.label.text = text
        cell.label.textColor = colorScheme.section.text
        cell.backgroundColor = colorScheme.section.background
    }
}
