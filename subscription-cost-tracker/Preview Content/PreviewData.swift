//
//  PreviewData.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import Foundation
import SwiftData

struct PreviewData {
    static let samples: [Subscription] = [
        Subscription(name: "Netflix", category: .video, amount: 1490, billingCycle: .monthly, startDate: Date(), weeklyUsageHours: 5.0),
        Subscription(name: "Spotify", category: .music, amount: 980, billingCycle: .monthly, startDate: Date(), weeklyUsageHours: 10.0),
        Subscription(name: "Adobe CC", category: .productivity, amount: 72336, billingCycle: .yearly, startDate: Date(), weeklyUsageHours: 1.0),
        Subscription(name: "ジム", category: .fitness, amount: 8800, billingCycle: .monthly, startDate: Date(), weeklyUsageHours: 0.0),
        Subscription(name: "iCloud+", category: .cloud, amount: 130, billingCycle: .monthly, startDate: Date(), weeklyUsageHours: 0.5),
    ]
}
