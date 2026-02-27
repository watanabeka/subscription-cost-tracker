//
//  HomeView.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CategoryStore.self) private var categoryStore
    @State private var viewModel = HomeViewModel()
    @State private var showingAddSheet = false
    @State private var editingSubscription: Subscription? = nil

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header - Monthly Total
                        VStack(spacing: 8) {
                            // コスパの悪いアプリ数バナー
                            let poorCount = viewModel.poorValueCount(threshold: categoryStore.costPerHourThreshold)
                            if poorCount > 0 {
                                Text(String(format: String(localized: "home_poor_value_label"), poorCount))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(Color(hue: 0.0, saturation: 0.55, brightness: 0.92).opacity(0.85))
                                    .clipShape(Capsule())
                            }

                            Text(String(localized: "monthly_total"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("\(categoryStore.currencySymbol)\(Int(viewModel.monthlyTotal))")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(.appTheme)
                                Text(String(localized: "per_month"))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)

                        // Subscription Cards（コスパの悪い順）
                        let sorted = viewModel.sortedSubscriptions(threshold: categoryStore.costPerHourThreshold)
                        if sorted.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.gray)
                                Text(String(localized: "empty_state"))
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 60)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(sorted, id: \.id) { subscription in
                                    Button {
                                        editingSubscription = subscription
                                    } label: {
                                        SubscriptionCardView(subscription: subscription)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Floating Action Button
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(.appTheme)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .padding(20)
            }
            .onAppear {
                viewModel.loadSubscriptions(from: modelContext)
            }
            .onChange(of: modelContext) {
                viewModel.loadSubscriptions(from: modelContext)
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEditSubscriptionView()
                    .onDisappear {
                        viewModel.loadSubscriptions(from: modelContext)
                    }
            }
            .sheet(item: $editingSubscription) { subscription in
                AddEditSubscriptionView(subscription: subscription)
                    .onDisappear {
                        viewModel.loadSubscriptions(from: modelContext)
                    }
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
