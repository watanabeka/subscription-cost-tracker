//
//  CalendarGridView.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import SwiftUI

struct CalendarGridView: View {
    let currentMonth: Date
    let subscriptions: [Subscription]

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in range {
            if let date = calendar.date(bySetting: .day, value: day, of: currentMonth) {
                days.append(date)
            }
        }

        return days
    }

    var body: some View {
        VStack(spacing: 8) {
            // Weekday Headers
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar Days
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        CalendarDayCell(date: date, subscriptions: paymentsForDay(date))
                    } else {
                        Color.clear
                            .frame(height: 50)
                    }
                }
            }
        }
    }

    private func paymentsForDay(_ date: Date) -> [Subscription] {
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
}

struct CalendarDayCell: View {
    let date: Date
    let subscriptions: [Subscription]

    private var dayLabel: String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayLabel)
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? .white : .primary)
                .frame(width: 24, height: 24)
                .background(isToday ? Color.indigo : Color.clear)
                .clipShape(Circle())

            if !subscriptions.isEmpty {
                HStack(spacing: 2) {
                    ForEach(subscriptions.prefix(3), id: \.id) { sub in
                        Circle()
                            .fill(sub.category == .video ? Color.indigo : Color.gray)
                            .frame(width: 4, height: 4)
                    }
                    if subscriptions.count > 3 {
                        Text("+\(subscriptions.count - 3)")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(subscriptions.isEmpty ? Color.clear : Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    CalendarGridView(
        currentMonth: Date(),
        subscriptions: PreviewData.samples
    )
    .padding()
}
