//
//  NotificationService.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import Foundation
import UserNotifications
import SwiftData

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    // 通知許可リクエスト
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            print("通知許可: \(granted)")
            if let error = error {
                print("通知許可エラー: \(error)")
            }
        }
    }

    // 毎月1日 午前9時にリマインド通知をスケジュール
    func scheduleMonthlyReminder() {
        let center = UNUserNotificationCenter.current()

        // 既存の通知を削除してから再登録
        center.removePendingNotificationRequests(withIdentifiers: ["monthly_reminder"])

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_title")
        content.body = String(localized: "notification_body")
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "monthly_reminder",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // 13時の週次利用状況確認通知をスケジュール（テスト用）
    func scheduleWeeklyUsageCheckNotification() {
        let center = UNUserNotificationCenter.current()

        // 既存の通知を削除
        center.removePendingNotificationRequests(withIdentifiers: ["weekly_usage_check"])

        let content = UNMutableNotificationContent()
        content.title = "サブスク利用チェック"
        content.body = "今週のサブスク利用状況はどうですか？"
        content.sound = .default

        // 毎日13時に通知（本番は週次にする予定）
        var dateComponents = DateComponents()
        dateComponents.hour = 13
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "weekly_usage_check",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("13時通知スケジュールエラー: \(error)")
            }
        }
    }

    // 21時のサブスク更新通知をスケジュール（トータル金額表示）
    func scheduleSubscriptionUpdateNotification(totalAmount: Double, startDate: Date) {
        let center = UNUserNotificationCenter.current()

        // 既存の通知を削除
        center.removePendingNotificationRequests(withIdentifiers: ["subscription_update"])

        let content = UNMutableNotificationContent()
        content.title = "サブスク更新のお知らせ"

        // 開始日からの日数を計算
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0

        // トータル金額をフォーマット
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        let amountString = formatter.string(from: NSNumber(value: totalAmount)) ?? "¥0"

        content.body = "開始から\(days)日経過。累計支出額: \(amountString)"
        content.sound = .default

        // 毎日21時に通知
        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "subscription_update",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("21時通知スケジュールエラー: \(error)")
            }
        }
    }

    // すべての通知をスケジュール
    func scheduleAllNotifications(modelContext: ModelContext) {
        // 13時の通知
        scheduleWeeklyUsageCheckNotification()

        // 21時の通知用にデータを取得
        let descriptor = FetchDescriptor<Subscription>()
        if let subscriptions = try? modelContext.fetch(descriptor) {
            // 最も古い開始日を取得
            let oldestStartDate = subscriptions.map { $0.startDate }.min() ?? Date()

            // トータル金額を計算（開始日からの累計）
            let totalAmount = calculateTotalSpent(subscriptions: subscriptions, from: oldestStartDate)

            scheduleSubscriptionUpdateNotification(totalAmount: totalAmount, startDate: oldestStartDate)
        }
    }

    // 開始日からの累計支出額を計算
    private func calculateTotalSpent(subscriptions: [Subscription], from startDate: Date) -> Double {
        let calendar = Calendar.current
        let now = Date()

        var total: Double = 0.0

        for subscription in subscriptions {
            let subStartDate = max(subscription.startDate, startDate)

            switch subscription.billingCycle {
            case .monthly:
                // 月額サブスクの場合、経過月数 × 料金
                let months = calendar.dateComponents([.month], from: subStartDate, to: now).month ?? 0
                total += Double(max(months, 1)) * subscription.amount

            case .yearly:
                // 年額サブスクの場合、経過年数 × 料金
                let years = calendar.dateComponents([.year], from: subStartDate, to: now).year ?? 0
                total += Double(max(years, 1)) * subscription.amount
            }
        }

        return total
    }
}
