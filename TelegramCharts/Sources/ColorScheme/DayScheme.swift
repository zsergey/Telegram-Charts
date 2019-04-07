//
//  DayScheme.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/14/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct DayScheme: ColorSchemeProtocol {
    
    var background: UIColor {
        return UIColor(hex: "#F7F7F7")!
    }
    
    var selectedCellView: UIView {
        return view(by: UIColor(hex: "#F6F8FA")!)
    }

    var title: UIColor {
        return UIColor(hex: "#000000")!
    }

    var statusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    var separator: UIColor {
        return UIColor(hex: "#C8C7CC")!
    }
    
    var separatorImageName: String {
        return "DayColorSeparator"
    }
    
    var button: ButtonColor {
        return ButtonColor(normal: UIColor(hex: "#327FDE")!)
    }

    var section: SectionColor {
        return SectionColor(background: UIColor(hex: "#EFEFF4")!,
                            text: UIColor(hex: "#6D6D72")!)
    }

    var chart: ChartColor {
        return ChartColor(background: UIColor(hex: "#FEFEFE")!,
                          grid: UIColor(hex: "#CFD1D2", alpha: 0.4)!,
                          accentGrid: UIColor(hex: "#CFD1D2")!,
                          text: UIColor(hex: "#999EA2")!)
    }

    var slider: SliderColor {
        return SliderColor(thumb: UIColor(hex: "#C3D1DF")!,
                           background: UIColor(hex: "#F7F8FA", alpha: 0.8)!,
                           arrow: UIColor(hex: "#FFFFFF")!)
    }

    var dotInfo: DotInfo {
        return DotInfo(background: UIColor(hex: "#F4F4F9")!,
                       text: UIColor(hex: "#6D6D72")!)
    }
}
