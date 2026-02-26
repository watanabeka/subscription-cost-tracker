//
//  DonutChartView.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import SwiftUI
import Charts

struct DonutChartView: View {
    let data: [(name: String, categoryId: String, amount: Double)]
    let total: Double
    let period: AnalyticsPeriod
    @Environment(CategoryStore.self) private var categoryStore

    /// カテゴリ内でのサービスの順位に基づいてシェードカラーを計算
    private func colorForService(name: String, categoryId: String) -> Color {
        let catItem = categoryStore.category(for: categoryId)
        let siblings = data
            .filter { $0.categoryId == categoryId }
            .sorted { $0.amount > $1.amount }
        let index = siblings.firstIndex(where: { $0.name == name }) ?? 0
        return catItem.shadeColor(index: index, total: siblings.count)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Donut Chart
            ZStack {
                Chart(data, id: \.name) { item in
                    SectorMark(
                        angle: .value(String(localized: "label_amount"), item.amount),
                        innerRadius: .ratio(0.58),
                        angularInset: 1.5
                    )
                    .foregroundStyle(colorForService(name: item.name, categoryId: item.categoryId))
                }

                // Center Label（期間に応じてサフィックスを変える）
                VStack(spacing: 4) {
                    Text("\(categoryStore.currencySymbol)\(Int(total))")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(period.chartCenterSuffix)
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
                            .fill(colorForService(name: item.name, categoryId: item.categoryId))
                            .frame(width: 10, height: 10)
                        Text(item.name)
                            .font(.caption)
                            .foregroundStyle(.primary)
                        Text("(\(categoryStore.category(for: item.categoryId).name))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(categoryStore.currencySymbol)\(Int(item.amount))")
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
            (name: "Netflix",  categoryId: "entertainment", amount: 1490),
            (name: "Disney+",  categoryId: "entertainment", amount: 990),
            (name: "Spotify",  categoryId: "entertainment", amount: 980),
            (name: "ジム",     categoryId: "lifestyle",     amount: 8800),
            (name: "Adobe CC", categoryId: "productivity",  amount: 6028),
            (name: "iCloud+",  categoryId: "communication", amount: 130)
        ],
        total: 18418,
        period: .monthly
    )
    .padding()
    .environment(CategoryStore())
}
