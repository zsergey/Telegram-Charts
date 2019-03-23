//
//  ChartDataSource.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/23/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class СoupleChartDataSource {
    var main: [ChartDataSource]
    var preview: [ChartDataSource]
    
    init(main: [ChartDataSource], preview: [ChartDataSource]) {
        self.main = main
        self.preview = preview
    }
} 

class ChartDataSource: Updatable {
    
    var range = IndexRange(start: CGFloat(0.0), end: CGFloat(0.0))
    
    var sliderWidth: CGFloat = 0

    var viewSize: CGSize = .zero
    
    var drawingStyle: DrawingStyleProtocol = StandardDrawingStyle()

    var chartModels: [ChartModel] {
        didSet {
            findMaxRangePoints()
        }
    }
    
    var animationDuration: CFTimeInterval = 0.5

    var selectedIndex: Int?

    var onChangeMaxValue: (() ->())?
    
    var onSetNewTargetMaxValue: (() ->())?
    
    var name: String = "FOLLOWERS"
    
    var isPreviewMode: Bool = false

    private(set) var lineGap: CGFloat = 60.0
    
    private(set) var topSpace: CGFloat = 0.0
    
    private(set) var bottomSpace: CGFloat = 0.0
    
    private(set) var topHorizontalLine: CGFloat = 95.0 / 100.0
    
    private(set) var minValue: CGFloat = 0
    
    public var maxValue: CGFloat = 0
    
    private(set) var targetMaxValue: CGFloat = 0
    
    private(set) var deltaToTargetValue: CGFloat = 0
    
    private(set) var frameAnimation: Int = 0
    
    private(set) var runMaxValueAnimation: Bool = false

    private(set) var countPoints: Int = 0
    
    private(set) var dataPoints: [[CGPoint]]?

    private(set) var paths: [UIBezierPath]?
    
    private(set) var maxRangePoints: [PointModel] = []
    
    private var viewDataSize: CGSize = .zero

    public var framesInAnimationDuration: Int {
        return Int(CFTimeInterval(60) * animationDuration)
    }
    
    init(chartModels: [ChartModel]) {
        self.chartModels = chartModels
    }

    func calcProperties() {
        self.findMaxRangePoints()
        let animateMaxValue = maxValue == 0 ? false : true
        if isPreviewMode {
            topSpace = 0.0
            bottomSpace = 0.0
            topHorizontalLine = 110.0 / 100.0
            
            countPoints = chartModels.map { $0.data.count }.max() ?? 0
            lineGap = viewSize.width / (CGFloat(countPoints) - 1)
            let max: CGFloat = chartModels.map { chartModel in
                if chartModel.isHidden {
                    return 0
                } else {
                    return CGFloat(chartModel.data.max()?.value ?? 0)
                }}.compactMap { $0 }.max() ?? 0
            setMaxValue(max, animated: animateMaxValue)
        } else {
            topSpace = 40.0
            bottomSpace = 20.0
            topHorizontalLine = 95.0 / 100.0
            lineGap = viewSize.width / (range.end - range.start - 1)
            var max: CGFloat = 0
            for chartModel in chartModels {
                if chartModel.isHidden { continue }
                for i in 0..<chartModel.data.count {
                    let x = (CGFloat(i) - range.start) * lineGap
                    if x >= 0, x <= viewSize.width {
                        let value = CGFloat(chartModel.data[i].value)
                        if value > max {
                            max = value
                        }
                    }
                }
            }
            setMaxValue(max, animated: animateMaxValue)
        }
        viewDataSize = CGSize(width: viewSize.width,
                              height: viewSize.height - topSpace - bottomSpace)

        // Calc points and paths.
        var dataPoints = [[CGPoint]]()
        var paths = [UIBezierPath]()
        for index in 0..<chartModels.count {
            var points = self.convertDataEntriesToPoints(entries: chartModels[index].data)
            
            if !isPreviewMode {
                for i in 0..<points.count {
                    points[i] = CGPoint(x: (CGFloat(i) - range.start) * lineGap, y: points[i].y)
                }
            }
            
            if let path = drawingStyle.createPath(dataPoints: points) {
                paths.append(path)
            }
            dataPoints.append(points)
        }
        self.dataPoints = dataPoints
        self.paths = paths
    }
    
    func calcHeight(for value: Int, with minMaxGap: CGFloat) -> CGFloat {
        if value == 0 {
            return viewDataSize.height
        }
        if Int(minMaxGap) == 0 {
            return -viewDataSize.height
        }
        return viewDataSize.height * (1 - ((CGFloat(value) - CGFloat(minValue)) / minMaxGap))
    }

    func calcLineValue(for value: CGFloat, with minMaxGap: CGFloat) -> Int {
        return Int((1 - value) * minMaxGap) + Int(minValue)
    }

    private func setMaxValue(_ newMaxValue: CGFloat, animated: Bool = false) {
        if animated {
            guard newMaxValue != targetMaxValue else {
                return
            }
            targetMaxValue = newMaxValue
            deltaToTargetValue = newMaxValue - maxValue
            frameAnimation = 0
            runMaxValueAnimation = true
            onSetNewTargetMaxValue?()
        } else {
            maxValue = newMaxValue
        }
    }

    private func convertDataEntriesToPoints(entries: [PointModel]) -> [CGPoint] {
        var result: [CGPoint] = []
        let minMaxGap = CGFloat(maxValue - minValue) * topHorizontalLine
        let startFrom: CGFloat = 0 // isPreviewMode ? 0 : 20 // TODO: + 40
        
        for i in 0..<entries.count {
            let height = calcHeight(for: entries[i].value, with: minMaxGap)
            let point = CGPoint(x: CGFloat(i) * lineGap + startFrom, y: height)
            result.append(point)
        }
        return result
    }

    private func findMaxRangePoints() {
        var points: [PointModel] = []
        _ = chartModels.map {
            if $0.data.count > points.count { points = $0.data }
        }
        self.maxRangePoints = points
    }
    
    func update() {
        guard runMaxValueAnimation else {
            return
        }
        if frameAnimation < framesInAnimationDuration {
            // Ease-in-out function from
            // https://math.stackexchange.com/questions/121720/ease-in-out-function
            var prevy: CGFloat = 0
            // TODO: вот это попробовать не циклом сделать
            for time in 0..<framesInAnimationDuration {
                let x = CGFloat(time) / CGFloat(framesInAnimationDuration - 1)
                let y = (x * x) / (x * x + (1.0 - x) * (1.0 - x))
                
                let toAddValue = deltaToTargetValue * (y - prevy)
                prevy = y
                
                if time == frameAnimation {
                    maxValue = maxValue + toAddValue
                    onChangeMaxValue?()
                }
            }
            frameAnimation += 1
        } else {
            runMaxValueAnimation = false
        }
    }
}
