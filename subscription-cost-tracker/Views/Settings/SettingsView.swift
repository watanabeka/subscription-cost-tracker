//
//  SettingsView.swift
//  subscription-cost-tracker
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(CategoryStore.self) private var categoryStore
    @Query private var allSubscriptions: [Subscription]

    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var editingCategory: CategoryItem? = nil
    @State private var editingName = ""
    @State private var showingDeleteInUseAlert = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var usedCategoryIds: Set<String> {
        Set(allSubscriptions.map { $0.category })
    }

    var body: some View {
        @Bindable var store = categoryStore

        NavigationStack {
            List {
                // MARK: App Info
                Section {
                    HStack {
                        Text(String(localized: "settings_version"))
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }

                    Button { openURL("itms-apps://itunes.apple.com/app/id000000000?action=write-review") } label: {
                        HStack {
                            Text(String(localized: "settings_review")).foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                    }

                    Button { openURL("https://example.com/privacy") } label: {
                        HStack {
                            Text(String(localized: "settings_privacy")).foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                }

                // MARK: Cost Performance
                Section {
                    // Threshold input
                    HStack {
                        Text(String(localized: "settings_cost_threshold"))
                        Spacer()
                        HStack(spacing: 4) {
                            Text("¥").foregroundStyle(.secondary)
                            TextField("1000", value: $store.costPerHourThreshold, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                            Text(String(localized: "per_hour")).foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: categoryStore.costPerHourThreshold) { _, _ in
                        categoryStore.saveThreshold()
                    }

                    // Dynamic threshold table
                    let t = categoryStore.costPerHourThreshold
                    VStack(alignment: .leading, spacing: 6) {
                        ThresholdRow(range: "> ¥\(formatYen(t * 2.0))/h",   label: String(localized: "status_too_expensive"), color: SubscriptionStatus.tooExpensive.color)
                        ThresholdRow(range: "> ¥\(formatYen(t))/h",         label: String(localized: "status_expensive"),     color: SubscriptionStatus.expensive.color)
                        ThresholdRow(range: "¥\(formatYen(t * 0.65))〜\(formatYen(t))/h", label: String(localized: "status_overpriced"), color: SubscriptionStatus.overpriced.color)
                        ThresholdRow(range: "¥\(formatYen(t * 0.30))〜\(formatYen(t * 0.65))/h", label: String(localized: "status_fair"), color: SubscriptionStatus.fair.color)
                        ThresholdRow(range: "< ¥\(formatYen(t * 0.30))/h",  label: String(localized: "status_good"),          color: SubscriptionStatus.good.color)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(String(localized: "settings_cost_performance_section"))
                }

                // MARK: Category Settings
                Section {
                    ForEach(categoryStore.categories) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.iconName)
                                .foregroundStyle(item.baseColor)
                                .frame(width: 28)
                            Text(item.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if usedCategoryIds.contains(item.id) {
                                Image(systemName: "person.2.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingCategory = item
                            editingName = item.name
                        }
                    }
                    .onDelete { offsets in
                        let items = offsets.map { categoryStore.categories[$0] }
                        let blocked = items.filter { usedCategoryIds.contains($0.id) }
                        if blocked.isEmpty {
                            categoryStore.delete(at: offsets)
                        } else {
                            showingDeleteInUseAlert = true
                        }
                    }
                    .onMove { from, to in
                        categoryStore.move(from: from, to: to)
                    }
                } header: {
                    HStack {
                        Text(String(localized: "settings_categories"))
                        Spacer()
                        Button {
                            newCategoryName = ""
                            showingAddCategory = true
                        } label: {
                            Image(systemName: "plus").font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "settings_title"))
            .toolbar { EditButton() }
        }
        // Add category
        .alert(String(localized: "settings_add_category"), isPresented: $showingAddCategory) {
            TextField(String(localized: "settings_category_name_placeholder"), text: $newCategoryName)
            Button(String(localized: "save")) {
                let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { categoryStore.add(name: trimmed) }
            }
            Button(String(localized: "cancel"), role: .cancel) {}
        }
        // Edit category
        .alert(String(localized: "settings_edit_category"),
               isPresented: Binding(get: { editingCategory != nil }, set: { if !$0 { editingCategory = nil } })) {
            TextField(String(localized: "settings_category_name_placeholder"), text: $editingName)
            Button(String(localized: "save")) {
                if let item = editingCategory {
                    let trimmed = editingName.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty { categoryStore.update(id: item.id, name: trimmed) }
                }
                editingCategory = nil
            }
            Button(String(localized: "cancel"), role: .cancel) { editingCategory = nil }
        }
        // Delete blocked
        .alert(String(localized: "category_in_use_title"), isPresented: $showingDeleteInUseAlert) {
            Button(String(localized: "cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "category_in_use_message"))
        }
    }

    private func formatYen(_ value: Double) -> String {
        let v = Int(value.rounded())
        return v >= 1000 ? "\(v / 1000),\(String(format: "%03d", v % 1000))" : "\(v)"
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - ThresholdRow

private struct ThresholdRow: View {
    let range: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(range)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(color)
        }
    }
}

#Preview {
    SettingsView()
        .environment(CategoryStore())
        .modelContainer(for: Subscription.self, inMemory: true)
}
