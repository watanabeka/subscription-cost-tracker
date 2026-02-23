//
//  NotificationService.swift
//  subscription-cost-tracker
//
//  Created by Claude Code
//

import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    // 通知許可リクエスト
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in }
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
}
