//
//  Item.swift
//  subscription-cost-tracker
//
//  Created by 渡辺海星 on 2026/02/23.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - App Theme Color
extension Color {
    static let appTheme = Color(red: 0.36, green: 0.60, blue: 0.85)
}

@Model
class Subscription {
    var id: UUID = UUID()
    var name: String = ""
    var category: SubscriptionCategory = SubscriptionCategory.other
    var amount: Double = 0.0
    var billingCycle: BillingCycle = BillingCycle.monthly
    var startDate: Date = Date()
    var weeklyUsageHours: Double = 0.0
    var createdAt: Date = Date()

    init(
        name: String,
        category: SubscriptionCategory,
        amount: Double,
        billingCycle: BillingCycle,
        startDate: Date,
        weeklyUsageHours: Double
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.amount = amount
        self.billingCycle = billingCycle
        self.startDate = startDate
        self.weeklyUsageHours = weeklyUsageHours
        self.createdAt = Date()
    }
}

// MARK: - 計算プロパティ
extension Subscription {
    var monthlyAmount: Double {
        billingCycle == .yearly ? amount / 12.0 : amount
    }

    var monthlyUsageHours: Double {
        weeklyUsageHours * 4.33
    }

    var costPerHour: Double? {
        guard monthlyUsageHours > 0 else { return nil }
        return monthlyAmount / monthlyUsageHours
    }

    var valueScore: Double {
        guard let cph = costPerHour else { return 0 }
        return max(0, min(1.0, 1.0 - (cph - 100) / 900))
    }

    var status: SubscriptionStatus {
        if weeklyUsageHours == 0 { return .unused }
        if valueScore < 0.3 { return .poor }
        if valueScore < 0.7 { return .fair }
        return .good
    }
}

// MARK: - Enums
enum BillingCycle: String, Codable, CaseIterable {
    case monthly
    case yearly

    var localizedLabel: String {
        switch self {
        case .monthly: return String(localized: "billing_monthly")
        case .yearly:  return String(localized: "billing_yearly")
        }
    }
}

enum SubscriptionCategory: String, Codable, CaseIterable {
    case video, music, fitness, productivity, game, news, cloud, other

    var icon: String {
        switch self {
        case .video:        return "play.tv"
        case .music:        return "music.note"
        case .fitness:      return "figure.run"
        case .productivity: return "briefcase"
        case .game:         return "gamecontroller"
        case .news:         return "newspaper"
        case .cloud:        return "cloud"
        case .other:        return "ellipsis.circle"
        }
    }

    var localizedLabel: String {
        String(localized: "category_\(rawValue)")
    }

    // カテゴリごとのHSBベース値 (hue, saturation)
    private var hsbBase: (hue: Double, sat: Double) {
        switch self {
        case .video:        return (0.600, 0.70)
        case .music:        return (0.755, 0.62)
        case .fitness:      return (0.370, 0.68)
        case .productivity: return (0.075, 0.78)
        case .game:         return (0.000, 0.72)
        case .news:         return (0.145, 0.80)
        case .cloud:        return (0.520, 0.62)
        case .other:        return (0.000, 0.00)
        }
    }

    /// カテゴリのベースカラー（カレンダー帯・アイコン等に使用）
    var baseColor: Color {
        if self == .other { return Color(white: 0.58) }
        let h = hsbBase
        return Color(hue: h.hue, saturation: h.sat, brightness: 0.78)
    }

    /// カテゴリ内のサービス位置に応じたシェードカラー（index 0 が最も暗い）
    func shadeColor(index: Int, total: Int) -> Color {
        if self == .other {
            let b = total > 1 ? 0.42 + Double(index) / Double(total - 1) * 0.32 : 0.58
            return Color(white: b)
        }
        let h = hsbBase
        let ratio = total > 1 ? Double(index) / Double(total - 1) : 0.5
        let brightness = 0.45 + ratio * 0.42   // 0.45（暗）→ 0.87（明）
        let saturation = h.sat - ratio * 0.20  // 明るくなるほど彩度を下げる
        return Color(hue: h.hue, saturation: max(0.10, saturation), brightness: min(0.95, brightness))
    }
}

enum SubscriptionStatus {
    case unused, poor, fair, good

    var color: Color {
        switch self {
        case .unused: return .red
        case .poor:   return .orange
        case .fair:   return .gray
        case .good:   return .green
        }
    }

    var label: String {
        switch self {
        case .unused: return String(localized: "status_unused")
        case .poor:   return String(localized: "status_poor")
        case .fair:   return String(localized: "status_fair")
        case .good:   return String(localized: "status_good")
        }
    }
}
