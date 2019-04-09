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
    
    var startX: CGFloat = 0
    
    var viewSize: CGSize = .zero
    
    var chartModels: [ChartModel] {
        didSet {
            dataPoints = nil
            paths = nil
            findMaxRangePoints()
        }
    }
    
    var selectedIndex: Int?

    var onChangeMaxValue: (() ->())?
    
    var onSetNewTargetMaxValue: (() ->())?
    
    var name: String
    
    var isPreviewMode: Bool = false

    var isAllChartsHidden: Bool {
        var result = true
        chartModels.forEach { result = result && $0.isHidden }
        return result
    }

    private(set) var lineGap: CGFloat = 60.0
    
    private(set) var topSpace: CGFloat = 0.0
    
    private(set) var bottomSpace: CGFloat = 0.0
    
    private(set) var topHorizontalLine: CGFloat = 95.0 / 100.0
    
    private(set) var minValue: CGFloat = 0
    
    public var maxValues: [CGFloat] = []

    private(set) var targetMaxValues: [CGFloat] = []
    
    private(set) var deltaToTargetValues: [CGFloat] = []
    
    private(set) var frameAnimation: Int = 0
    
    private(set) var runMaxValueAnimation: Bool = false

    private(set) var countPoints: Int = 0
    
    private(set) var dataPoints: [[CGPoint]]?

    private(set) var paths: [UIBezierPath]?
    
    private(set) var maxRangePoints: [PointModel] = []
    
    private var viewDataSize: CGSize = .zero

    private(set) var yScaled: Bool = false
    
    public var framesInAnimationDuration: Int {
        return Int(CFTimeInterval(60) * UIView.animationDuration)
    }
    
    init(chartModels: [ChartModel], name: String) {
        self.name = name
        self.chartModels = chartModels
        chartModels.forEach { yScaled = $0.yScaled || yScaled }
        if yScaled {
            chartModels.forEach { _ in
                maxValues.append(0)
                targetMaxValues.append(0)
                deltaToTargetValues.append(0)
            }
        } else {
            maxValues.append(0)
            targetMaxValues.append(0)
            deltaToTargetValues.append(0)
        }
    }
    
    private func calcMaxValue(animateMaxValue value: Bool) {
        if isPreviewMode {
            if yScaled {
                // Individual maximum in full range.
                var newMaxValues = self.maxValues
                for index in 0..<chartModels.count {
                    let chartModel = chartModels[index]
                    if chartModel.isHidden {
                        newMaxValues[index] = 0
                    } else {
                        newMaxValues[index] = CGFloat(chartModel.data.max()?.value ?? 0)
                    }
                }
                setMaxValues(newMaxValues, animated: value)
            } else {
                // One maximum in full range.
                let max: CGFloat = chartModels.map { chartModel in
                    if chartModel.isHidden {
                        return 0
                    } else {
                        return CGFloat(chartModel.data.max()?.value ?? 0)
                    }}.compactMap { $0 }.max() ?? 0
                setMaxValues([max], animated: value)
            }
        } else {
            if yScaled {
                // Individual maximum in specific range.
                var newMaxValues = self.maxValues
                for index in 0..<chartModels.count {
                    let chartModel = chartModels[index]
                    if chartModel.isHidden {
                        newMaxValues[index] = 0
                    } else {
                        var max: CGFloat = 0
                        for i in 0..<chartModel.data.count {
                            let x = (CGFloat(i) - range.start) * lineGap
                            if x >= 0, x <= viewSize.width {
                                let value = CGFloat(chartModel.data[i].value)
                                if value > max {
                                    max = value
                                }
                            }
                        }
                        newMaxValues[index] = max
                    }
                }
                setMaxValues(newMaxValues, animated: value)
            } else {
                // One maximum in specific range.
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
                setMaxValues([max], animated: value)
            }
        }
    }
    
    private func calcConstants() {
        if isPreviewMode {
            topSpace = 0.0
            bottomSpace = 0.0
            topHorizontalLine = 110.0 / 100.0
            
            countPoints = chartModels.map { $0.data.count }.max() ?? 0
            if countPoints <= 0 {
                lineGap = 0
            } else {
                lineGap = viewSize.width / (CGFloat(countPoints) - 1)
            }
        } else {
            topSpace = 40.0
            bottomSpace = 20.0
            topHorizontalLine = 95 / 100.0
            let value = range.end - range.start - 1
            if value <= 0 {
                lineGap = 0
            } else {
                lineGap = viewSize.width / value
            }
        }
    }
    
    private func calcPointsAndMakePaths() {
        let isUpdating = dataPoints != nil && self.paths != nil
        var newDataPoints = isUpdating ? nil : [[CGPoint]]()
        var newPaths = isUpdating ? nil : [UIBezierPath]()
        
        for index in 0..<chartModels.count {
            let chartModel = chartModels[index]
            var maxValue: CGFloat = 0
            if yScaled {
                maxValue = maxValues[index]
            } else if let firstMax = maxValues.first {
                maxValue = firstMax
            }
            var points = self.convertDataEntriesToPoints(entries: chartModels[index].data, maxValue: maxValue)
            
            if !isPreviewMode {
                for i in 0..<points.count {
                    points[i] = CGPoint(x: (CGFloat(i) - range.start) * lineGap, y: points[i].y)
                }
            }
            
            if let path = chartModel.drawingStyle.createPath(dataPoints: points) {
                if isUpdating {
                    self.paths?[index] = path
                } else {
                    newPaths!.append(path)
                }
            }
            if isUpdating {
                self.dataPoints?[index] = points
            } else {
                newDataPoints!.append(points)
            }
        }
        if !isUpdating {
            self.dataPoints = newDataPoints
            self.paths = newPaths
        }
    }
    
    func calcProperties() {
        findMaxRangePoints()
        calcConstants()
        calcMaxValue(animateMaxValue: true) // TODO: was maxValue == 0 ? false : true
        viewDataSize = CGSize(width: viewSize.width,
                              height: viewSize.height - topSpace - bottomSpace)
        calcPointsAndMakePaths()
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
    
    private func isEqualArrays(_ values: [CGFloat], _ otherValues: [CGFloat]) -> Bool {
        guard values.count == otherValues.count else {
            return false
        }
        for index in 0..<maxValues.count {
            if values[index] != otherValues[index] {
                return false
            }
        }
        return true
    }
    
    private func setMaxValues(_ newMaxValues: [CGFloat], animated: Bool = false) {
        if animated {
            guard !isEqualArrays(newMaxValues, targetMaxValues),
                !isEqualArrays(newMaxValues, maxValues) else {
                    return
            }
            targetMaxValues = newMaxValues
            for index in 0..<maxValues.count {
                deltaToTargetValues[index] = newMaxValues[index] - maxValues[index]
            }
            frameAnimation = 0
            runMaxValueAnimation = true
            onSetNewTargetMaxValue?()
        } else {
            maxValues = newMaxValues
        }
    }

    private func convertDataEntriesToPoints(entries: [PointModel], maxValue: CGFloat) -> [CGPoint] {
        
        var result: [CGPoint] = []
        let minMaxGap = CGFloat(maxValue - minValue) * topHorizontalLine
        for i in 0..<entries.count {
            let height = calcHeight(for: entries[i].value, with: minMaxGap)
            let point = CGPoint(x: CGFloat(i) * lineGap, y: height)
            result.append(point)
        }
        return result
    }

    private func findMaxRangePoints() {
        var points: [PointModel] = []
        chartModels.forEach {
            if $0.data.count > points.count {
                points = $0.data
            }
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
            
            for time in 0..<framesInAnimationDuration {
                let x = CGFloat(time) / CGFloat(framesInAnimationDuration - 1)
                let y = (x * x) / (x * x + (1.0 - x) * (1.0 - x))
                
                if time == frameAnimation {
                    for index in 0..<deltaToTargetValues.count {
                        let toAddValue = deltaToTargetValues[index] * (y - prevy)
                        maxValues[index] = maxValues[index] + toAddValue
                    }
                    onChangeMaxValue?()
                }
                prevy = y

            }
            frameAnimation += 1
        } else {
            runMaxValueAnimation = false
        }
    }

}
