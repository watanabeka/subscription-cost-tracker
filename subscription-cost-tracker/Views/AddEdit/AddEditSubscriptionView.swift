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

    var subscription: Subscription?

    @State private var name: String = ""
    @State private var category: SubscriptionCategory = .other
    @State private var amount: Double = 0.0
    @State private var billingCycle: BillingCycle = .monthly
    @State private var startDate: Date = Date()
    @State private var weeklyUsageHours: Double = 0.0
    @State private var showingDeleteAlert = false
    @State private var searchText: String = ""

    private let presetServices = [
        "Netflix", "Amazon Prime", "Disney+", "Hulu", "Apple TV+", "YouTube Premium",
        "Spotify", "Apple Music", "Amazon Music", "LINE MUSIC",
        "Adobe Creative Cloud", "Microsoft 365", "iCloud+", "Google One", "Dropbox",
        "ChatGPT Plus", "Notion", "Slack", "Canva",
        "Nintendo Switch Online", "Xbox Game Pass",
        "Kindle Unlimited", "Audible", "dマガジン",
        "ジム"
    ]

    private var filteredPresets: [String] {
        if searchText.isEmpty {
            return []
        }
        return presetServices.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                // Service Name with Suggestions
                Section {
                    TextField(String(localized: "service_name_placeholder"), text: $searchText)
                        .onChange(of: searchText) { _, newValue in
                            name = newValue
                        }

                    if !filteredPresets.isEmpty {
                        ForEach(filteredPresets, id: \.self) { preset in
                            Button {
                                name = preset
                                searchText = preset
                            } label: {
                                HStack {
                                    Text(preset)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                // Category
                Section {
                    Picker("Category", selection: $category) {
                        ForEach(SubscriptionCategory.allCases, id: \.self) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                Text(cat.localizedLabel)
                            }
                            .tag(cat)
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
                        Text("Billing Cycle")
                    }
                    .pickerStyle(.segmented)
                }

                // Start Date
                Section {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }

                // Weekly Usage Hours
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "weekly_usage"))
                                .font(.body)
                            if weeklyUsageHours == 0 {
                                Text(String(localized: "unused_label"))
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }

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
                    searchText = subscription.name
                    category = subscription.category
                    amount = subscription.amount
                    billingCycle = subscription.billingCycle
                    startDate = subscription.startDate
                    weeklyUsageHours = subscription.weeklyUsageHours
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
        dismiss()
    }

    private func deleteSubscription() {
        if let subscription = subscription {
            modelContext.delete(subscription)
            try? modelContext.save()
        }
        dismiss()
    }
}

#Preview {
    AddEditSubscriptionView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
