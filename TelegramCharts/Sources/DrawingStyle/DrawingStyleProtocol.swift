//
//  DrawingStyleProtocol.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/14/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

protocol DrawingStyleProtocol {
    func createPath(dataPoints: [CGPoint], lineGap: CGFloat, viewSize: CGSize) -> UIBezierPath?
}
