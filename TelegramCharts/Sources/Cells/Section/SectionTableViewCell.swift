//
//  SectionTableViewCell.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 22/03/2019.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class SectionTableViewCell: UITableViewCell {
    
    @IBOutlet var label: UILabel!
    
    var model: SectionTableViewCellModel?
}

extension SectionTableViewCell: ColorUpdatable {
    
    func updateColors(changeColorScheme: Bool) {
        if let model = model {
            if changeColorScheme {
                model.colorScheme = model.colorScheme.next()
            }
            self.label.textColor = model.colorScheme.section.text
            self.label.backgroundColor = model.colorScheme.section.background
            self.backgroundColor = model.colorScheme.section.background
        }
    }
}
