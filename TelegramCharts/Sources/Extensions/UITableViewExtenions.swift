//
//  UITableViewExtenions.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 21/03/2019.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

extension UITableView {
    func dequeueReusableCell(for indexPath: IndexPath, with model: CellViewAnyModelType) -> UITableViewCell {
        let cellIdentifier = String(describing: type(of: model).cellClass())
        let cell = dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        return cell
    }
}

extension UITableView {
    func registerNibs(from displayCollection: DisplayCollection) {
        registerNibs(fromType: type(of: displayCollection))
    }
    
    private func registerNibs(fromType displayCollectionType: DisplayCollection.Type) {
        for cellModel in displayCollectionType.modelsForRegistration {
            if let tableCellClass = cellModel.cellClass() as? UITableViewCell.Type {
                registerNib(for: tableCellClass)
            }
        }
    }
    
    func registerNib(for cellClass: UITableViewCell.Type) {
        register(cellClass.nib, forCellReuseIdentifier: cellClass.identifier)
    }
}

