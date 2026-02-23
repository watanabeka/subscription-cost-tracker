//
//  ContentView.swift
//  subscription-cost-tracker
//
//  Created by 渡辺海星 on 2026/02/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(String(localized: "home_title"), systemImage: "house")
                }
            CalendarView()
                .tabItem {
                    Label(String(localized: "calendar_title"), systemImage: "calendar")
                }
            AnalyticsView()
                .tabItem {
                    Label(String(localized: "analytics_title"), systemImage: "chart.pie")
                }
        }
        .tint(.indigo)
    }
}
