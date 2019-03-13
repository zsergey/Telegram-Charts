//
//  LineChart.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/11/19.
//  Copyright © 2019 Sergey Zapuhlyak. All rights reserved.
//

import UIKit

class LineChart: UIView {
    
    var colorScheme: ColorSchemeProtocol = DayScheme(){
        didSet {
            backgroundColor = colorScheme.backgroundColor
            setNeedsLayout()
        }
    }
    
    /// gap between each point
    var lineGap: CGFloat = 60.0
    
    /// preseved space at top of the chart
    let topSpace: CGFloat = 40.0
    
    /// preserved space at bottom of the chart to show labels along the Y axis
    let bottomSpace: CGFloat = 40.0
    
    /// The top most horizontal line in the chart will be 10% higher than the highest value in the chart
    let topHorizontalLine: CGFloat = 110.0 / 100.0
    
    var isCurved: Bool = false

    /// Active or desactive animation on dots
    var animateDots: Bool = false

    /// Active or desactive dots
    var showDots: Bool = false

    /// Dot inner Radius
    var innerRadius: CGFloat = 8

    /// Dot outer Radius
    var outerRadius: CGFloat = 12
    
    var dataEntries: [ChartModel]? {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// Contains the main line which represents the data
    private let dataLayer: CALayer = CALayer()
    
    /// Contains dataLayer and gradientLayer
    private let mainLayer: CALayer = CALayer()
    
    /// Contains mainLayer and label for each data entry
    private let scrollView: UIScrollView = UIScrollView()
    
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
        scrollView.layer.addSublayer(mainLayer)
        
        layer.addSublayer(gridLayer)
        addSubview(scrollView)
        backgroundColor = colorScheme.backgroundColor
    }
    
    override func layoutSubviews() {
        scrollView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        if let dataEntries = dataEntries {
            scrollView.contentSize = CGSize(width: CGFloat(dataEntries.count) * lineGap, height: self.frame.size.height)
            mainLayer.frame = CGRect(x: 0, y: 0, width: CGFloat(dataEntries.count) * lineGap, height: self.frame.size.height)
            dataLayer.frame = CGRect(x: 0, y: topSpace, width: mainLayer.frame.width, height: mainLayer.frame.height - topSpace - bottomSpace)
            dataPoints = [[CGPoint]]()
            for index in 0..<dataEntries.count {
                let points = convertDataEntriesToPoints(entries: dataEntries[index].data)
                dataPoints?.append(points)
            }
            
            gridLayer.frame = CGRect(x: 0, y: topSpace, width: self.frame.width, height: mainLayer.frame.height - topSpace - bottomSpace)
            if showDots { drawDots() }
            clean()
            drawHorizontalLines()
            if isCurved {
                //drawCurvedChart()
            } else {
                drawChart()
            }
            drawLables()
        }
    }
    
    /**
     Convert an array of PointModel to an array of CGPoint on dataLayer coordinate system
     */
    private func convertDataEntriesToPoints(entries: [PointModel]) -> [CGPoint] {
        if let max = entries.max()?.value,
            let min = entries.min()?.value {
            
            var result: [CGPoint] = []
            let minMaxRange: CGFloat = CGFloat(max - min) * topHorizontalLine
            
            for i in 0..<entries.count {
                let height = dataLayer.frame.height * (1 - ((CGFloat(entries[i].value) - CGFloat(min)) / minMaxRange))
                let point = CGPoint(x: CGFloat(i)*lineGap + 40, y: height)
                result.append(point)
            }
            return result
        }
        return []
    }
    
    /**
     Draw a zigzag line connecting all points in dataPoints
     */
    private func drawChart() {
        if let dataPoints = dataPoints, dataPoints.count > 0,
            let dataEntries = dataEntries {
            
            for index in 0..<dataEntries.count {
                let points = dataPoints[index]
                let dataEntry = dataEntries[index]
                if let path = createPath(dataPoints: points) {
                    let lineLayer = CAShapeLayer()
                    lineLayer.path = path.cgPath
                    lineLayer.strokeColor = dataEntry.color.cgColor
                    lineLayer.fillColor = UIColor.clear.cgColor
                    dataLayer.addSublayer(lineLayer)
                }
            }
        }
    }

    /**
     Create a zigzag bezier path that connects all points in dataPoints
     */
    private func createPath(dataPoints: [CGPoint]) -> UIBezierPath? {
        guard dataPoints.count > 0 else {
            return nil
        }
        let path = UIBezierPath()
        path.move(to: dataPoints[0])
        
        for i in 1..<dataPoints.count {
            path.addLine(to: dataPoints[i])
        }
        return path
    }
    
    /**
     Draw a curved line connecting all points in dataPoints
     */
//    private func drawCurvedChart() {
//        guard let dataPoints = dataPoints, dataPoints.count > 0 else {
//            return
//        }
//        if let path = CurveAlgorithm.shared.createCurvedPath(dataPoints) {
//            let lineLayer = CAShapeLayer()
//            lineLayer.path = path.cgPath
//            lineLayer.strokeColor = UIColor.white.cgColor
//            lineLayer.fillColor = UIColor.clear.cgColor
//            dataLayer.addSublayer(lineLayer)
//        }
//    }
    
    /**
     Create titles at the bottom for all entries showed in the chart
     */
    private func drawLables() {
//        if let dataEntries = dataEntries,
//            dataEntries.count > 0 {
//            for i in 0..<dataEntries.count {
//                let textLayer = CATextLayer()
//                textLayer.frame = CGRect(x: lineGap*CGFloat(i) - lineGap/2 + 40, y: mainLayer.frame.size.height - bottomSpace/2 - 8, width: lineGap, height: 16)
//                textLayer.foregroundColor = colorScheme.textColor.cgColor
//                textLayer.backgroundColor = UIColor.clear.cgColor
//                textLayer.alignmentMode = .center
//                textLayer.contentsScale = UIScreen.main.scale
//                textLayer.font = CTFontCreateWithName(UIFont.systemFont(ofSize: 0).fontName as CFString, 0, nil)
//                textLayer.fontSize = 11
//                textLayer.string = dataEntries[i].label
//                mainLayer.addSublayer(textLayer)
//            }
//        }
    }
    
    /**
     Create horizontal lines (grid lines) and show the value of each line
     */
    private func drawHorizontalLines() {
//        guard let dataEntries = dataEntries else {
//            return
//        }
//
//        var gridValues: [CGFloat]? = nil
//        if dataEntries.count < 4 && dataEntries.count > 0 {
//            gridValues = [0, 1]
//        } else if dataEntries.count >= 4 {
//            gridValues = [0, 0.25, 0.5, 0.75, 1]
//        }
//        if let gridValues = gridValues {
//            for value in gridValues {
//                let height = value * gridLayer.frame.size.height
//
//                let path = UIBezierPath()
//                path.move(to: CGPoint(x: 0, y: height))
//                path.addLine(to: CGPoint(x: gridLayer.frame.size.width, y: height))
//
//                let lineLayer = CAShapeLayer()
//                lineLayer.path = path.cgPath
//                lineLayer.fillColor = UIColor.clear.cgColor
//                lineLayer.strokeColor = colorScheme.gridColor.cgColor
//                lineLayer.lineWidth = 0.5
//                if (value > 0.0 && value < 1.0) {
//                    lineLayer.lineDashPattern = [4, 4]
//                }
//
//                gridLayer.addSublayer(lineLayer)
//
//                var minMaxGap:CGFloat = 0
//                var lineValue:Int = 0
//                if let max = dataEntries.max()?.value,
//                    let min = dataEntries.min()?.value {
//                    minMaxGap = CGFloat(max - min) * topHorizontalLine
//                    lineValue = Int((1-value) * minMaxGap) + Int(min)
//                }
//
//                let textLayer = CATextLayer()
//                textLayer.frame = CGRect(x: 4, y: height, width: 50, height: 16)
//                textLayer.foregroundColor = colorScheme.textColor.cgColor
//                textLayer.backgroundColor = UIColor.clear.cgColor
//                textLayer.contentsScale = UIScreen.main.scale
//                textLayer.font = CTFontCreateWithName(UIFont.systemFont(ofSize: 0).fontName as CFString, 0, nil)
//                textLayer.fontSize = 12
//                textLayer.string = "\(lineValue)"
//
//                gridLayer.addSublayer(textLayer)
//            }
//        }
    }
    
    private func clean() {
        mainLayer.sublayers?.forEach({
            if $0 is CATextLayer {
                $0.removeFromSuperlayer()
            }
        })
        dataLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
        gridLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
    }
    /**
     Create Dots on line points
     */
    private func drawDots() {
//        var dotLayers: [DotCALayer] = []
//        if let dataPoints = dataPoints {
//            for dataPoint in dataPoints {
//                let xValue = dataPoint.x - outerRadius/2
//                let yValue = (dataPoint.y + lineGap) - (outerRadius * 2)
//                let dotLayer = DotCALayer()
//                dotLayer.dotInnerColor = UIColor.white
//                dotLayer.innerRadius = innerRadius
//                dotLayer.backgroundColor = UIColor.white.cgColor
//                dotLayer.cornerRadius = outerRadius / 2
//                dotLayer.frame = CGRect(x: xValue, y: yValue, width: outerRadius, height: outerRadius)
//                dotLayers.append(dotLayer)
//
//                mainLayer.addSublayer(dotLayer)
//
//                if animateDots {
//                    let anim = CABasicAnimation(keyPath: "opacity")
//                    anim.duration = 1.0
//                    anim.fromValue = 0
//                    anim.toValue = 1
//                    dotLayer.add(anim, forKey: "opacity")
//                }
//            }
//        }
    }
}
