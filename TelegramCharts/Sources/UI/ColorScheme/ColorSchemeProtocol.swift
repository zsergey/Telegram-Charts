//
//  ColorSchemeProtocol.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/13/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct SliderColor {
    let thumb: UIColor
    let line: UIColor
    let background: UIColor
    let arrow: UIColor
}

protocol ColorSchemeProtocol {
    var background: UIColor { get }
    var grid: UIColor { get }
    var text: UIColor { get }
    
    var slider: SliderColor { get }
}
