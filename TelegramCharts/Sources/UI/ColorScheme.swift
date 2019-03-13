//
//  ColorScheme.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/13/19.
//  Copyright © 2019 Sergey Zapuhlyak. All rights reserved.
//

import UIKit

protocol ColorSchemeProtocol {
    var backgroundColor: UIColor { get }
    var gridColor: UIColor { get }
    var textColor: UIColor { get }
}

struct DayScheme: ColorSchemeProtocol {
    var backgroundColor: UIColor { return UIColor(hex: "#FEFEFE")! }
    var gridColor: UIColor { return UIColor(hex: "#FEFEFE")! }
    var textColor: UIColor { return UIColor(hex: "#999EA2")!}
}

struct HightScheme: ColorSchemeProtocol {
    var backgroundColor: UIColor { return UIColor(hex: "#242F3E")! }
    var gridColor: UIColor { return UIColor(hex: "#1D2733")! }
    var textColor: UIColor { return UIColor(hex: "#606D7C")!}
}

