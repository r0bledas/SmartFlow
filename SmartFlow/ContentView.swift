//
//  ContentView.swift
//  SmartFlow
//
//  Created by Raudel Alejandro on 14-08-2025.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("appLanguage") private var appLanguage = Locale.current.language.languageCode?.identifier ?? "en"
    @EnvironmentObject var waterModel: WaterUsageModel
    
    var body: some View {
        ZStack {
            TabView {
                NavigationStack {
                    HomeView()
                }
                .tabItem {
                    Label(L("Home"), systemImage: "drop.fill")
                }
                
                SetLimitView()
                    .tabItem {
                        Label(L("Set Limit"), systemImage: "gauge.badge.plus")
                    }
                
                NavigationStack {
                    HistoryView()
                }
                .tabItem {
                    Label(L("History"), systemImage: "chart.line.uptrend.xyaxis")
                }
                
                NavigationStack {
                    AchievementsView()
                }
                .tabItem {
                    Label(L("Achievements"), systemImage: "trophy.fill")
                }
                
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label(L("Settings"), systemImage: "gear")
                }
            }
            .accentColor(.blue)
            
            if !hasSeenOnboarding {
                Color.black.ignoresSafeArea()
                    .transition(.opacity)
                
                OnboardingView()
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .environment(\.locale, .init(identifier: appLanguage))
    }
}

#Preview {
    ContentView()
}
