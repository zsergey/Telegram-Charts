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

struct ChartColor {
    var background: UIColor
    var grid: UIColor
    var text: UIColor
}

protocol ColorSchemeProtocol {
    var background: UIColor { get }
    var title: UIColor { get }
    var statusBarStyle: UIStatusBarStyle { get }
    
    var chart: ChartColor { get }
    var slider: SliderColor { get }
}
