//
//  ChartsViewController.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/11/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ChartViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var dateOnButton: UIBarButtonItem!
    
    static var isDateOn = false
    
    var displayCollection: ChartDisplayCollection!
   
    var isDebug = false // TODO

    var currentFPS: Int = 0 {
        didSet {
//            let text = "\(currentFPS) fps"
//            if abs(oldValue - currentFPS) > 1 {
//                buttonFPS.setTitle(text, for: .normal)
//                buttonFPS.tintColor = currentFPS < 50 ? .red : .gray
//            }
//            if currentFPS < 59 {
//                print(text)
//            }
        }
    }
    
    @IBOutlet var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.rowHeight = 0
            tableView.estimatedRowHeight = 0
        }
    }
    
    var needsLayoutNavigationBar = false
    
    var colorScheme: ColorSchemeProtocol! {
        didSet {
            (navigationController as? NavigationViewController)?.colorScheme = colorScheme
            
            let navigationBar = self.navigationController?.navigationBar
            self.tableView.backgroundColor = self.colorScheme.section.background
            UIView.animateEaseInOut(with: UIView.animationDuration) {
                self.tableView.separatorColor = self.colorScheme.separator

                navigationBar?.barTintColor = self.colorScheme.background
                navigationBar?.titleTextAttributes = [.foregroundColor: self.colorScheme.title]
                if self.needsLayoutNavigationBar {
                    navigationBar?.layoutIfNeeded()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.isTranslucent = false
        dateOnButton.isEnabled = false
        
        let dataSource = ChartDataSourceFactory.make()
        self.displayCollection = self.createDisplayCollection(dataSource: dataSource)
        self.tableView.reloadData()

        let displayLink = CADisplayLink(target: self, selector: #selector(update(link:)))
        displayLink.add(to: .current, forMode: .common)
        
        needsLayoutNavigationBar = true
    }
    
    func createDisplayCollection(dataSource: СoupleChartDataSource) -> ChartDisplayCollection {
        colorScheme = DayScheme()
        let displayCollection = ChartDisplayCollection(dataSource: dataSource,
                                                       colorScheme: colorScheme)
        tableView.backgroundColor = colorScheme.section.background
        tableView.registerNibs(from: displayCollection)
        return displayCollection
    }
    
    private var isChangingTheme = false
    
    private var isScrolling = false
    
    private var lastTime: CFTimeInterval = 0.0

    private var firstTime: CFTimeInterval = 0.0
    
    func calcPerformance(_ link: CADisplayLink) {
        if lastTime == 0.0 {
            firstTime = link.timestamp
            lastTime = link.timestamp
        }
        
        let currentTime = link.timestamp
        
        let deltaTime = currentTime - lastTime
        if deltaTime != 0 {
            currentFPS = Int(1 / deltaTime)
        }

        let elapsedTime = floor((currentTime - lastTime) * 10_000) / 10
        let totalElapsedTime = currentTime - firstTime
        if elapsedTime > 16.7 {
            print("Frame was dropped with elapsed time of \(elapsedTime) at \(totalElapsedTime)")
        }
        lastTime = link.timestamp
    }
    
    @objc func update(link: CADisplayLink) {
        if isDebug {
            calcPerformance(link)
        }
        tableView.visibleCells.forEach { ($0 as? ChartTableViewCell)?.update() }
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
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        scrollingFinished()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollingFinished()
    }
    
    func scrollingFinished() {
        isScrolling = false
        for cell in tableView.visibleCells {
            if let cell = cell as? ChartTableViewCell {
                cell.chartView.isScrolling = false
                cell.previewChartView.isScrolling = false
                cell.chartView.drawLabels(byScroll: true)
            }
        }
    }
    
    func scrollingStarted() {
        isScrolling = true
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
        let model = displayCollection.fetchModel(for: indexPath)
        model.setupDefault(on: cell)
        if let cell = cell as? ChartTableViewCell {
            cell.drawViews()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ChartViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayCollection.numberOfRows(in: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = displayCollection.fetchModel(for: indexPath)
        let cell = tableView.dequeueReusableCell(for: indexPath, with: model)
        cell.separatorInset = displayCollection.separatorInset(for: indexPath, view: view)
        model.setupDefault(on: cell)
        if let cell = cell as? ChartTableViewCell {
            cell.drawViews()
        }
        return cell
    }
}

extension ChartViewController {
    
    func animateColorSchemeSwitch() {
        if let snapshotView = self.view.snapshotView(afterScreenUpdates: false) {
            self.view.addSubview(snapshotView)
            self.isChangingTheme = true
            UIView.animate(withDuration: UIView.animationDuration, animations: {
                snapshotView.alpha = 0
            }) { (_) in
                snapshotView.removeFromSuperview()
                self.isChangingTheme = false
            }
        }
    }
    
    @IBAction func tapDateOnButton(_ sender: UIBarButtonItem) {
        ChartViewController.isDateOn = !ChartViewController.isDateOn
        let nextMode = ChartViewController.isDateOn ? "Dates Off" : "Dates On"
        sender.title = nextMode
        for cell in self.tableView.visibleCells {
            if let cell = cell as? ChartTableViewCell {
                if ChartViewController.isDateOn {
                    cell.chartView.drawLabels(byScroll: false)
                } else {
                    cell.chartView.createLabels(needsHide: true)
                }
            }
        }
    }
    
    @IBAction func tapChangeColorSchemeButton(_ sender: UIBarButtonItem) {
        guard !isChangingTheme else {
            return
        }

        if isScrolling {
            let offset = tableView.contentOffset
            tableView.setContentOffset(offset, animated: false)
        }
        
        FeedbackGenerator.impactOccurred(style: .medium)
        animateColorSchemeSwitch()
        displayCollection.colorScheme = colorScheme.next()
        colorScheme = displayCollection.colorScheme
        for cell in self.tableView.visibleCells {
            if let cell = cell as? ColorUpdatable {
                cell.updateColors(changeColorScheme: true)
            }
        }
        let nextMode = colorScheme is DayScheme ? "Night Mode" : "Day Mode"
        sender.title = nextMode
    }
}

