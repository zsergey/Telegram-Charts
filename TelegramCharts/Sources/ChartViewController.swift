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
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.rowHeight = 0
            tableView.estimatedRowHeight = 370
        }
    }
    
    var needsLayoutNavigationBar = false
    
    var colorScheme: ColorSchemeProtocol! {
        didSet {
            (navigationController as? NavigationViewController)?.colorScheme = colorScheme
            
            let navigationBar = self.navigationController?.navigationBar
            UIView.animateEaseInOut(with: UIView.animationDuration) {
                self.tableView.layer.backgroundColor = self.colorScheme.section.background.cgColor
                self.tableView.separatorColor = self.colorScheme.separator
                
                navigationBar?.barTintColor = self.colorScheme.background
                navigationBar?.titleTextAttributes = [.foregroundColor: self.colorScheme.title]
                if self.needsLayoutNavigationBar {
                    navigationBar?.layoutIfNeeded()
                }
            }
        }
    }
    
    var drawingStyleProtocol: DrawingStyleProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.isTranslucent = false
        
        createDisplayCollection()

        self.activityIndicator.startAnimating()
        self.tableView.separatorStyle = .none

        DispatchQueue.global(qos: .background).async {
            let dataSource = ChartDataSourceFactory.make()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.displayCollection = ChartDisplayCollection(dataSource: dataSource,
                                                                colorScheme: self.colorScheme,
                                                                drawingStyle: self.drawingStyleProtocol)
                self.tableView.separatorStyle = .singleLine
                self.activityIndicator.stopAnimating()
                self.tableView.reloadData()
            }
        }

        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .current, forMode: .common)
        
        needsLayoutNavigationBar = true
    }
    
    func createDisplayCollection() {
        colorScheme = DayScheme()
        drawingStyleProtocol = StandardDrawingStyle()
        let dataSource = СoupleChartDataSource(main: [ChartDataSource](),
                                                preview: [ChartDataSource]())

        displayCollection = ChartDisplayCollection(dataSource: dataSource,
                                                   colorScheme: colorScheme,
                                                   drawingStyle: drawingStyleProtocol)
        
        displayCollection.onChangeDrawingStyle = { [weak self] in
            guard let self = self else { return }
            let cells = self.tableView.visibleCells
            for cell in cells {
                if let cell = cell as? ChartTableViewCell {
                    cell.calcProperties()
                }
            }
        }
        
        displayCollection.onChangeColorScheme = { [weak self] in
            guard let self = self else { return }
            self.colorScheme = self.displayCollection.colorScheme
            for cell in self.tableView.visibleCells {
                if let cell = cell as? ColorUpdatable {
                    cell.updateColors(animated: true)
                }
            }
        }
        tableView.registerNibs(from: displayCollection)
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

    func didSelectRow(at indexPath: IndexPath, chartAt chartIndexPath: IndexPath?) {
        if let _ = tableView.cellForRow(at: indexPath) as? TitleTableViewCell {
            reloadRows([indexPath])
        }
        if let chartIndexPath = chartIndexPath,
            let cell = tableView.cellForRow(at: chartIndexPath) as? ChartTableViewCell {
            cell.calcProperties()
        }
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
        didSelectRow(at: indexPath, chartAt: chartIndexPath)
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
