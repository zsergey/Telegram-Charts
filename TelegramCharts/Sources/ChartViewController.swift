//
//  ChartsViewController.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/11/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ChartViewController: UIViewController {
    
    var displayCollection: ChartDisplayCollection!

    @IBOutlet var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.rowHeight = 0
            tableView.estimatedRowHeight = 370
        }
    }
    
    var colorScheme: ColorSchemeProtocol! {
        didSet {
            navigationController?.navigationBar.barTintColor = colorScheme.background
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: colorScheme.title]
            (navigationController as? NavigationViewController)?.colorScheme = colorScheme

            tableView.backgroundColor = colorScheme.section.background
            tableView.separatorColor = colorScheme.separator
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.isTranslucent = false

        colorScheme = NightScheme()
        
        displayCollection = ChartDisplayCollection(colorScheme: colorScheme,
                                                   drawingStyle: StandardDrawingStyle())
        displayCollection.charts = ChartModelFactory.readChartModels()
        displayCollection.onChangeDataSource = { [weak self] in
            guard let self = self else { return }
            self.colorScheme = self.displayCollection.colorScheme
            self.reloadRows(self.visibleRows())
        }
        tableView.registerNibs(from: displayCollection)

        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .current, forMode: .common)
    }
    
    @objc func update() {
        _ = tableView.visibleCells.map { ($0 as? ChartTableViewCell)?.update() }
    }

    func reloadRows(_ rows: [IndexPath]) {
        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: rows, with: .fade)
        self.tableView.endUpdates()
    }
    
    func visibleRows() -> [IndexPath] {
        var indexPaths = [IndexPath]()
        let cells = self.tableView.visibleCells
        for cell in cells {
            if let indexPath = self.tableView.indexPath(for: cell) {
                indexPaths.append(indexPath)
            }
        }
        return indexPaths
    }
    
}

extension ChartViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return displayCollection.height(for: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let model = displayCollection.model(for: indexPath)
        model.setupDefault(on: cell)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let chartIndexPath = displayCollection.didSelect(indexPath: indexPath)
        
        
        if let _ = tableView.cellForRow(at: indexPath) {
            reloadRows([indexPath])
        }
        if let chartIndexPath = chartIndexPath,
             let cell = tableView.cellForRow(at: chartIndexPath) as? ChartTableViewCell {
            cell.layoutIfNeeded()
        }
    }
}

extension ChartViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayCollection.numberOfRows(in: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = displayCollection.model(for: indexPath)
        let cell = tableView.dequeueReusableCell(for: indexPath, with: model)
        cell.separatorInset = displayCollection.separatorInset(for: indexPath, view: view)
        cell.accessoryType = displayCollection.accessoryType(for: indexPath)
        return cell
    }
}
