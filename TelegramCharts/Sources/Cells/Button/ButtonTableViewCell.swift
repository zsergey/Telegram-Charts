//
//  ButtonTableViewCell.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 21/03/2019.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ButtonTableViewCell: UITableViewCell {

    @IBOutlet var label: UILabel!
    
    var model: ButtonTableViewCellModel?
}

extension ButtonTableViewCell: ColorUpdatable {
    
    func updateColors(changeColorScheme: Bool) {
        if let model = model {
            if changeColorScheme {
                model.colorScheme = model.colorScheme.next()
            }
            self.label.textColor = model.colorScheme.button.normal
            self.backgroundColor = model.colorScheme.chart.background
            self.selectedBackgroundView = model.colorScheme.selectedCellView
        }
    }
}
