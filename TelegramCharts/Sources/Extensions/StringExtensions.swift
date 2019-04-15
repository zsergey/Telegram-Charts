//
//  StringExtensions.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 4/15/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import Foundation

public extension String {
    subscript(short: Int) -> String {
        get {
            return String(self[index(startIndex, offsetBy: short)])
        }
    }
    
    var boolValue: Bool {
        if self == "1" {
            return true
        }
        return false
    }
}
