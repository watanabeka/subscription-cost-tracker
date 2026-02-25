//
//  AddEditSubscriptionView.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct AddEditSubscriptionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(CategoryStore.self) private var categoryStore

    var subscription: Subscription?

    @State private var name: String = ""
    @State private var category: String = "other"
    @State private var amount: Double = 0.0
    @State private var billingCycle: BillingCycle = .monthly
    @State private var startDate: Date = Date()
    @State private var weeklyUsageHours: Double = 0.0
    @State private var showingDeleteAlert = false

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                // Service Name
                Section {
                    TextField(String(localized: "service_name_placeholder"), text: $name)
                }

                // Category
                Section {
                    Picker(String(localized: "label_category"), selection: $category) {
                        ForEach(categoryStore.categories) { cat in
                            HStack {
                                Image(systemName: cat.iconName)
                                Text(cat.name)
                            }
                            .tag(cat.id)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Amount and Billing Cycle
                Section {
                    HStack {
                        Text("¥")
                            .foregroundStyle(.secondary)
                        TextField(String(localized: "amount_placeholder"), value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                    }

                    Picker(selection: $billingCycle) {
                        ForEach(BillingCycle.allCases, id: \.self) { cycle in
                            Text(cycle.localizedLabel).tag(cycle)
                        }
                    } label: {
                        Text(String(localized: "label_billing_cycle"))
                    }
                    .pickerStyle(.segmented)
                }

                // Start Date
                Section {
                    DatePicker(String(localized: "label_start_date"), selection: $startDate, displayedComponents: .date)
                }

                // Weekly Usage Hours
                Section {
                    HStack {
                        Text(String(localized: "weekly_usage"))
                            .font(.body)

                        Spacer()

                        Stepper(value: $weeklyUsageHours, in: 0...40, step: 0.5) {
                            Text(String(format: "%.1fh", weeklyUsageHours))
                                .font(.headline)
                        }
                    }
                }

                // Delete Button (Edit mode only)
                if subscription != nil {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text(String(localized: "delete"))
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(subscription == nil ? String(localized: "add_subscription") : String(localized: "edit_subscription"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save")) {
                        saveSubscription()
                    }
                    .disabled(!isValid)
                }
            }
            .alert(String(localized: "delete_confirm_title"), isPresented: $showingDeleteAlert) {
                Button(String(localized: "delete"), role: .destructive) {
                    deleteSubscription()
                }
                Button(String(localized: "cancel"), role: .cancel) {}
            } message: {
                Text(String(localized: "delete_confirm_message"))
            }
            .onAppear {
                if let subscription = subscription {
                    name = subscription.name
                    category = subscription.category
                    amount = subscription.amount
                    billingCycle = subscription.billingCycle
                    startDate = subscription.startDate
                    weeklyUsageHours = subscription.weeklyUsageHours
                } else {
                    // Default to first visible category
                    category = categoryStore.categories.first?.id ?? "other"
                }
            }
        }
    }

    private func saveSubscription() {
        if let existing = subscription {
            existing.name = name.trimmingCharacters(in: .whitespaces)
            existing.category = category
            existing.amount = amount
            existing.billingCycle = billingCycle
            existing.startDate = startDate
            existing.weeklyUsageHours = weeklyUsageHours
        } else {
            let newSubscription = Subscription(
                name: name.trimmingCharacters(in: .whitespaces),
                category: category,
                amount: amount,
                billingCycle: billingCycle,
                startDate: startDate,
                weeklyUsageHours: weeklyUsageHours
            )
            modelContext.insert(newSubscription)
        }

        try? modelContext.save()

        // 通知を再スケジュール（トータル金額を更新）
        NotificationService.shared.scheduleAllNotifications(modelContext: modelContext)

        dismiss()
    }

    private func deleteSubscription() {
        if let subscription = subscription {
            modelContext.delete(subscription)
            try? modelContext.save()

            // 通知を再スケジュール（トータル金額を更新）
            NotificationService.shared.scheduleAllNotifications(modelContext: modelContext)
        }
        dismiss()
    }
}

#Preview {
    AddEditSubscriptionView()
        .modelContainer(for: Subscription.self, inMemory: true)
        .environment(CategoryStore())
}
