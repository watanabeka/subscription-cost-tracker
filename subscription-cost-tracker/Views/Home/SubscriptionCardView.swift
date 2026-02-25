//
//  SubscriptionCardView.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import SwiftUI

struct SubscriptionCardView: View {
    let subscription: Subscription
    @Environment(CategoryStore.self) private var categoryStore

    var body: some View {
        let cat = categoryStore.category(for: subscription.category)
        let status = subscription.status(threshold: categoryStore.costPerHourThreshold)

        HStack(spacing: 16) {
            // Left border with status color
            Rectangle()
                .fill(status.color)
                .frame(width: 4)

            // Category icon
            Image(systemName: cat.iconName)
                .font(.title2)
                .foregroundStyle(.appTheme)
                .frame(width: 40)

            // Service name and category
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(cat.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Monthly amount and status badge
            VStack(alignment: .trailing, spacing: 6) {
                Text("¥\(Int(subscription.monthlyAmount))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                // Status badge
                Text(status.label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(status.color)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 16)
        .padding(.trailing, 16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 16) {
        SubscriptionCardView(
            subscription: Subscription(
                name: "Netflix",
                category: "entertainment",
                amount: 1490,
                billingCycle: .monthly,
                startDate: Date(),
                weeklyUsageHours: 5.0
            )
        )
        SubscriptionCardView(
            subscription: Subscription(
                name: "Spotify",
                category: "entertainment",
                amount: 980,
                billingCycle: .monthly,
                startDate: Date(),
                weeklyUsageHours: 10.0
            )
        )
        SubscriptionCardView(
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
