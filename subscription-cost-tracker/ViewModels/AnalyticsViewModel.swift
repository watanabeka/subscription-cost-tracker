//
//  AnalyticsViewModel.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import Foundation
import SwiftData

// MARK: - AnalyticsPeriod

enum AnalyticsPeriod: CaseIterable {
    case monthly, yearly, cumulative

    var label: String {
        switch self {
        case .monthly:    return String(localized: "period_monthly")
        case .yearly:     return String(localized: "period_yearly")
        case .cumulative: return String(localized: "period_cumulative")
        }
    }

    /// ドーナツチャート中央に表示するサフィックス
    var chartCenterSuffix: String {
        switch self {
        case .monthly:    return String(localized: "per_month")
        case .yearly:     return String(localized: "per_year")
        case .cumulative: return String(localized: "label_cumulative")
        }
    }
}

// MARK: - AnalyticsViewModel

@Observable
class AnalyticsViewModel {
    var subscriptions: [Subscription] = []

    // MARK: Period-based totals

    func total(for period: AnalyticsPeriod) -> Double {
        switch period {
        case .monthly:    return subscriptions.reduce(0) { $0 + $1.monthlyAmount }
        case .yearly:     return subscriptions.reduce(0) { $0 + $1.monthlyAmount * 12 }
        case .cumulative: return subscriptions.reduce(0) { $0 + $1.cumulativeAmount }
        }
    }

    /// ドーナツチャート用データ（期間に応じて金額が変わる）
    func serviceData(for period: AnalyticsPeriod) -> [(name: String, categoryId: String, amount: Double)] {
        subscriptions.map { sub -> (name: String, categoryId: String, amount: Double) in
            let amount: Double
            switch period {
            case .monthly:    amount = sub.monthlyAmount
            case .yearly:     amount = sub.monthlyAmount * 12
            case .cumulative: amount = sub.cumulativeAmount
            }
            return (name: sub.name, categoryId: sub.category, amount: amount)
        }.sorted { $0.amount > $1.amount }
    }

    /// コストパフォーマンスカード用（常に月額ベース）
    var sortedByAmount: [Subscription] {
        subscriptions.sorted { $0.monthlyAmount > $1.monthlyAmount }
    }

    func loadSubscriptions(from context: ModelContext) {
        let descriptor = FetchDescriptor<Subscription>()
        subscriptions = (try? context.fetch(descriptor)) ?? []
    }
}
