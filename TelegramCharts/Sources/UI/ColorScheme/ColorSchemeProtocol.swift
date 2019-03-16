//
//  ColorSchemeProtocol.swift
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

    var shortBackgroundColor: UIColor { get } // zsergey - временная
}
