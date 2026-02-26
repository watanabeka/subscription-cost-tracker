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
        return Color(hue: colorHue, saturation: 0.70, brightness: 0.82)
    }

    /// カテゴリ内サービス位置に応じたシェードカラー（index 0 が最も暗い）
    func shadeColor(index: Int, total: Int) -> Color {
        guard id != "other" else {
            let b = total > 1 ? 0.42 + Double(index) / Double(total - 1) * 0.32 : 0.58
            return Color(white: b)
        }
        let ratio = total > 1 ? Double(index) / Double(total - 1) : 0.5
        let brightness = 0.45 + ratio * 0.42
        let saturation = max(0.10, 0.70 - ratio * 0.22)
        return Color(hue: colorHue, saturation: saturation, brightness: min(0.95, brightness))
    }
}

// MARK: - CurrencyOption

struct CurrencyOption: Identifiable {
    let id: String          // ISO code e.g. "USD"
    let symbol: String      // e.g. "$"
    let displayName: String // e.g. "USD ($)"
}

// MARK: - CategoryStore

@Observable
final class CategoryStore {

    /// バージョンを上げるとカテゴリを再シード（色変更時等）
    private static let storageKey   = "categoryStore_v2"
    private static let thresholdKey = "costPerHourThreshold"
    private static let currencyKey  = "selectedCurrencyCode"

    var categories: [CategoryItem] = []

    /// 「高いと感じる」時間あたりコストの基準値（円/h）デフォルト 1000
    var costPerHourThreshold: Double = 1000

    /// Selected currency ISO code (e.g. "USD", "JPY")
    var selectedCurrencyCode: String = "USD"

    /// Currency symbol derived from selectedCurrencyCode
    var currencySymbol: String {
        Self.supportedCurrencies.first { $0.id == selectedCurrencyCode }?.symbol ?? "$"
    }

    /// Supported currencies
    static let supportedCurrencies: [CurrencyOption] = [
        CurrencyOption(id: "USD", symbol: "$",   displayName: "USD ($)"),
        CurrencyOption(id: "JPY", symbol: "¥",   displayName: "JPY (¥)"),
        CurrencyOption(id: "EUR", symbol: "€",   displayName: "EUR (€)"),
        CurrencyOption(id: "GBP", symbol: "£",   displayName: "GBP (£)"),
        CurrencyOption(id: "CNY", symbol: "CN¥", displayName: "CNY (CN¥)"),
    ]

    /// Returns the symbol for a given currency code (for use in non-SwiftUI contexts)
    static func symbol(forCurrencyCode code: String) -> String {
        supportedCurrencies.first { $0.id == code }?.symbol ?? "$"
    }

    static let fallback = CategoryItem(
        id: "other", name: "Other",
        iconName: "ellipsis.circle", colorHue: 0, isBuiltin: true
    )

    init() {
        let stored = UserDefaults.standard.double(forKey: Self.thresholdKey)
        costPerHourThreshold = stored > 0 ? stored : 1000

        if let saved = UserDefaults.standard.string(forKey: Self.currencyKey) {
            selectedCurrencyCode = saved
        } else {
            // First launch: default based on device language
            let langCode = Locale.current.language.languageCode?.identifier ?? "en"
            selectedCurrencyCode = langCode == "ja" ? "JPY" : "USD"
            UserDefaults.standard.set(selectedCurrencyCode, forKey: Self.currencyKey)
        }

        load()
    }

    // MARK: - Threshold persistence

    func saveThreshold() {
        UserDefaults.standard.set(costPerHourThreshold, forKey: Self.thresholdKey)
    }

    // MARK: - Currency persistence

    func saveCurrency() {
        UserDefaults.standard.set(selectedCurrencyCode, forKey: Self.currencyKey)
    }

    // MARK: - Default categories（v2: 色を刷新）

    private func makeDefaults() -> [CategoryItem] {
        [
            // エンタメ: ビビッドなピンク/マゼンタ
            CategoryItem(id: "entertainment",
                         name: String(localized: "category_entertainment"),
                         iconName: "sparkles",          colorHue: 0.86, isBuiltin: true),
            // 仕事・生産性: 落ち着いたブルー
            CategoryItem(id: "productivity",
                         name: String(localized: "category_productivity"),
                         iconName: "briefcase",          colorHue: 0.60, isBuiltin: true),
            // 学習: エメラルドグリーン
            CategoryItem(id: "learning",
                         name: String(localized: "category_learning"),
                         iconName: "book.closed",        colorHue: 0.38, isBuiltin: true),
            // ライフスタイル: オレンジ
            CategoryItem(id: "lifestyle",
                         name: String(localized: "category_lifestyle"),
                         iconName: "leaf",               colorHue: 0.07, isBuiltin: true),
            // 通信・固定費: ティール/シアン
            CategoryItem(id: "communication",
                         name: String(localized: "category_communication"),
                         iconName: "antenna.radiowaves.left.and.right", colorHue: 0.52, isBuiltin: true),
            // ショッピング: レッド
            CategoryItem(id: "shopping",
                         name: String(localized: "category_shopping"),
                         iconName: "cart",               colorHue: 0.97, isBuiltin: true),
            // その他: グレー
            CategoryItem(id: "other",
                         name: String(localized: "category_other"),
                         iconName: "ellipsis.circle",   colorHue: 0.0,  isBuiltin: true),
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
        let hues: [Double] = [0.55, 0.13, 0.83, 0.02, 0.47, 0.68, 0.27]
        let hue = hues[categories.count % hues.count]
        let item = CategoryItem(
            id: UUID().uuidString, name: name,
            iconName: "tag", colorHue: hue, isBuiltin: false
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
