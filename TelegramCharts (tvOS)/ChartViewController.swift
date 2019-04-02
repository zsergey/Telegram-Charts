//
//  ChartViewController.swift
//  TelegramCharts (tvOS)
//
//  Created by Sergey Zapuhlyak on 3/26/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ChartViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet var chartView: ChartView!
    @IBOutlet var previewChartView: ChartView!
    @IBOutlet var sliderView: SliderView!

    var needsLayoutNavigationBar = false
    
    private var chartDataSource: ChartDataSource!
    private var previewChartDataSource: ChartDataSource!

    var colorScheme: ColorSchemeProtocol! {
        didSet {
            self.chartView.colorScheme = colorScheme
            self.previewChartView.colorScheme = colorScheme
            self.sliderView.colorScheme = colorScheme
            UIView.animateEaseInOut(with: UIView.animationDuration) {
                self.view.backgroundColor = self.colorScheme.chart.background
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dataSource = ChartDataSourceFactory.make()
        guard let chartDataSource = dataSource.main.first,
            let previewChartDataSource = dataSource.preview.first
            else { return }
        
        self.chartDataSource = chartDataSource
        self.previewChartDataSource = previewChartDataSource
        
        setupSlider()
        setupChartView()
        setupPreviewChartDataSource()
        colorScheme = NightScheme()

        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .current, forMode: .common)
    }
    
    func setupSlider() {
        self.sliderView.chartModels = chartDataSource.chartModels
        self.sliderView.sliderWidth = chartDataSource.sliderWidth
        self.sliderView.startX = chartDataSource.startX
        self.sliderView.currentRange = chartDataSource.range
        self.sliderView.setNeedsLayout()
        
        self.sliderView.onChangeRange = { range, sliderWidth, startX in
            self.chartDataSource.range = range
            self.chartDataSource.sliderWidth = sliderWidth
            self.chartDataSource.startX = startX
            self.chartDataSource.selectedIndex = nil
            self.chartView.cleanDots()
            
            self.calcProperties(of: self.chartDataSource, for: self.chartView)
        }
        self.sliderView.onBeganTouch = { sliderDirection in
            self.chartView.sliderDirection = sliderDirection
            self.chartView.setNeedsLayout()
        }
        self.sliderView.onEndTouch = { sliderDirection in
            self.chartView.sliderDirection = sliderDirection
            self.chartView.setNeedsLayout()
            
            self.calcProperties(of: self.chartDataSource, for: self.chartView)
        }
    }
    
    func setupChartView() {
        self.chartView.dataSource = chartDataSource
        self.chartView.isScrolling = false
        self.chartDataSource.selectedIndex = nil
        self.chartView.cleanDots()
        
        chartDataSource.onChangeMaxValue = {
            self.calcProperties(of: self.chartDataSource, for: self.chartView)
            self.chartDataSource.selectedIndex = nil
            self.chartView.cleanDots()
        }
        chartDataSource.onSetNewTargetMaxValue = {
            DispatchQueue.main.async {
                self.chartView.drawHorizontalLines(animated: true)
            }
        }
    }
    
    func setupPreviewChartDataSource() {
        self.previewChartView.dataSource = previewChartDataSource
        previewChartDataSource.onChangeMaxValue = {
            self.calcProperties(of: self.previewChartDataSource, for: self.previewChartView)
        }
    }
    
    @objc func update() {
        self.chartView.update()
        self.previewChartView.update()
    }
  
    func calcProperties(of dataSource: ChartDataSource, for view: ChartView) {
        dataSource.calcProperties()
        view.setNeedsLayout()
    }
    
    func calcProperties() {
        if let chartDataSource = chartDataSource,
            let previewChartDataSource = previewChartDataSource {
            chartDataSource.calcProperties()
            previewChartDataSource.calcProperties()
            self.view.setNeedsLayout()
            self.chartView.setNeedsLayout()
            self.previewChartView.setNeedsLayout()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let chartDataSource = chartDataSource,
            let previewChartDataSource = previewChartDataSource,
            (chartDataSource.viewSize != chartView.frame.size ||
            previewChartDataSource.viewSize != previewChartView.frame.size){
            
            chartDataSource.viewSize = chartView.frame.size
            previewChartDataSource.viewSize = previewChartView.frame.size
            
            calcProperties()
        }
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
    }
}
