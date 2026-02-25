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
