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

// foregroundStyle(.appTheme) 等のショートハンドを使えるようにする
extension ShapeStyle where Self == Color {
    static var appTheme: Color { Color(red: 0.36, green: 0.60, blue: 0.85) }
}

@Model
class Subscription {
    var id: UUID = UUID()
    var name: String = ""
    var category: String = "other"   // stores CategoryItem.id
    var amount: Double = 0.0
    var billingCycle: BillingCycle = BillingCycle.monthly
    var startDate: Date = Date()
    var weeklyUsageHours: Double = 0.0
    var createdAt: Date = Date()

    init(
        name: String,
        category: String,
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

    /// 登録開始日からの累計支払い額
    var cumulativeAmount: Double {
        let calendar = Calendar.current
        let now = Date()
        if billingCycle == .monthly {
            let months = max(1, (calendar.dateComponents([.month], from: startDate, to: now).month ?? 0) + 1)
            return amount * Double(months)
        } else {
            let years = max(1, (calendar.dateComponents([.year], from: startDate, to: now).year ?? 0) + 1)
            return amount * Double(years)
        }
    }

    /// コスパスコア 0（悪）→ 1（良）: cph が threshold の 0〜200% を 1〜0 に線形マッピング
    func valueScore(threshold: Double) -> Double {
        guard let cph = costPerHour, cph > 0, threshold > 0 else { return 0 }
        return max(0, min(1, 1.0 - (cph / threshold) / 2.0))
    }

    /// コスパステータス（threshold は CategoryStore.costPerHourThreshold）
    func status(threshold: Double) -> SubscriptionStatus {
        guard weeklyUsageHours > 0 else { return .unused }
        guard let cph = costPerHour else { return .unused }
        let pct = (cph / threshold) * 100.0
        if pct > 200 { return .tooExpensive }
        if pct > 100 { return .expensive }
        if pct > 65  { return .overpriced }
        if pct >= 30 { return .fair }
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


enum SubscriptionStatus {
    case unused, tooExpensive, expensive, overpriced, fair, good

    var color: Color {
        switch self {
        case .unused:       return Color(white: 0.55)
        case .tooExpensive: return Color(hue: 0.00, saturation: 0.85, brightness: 0.72)
        case .expensive:    return Color(hue: 0.02, saturation: 0.80, brightness: 0.85)
        case .overpriced:   return Color(hue: 0.07, saturation: 0.90, brightness: 0.82)
        case .fair:         return Color(hue: 0.10, saturation: 0.82, brightness: 0.68)
        case .good:         return Color(hue: 0.36, saturation: 0.70, brightness: 0.58)
        }
    }

    var label: String {
        switch self {
        case .unused:       return String(localized: "status_unused")
        case .tooExpensive: return String(localized: "status_too_expensive")
        case .expensive:    return String(localized: "status_expensive")
        case .overpriced:   return String(localized: "status_overpriced")
        case .fair:         return String(localized: "status_fair")
        case .good:         return String(localized: "status_good")
        }
    }

    /// コスパの悪い順（0が最悪）
    var sortOrder: Int {
        switch self {
        case .tooExpensive: return 0
        case .expensive:    return 1
        case .overpriced:   return 2
        case .fair:         return 3
        case .good:         return 4
        case .unused:       return 5
        }
    }

    /// 割高以上かどうか（ホーム・通知のカウント用）
    var isPoorValue: Bool {
        switch self {
        case .tooExpensive, .expensive, .overpriced: return true
        default: return false
        }
    }
}
