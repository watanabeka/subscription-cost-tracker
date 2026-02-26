//
//  CalendarView.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CategoryStore.self) private var categoryStore
    @State private var viewModel = CalendarViewModel()
    @State private var editingSubscription: Subscription? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Month Navigation Header
                    HStack {
                        Button {
                            viewModel.moveMonth(by: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundStyle(.appTheme)
                                .frame(width: 44, height: 44)
                        }

                        Spacer()

                        Text(viewModel.monthLabel)
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        Button {
                            viewModel.moveMonth(by: 1)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundStyle(.appTheme)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Calendar Grid
                    CalendarGridView(
                        currentMonth: viewModel.currentMonth,
                        subscriptions: viewModel.subscriptions
                    )
                    .padding(.horizontal)

                    // Payments List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(String(localized: "label_payment_schedule"))
                                .font(.headline)
                            Spacer()
                            let monthTotal = viewModel.paymentsForMonth().reduce(0.0) { sum, payment in
                                sum + payment.1.reduce(0.0) { $0 + $1.monthlyAmount }
                            }
                            Text("\(categoryStore.currencySymbol)\(Int(monthTotal))")
                                .font(.headline)
                                .foregroundStyle(.appTheme)
                        }
                        .padding(.horizontal)

                        if viewModel.paymentsForMonth().isEmpty {
                            Text(String(localized: "label_no_payments"))
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 40)
                        } else {
                            ForEach(viewModel.paymentsForMonth(), id: \.0) { date, subs in
                                PaymentDayRow(date: date, subscriptions: subs) { sub in
                                    editingSubscription = sub
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                }
            }
            .onAppear {
                viewModel.loadSubscriptions(from: modelContext)
            }
            .onChange(of: modelContext) {
                viewModel.loadSubscriptions(from: modelContext)
            }
            .sheet(item: $editingSubscription) { sub in
                AddEditSubscriptionView(subscription: sub)
                    .onDisappear {
                        viewModel.loadSubscriptions(from: modelContext)
                    }
            }
        }
    }
}

struct PaymentDayRow: View {
    let date: Date
    let subscriptions: [Subscription]
    let onSelect: (Subscription) -> Void
    @Environment(CategoryStore.self) private var categoryStore

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MdE")
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 日付のみ表示（合計額は削除）
            Text(dateLabel)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.appTheme)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(subscriptions, id: \.id) { sub in
                    Button {
                        onSelect(sub)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: categoryStore.category(for: sub.category).iconName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            Text(sub.name)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(categoryStore.currencySymbol)\(Int(sub.monthlyAmount))")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if sub.id != subscriptions.last?.id {
                        Divider()
                            .padding(.leading, 28)
                    }
                }
            }
            .padding(.leading, 8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
