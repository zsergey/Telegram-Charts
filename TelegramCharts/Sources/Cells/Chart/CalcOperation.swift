//
//  CalcOperation.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 4/12/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import Foundation

class CalcOperation: Operation {

    let dataSource: ChartDataSource
    let shouldCalcMaxValue: Bool
    let animateMaxValue: Bool
    let changedIsHidden: Bool

    init(dataSource: ChartDataSource,
         shouldCalcMaxValue: Bool,
         animateMaxValue: Bool,
         changedIsHidden: Bool) {

        self.dataSource = dataSource
        self.shouldCalcMaxValue = shouldCalcMaxValue
        self.animateMaxValue = animateMaxValue
        self.changedIsHidden = changedIsHidden
    }
    
    override func main() {
        if self.isCancelled {
            return
        }
        
        dataSource.calcProperties(shouldCalcMaxValue: shouldCalcMaxValue,
                                  animateMaxValue: animateMaxValue,
                                  changedIsHidden: changedIsHidden)
    }
}
