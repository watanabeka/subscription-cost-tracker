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

    static let frequencyKey = "notificationFrequency"
    private static let notificationId = "subscription_check"

    // 通知許可リクエスト
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    /// サブスク確認通知をスケジュール（頻度と割高アプリ数を渡す）
    func scheduleSubscriptionCheckNotification(frequency: String, poorValueCount: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationId])

        guard frequency != "off" else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_check_title")
        content.body = String(format: String(localized: "notification_check_body"), poorValueCount)
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        if frequency == "weekly" {
            dateComponents.weekday = 2  // 月曜日
        } else {
            dateComponents.day = 1      // 毎月1日
        }

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: Self.notificationId,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Subscription check notification error: \(error)")
            }
        }
    }

    /// ModelContextからサブスク情報を取得して通知をスケジュール
    func scheduleAllNotifications(modelContext: ModelContext) {
        let frequency = UserDefaults.standard.string(forKey: Self.frequencyKey) ?? "monthly"
        guard frequency != "off" else {
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: [Self.notificationId])
            return
        }

        let descriptor = FetchDescriptor<Subscription>()
        let subscriptions = (try? modelContext.fetch(descriptor)) ?? []

        let thresholdRaw = UserDefaults.standard.double(forKey: "costPerHourThreshold")
        let threshold = thresholdRaw > 0 ? thresholdRaw : 1000

        let poorValueCount = subscriptions.filter {
            $0.status(threshold: threshold).isPoorValue
        }.count

        scheduleSubscriptionCheckNotification(frequency: frequency, poorValueCount: poorValueCount)
    }
}
