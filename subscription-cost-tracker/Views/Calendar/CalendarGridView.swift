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
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

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
        VStack(spacing: 4) {
            // Weekday Headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar Days
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        CalendarDayCell(date: date, subscriptions: paymentsForDay(date))
                    } else {
                        Color.clear
                            .frame(height: 60)
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
        VStack(spacing: 3) {
            // Day number
            Text(dayLabel)
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? .white : .primary)
                .frame(width: 24, height: 24)
                .background(isToday ? Color.appTheme : Color.clear)
                .clipShape(Circle())

            // Service name bands
            if !subscriptions.isEmpty {
                VStack(spacing: 2) {
                    ForEach(subscriptions.prefix(2), id: \.id) { sub in
                        Text(sub.name)
                            .font(.system(size: 7, weight: .medium))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 2)
                            .padding(.vertical, 1.5)
                            .background(sub.category.baseColor.opacity(0.22))
                            .foregroundStyle(sub.category.baseColor)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                    if subscriptions.count > 2 {
                        Text("+\(subscriptions.count - 2)")
                            .font(.system(size: 7))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 60)
        .padding(.vertical, 2)
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
