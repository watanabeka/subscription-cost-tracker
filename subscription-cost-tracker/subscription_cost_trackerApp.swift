//
//  subscription_cost_trackerApp.swift
//  subscription-cost-tracker
//
//  Created by 渡辺海星 on 2026/02/23.
//

import SwiftUI
import SwiftData

@main
struct subscription_cost_trackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NotificationService.shared.requestPermission()
                    NotificationService.shared.scheduleMonthlyReminder()
                }
        }
        .modelContainer(for: Subscription.self)
    }
}
