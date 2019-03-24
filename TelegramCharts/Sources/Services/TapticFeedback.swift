//
//  TapticFeedback.swift
//  TelegramCharts
//
//  Created by Sergey Zapuhlyak on 3/23/19.
//  Copyright © 2019 @zsergey. All rights reserved.
//

import UIKit

struct FeedbackGenerator {
    
    enum FeedbackType {
        case success
        case warning
        case error
    }
    
    enum FeedbackStyle {
        case light
        case medium
        case heavy
    }
    
    static func notificationOccurred(_ type: FeedbackType) {
        if #available(iOS 10.0, *) {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            switch type {
            case.success: feedbackGenerator.notificationOccurred(.success)
            case.warning: feedbackGenerator.notificationOccurred(.warning)
            case.error: feedbackGenerator.notificationOccurred(.error)
            }
        }
    }
    
    static func impactOccurred(style: FeedbackStyle) {
        if #available(iOS 10.0, *) {
            var feedbackGenerator: UIImpactFeedbackGenerator?
            switch style {
                case .light: feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                case .medium: feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                case .heavy: feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
            }
            feedbackGenerator?.impactOccurred()
        }
    }
}
