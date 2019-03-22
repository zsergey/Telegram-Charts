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
        }
    }
    
    var colorScheme: ColorSchemeProtocol! {
        didSet {
            navigationController?.navigationBar.barTintColor = colorScheme.background
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: colorScheme.title]
            (navigationController as? NavigationViewController)?.colorScheme = colorScheme

            tableView.backgroundColor = colorScheme.section.background
            tableView.separatorColor = colorScheme.separator
//            chartView.colorScheme = colorScheme
//            previewChartView.colorScheme = colorScheme
//            sliderView.colorScheme = colorScheme
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.isTranslucent = false

        colorScheme = NightScheme()
        
        displayCollection = ChartDisplayCollection(colorScheme: colorScheme)
        displayCollection.charts = ChartModelFactory.readChartModels()
        tableView.registerNibs(from: displayCollection)

        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .current, forMode: .common)
    }
    
    @objc func update() {
        _ = tableView.visibleCells.map { ($0 as? ChartTableViewCell)?.update() }
    }

//    func changeIsHidden(for index: Int, sender: UISwitch) {
//        if var chartModels = chartView.chartModels {
//            chartModels[index].isHidden = !sender.isOn
//            chartView.chartModels = chartModels
//            previewChartView.chartModels = chartModels
//            chartView.setNeedsLayout()
//            previewChartView.setNeedsLayout()
//        }
//    }
//    
//    @IBAction func chartSwicth1Changed(_ sender: UISwitch) {
//        changeIsHidden(for: 0, sender: sender)
//    }
//    
//    @IBAction func chartSwicth2Changed(_ sender: UISwitch) {
//        changeIsHidden(for: 1, sender: sender)
//    }
    
    
}

extension ChartViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return displayCollection.height(for: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let model = displayCollection.model(for: indexPath)
        model.setupDefault(on: cell)
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
        return cell
    }
}
