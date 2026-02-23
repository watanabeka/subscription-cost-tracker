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
    @State private var viewModel = CalendarViewModel()

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
                                .foregroundStyle(.indigo)
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
                                .foregroundStyle(.indigo)
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
                        Text("Payment Schedule")
                            .font(.headline)
                            .padding(.horizontal)

                        if viewModel.paymentsForMonth().isEmpty {
                            Text("No payments this month")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 40)
                        } else {
                            ForEach(viewModel.paymentsForMonth(), id: \.0) { date, subs in
                                PaymentDayRow(date: date, subscriptions: subs)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle(String(localized: "calendar_title"))
            .onAppear {
                viewModel.loadSubscriptions(from: modelContext)
            }
            .onChange(of: modelContext) {
                viewModel.loadSubscriptions(from: modelContext)
            }
        }
    }
}

struct PaymentDayRow: View {
    let date: Date
    let subscriptions: [Subscription]

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d (E)"
        return formatter.string(from: date)
    }

    private var totalAmount: Double {
        subscriptions.reduce(0) { $0 + $1.monthlyAmount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dateLabel)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.indigo)
                Spacer()
                Text("¥\(Int(totalAmount))")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(subscriptions, id: \.id) { sub in
                    HStack(spacing: 8) {
                        Image(systemName: sub.category.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        Text(sub.name)
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("¥\(Int(sub.monthlyAmount))")
                            .font(.body)
                            .foregroundStyle(.secondary)
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
