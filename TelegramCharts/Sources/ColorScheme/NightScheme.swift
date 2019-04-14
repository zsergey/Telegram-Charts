//
//  NightScheme.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/14/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct NightScheme: ColorSchemeProtocol {

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
        
        background = UIColor(hex: "#24303F")!
        
        selectedCellView = UIView()
        
        title = UIColor(hex: "#FFFFFF")!
        
        statusBarStyle = .lightContent
        
        separator = UIColor(hex: "#131A22")!
        
        separatorImageName = "NightColorSeparator"
        
        button = ButtonColor(normal: UIColor(hex: "#327FDE")!)
        
        section = SectionColor(background: UIColor(hex: "#1A222C")!,
                               text: UIColor(hex: "#5E6B7D")!)

        chart = ChartColor(background: UIColor(hex: "#242F3E")!,
                           grid: UIColor(hex: "#141B22", alpha: 0.4)!,
                           accentGrid: UIColor(hex: "#141B22")!,
                           text: UIColor(hex: "#606D7C")!)
        
        
        slider = SliderColor(thumb: UIColor(hex: "#58626C")!,
                             background: UIColor(hex: "#1D2A39", alpha: 0.8)!,
                             arrow: UIColor(hex: "#FFFFFF")!)
        
        dotInfo = DotInfo(background: UIColor(hex: "#1D2836")!,
                          text: UIColor(hex: "#FFFFFF")!)
    
        selectedCellView = self.view(by: UIColor(hex: "#1F2A39")!)

    }
}

