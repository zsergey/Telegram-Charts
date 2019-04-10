//
//  DisplayCollection.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 21/03/2019.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import Foundation

protocol DisplayCollection {
    static var modelsForRegistration: [CellViewAnyModelType.Type] { get }
    
    func numberOfRows(in section: Int) -> Int
    func fetchModel(for indexPath: IndexPath) -> CellViewAnyModelType
}

extension DisplayCollection {
    var numberOfSections: Int {
        return 1
    }
}
