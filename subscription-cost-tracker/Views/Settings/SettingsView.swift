//
//  SettingsView.swift
//  subscription-cost-tracker
//

import SwiftUI

struct SettingsView: View {
    @Environment(CategoryStore.self) private var categoryStore

    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var editingCategory: CategoryItem? = nil
    @State private var editingName = ""

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: App Info
                Section {
                    // Version
                    HStack {
                        Text(String(localized: "settings_version"))
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }

                    // Review
                    Button {
                        openURL("itms-apps://itunes.apple.com/app/id000000000?action=write-review")
                    } label: {
                        HStack {
                            Text(String(localized: "settings_review"))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    // Privacy Policy
                    Button {
                        openURL("https://example.com/privacy")
                    } label: {
                        HStack {
                            Text(String(localized: "settings_privacy"))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
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
                        categoryStore.delete(at: offsets)
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
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "settings_title"))
            .toolbar {
                EditButton()
            }
        }
        // Add category alert
        .alert(String(localized: "settings_add_category"), isPresented: $showingAddCategory) {
            TextField(String(localized: "settings_category_name_placeholder"), text: $newCategoryName)
            Button(String(localized: "save")) {
                let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    categoryStore.add(name: trimmed)
                }
            }
            Button(String(localized: "cancel"), role: .cancel) {}
        }
        // Edit category alert
        .alert(String(localized: "settings_edit_category"),
               isPresented: Binding(
                   get: { editingCategory != nil },
                   set: { if !$0 { editingCategory = nil } }
               )) {
            TextField(String(localized: "settings_category_name_placeholder"), text: $editingName)
            Button(String(localized: "save")) {
                if let item = editingCategory {
                    let trimmed = editingName.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        categoryStore.update(id: item.id, name: trimmed)
                    }
                }
                editingCategory = nil
            }
            Button(String(localized: "cancel"), role: .cancel) {
                editingCategory = nil
            }
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    SettingsView()
        .environment(CategoryStore())
}
