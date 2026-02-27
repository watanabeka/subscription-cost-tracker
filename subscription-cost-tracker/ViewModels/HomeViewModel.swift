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

    /// コスパの悪い順（割高→未使用）に並べ、同ステータス内は月額降順
    func sortedSubscriptions(threshold: Double) -> [Subscription] {
        subscriptions.sorted { lhs, rhs in
            let ls = lhs.status(threshold: threshold)
            let rs = rhs.status(threshold: threshold)
            if ls.sortOrder != rs.sortOrder {
                return ls.sortOrder < rs.sortOrder
            }
            return lhs.monthlyAmount > rhs.monthlyAmount
        }
    }

    /// 割高以上のアプリ数（overpriced / expensive / tooExpensive）
    func poorValueCount(threshold: Double) -> Int {
        subscriptions.filter { $0.status(threshold: threshold).isPoorValue }.count
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
