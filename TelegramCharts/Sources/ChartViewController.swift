//
//  ChartsViewController.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/11/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ChartViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var displayCollection: ChartDisplayCollection!
    
    @IBOutlet var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.rowHeight = 0
            tableView.estimatedRowHeight = 372
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
        
        let empty = СoupleChartDataSource(main: [ChartDataSource](),
                                           preview: [ChartDataSource]())
        self.displayCollection = createDisplayCollection(dataSource: empty)

        let dataSource = ChartDataSourceFactory.make()
        self.displayCollection = self.createDisplayCollection(dataSource: dataSource)
        self.tableView.reloadData()

        let displayLink = CADisplayLink(target: self, selector: #selector(update(link:)))
        displayLink.add(to: .current, forMode: .common)
        
        needsLayoutNavigationBar = true
    }
    
    func createDisplayCollection(dataSource: СoupleChartDataSource) -> ChartDisplayCollection {
        colorScheme = DayScheme()
        drawingStyleProtocol = StandardDrawingStyle()

        let displayCollection = ChartDisplayCollection(dataSource: dataSource,
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
        return displayCollection
    }
    
    var lastTime: CFTimeInterval = 0.0
    var firstTime: CFTimeInterval = 0.0

    @objc func update(link: CADisplayLink) {
        
        if lastTime == 0.0 {
            firstTime = link.timestamp
            lastTime = link.timestamp
        }
        
        let currentTime = link.timestamp
        let elapsedTime = floor((currentTime - lastTime) * 10_000) / 10
        let totalElapsedTime = currentTime - firstTime
        
        if elapsedTime > 16.7 {
            print("Frame was dropped with elapsed time of \(elapsedTime) at \(totalElapsedTime)")
        }
        lastTime = link.timestamp
        
        tableView.visibleCells.forEach { ($0 as? ChartTableViewCell)?.update() }
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
        if let cell = tableView.cellForRow(at: indexPath) {
            if cell is TitleTableViewCell {
                reloadRows([indexPath])
            } else if cell is ButtonTableViewCell {
                // Update all buttons.
                for visibleCell in tableView.visibleCells {
                    if let cell = visibleCell as? ButtonTableViewCell {
                        if let indexPath = tableView.indexPath(for: cell) {
                            displayCollection.updateButtonText(for: indexPath,
                                                               in: cell)
                        }
                    }
                }
            }
        }
        if let chartIndexPath = chartIndexPath,
            let cell = tableView.cellForRow(at: chartIndexPath) as? ChartTableViewCell {
            cell.model?.chartDataSource.selectedIndex = nil
            cell.chartView.cleanDots()
            cell.calcProperties()
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollingStarted()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            scrollingStarted()
        } else {
            scrollingFinished()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollingFinished()
    }
    
    func scrollingFinished() {
        for cell in tableView.visibleCells {
            if let cell = cell as? ChartTableViewCell {
                cell.chartView.isScrolling = false
                cell.previewChartView.isScrolling = false
                cell.chartView.drawLabels(byScroll: true)
            }
        }
    }
    
    func scrollingStarted() {
        for cell in tableView.visibleCells {
            if let cell = cell as? ChartTableViewCell {
                cell.chartView.isScrolling = true
                cell.previewChartView.isScrolling = true
            }
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
