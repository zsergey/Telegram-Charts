//
//  Date+Formatter.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/20/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import Foundation

extension Date {
    
    var format: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: self)
    }
    
}
