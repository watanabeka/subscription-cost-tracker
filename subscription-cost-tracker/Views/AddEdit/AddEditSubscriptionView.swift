//
//  AddEditSubscriptionView.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData
import StoreKit

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

    private var isAddMode: Bool { subscription == nil }

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
                        Text(categoryStore.currencySymbol)
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
                            Text(String(format: "%.1f", weeklyUsageHours) + String(localized: "hours_per_week_unit"))
                                .font(.headline)
                        }
                    }
                }
            }
            .navigationTitle(isAddMode
                ? String(localized: "add_subscription")
                : String(localized: "edit_subscription"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isAddMode {
                    // 追加モード: 右上に「閉じる」
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(String(localized: "close_button")) {
                            dismiss()
                        }
                    }
                } else {
                    // 編集モード: 右上にゴミ箱アイコン（左の＜はNavigationStackが自動表示）
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            // 画面下部の保存ボタン（片手操作しやすい位置）
            .safeAreaInset(edge: .bottom) {
                Button(action: saveSubscription) {
                    Text(String(localized: "save"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(isValid ? Color.appTheme : Color(.systemGray4))
                        .foregroundStyle(isValid ? .white : Color(.systemGray2))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!isValid)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
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
                    category = categoryStore.categories.first?.id ?? "other"
                }
            }
        }
    }

    private func saveSubscription() {
        let isNewSubscription = subscription == nil

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
        NotificationService.shared.scheduleAllNotifications(modelContext: modelContext)

        // 新規追加時にレビュー依頼をチェック
        if isNewSubscription {
            requestReviewIfNeeded()
        }

        dismiss()
    }

    private func requestReviewIfNeeded() {
        // レビュー依頼を既に表示したかチェック
        let hasRequestedReview = UserDefaults.standard.bool(forKey: "hasRequestedReview")
        guard !hasRequestedReview else { return }

        // 全サブスク数を取得
        let descriptor = FetchDescriptor<Subscription>()
        guard let subscriptions = try? modelContext.fetch(descriptor) else { return }

        // サブスクが2つになったらレビュー依頼を表示
        if subscriptions.count == 2 {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
                UserDefaults.standard.set(true, forKey: "hasRequestedReview")
            }
        }
    }

    private func deleteSubscription() {
        if let subscription = subscription {
            modelContext.delete(subscription)
            try? modelContext.save()
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
