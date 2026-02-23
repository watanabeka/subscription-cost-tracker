//
//  HomeViewModel.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class HomeViewModel {
    var subscriptions: [Subscription] = []

    var monthlyTotal: Double {
        subscriptions.reduce(0) { $0 + $1.monthlyAmount }
    }

    var sortedSubscriptions: [Subscription] {
        subscriptions.sorted { $0.monthlyAmount > $1.monthlyAmount }
    }

    func loadSubscriptions(from context: ModelContext) {
        let descriptor = FetchDescriptor<Subscription>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        subscriptions = (try? context.fetch(descriptor)) ?? []
    }

    func deleteSubscription(_ subscription: Subscription, from context: ModelContext) {
        context.delete(subscription)
        try? context.save()
        loadSubscriptions(from: context)
    }
}
