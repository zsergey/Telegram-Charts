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
    
    func updateColors(animated: Bool) {
        if let model = model {
            if animated {
                model.colorScheme = model.colorScheme.next()
            }
            let animations = {
                self.label.textColor = model.colorScheme.section.text
                self.backgroundColor = model.colorScheme.section.background
            }
            if animated {
                UIView.animateEaseInOut(with: UIView.animationDuration, animations: animations)
            } else {
                animations()
            }
        }
    }
}
