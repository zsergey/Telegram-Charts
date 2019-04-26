//
//  NewLabelsProcessor.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 20/04/2019.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

class NewLabelsProcessor {
    
    private (set) var labelsToHide = Set<TextLayer>()
    
    private (set) var labelsToShow = Set<TextLayer>()

//    var isScrolling: Bool
//
//    var sliderDirection: SliderDirection
//
//    var setFinishedSliderDirection: Bool
//
//    var dataSource: ChartDataSource?
    
    var globalStaticLabel: TextLayer? = nil
    
    var contentSize: CGSize
    
    private let trailingSpace: CGFloat = 16
    
    private let leadingSpace: CGFloat = 16

    var countCalls = 0

    init(contentSize: CGSize) {
        self.contentSize = contentSize
    }

//    init(dataSource: ChartDataSource?, isScrolling: Bool, sliderDirection: SliderDirection,
//         setFinishedSliderDirection: Bool, contentSize: CGSize) {
//        self.dataSource = dataSource
//        self.isScrolling = isScrolling
//        self.sliderDirection = sliderDirection
//        self.setFinishedSliderDirection = setFinishedSliderDirection
//        self.contentSize = contentSize
//    }
    
    func findStaticLabelLeft(onlyVisible: Bool, in labels: [TextLayer]) -> TextLayer? {
        labels.forEach { $0.isStatic = false }
        for index in 0..<labels.count {
            let label = labels[index]
            let found: () -> (TextLayer?) = {
                label.isStatic = true
                label.opacity = 1
                return label
            }
            if onlyVisible {
                if label.opacity == 1, label.frame.origin.x + ChartContentView.labelWidth > 0 {
                    return found()
                }
            } else {
                if label.frame.origin.x < trailingSpace {
                    label.opacity = 0
                } else {
                    return found()
                }
            }
        }
        return nil
    }
    
    func findStaticLabelRight(onlyVisible: Bool, in labels: [TextLayer]) -> TextLayer? {
        labels.forEach { $0.isStatic = false }
        let range = 0..<labels.count
        for index in range {
            let inverseIndex = range.endIndex - index - 1
            let label = labels[inverseIndex]
            let found: () -> (TextLayer?) = {
                label.isStatic = true
                label.opacity = 1
                return label
            }
            if onlyVisible {
                if label.opacity == 1,
                    label.frame.origin.x - label.frame.size.width / 2 < contentSize.width - trailingSpace {
                    return found()
                }
            } else {
                if label.frame.origin.x - label.frame.size.width / 2 < contentSize.width - trailingSpace {
                    return found()
                } else {
                    label.opacity = 0
                }
            }
        }
        return nil
    }
    
    func processLabels(from labels: [TextLayer], lineGap: CGFloat, isFirstCall: Bool,
                       staticLabel: TextLayer?, lookToRight: Bool) {
        
        var visibleLabels = [TextLayer]()
        let inverse = !lookToRight
        var wereHiddenLayers = false
        var lastFrame: CGRect = .zero
        if let staticLabel = staticLabel {
            lastFrame = staticLabel.frame
        }
        
        // Find a range.
        var range = 0..<labels.count
        if isFirstCall {
            labelsToHide = Set<TextLayer>()
            labelsToShow = Set<TextLayer>()
            countCalls = 0
            let indexLabel = labels.firstIndex(of: staticLabel!)! // TODO Force unwrap
            range = lookToRight ? indexLabel..<labels.count : 0..<indexLabel + 1
        }
        
        for index in range {
            let inverseIndex = range.endIndex - index - 1

            let textLayer = inverse ? labels[inverseIndex] : labels[index]
            let coef: CGFloat = inverse ? -1 : 1
            
            let startXFrame = textLayer.frame.origin.x - textLayer.frame.size.width * coef / 2
            
            if textLayer.isStatic {
                continue
            }
            
            // Skeep unvisible labels.
            /* вроде не нужно
            if textLayer.frame.origin.x - textLayer.frame.size.width / 2 + contentSize.width < 0 ||
                textLayer.frame.origin.x + textLayer.frame.size.width / 2 > contentSize.width {
                continue
             }*/
            
            countCalls += 1
            
            if lastFrame == .zero {
                /*textLayer.toOpacity = 1
                if !isScrolling {
                    textLayer.opacity = 1
                }*/
                textLayer.opacity = 1
                lastFrame = textLayer.frame
                visibleLabels.append(textLayer)
            } else {
                let endXLastFrame = lastFrame.origin.x + lastFrame.size.width * coef / 2 + ChartContentView.labelWidth * coef
                let condition = inverse ? startXFrame < endXLastFrame : startXFrame > endXLastFrame
                if condition {
                    /*textLayer.toOpacity = 1
                    if !isScrolling {
                        textLayer.opacity = 1
                    }*/
                    textLayer.opacity = 1
                    lastFrame = textLayer.frame
                    visibleLabels.append(textLayer)
                } else {
                    let delta = inverse ? startXFrame - endXLastFrame : endXLastFrame - startXFrame
                    let opacity = max(Float(1 - delta / textLayer.frame.size.width), 0)
                    
                    /*if sliderDirection == .center ||
                        sliderDirection == .none,
                        opacity >= 0.5 {
                        opacity = 1
                    }
                    
                    if sliderDirection == .finished, opacity >= 0.5 {
                        // nothing to change.
                    } else {
                        textLayer.toOpacity = opacity
                        if !isScrolling {
                            textLayer.opacity = opacity
                        }
                    }
                    
                    if !isScrolling {
                        textLayer.opacity = opacity
                    }*/
                    textLayer.opacity = opacity
                    if opacity < 0.5 {
                        labelsToHide.insert(textLayer)
                    } else if opacity >= 0.5 {
                        labelsToShow.insert(textLayer)
                    }

                    if opacity == 0 {
                        lastFrame = .zero
                        wereHiddenLayers = true
                        labelsToHide.remove(textLayer)
                        labelsToShow.remove(textLayer)
                    }
                }
            }
        }
        
        if wereHiddenLayers {
            processLabels(from: visibleLabels, lineGap: lineGap, isFirstCall: false,
                          staticLabel: staticLabel, lookToRight: lookToRight)
        }
    }
    
}
