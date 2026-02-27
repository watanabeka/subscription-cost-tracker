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
                    VStack(spacing: 0) {
                        // コスパの悪いアプリ数バナー（横幅いっぱい）
                        let poorCount = viewModel.poorValueCount(threshold: categoryStore.costPerHourThreshold)
                        if poorCount > 0 {
                            Text(String(format: String(localized: "home_poor_value_label"), poorCount))
                                .font(.system(size: 12 * 1.2)) // captionサイズ(12pt)を20%増
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(hue: 0.0, saturation: 0.55, brightness: 0.92).opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(.horizontal) // カードと同じ余白
                                .padding(.top, 16) // ラベル上側の余白
                                .padding(.bottom, 7) // ラベルと金額の間の余白（20の1/3≈7）
                        }

                        // Header - Monthly Total
                        VStack(spacing: 8) {
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
                        .padding(.bottom, -14) // 金額とカードの間の余白を半分に（24 - 14 = 10）

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
