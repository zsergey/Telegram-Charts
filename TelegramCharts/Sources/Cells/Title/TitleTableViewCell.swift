//
//  TitleTableViewCell.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 21/03/2019.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class TitleTableViewCell: UITableViewCell {

    @IBOutlet var iconView: UIView!
    @IBOutlet var label: UILabel!
    
    var model: TitleTableViewCellModel?

    override func setSelected(_ selected: Bool, animated: Bool) {
        let color = iconView.backgroundColor
        super.setSelected(selected, animated: animated)
        
        if selected {
            iconView.backgroundColor = color
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let color = iconView.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        
        if highlighted {
            iconView.backgroundColor = color
        }
    }
}

extension TitleTableViewCell: ColorUpdatable {
    
    func updateColors(animated: Bool) {
        if let model = model {
            if animated {
                model.colorScheme = model.colorScheme.next()
            }
            self.selectedBackgroundView = model.colorScheme.selectedCellView
            let animations = {
                self.label.textColor = model.colorScheme.title
                self.backgroundColor = model.colorScheme.chart.background
            }
            if animated {
                UIView.animateEaseInOut(with: UIView.animationDuration, animations: animations)
            } else {
                animations()
            }
        }
    }
}
