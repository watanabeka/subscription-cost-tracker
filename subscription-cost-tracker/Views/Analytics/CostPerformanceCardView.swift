//
//  CostPerformanceCardView.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import SwiftUI

struct CostPerformanceCardView: View {
    let subscription: Subscription
    @Environment(CategoryStore.self) private var categoryStore

    var body: some View {
        let cat      = categoryStore.category(for: subscription.category)
        let threshold = categoryStore.costPerHourThreshold
        let status   = subscription.status(threshold: threshold)
        let score    = subscription.valueScore(threshold: threshold)

        VStack(alignment: .leading, spacing: 12) {
            // Header: Service name and category icon
            HStack(spacing: 12) {
                Image(systemName: cat.iconName)
                    .font(.title3)
                    .foregroundStyle(.appTheme)

                VStack(alignment: .leading, spacing: 2) {
                    Text(subscription.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(cat.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status Badge
                Text(status.label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(status.color)
                    .clipShape(Capsule())
            }

            // Value Score Progress Bar (ゲージ)
            if subscription.weeklyUsageHours > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(String(localized: "label_value_score"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.0f%%", score * 100))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)
                            // Filled portion with gradient ending at status color
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: gradientColors(for: status),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * score, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }

            // Stats Grid
            HStack(spacing: 0) {
                // Monthly Amount
                StatItem(
                    label: String(localized: "monthly_total"),
                    value: "\(categoryStore.currencySymbol)\(Int(subscription.monthlyAmount))"
                )

                Divider()
                    .frame(height: 40)

                // Weekly Usage — 0時間の場合は「−」表示
                StatItem(
                    label: String(localized: "weekly_usage"),
                    value: subscription.weeklyUsageHours > 0
                        ? String(format: String(localized: "hours_per_week"), subscription.weeklyUsageHours)
                        : "−"
                )

                Divider()
                    .frame(height: 40)

                // Cost Per Hour — 利用時間なしの場合は「−」表示
                StatItem(
                    label: String(localized: "cost_per_hour"),
                    value: subscription.costPerHour != nil
                        ? "\(categoryStore.currencySymbol)\(Int(subscription.costPerHour!))\(String(localized: "per_hour"))"
                        : "−"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    /// Returns gradient colors from red to the status color
    private func gradientColors(for status: SubscriptionStatus) -> [Color] {
        let startColor = Color(hue: 0.00, saturation: 0.85, brightness: 0.72) // tooExpensive red

        switch status {
        case .unused:
            // Gray for unused
            return [Color(white: 0.55), Color(white: 0.55)]
        case .tooExpensive:
            // Only red for very poor status
            return [startColor, startColor]
        case .expensive:
            // Red to dark red/orange
            return [startColor, Color(hue: 0.02, saturation: 0.80, brightness: 0.85)]
        case .overpriced:
            // Red to orange
            return [startColor, Color(hue: 0.07, saturation: 0.90, brightness: 0.82)]
        case .fair:
            // Red to yellow
            return [startColor, Color(hue: 0.10, saturation: 0.82, brightness: 0.68)]
        case .good:
            // Red to green
            return [startColor, Color(hue: 0.36, saturation: 0.70, brightness: 0.58)]
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack(spacing: 16) {
        CostPerformanceCardView(
            subscription: Subscription(
                name: "Netflix",
                category: "entertainment",
                amount: 1490,
                billingCycle: .monthly,
                startDate: Date(),
                weeklyUsageHours: 5.0
            )
        )
        CostPerformanceCardView(
            subscription: Subscription(
                name: "Adobe CC",
                category: "productivity",
                amount: 72336,
                billingCycle: .yearly,
                startDate: Date(),
                weeklyUsageHours: 1.0
            )
        )
        CostPerformanceCardView(
            subscription: Subscription(
                name: "ジム",
                category: "lifestyle",
                amount: 8800,
                billingCycle: .monthly,
                startDate: Date(),
                weeklyUsageHours: 0.0
            )
        )
    }
    .padding()
    .environment(CategoryStore())
}
