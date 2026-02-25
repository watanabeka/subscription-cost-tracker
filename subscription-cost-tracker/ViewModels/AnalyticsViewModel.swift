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

    /// サービス単位のデータ（ドーナツチャート用）
    var serviceData: [(name: String, categoryId: String, amount: Double)] {
        subscriptions
            .map { (name: $0.name, categoryId: $0.category, amount: $0.monthlyAmount) }
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
