//
//  CategoryStore.swift
//  subscription-cost-tracker
//

import Foundation
import SwiftUI
import Observation

// MARK: - CategoryItem

struct CategoryItem: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var iconName: String
    var colorHue: Double   // HSB hue (0–1); ignored for "other"
    let isBuiltin: Bool

    // MARK: Color helpers

    var baseColor: Color {
        guard id != "other" else { return Color(white: 0.58) }
        return Color(hue: colorHue, saturation: 0.65, brightness: 0.78)
    }

    /// カテゴリ内サービス位置に応じたシェードカラー（index 0 が最も暗い）
    func shadeColor(index: Int, total: Int) -> Color {
        guard id != "other" else {
            let b = total > 1 ? 0.42 + Double(index) / Double(total - 1) * 0.32 : 0.58
            return Color(white: b)
        }
        let ratio = total > 1 ? Double(index) / Double(total - 1) : 0.5
        let brightness = 0.45 + ratio * 0.42           // 0.45（暗）→ 0.87（明）
        let saturation = max(0.10, 0.65 - ratio * 0.20) // 明るくなるほど彩度を下げる
        return Color(hue: colorHue, saturation: saturation, brightness: min(0.95, brightness))
    }
}

// MARK: - CategoryStore

@Observable
final class CategoryStore {

    private static let storageKey = "categoryStore_v1"

    var categories: [CategoryItem] = []

    static let fallback = CategoryItem(
        id: "other", name: "Other",
        iconName: "ellipsis.circle", colorHue: 0, isBuiltin: true
    )

    init() {
        load()
    }

    // MARK: - Default categories

    private func makeDefaults() -> [CategoryItem] {
        [
            CategoryItem(id: "entertainment",
                         name: String(localized: "category_entertainment"),
                         iconName: "sparkles",          colorHue: 0.085, isBuiltin: true),
            CategoryItem(id: "productivity",
                         name: String(localized: "category_productivity"),
                         iconName: "briefcase",          colorHue: 0.075, isBuiltin: true),
            CategoryItem(id: "learning",
                         name: String(localized: "category_learning"),
                         iconName: "book.closed",        colorHue: 0.370, isBuiltin: true),
            CategoryItem(id: "lifestyle",
                         name: String(localized: "category_lifestyle"),
                         iconName: "leaf",               colorHue: 0.310, isBuiltin: true),
            CategoryItem(id: "communication",
                         name: String(localized: "category_communication"),
                         iconName: "antenna.radiowaves.left.and.right", colorHue: 0.600, isBuiltin: true),
            CategoryItem(id: "shopping",
                         name: String(localized: "category_shopping"),
                         iconName: "cart",               colorHue: 0.755, isBuiltin: true),
            CategoryItem(id: "other",
                         name: String(localized: "category_other"),
                         iconName: "ellipsis.circle",   colorHue: 0.0,   isBuiltin: true),
        ]
    }

    // MARK: - Persistence

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode([CategoryItem].self, from: data) {
            categories = saved
        } else {
            categories = makeDefaults()
            persist()
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    // MARK: - Lookup

    func category(for id: String) -> CategoryItem {
        categories.first { $0.id == id } ?? Self.fallback
    }

    // MARK: - Mutations

    func add(name: String) {
        // Cycle through visually distinct hues for new custom categories
        let hues: [Double] = [0.55, 0.13, 0.83, 0.02, 0.47, 0.68, 0.27]
        let hue = hues[categories.count % hues.count]
        let item = CategoryItem(
            id: UUID().uuidString,
            name: name,
            iconName: "tag",
            colorHue: hue,
            isBuiltin: false
        )
        categories.append(item)
        persist()
    }

    func delete(at offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
        persist()
    }

    func update(id: String, name: String) {
        guard let index = categories.firstIndex(where: { $0.id == id }) else { return }
        categories[index].name = name
        persist()
    }

    func move(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
        persist()
    }
}
