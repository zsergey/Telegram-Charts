//
//  DayScheme.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/14/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct DayScheme: ColorSchemeProtocol {
    
    var background: UIColor
    
    var selectedCellView: UIView
    
    var title: UIColor
    
    var statusBarStyle: UIStatusBarStyle
    
    var separator: UIColor
    
    var separatorImageName: String
    
    var button: ButtonColor
    
    var section: SectionColor
    
    var chart: ChartColor
    
    var slider: SliderColor
    
    var dotInfo: DotInfo
    
    init() {
        
        background = UIColor(hex: "#F7F7F7")!
        
        selectedCellView = UIView()
        
        title = UIColor(hex: "#000000")!
        
        statusBarStyle = .default
        
        separator = UIColor(hex: "#C8C7CC")!
        
        separatorImageName = "DayColorSeparator"
        
        button = ButtonColor(normal: UIColor(hex: "#327FDE")!)
        
        section = SectionColor(background: UIColor(hex: "#EFEFF4")!,
                               text: UIColor(hex: "#6D6D72")!)
        
        chart = ChartColor(background: UIColor(hex: "#FEFEFE")!,
                           grid: UIColor(hex: "#CFD1D2", alpha: 0.4)!,
                           accentGrid: UIColor(hex: "#CFD1D2")!,
                           text: UIColor(hex: "#999EA2")!)
        
        slider = SliderColor(thumb: UIColor(hex: "#C3D1DF")!,
                             background: UIColor(hex: "#F7F8FA", alpha: 0.8)!,
                             arrow: UIColor(hex: "#FFFFFF")!)

        dotInfo = DotInfo(background: UIColor(hex: "#F4F4F9")!,
                          text: UIColor(hex: "#6D6D72")!)
        
        selectedCellView = self.view(by: UIColor(hex: "#F6F8FA")!)
    }
}
