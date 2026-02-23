//
//  CalendarViewModel.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import Foundation
import SwiftData

@Observable
class CalendarViewModel {
    var subscriptions: [Subscription] = []
    var currentMonth: Date = Date()

    var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: currentMonth)
    }

    func loadSubscriptions(from context: ModelContext) {
        let descriptor = FetchDescriptor<Subscription>()
        subscriptions = (try? context.fetch(descriptor)) ?? []
    }

    func moveMonth(by months: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: months, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    func paymentsForDay(_ date: Date) -> [Subscription] {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)

        return subscriptions.filter { subscription in
            let startDay = calendar.component(.day, from: subscription.startDate)
            let startMonth = calendar.component(.month, from: subscription.startDate)
            let startYear = calendar.component(.year, from: subscription.startDate)

            // 月額の場合: 毎月同じ日
            if subscription.billingCycle == .monthly {
                // 月末補正
                let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
                let adjustedDay = min(startDay, daysInMonth)
                return day == adjustedDay
            }

            // 年額の場合: 開始月・開始日が一致
            if subscription.billingCycle == .yearly {
                return month == startMonth && day == startDay && year >= startYear
            }

            return false
        }
    }

    func paymentsForMonth() -> [(Date, [Subscription])] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth) else {
            return []
        }

        var result: [(Date, [Subscription])] = []

        for day in range {
            if let date = calendar.date(bySetting: .day, value: day, of: currentMonth) {
                let payments = paymentsForDay(date)
                if !payments.isEmpty {
                    result.append((date, payments))
                }
            }
        }

        return result.sorted { $0.0 < $1.0 }
    }
}
