//
//  ChartView.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/11/19.
//  Copyright © 2019 Sergey Zapuhlyak. All rights reserved.
//

import UIKit

class ChartView: UIView {
    
    var range: Range<Int> = 0..<1 {
        didSet {
            setNeedsLayout()
        }
    }
    
    var drawingStyle: DrawingStyleProtocol = StandardDrawingStyle() {
        didSet {
            setNeedsLayout()
        }
    }

    var colorScheme: ColorSchemeProtocol = NightScheme(){
        didSet {
            backgroundColor = colorScheme.backgroundColor
            setNeedsLayout()
        }
    }
    
    var isShortView: Bool = false {
        didSet {
            backgroundColor = isShortView ? colorScheme.shortBackgroundColor : colorScheme.backgroundColor
            setNeedsLayout()
        }
    }
    
    /// gap between each point
    var lineGap: CGFloat = 60.0
    
    /// preseved space at top of the chart
    var topSpace: CGFloat = 40.0
    
    /// preserved space at bottom of the chart to show labels along the Y axis
    var bottomSpace: CGFloat = 40.0
    
    /// The top most horizontal line in the chart will be 10% higher than the highest value in the chart
    var topHorizontalLine: CGFloat = 95.0 / 100.0
    
    /// Active or desactive animation on dots
    var animateDots: Bool = false

    /// Active or desactive dots
    var showDots: Bool = true

    /// Dot inner Radius
    var innerRadius: CGFloat = 6

    /// Dot outer Radius
    var outerRadius: CGFloat = 10
    
    var chartModels: [ChartModel]? {
        didSet {
            setNeedsLayout()
        }
    }
    
    var countPoints: Int {
        if isShortView {
            return chartModels?.map { $0.data.count }.max() ?? 0
        }
        return range.count
    }

    var maxValue: Int? {
        return chartModels?.map { chart in
            let data = isShortView ? chart.data : Array(chart.data[range])
            return data.max()?.value }.compactMap { $0 }.max()
    }

    var minValue: Int? {
        return 0 // dataEntries?.map { $0.data.min()?.value }.compactMap { $0 }.min()
    }
        
    /// Contains the main line which represents the data
    private let dataLayer: CALayer = CALayer()
    
    /// Contains dataLayer and gradientLayer
    private let mainLayer: CALayer = CALayer()
    
    /// Contains mainLayer and label for each data entry
    //private let scrollView: UIScrollView = UIScrollView()
    
    /// Contains horizontal lines
    private let gridLayer: CALayer = CALayer()
    
    /// An array of CGPoint on dataLayer coordinate system that the main line will go through. These points will be calculated from dataEntries array
    private var dataPoints: [[CGPoint]]?

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
    
    private func setupView() {
        mainLayer.addSublayer(dataLayer)
        layer.addSublayer(gridLayer)
        layer.addSublayer(mainLayer)
        //scrollView.layer.addSublayer(mainLayer)
        
        //addSubview(scrollView)
        backgroundColor = colorScheme.backgroundColor
        clipsToBounds = true
    }
    
    override func layoutSubviews() {
        //scrollView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        let countPoints = self.countPoints
        guard let chartModels = chartModels else {
            return
        }
        calcProperties()
        
        let width = CGFloat(countPoints) * lineGap
        let height = self.frame.size.height
        //scrollView.contentSize = CGSize(width: width, height: height)
        mainLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        dataLayer.frame = CGRect(x: 0, y: topSpace, width: mainLayer.frame.width,
                                 height: mainLayer.frame.height - topSpace - bottomSpace)
        
        dataPoints = [[CGPoint]]()
        for index in 0..<chartModels.count {
            let points = convertDataEntriesToPoints(entries: chartModels[index].data)
            dataPoints?.append(points)
        }
        
        gridLayer.frame = CGRect(x: 0, y: topSpace, width: self.frame.width, height: mainLayer.frame.height - topSpace - bottomSpace)
        
        clean()
        if showDots { drawDots() }
        drawHorizontalLines()
        drawCharts()
        drawLables()
    }
    
    private func calcProperties() {
        if isShortView {
            lineGap = self.frame.size.width / (CGFloat(countPoints) - 1)
            topSpace = 0.0
            bottomSpace = 0.0
            topHorizontalLine = 110.0 / 100.0
        } else {
            lineGap = self.frame.size.width / (CGFloat(range.count) - 1)
            topSpace = 40.0
            bottomSpace = 40.0
            topHorizontalLine = 95.0 / 100.0
        }
    }
    
    private func convertDataEntriesToPoints(entries: [PointModel]) -> [CGPoint] {
        guard let max = maxValue, let min = minValue else {
            return []
        }
        var result: [CGPoint] = []
        let minMaxRange: CGFloat = CGFloat(max - min) * topHorizontalLine
        let startFrom: CGFloat = 0 //isShortView ? 0 : 20 // zsergey + 40
        
        for i in 0..<entries.count {
            let height = dataLayer.frame.height * (1 - ((CGFloat(entries[i].value) - CGFloat(min)) / minMaxRange))
            let point = CGPoint(x: CGFloat(i) * lineGap + startFrom, y: height)
            result.append(point)
        }
        return result
    }
    
    private func drawCharts() {
        guard let dataPoints = dataPoints, dataPoints.count > 0,
            let chartModels = chartModels else {
            return
        }
        for index in 0..<chartModels.count {
            let chartModel = chartModels[index]
            if chartModel.isHidden { continue }

            var points = dataPoints[index]
            if !isShortView {
                points = Array(points[range])
                for i in 0..<points.count {
                    points[i] = CGPoint(x: CGFloat(i) * lineGap, y: points[i].y)
                }
            }
            if let path = drawingStyle.createPath(dataPoints: points) {
                let lineLayer = CAShapeLayer()
                lineLayer.path = path.cgPath
                lineLayer.strokeColor = chartModel.color.cgColor
                lineLayer.fillColor = UIColor.clear.cgColor
                lineLayer.lineWidth = isShortView ? 1.0 : 2.0
                dataLayer.addSublayer(lineLayer)
            }
        }
    }
        
    private func drawLables() {
        guard let chartModels = chartModels, chartModels.count > 0, !isShortView else {
            return
        }
        var points: [PointModel]?
        _ = chartModels.map {
            if $0.data.count > points?.count ?? 0 { points = $0.data }
        }
        if var points = points {
            if !isShortView {
                points = Array(points[range])
            }

            let startFrom: CGFloat = 0 //isShortView ? 0 : 20 // zsergey + 40
            for i in 0..<points.count {
                let textLayer = CATextLayer()
                textLayer.frame = CGRect(x: CGFloat(i) * lineGap - lineGap / 2 + startFrom,
                                         y: mainLayer.frame.size.height - bottomSpace / 2 - 8,
                                         width: lineGap,
                                         height: 16)
                textLayer.foregroundColor = colorScheme.textColor.cgColor
                textLayer.backgroundColor = UIColor.clear.cgColor
                textLayer.alignmentMode = .center
                textLayer.contentsScale = UIScreen.main.scale
                textLayer.font = CTFontCreateWithName(UIFont.systemFont(ofSize: 0).fontName as CFString, 0, nil)
                textLayer.fontSize = 11
                textLayer.string = points[i].label
                mainLayer.addSublayer(textLayer)
            }
        }
    }
    
    private func drawHorizontalLines() {
        guard let _ = chartModels, !isShortView else {
            return
        }

        let gridValues: [CGFloat] = [0, 0.2, 0.4, 0.6, 0.8, 1]
        for value in gridValues {
            let height = value * gridLayer.frame.size.height
            
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: height))
            path.addLine(to: CGPoint(x: gridLayer.frame.size.width, y: height))
            
            let lineLayer = CAShapeLayer()
            lineLayer.path = path.cgPath
            lineLayer.fillColor = UIColor.clear.cgColor
            lineLayer.strokeColor = colorScheme.gridColor.cgColor
            lineLayer.lineWidth = 0.5
            gridLayer.addSublayer(lineLayer)
            
            var minMaxGap: CGFloat = 0
            var lineValue: Int = 0
            if let max = maxValue,
                let min = minValue {
                minMaxGap = CGFloat(max - min) * topHorizontalLine
                lineValue = Int((1 - value) * minMaxGap) + Int(min)
            }

            let textLayer = CATextLayer()
            textLayer.frame = CGRect(x: 4, y: height - 16, width: 50, height: 16)
            textLayer.foregroundColor = colorScheme.textColor.cgColor
            textLayer.backgroundColor = UIColor.clear.cgColor
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.font = CTFontCreateWithName(UIFont.systemFont(ofSize: 0).fontName as CFString, 0, nil)
            textLayer.fontSize = 12
            textLayer.string = lineValue.format
            
            gridLayer.addSublayer(textLayer)
        }
    }
    
    private func clean() {
        mainLayer.sublayers?.forEach({
            if $0 is CATextLayer {
                $0.removeFromSuperlayer()
            }
        })
        dataLayer.sublayers?.forEach({ $0.removeFromSuperlayer() })
        gridLayer.sublayers?.forEach({ $0.removeFromSuperlayer() })
    }

    private func drawDots() {
        guard let dataPoints = dataPoints, dataPoints.count > 0, !isShortView,
            let chartModels = chartModels else {
            return
        }
        
        for index in 0..<chartModels.count {
            let chartModel = chartModels[index]
            if chartModel.isHidden { continue }
            
            var dotLayers: [DotCALayer] = []
            var points = dataPoints[index]
            if !isShortView {
                points = Array(points[range])
            }
            for i in 0..<points.count {
                let dataPoint = points[i]
                let xValue = CGFloat(i) * lineGap - outerRadius / 2
                let yValue = dataPoint.y + bottomSpace - outerRadius / 2
                let dotLayer = DotCALayer()
                dotLayer.dotInnerColor = colorScheme.backgroundColor
                dotLayer.innerRadius = innerRadius
                dotLayer.backgroundColor = chartModel.color.cgColor
                dotLayer.cornerRadius = outerRadius / 2
                dotLayer.frame = CGRect(x: xValue, y: yValue, width: outerRadius, height: outerRadius)
                dotLayers.append(dotLayer)
                
                mainLayer.addSublayer(dotLayer)
                
                if animateDots {
                    let anim = CABasicAnimation(keyPath: "opacity")
                    anim.duration = 1.0
                    anim.fromValue = 0
                    anim.toValue = 1
                    dotLayer.add(anim, forKey: "opacity")
                }
            }
        }
    }
}
