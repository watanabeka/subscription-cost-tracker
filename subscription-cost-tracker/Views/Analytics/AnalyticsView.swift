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
    @State private var viewModel = AnalyticsViewModel()
    @State private var period: AnalyticsPeriod = .monthly

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
                            Text(String(localized: "label_amount"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

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

                    // Cost Performance Cards（月額ベースで固定）
                    if !viewModel.sortedByAmount.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "label_cost_performance"))
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(viewModel.sortedByAmount, id: \.id) { subscription in
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
