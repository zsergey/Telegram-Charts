//
//  Int+Format.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/14/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import Foundation

extension Int {
    var format: String {
        switch self {
        case 0..<1_000:
            return "\(self)"
        case 1_000..<1_000_000:
            let value = Float(self) / 1_000
            let twoDecimalPlaces = String(format: "%.1f", value)
            return "\(twoDecimalPlaces)K"
        default:
            let value = Float(self) / 1_000_000
            let twoDecimalPlaces = String(format: "%.1f", value)
            return "\(twoDecimalPlaces)M"
        }
    }
}
