//
//  Updatable.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/22/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

protocol Updatable {
    func update()
}

protocol ColorUpdatable {
    func updateColors(changeColorScheme: Bool)
}
