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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Donut Chart Section
                    if !viewModel.categoryData.isEmpty {
                        VStack(spacing: 16) {
                            Text(String(localized: "monthly_total"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            DonutChartView(
                                data: viewModel.categoryData,
                                total: viewModel.monthlyTotal
                            )
                            .frame(height: 280)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                    // Cost Performance Cards
                    if !viewModel.sortedByAmount.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cost Performance")
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
                            Text("No data to analyze")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 60)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(String(localized: "analytics_title"))
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
}
