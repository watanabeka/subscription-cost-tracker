//
//  AnalyticsView.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CategoryStore.self) private var categoryStore
    @State private var viewModel = AnalyticsViewModel()
    @State private var period: AnalyticsPeriod = .monthly
    @State private var sortOption: CostPerformanceSortOption = .costPerformance

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 期間ピッカー（月 / 年 / 累計）
                    Picker("", selection: $period) {
                        ForEach(AnalyticsPeriod.allCases, id: \.self) { p in
                            Text(p.label).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    let currentData = viewModel.serviceData(for: period)

                    // Donut Chart Section
                    if !currentData.isEmpty {
                        VStack(spacing: 16) {
                            DonutChartView(
                                data: currentData,
                                total: viewModel.total(for: period),
                                period: period
                            )
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                    // Cost Performance Cards
                    let sorted = viewModel.sortedForCostPerformance(
                        by: sortOption,
                        threshold: categoryStore.costPerHourThreshold
                    )
                    if !sorted.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            // ヘッダー行：タイトル + ソートフィルター
                            HStack {
                                Text(String(localized: "label_cost_performance"))
                                    .font(.headline)
                                Spacer()
                                Menu {
                                    ForEach(CostPerformanceSortOption.allCases, id: \.self) { option in
                                        Button {
                                            sortOption = option
                                        } label: {
                                            HStack {
                                                Text(option.label)
                                                if sortOption == option {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(sortOption.label)
                                            .font(.subheadline)
                                            .foregroundStyle(.appTheme)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                            .foregroundStyle(.appTheme)
                                    }
                                }
                            }
                            .padding(.horizontal)

                            ForEach(sorted, id: \.id) { subscription in
                                CostPerformanceCardView(subscription: subscription)
                                    .padding(.horizontal)
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.pie")
                                .font(.system(size: 60))
                                .foregroundStyle(.gray)
                            Text(String(localized: "label_no_analytics"))
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 60)
                    }
                }
                .padding(.vertical)
            }
            .onAppear {
                viewModel.loadSubscriptions(from: modelContext)
            }
            .onChange(of: modelContext) {
                viewModel.loadSubscriptions(from: modelContext)
            }
        }
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: Subscription.self, inMemory: true)
        .environment(CategoryStore())
}
