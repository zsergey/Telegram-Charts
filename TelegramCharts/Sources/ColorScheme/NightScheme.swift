//
//  NightScheme.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/14/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct NightScheme: ColorSchemeProtocol {

    var background: UIColor {
        return UIColor(hex: "#24303F")!
    }
    
    var selectedCellView: UIView {
        return view(by: UIColor(hex: "#1F2A39")!)
    }

    var title: UIColor {
        return UIColor(hex: "#FFFFFF")!
    }
    
    var statusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var separator: UIColor {
        return UIColor(hex: "#131A22")!
    }
    
    var separatorImageName: String {
        return "NightColorSeparator"
    }

    var button: ButtonColor {
        return ButtonColor(normal: UIColor(hex: "#327FDE")!)
    }

    var section: SectionColor {
        return SectionColor(background: UIColor(hex: "#1A222C")!,
                            text: UIColor(hex: "#5E6B7D")!)
    }

    var chart: ChartColor {
        return ChartColor(background: UIColor(hex: "#242F3E")!,
                          grid: UIColor(hex: "#141B22", alpha: 0.4)!, 
                          accentGrid: UIColor(hex: "#141B22")!,
                          text: UIColor(hex: "#606D7C")!)
    }

    var slider: SliderColor {
        return SliderColor(thumb: UIColor(hex: "#58626C")!,
                           background: UIColor(hex: "#1D2A39", alpha: 0.8)!,
                           arrow: UIColor(hex: "#FFFFFF")!)
    }
    
    var dotInfo: DotInfo {
        return DotInfo(background: UIColor(hex: "#1D2836")!,
                       text: UIColor(hex: "#FFFFFF")!)
    }
}
