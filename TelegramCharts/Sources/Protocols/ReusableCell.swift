//
//  ReusableCell.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 21/03/2019.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

protocol ReusableCell {
    static var identifier: String { get }
    static var nib: UINib { get }
}
