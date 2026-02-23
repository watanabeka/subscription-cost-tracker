//
//  DonutChartView.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import SwiftUI
import Charts

struct DonutChartView: View {
    let data: [(category: SubscriptionCategory, amount: Double)]
    let total: Double

    private let chartColors: [SubscriptionCategory: Color] = [
        .video: .blue,
        .music: .purple,
        .fitness: .green,
        .productivity: .orange,
        .game: .red,
        .news: .yellow,
        .cloud: .cyan,
        .other: .gray
    ]

    var body: some View {
        ZStack {
            // Donut Chart
            Chart(data, id: \.category) { item in
                SectorMark(
                    angle: .value("Amount", item.amount),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(chartColors[item.category] ?? .gray)
            }

            // Center Label
            VStack(spacing: 4) {
                Text("¥\(Int(total))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(String(localized: "per_month"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .overlay(alignment: .bottom) {
            // Legend
            VStack(alignment: .leading, spacing: 8) {
                ForEach(data, id: \.category) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(chartColors[item.category] ?? .gray)
                            .frame(width: 12, height: 12)
                        Text(item.category.localizedLabel)
                            .font(.caption)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("¥\(Int(item.amount))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 220)
        }
    }
}

#Preview {
    DonutChartView(
        data: [
            (.video, 1490),
            (.music, 980),
            (.fitness, 8800),
            (.productivity, 6028),
            (.cloud, 130)
        ],
        total: 17428
    )
    .frame(height: 280)
    .padding()
}
