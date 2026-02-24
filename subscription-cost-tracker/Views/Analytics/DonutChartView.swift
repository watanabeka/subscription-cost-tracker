//
//  DonutChartView.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import SwiftUI
import Charts

struct DonutChartView: View {
    let data: [(name: String, category: SubscriptionCategory, amount: Double)]
    let total: Double

    /// カテゴリ内でのサービスの順位に基づいてシェードカラーを計算
    private func colorForService(name: String, category: SubscriptionCategory) -> Color {
        // 同カテゴリのサービスを金額降順で並べて index を特定
        let siblings = data
            .filter { $0.category == category }
            .sorted { $0.amount > $1.amount }
        let index = siblings.firstIndex(where: { $0.name == name }) ?? 0
        return category.shadeColor(index: index, total: siblings.count)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Donut Chart
            ZStack {
                Chart(data, id: \.name) { item in
                    SectorMark(
                        angle: .value("金額", item.amount),
                        innerRadius: .ratio(0.58),
                        angularInset: 1.5
                    )
                    .foregroundStyle(colorForService(name: item.name, category: item.category))
                }

                // Center Label
                VStack(spacing: 4) {
                    Text("¥\(Int(total))")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(String(localized: "per_month"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 200)

            // Legend — サービス名で表示、カテゴリ同系色
            VStack(alignment: .leading, spacing: 6) {
                ForEach(data, id: \.name) { item in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorForService(name: item.name, category: item.category))
                            .frame(width: 10, height: 10)
                        Text(item.name)
                            .font(.caption)
                            .foregroundStyle(.primary)
                        Text("(\(item.category.localizedLabel))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("¥\(Int(item.amount))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    DonutChartView(
        data: [
            (name: "Netflix", category: .video, amount: 1490),
            (name: "Disney+", category: .video, amount: 990),
            (name: "Spotify", category: .music, amount: 980),
            (name: "ジム", category: .fitness, amount: 8800),
            (name: "Adobe CC", category: .productivity, amount: 6028),
            (name: "iCloud+", category: .cloud, amount: 130)
        ],
        total: 18418
    )
    .padding()
}
