//
//  DateCache.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 4/14/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import Foundation

class DateCache {
    
    var chachedShortDates = [Date: String]()
    var chachedFullDates = [Date: String]()

    static var shared = DateCache()
    
    @discardableResult
    func shortFormat(for date: Date) -> String {
        if let value = chachedShortDates[date] {
            return value
        }
        
        let value = date.shortFormat
        chachedShortDates[date] = value
        return value
    }
    
    @discardableResult
    func fullFormat(for date: Date) -> String {
        if let value = chachedFullDates[date] {
            return value
        }
        
        let value = date.fullFormat
        chachedFullDates[date] = value
        return value
    }
}
