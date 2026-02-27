//
//  SettingsView.swift
//  subscription-cost-tracker
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(CategoryStore.self) private var categoryStore
    @Query private var allSubscriptions: [Subscription]

    @AppStorage("notificationFrequency") private var notificationFrequency: String = "monthly"
    @State private var hasCheckedNotificationPermission = false

    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var editingCategory: CategoryItem? = nil
    @State private var editingName = ""
    @State private var showingDeleteInUseAlert = false
    @State private var showingThresholdInput = false
    @State private var tempThresholdText = ""
    @FocusState private var isThresholdFocused: Bool

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var usedCategoryIds: Set<String> {
        Set(allSubscriptions.map { $0.category })
    }

    private var poorValueCount: Int {
        allSubscriptions.filter {
            $0.status(threshold: categoryStore.costPerHourThreshold).isPoorValue
        }.count
    }

    private var selectedCurrencyDisplayName: String {
        CategoryStore.supportedCurrencies
            .first { $0.id == categoryStore.selectedCurrencyCode }?.displayName
            ?? categoryStore.currencySymbol
    }

    var body: some View {
        @Bindable var store = categoryStore

        NavigationStack {
            List {
                // MARK: 通知（一番上）
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "settings_notification_description"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        // カスタム通知頻度ピッカー
                        HStack(spacing: 0) {
                            NotificationFrequencyButton(
                                title: String(localized: "notification_off"),
                                isSelected: notificationFrequency == "off",
                                position: .leading
                            ) {
                                notificationFrequency = "off"
                            }

                            NotificationFrequencyButton(
                                title: String(localized: "notification_weekly"),
                                isSelected: notificationFrequency == "weekly",
                                position: .middle
                            ) {
                                notificationFrequency = "weekly"
                            }

                            NotificationFrequencyButton(
                                title: String(localized: "notification_monthly"),
                                isSelected: notificationFrequency == "monthly",
                                position: .trailing
                            ) {
                                notificationFrequency = "monthly"
                            }
                        }
                        .frame(height: 44) // 20%増し（元の36.67から44へ）
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.appTheme.opacity(0.3), lineWidth: 1)
                        )

                        // 通知時刻の説明
                        if notificationFrequency == "weekly" {
                            Text(String(localized: "notification_time_weekly"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if notificationFrequency == "monthly" {
                            Text(String(localized: "notification_time_monthly"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(String(localized: "settings_notification_section"))
                }
                .onAppear {
                    // 通知許可状態をチェック
                    if !hasCheckedNotificationPermission {
                        checkNotificationPermission()
                        hasCheckedNotificationPermission = true
                    }
                }
                .onChange(of: notificationFrequency) {
                    NotificationService.shared.scheduleSubscriptionCheckNotification(
                        frequency: notificationFrequency,
                        poorValueCount: poorValueCount
                    )
                }

                // MARK: Currency
                Section {
                    HStack {
                        Text(String(localized: "settings_currency"))
                        Spacer()
                        Menu {
                            ForEach(CategoryStore.supportedCurrencies) { currency in
                                Button {
                                    categoryStore.selectedCurrencyCode = currency.id
                                    categoryStore.saveCurrency()
                                } label: {
                                    Text(currency.displayName)
                                }
                            }
                        } label: {
                            Text(selectedCurrencyDisplayName)
                                .fontWeight(.bold)
                                .foregroundStyle(.appTheme)
                        }
                    }
                } header: {
                    Text(String(localized: "settings_currency_section"))
                }

                // MARK: Cost Performance
                Section {
                    // Threshold input
                    HStack {
                        Text(String(localized: "settings_cost_threshold"))
                        Spacer()
                        Button {
                            tempThresholdText = "\(Int(categoryStore.costPerHourThreshold))"
                            showingThresholdInput = true
                        } label: {
                            HStack(spacing: 4) {
                                Text(categoryStore.currencySymbol)
                                    .fontWeight(.bold)
                                    .font(.system(size: 17 * 1.3))
                                Text("\(Int(categoryStore.costPerHourThreshold))")
                                    .fontWeight(.bold)
                                    .font(.system(size: 17 * 1.3))
                                Text(String(localized: "per_hour"))
                                    .foregroundStyle(.secondary)
                            }
                            .foregroundStyle(.appTheme)
                        }
                    }

                    // Dynamic threshold table
                    let t = categoryStore.costPerHourThreshold
                    let sym = categoryStore.currencySymbol
                    let perHour = String(localized: "per_hour")
                    VStack(alignment: .leading, spacing: 6) {
                        ThresholdRow(range: "> \(sym)\(formatAmount(t * 2.0))\(perHour)",   label: String(localized: "status_too_expensive"), color: SubscriptionStatus.tooExpensive.color)
                        ThresholdRow(range: "> \(sym)\(formatAmount(t))\(perHour)",         label: String(localized: "status_expensive"),     color: SubscriptionStatus.expensive.color)
                        ThresholdRow(range: "\(sym)\(formatAmount(t * 0.65)) – \(sym)\(formatAmount(t))\(perHour)", label: String(localized: "status_overpriced"), color: SubscriptionStatus.overpriced.color)
                        ThresholdRow(range: "\(sym)\(formatAmount(t * 0.30)) – \(sym)\(formatAmount(t * 0.65))\(perHour)", label: String(localized: "status_fair"), color: SubscriptionStatus.fair.color)
                        ThresholdRow(range: "< \(sym)\(formatAmount(t * 0.30))\(perHour)",  label: String(localized: "status_good"),          color: SubscriptionStatus.good.color)
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
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.appTheme))
                        }
                    }
                }

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
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        // Threshold input sheet
        .sheet(isPresented: $showingThresholdInput) {
            NavigationStack {
                VStack(spacing: 20) {
                    Text(String(localized: "settings_cost_threshold"))
                        .font(.headline)
                        .padding(.top, 20)

                    HStack(spacing: 8) {
                        Text(categoryStore.currencySymbol)
                            .font(.title2)
                            .fontWeight(.bold)
                        TextField("1000", text: $tempThresholdText)
                            .keyboardType(.numberPad)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .frame(width: 120)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .focused($isThresholdFocused)
                        Text(String(localized: "per_hour"))
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(String(localized: "close_button")) {
                            saveThreshold()
                            showingThresholdInput = false
                        }
                    }
                }
                .onAppear {
                    isThresholdFocused = true
                }
            }
            .presentationDetents([.height(250)])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(false)
            .onDisappear {
                if !tempThresholdText.isEmpty {
                    saveThreshold()
                }
            }
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

    private func saveThreshold() {
        if let value = Double(tempThresholdText), value > 0 {
            categoryStore.costPerHourThreshold = value
            categoryStore.saveThreshold()
        }
    }

    private func formatAmount(_ value: Double) -> String {
        let v = Int(value.rounded())
        return v >= 1000 ? "\(v / 1000),\(String(format: "%03d", v % 1000))" : "\(v)"
    }

    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                // 通知が拒否されている場合はオフに設定
                if settings.authorizationStatus == .denied {
                    notificationFrequency = "off"
                }
            }
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - NotificationFrequencyButton

private struct NotificationFrequencyButton: View {
    enum Position {
        case leading, middle, trailing
    }

    let title: String
    let isSelected: Bool
    let position: Position
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : .appTheme)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? Color.appTheme.opacity(0.85) : Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .clipShape(
            RoundedCorners(
                topLeft: position == .leading ? 8 : 0,
                topRight: position == .trailing ? 8 : 0,
                bottomLeft: position == .leading ? 8 : 0,
                bottomRight: position == .trailing ? 8 : 0
            )
        )
    }
}

// MARK: - RoundedCorners

private struct RoundedCorners: Shape {
    var topLeft: CGFloat = 0
    var topRight: CGFloat = 0
    var bottomLeft: CGFloat = 0
    var bottomRight: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.size.width
        let height = rect.size.height

        // 左上
        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))

        // 右上
        if topRight > 0 {
            path.addArc(
                center: CGPoint(x: rect.maxX - topRight, y: rect.minY + topRight),
                radius: topRight,
                startAngle: Angle(degrees: -90),
                endAngle: Angle(degrees: 0),
                clockwise: false
            )
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))

        // 右下
        if bottomRight > 0 {
            path.addArc(
                center: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight),
                radius: bottomRight,
                startAngle: Angle(degrees: 0),
                endAngle: Angle(degrees: 90),
                clockwise: false
            )
        }

        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))

        // 左下
        if bottomLeft > 0 {
            path.addArc(
                center: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft),
                radius: bottomLeft,
                startAngle: Angle(degrees: 90),
                endAngle: Angle(degrees: 180),
                clockwise: false
            )
        }

        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))

        // 左上
        if topLeft > 0 {
            path.addArc(
                center: CGPoint(x: rect.minX + topLeft, y: rect.minY + topLeft),
                radius: topLeft,
                startAngle: Angle(degrees: 180),
                endAngle: Angle(degrees: 270),
                clockwise: false
            )
        }

        return path
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
