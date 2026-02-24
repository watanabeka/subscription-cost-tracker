//
//  CostPerformanceCardView.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import SwiftUI

struct CostPerformanceCardView: View {
    let subscription: Subscription

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Service name and category icon
            HStack(spacing: 12) {
                Image(systemName: subscription.category.icon)
                    .font(.title3)
                    .foregroundStyle(.appTheme)

                VStack(alignment: .leading, spacing: 2) {
                    Text(subscription.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subscription.category.localizedLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status Badge
                Text(subscription.status.label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(subscription.status.color)
                    .clipShape(Capsule())
            }

            Divider()

            // Stats Grid
            HStack(spacing: 0) {
                // Monthly Amount
                StatItem(
                    label: String(localized: "monthly_total"),
                    value: "¥\(Int(subscription.monthlyAmount))"
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
                        ? "¥\(Int(subscription.costPerHour!))\(String(localized: "per_hour"))"
                        : "−"
                )
            }

            // Value Score Progress Bar
            if subscription.weeklyUsageHours > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(String(localized: "label_value_score"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.0f%%", subscription.valueScore * 100))
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

                            // Progress
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.red, .orange, .yellow, .green],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * subscription.valueScore, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                category: .video,
                amount: 1490,
                billingCycle: .monthly,
                startDate: Date(),
                weeklyUsageHours: 5.0
            )
        )
        CostPerformanceCardView(
            subscription: Subscription(
                name: "Adobe CC",
                category: .productivity,
                amount: 72336,
                billingCycle: .yearly,
                startDate: Date(),
                weeklyUsageHours: 1.0
            )
        )
        CostPerformanceCardView(
            subscription: Subscription(
                name: "ジム",
                category: .fitness,
                amount: 8800,
                billingCycle: .monthly,
                startDate: Date(),
                weeklyUsageHours: 0.0
            )
        )
    }
    .padding()
}
