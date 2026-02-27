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

// MARK: - CostPerformanceSortOption

enum CostPerformanceSortOption: CaseIterable {
    case costPerformance, startDate, amount, usageHours

    var label: String {
        switch self {
        case .costPerformance: return String(localized: "analytics_sort_cost_performance")
        case .startDate:       return String(localized: "analytics_sort_start_date")
        case .amount:          return String(localized: "analytics_sort_amount")
        case .usageHours:      return String(localized: "analytics_sort_usage_hours")
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

    /// コストパフォーマンスカード用（ソートオプションに応じて並べ替え）
    func sortedForCostPerformance(by option: CostPerformanceSortOption, threshold: Double) -> [Subscription] {
        switch option {
        case .costPerformance:
            return subscriptions.sorted { lhs, rhs in
                let ls = lhs.status(threshold: threshold)
                let rs = rhs.status(threshold: threshold)
                if ls.sortOrder != rs.sortOrder {
                    return ls.sortOrder < rs.sortOrder
                }
                return lhs.monthlyAmount > rhs.monthlyAmount
            }
        case .startDate:
            return subscriptions.sorted { $0.startDate > $1.startDate }
        case .amount:
            return subscriptions.sorted { $0.monthlyAmount > $1.monthlyAmount }
        case .usageHours:
            return subscriptions.sorted { $0.weeklyUsageHours > $1.weeklyUsageHours }
        }
    }

    func loadSubscriptions(from context: ModelContext) {
        let descriptor = FetchDescriptor<Subscription>()
        subscriptions = (try? context.fetch(descriptor)) ?? []
    }
}
