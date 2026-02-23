//
//  AnalyticsViewModel.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import Foundation
import SwiftData

@Observable
class AnalyticsViewModel {
    var subscriptions: [Subscription] = []

    var monthlyTotal: Double {
        subscriptions.reduce(0) { $0 + $1.monthlyAmount }
    }

    var categoryData: [(category: SubscriptionCategory, amount: Double)] {
        let grouped = Dictionary(grouping: subscriptions, by: { $0.category })
        return grouped.map { (category: $0.key, amount: $0.value.reduce(0) { $0 + $1.monthlyAmount }) }
            .sorted { $0.amount > $1.amount }
    }

    var sortedByAmount: [Subscription] {
        subscriptions.sorted { $0.monthlyAmount > $1.monthlyAmount }
    }

    func loadSubscriptions(from context: ModelContext) {
        let descriptor = FetchDescriptor<Subscription>()
        subscriptions = (try? context.fetch(descriptor)) ?? []
    }
}
