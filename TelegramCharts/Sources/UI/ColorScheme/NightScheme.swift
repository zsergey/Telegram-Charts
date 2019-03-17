//
//  NightScheme.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/14/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct NightScheme: ColorSchemeProtocol {
    var background: UIColor { return UIColor(hex: "#242F3E")! }
    var grid: UIColor { return UIColor(hex: "#141B22")! }
    var text: UIColor { return UIColor(hex: "#606D7C")! }
    
    var slider: SliderColor {
        return SliderColor(thumb: UIColor(hex: "#384657", alpha: 0.5)!,
                           line: UIColor(hex: "#303A4A")!,
                           background: UIColor(hex: "#1F2A39", alpha: 0.5)!,
                           arrow: UIColor(hex: "#FFFFFF")!)
    }
}
