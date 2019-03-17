//
//  DayScheme.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/14/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct DayScheme: ColorSchemeProtocol {
    var background: UIColor { return UIColor(hex: "#FEFEFE")! }
    var grid: UIColor { return UIColor(hex: "#E1E2E3")! } 
    var text: UIColor { return UIColor(hex: "#999EA2")! }

    var slider: SliderColor {
        return SliderColor(thumb: UIColor(hex: "#CCD4DD", alpha: 0.5)!,
                           line: UIColor(hex: "#E6E9ED")!,
                           background: UIColor(hex: "#F6F8FA", alpha: 0.5)!,
                           arrow: UIColor(hex: "#FFFFFF")!)
    }
}
