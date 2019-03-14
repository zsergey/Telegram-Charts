//
//  DrawingStyleProtocol.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/14/19.
//  Copyright © 2019 Sergey Zapuhlyak. All rights reserved.
//

import UIKit

protocol DrawingStyleProtocol {
    func createPath(dataPoints: [CGPoint]) -> UIBezierPath?
}
