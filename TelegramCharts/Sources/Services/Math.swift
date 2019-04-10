//
//  Math.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 4/10/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct Math {
    
    // Source: https://math.stackexchange.com/questions/121720/ease-in-out-function
    //
    static func calcEaseInOut(for time: Int, totalTime: Int) -> CGFloat {
        guard time < totalTime else {
            return 0
        }
        assert(time < totalTime, "Math.calcEaseInOut: time must be less than total time")
        let x = CGFloat(time) / CGFloat(totalTime - 1)
        let y = (x * x) / (x * x + (1.0 - x) * (1.0 - x))
        return y
    }
    
    static func calcDeltaEaseInOut(for time: Int, totalTime: Int) -> CGFloat {
        guard time < totalTime else {
            return 0
        }

        assert(time < totalTime, "Math.calcDeltaEaseInOut: time must be less than total time")
        let previousTime = time - 1
        let previousValue = previousTime >= 0 ? calcEaseInOut(for: previousTime, totalTime: totalTime) : 0
        let value = calcEaseInOut(for: time, totalTime: totalTime)
        return value - previousValue
    }

    static func isEqualArrays(_ values: [CGFloat], _ otherValues: [CGFloat]) -> Bool {
        guard values.count == otherValues.count else {
            return false
        }
        for index in 0..<values.count {
            if values[index] != otherValues[index] {
                return false
            }
        }
        return true
    }

}
