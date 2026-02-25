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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Subscription.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // 通知許可をリクエスト
                    NotificationService.shared.requestPermission()

                    // ModelContextを取得して全ての通知をスケジュール
                    let modelContext = sharedModelContainer.mainContext
                    NotificationService.shared.scheduleAllNotifications(modelContext: modelContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
