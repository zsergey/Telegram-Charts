//
//  ChartView.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/11/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class ChartView: UIView, Reusable, Updatable {
    
    var dataSource: ChartDataSource?

    // TODO:
//    var range: IndexRange = (0, 0) {
//        didSet {
//            self.dataSource?.selectedIndex = nil
//            cleanDots()
//        }
//    }
    
    var colorScheme: ColorSchemeProtocol = DayScheme() { didSet { setNeedsLayout() } }
    
    var sliderDirection: SliderDirection = .finished

    private let labelWidth: CGFloat = 35
    
    private let dataLayer: CALayer = CALayer()
    
    private let mainLayer: CALayer = CALayer()
    
    private let gridLayer: CALayer = CALayer()

    private var chartLines: [CAShapeLayer]?

    private var gridLines: [ValueLayer]?

    private var gridLinesToRemove: [ValueLayer]?
    
    private var labels: [CATextLayer]?
    
    private var innerRadius: CGFloat = 6
    
    private var outerRadius: CGFloat = 10

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    func update() {
        dataSource?.update()
    }
    
    private func setupView() {
        mainLayer.addSublayer(dataLayer)
        layer.addSublayer(gridLayer)
        layer.addSublayer(mainLayer)
        clipsToBounds = true
    }
    
    override func layoutSubviews() {
        backgroundColor = colorScheme.chart.background
        guard let dataSource = dataSource,
            let dataPoints = dataSource.dataPoints, dataPoints.count > 0 else {
            return
        }
        
        let animateMaxValue = dataSource.maxValue == 0 ? false : true

        let width = CGFloat(dataSource.countPoints) * dataSource.lineGap
        let height = self.frame.size.height
        self.mainLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        self.dataLayer.frame = CGRect(x: 0, y: dataSource.topSpace,
                                      width: self.mainLayer.frame.width,
                                      height: self.mainLayer.frame.height - dataSource.topSpace - dataSource.bottomSpace)
        
        self.gridLayer.frame = CGRect(x: 0, y: dataSource.topSpace,
                                      width: self.frame.width,
                                      height: self.mainLayer.frame.height - dataSource.topSpace - dataSource.bottomSpace)
        
        if !animateMaxValue {
            self.drawHorizontalLines(animated: false)
        }
        
        self.drawCharts()
        // TODO: пока закомментил
        //self.drawLables(animated: animateMaxValue)
    }
    
    private func drawCharts() {
        guard let dataSource = dataSource,
            let dataPoints = dataSource.dataPoints, dataPoints.count > 0,
            let paths = dataSource.paths else {
            return
        }
        
        let isUpdating = chartLines != nil
        var newChartLines = isUpdating ? nil : [CAShapeLayer]()
        
        for index in 0..<dataSource.chartModels.count {
            let chartModel = dataSource.chartModels[index]
            let lineLayer = isUpdating ? chartLines![index] : CAShapeLayer()
            let path = paths[index]
            if isUpdating {
                lineLayer.changePath(to: path, animationDuration: dataSource.animationDuration)
                CATransaction.setDisableActions(true)
                if chartModel.opacity != lineLayer.opacity {
                    let toValue: Float = chartModel.opacity
                    let fromValue: Float = lineLayer.opacity
                    lineLayer.changeOpacity(from: fromValue, to: toValue,
                                            animationDuration: dataSource.animationDuration)
                }
            } else {
                lineLayer.path = path.cgPath
                lineLayer.opacity = chartModel.opacity
                lineLayer.strokeColor = chartModel.color.cgColor
                lineLayer.fillColor = UIColor.clear.cgColor
                lineLayer.lineWidth = dataSource.isPreviewMode ? 1.0 : 2.0
                dataLayer.addSublayer(lineLayer)
                newChartLines!.append(lineLayer)
            }
        }
        
        if !isUpdating {
            chartLines = newChartLines
        }
    }
        
    private func drawLables(animated: Bool) {
        guard let dataSource = dataSource,
            dataSource.chartModels.count > 0,
            !dataSource.isPreviewMode else {
            return
        }
        
        let isUpdating = labels != nil
        var newLabels = isUpdating ? nil : [CATextLayer]()

        let startFrom: CGFloat = 0 // isPreviewMode ? 0 : 20 // TODO: + 40
        
        for index in 0..<dataSource.maxRangePoints.count {
            let textLayer = isUpdating ? labels![index] : CATextLayer()
            
            let x = (CGFloat(index) - dataSource.range.start) * dataSource.lineGap - labelWidth / 2 + startFrom
            
            CATransaction.setDisableActions(true)
            textLayer.frame = CGRect(x: x,
                                     y: mainLayer.frame.size.height - dataSource.bottomSpace / 2 - 4,
                                     width: labelWidth,
                                     height: 16)
            if !isUpdating {
                textLayer.foregroundColor = colorScheme.chart.text.cgColor
                textLayer.backgroundColor = UIColor.clear.cgColor
                textLayer.alignmentMode = .center
                textLayer.contentsScale = UIScreen.main.scale
                textLayer.font = CTFontCreateWithName(UIFont.systemFont(ofSize: 0).fontName as CFString, 0, nil)
                textLayer.fontSize = 11
                textLayer.string = dataSource.maxRangePoints[index].date
                mainLayer.addSublayer(textLayer)
                newLabels!.append(textLayer)
            }
        }

        if !isUpdating {
            labels = newLabels
        }

        switch sliderDirection {
        case .center, .finished, .none:
            hideLabels(skipHidden: true, animated: animated)
        case .left, .right:
            hideLabels(skipHidden: false, animated: animated)
        }
    }
    
    func hideLabels(skipHidden: Bool, animated: Bool) {
        guard let dataSource = dataSource,
            dataSource.chartModels.count > 0,
            !dataSource.isPreviewMode else {
                return
        }

        var wereHiddenLayers = false
        var lastFrame: CGRect = .zero
        
        var layersToHide = [CATextLayer]()
        for index in 0..<dataSource.maxRangePoints.count {
            let textLayer = labels![index]
            
            if skipHidden, textLayer.opacity == 0 {
                continue
            }
            
            let startXFrame = textLayer.frame.origin.x - textLayer.frame.size.width / 2
            CATransaction.setDisableActions(true)
            
            if lastFrame == .zero {
                textLayer.opacity = 1
                lastFrame = textLayer.frame
            } else {
                let endXLastFrame = lastFrame.origin.x + lastFrame.size.width / 2 + labelWidth
                if startXFrame > endXLastFrame {
                    textLayer.opacity = 1
                    lastFrame = textLayer.frame
                } else {
                    var opacity = max(Float(1 - (endXLastFrame - startXFrame) / textLayer.frame.size.width), 0)
                    
                    if sliderDirection == .center ||
                        sliderDirection == .none,
                        opacity >= 0.5 {
                        opacity = 1
                    }
                    
                    if sliderDirection == .finished, opacity >= 0.5 {
                        // nothing to change.
                    } else {
                        textLayer.opacity = opacity
                    }
                    
                    if opacity == 0 {
                        lastFrame = .zero
                        wereHiddenLayers = true
                    } else if opacity != 1 {
                        layersToHide.append(textLayer)
                    }
                }
            }
            
            if wereHiddenLayers {
                hideLabels(skipHidden: true, animated: animated)
            } else if sliderDirection == .finished {
                for textLayer in layersToHide {
                    let toOpacity: Float = textLayer.opacity >= 0.5 ? 1 : 0
                    textLayer.changeOpacity(from: textLayer.opacity, to: toOpacity,
                                            animationDuration: animated ? dataSource.animationDuration : 0)
                }
            }
        }
    }
    
    func drawHorizontalLines(animated: Bool) {
        guard let dataSource = dataSource,
            !dataSource.isPreviewMode else {
                return
        }

        let minMaxGap = CGFloat(dataSource.maxValue - dataSource.minValue) * dataSource.topHorizontalLine
        let newMinMaxGap = CGFloat(dataSource.targetMaxValue - dataSource.minValue) * dataSource.topHorizontalLine
        
        let heightGrid: CGFloat = 30
        let widthGrid: CGFloat = self.frame.size.width
        let isUpdating = self.gridLines != nil
        var newGridLines = [ValueLayer]()
        var newGridLinesToRemove = [ValueLayer]()

        _ = gridLinesToRemove?.map { $0.removeFromSuperlayer() }
        
        let gridValues: [CGFloat] = [0, 0.2, 0.4, 0.6, 0.8, 1]
        for index in 0..<gridValues.count {
            let value = gridValues[index]
            var duration: CFTimeInterval = 0
            if animated {
                duration = value == 1 ? 0 : dataSource.animationDuration
            }

            let lineValue = dataSource.calcLineValue(for: value, with: minMaxGap)
            let newLineValue = dataSource.calcLineValue(for: value, with: newMinMaxGap)
            
            let oldValueLayer = isUpdating ? gridLines![index] : nil
            let newValueLayer = ValueLayer()

            let fromNewHeight = dataSource.calcHeight(for: newLineValue, with: minMaxGap)
            let fromNewFrame = CGRect(x: 0, y: fromNewHeight, width: frame.size.width, height: heightGrid)
            let toNewHeight = dataSource.calcHeight(for: newLineValue, with: newMinMaxGap) + heightGrid / 2
            let toNewPoint = CGPoint(x: widthGrid / 2, y: toNewHeight)
            newValueLayer.lineColor = colorScheme.chart.grid
            newValueLayer.textColor = colorScheme.chart.text
            gridLayer.addSublayer(newValueLayer)
            newGridLines.append(newValueLayer)
            
            if let oldValueLayer = oldValueLayer {
                let toHeight = dataSource.calcHeight(for: lineValue, with: newMinMaxGap) + heightGrid / 2
                let toPoint = CGPoint(x: widthGrid / 2, y: toHeight)
                CATransaction.setDisableActions(true)
                oldValueLayer.moveTo(point: toPoint, animationDuration: duration)
                oldValueLayer.changeOpacity(from: 1, to: 0, animationDuration: duration)
                newGridLinesToRemove.append(oldValueLayer)
            }
            
            if isUpdating {
                newValueLayer.lineValue = newLineValue
                newValueLayer.opacity = 0
                newValueLayer.frame = fromNewFrame
                newValueLayer.moveTo(point: toNewPoint, animationDuration: duration)
                newValueLayer.changeOpacity(from: 0, to: 1, animationDuration: duration)
            } else {
                newValueLayer.lineValue = lineValue
                newValueLayer.opacity = 1
                let height = dataSource.calcHeight(for: lineValue, with: minMaxGap)
                let rect = CGRect(x: 0, y: height, width: frame.size.width, height: heightGrid)
                newValueLayer.frame = rect
            }
        }
        
        gridLines = newGridLines
        gridLinesToRemove = newGridLinesToRemove
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        drawDotsIfNeeded(touches)
    }
    
    private func drawDotsIfNeeded(_ touches: Set<UITouch>) {
        guard let dataSource = dataSource,
            let dataPoints = dataSource.dataPoints, dataPoints.count > 0,
            !dataSource.isPreviewMode, let touch = touches.first else {
                return
        }
        let location = touch.location(in: self)
        guard location.x >= 0, location.x <= frame.size.width else {
            return
        }
        
        let newSelectedIndex = Int((location.x + dataSource.range.start * dataSource.lineGap) / dataSource.lineGap)
        var isUpdating = dataSource.selectedIndex == nil
        if let selectedIndex = dataSource.selectedIndex,
            selectedIndex != newSelectedIndex {
            isUpdating = true
        }
        if isUpdating {
            dataSource.selectedIndex = newSelectedIndex
            cleanDots()
            drawDots()
        }
    }
    
    private func cleanDots() {
        CATransaction.setDisableActions(true)
        dataLayer.sublayers?.forEach {
            if $0 is DotLayer {
                $0.removeFromSuperlayer()
            }
        }
    }

    private func drawDots() {
        guard let dataSource = dataSource,
            let dataPoints = dataSource.dataPoints, dataPoints.count > 0,
            !dataSource.isPreviewMode,
            let selectedIndex = dataSource.selectedIndex else {
            return
        }

        for index in 0..<dataSource.chartModels.count {
            let chartModel = dataSource.chartModels[index]
             if chartModel.isHidden { continue }
            
            var dotLayers: [DotLayer] = []
            var points = dataPoints[index]
            
            let dataPoint = points[selectedIndex]
            let xValue = (CGFloat(selectedIndex) - dataSource.range.start) * dataSource.lineGap - outerRadius / 2
            let yValue = dataPoint.y  - outerRadius / 2

            let dotLayer = DotLayer()
            dotLayer.dotInnerColor = colorScheme.chart.background
            dotLayer.innerRadius = innerRadius
            dotLayer.backgroundColor = chartModel.color.cgColor
            dotLayer.cornerRadius = outerRadius / 2
            dotLayer.frame = CGRect(x: xValue, y: yValue, width: outerRadius, height: outerRadius)
            dotLayers.append(dotLayer)
            dataLayer.addSublayer(dotLayer)
        }
    }
    
    func prepareForReuse() {
        chartLines = nil
        gridLines = nil
        labels = nil
        dataSource = nil

        mainLayer.sublayers?.forEach {
            if $0 is CATextLayer {
                $0.removeFromSuperlayer()
            }
        }

        dataLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        gridLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }

}
