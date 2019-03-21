//
//  CellViewModel.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 21/03/2019.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

protocol CellViewAnyModelType {
    static func cellClass() -> UIView.Type
    func setupDefault(on cell: UIView)
}

protocol CellViewModelType: CellViewAnyModelType {
    associatedtype CellClass: UIView
    func setup(on cell: CellClass)
}

extension CellViewModelType {
    static func cellClass() -> UIView.Type {
        return Self.CellClass.self
    }
    
    func setupDefault(on cell: UIView) {
        setup(on: cell as! Self.CellClass)
    }
}
