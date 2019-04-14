//
//  Date+Formatter.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/20/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import Foundation

extension Date {
    
    var shortFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: self)
    }

    var fullFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM YYYY"
        return formatter.string(from: self)
    }

}
