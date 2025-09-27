//
//  ContentView.swift
//  SmartFlow
//
//  Created by Raudel Alejandro on 14-08-2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var waterModel: WaterUsageModel
    
    var body: some View {
        TabView {
            NavigationView {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "drop.fill")
            }
            
            SetLimitView()
                .tabItem {
                    Label("Set Limit", systemImage: "gauge.badge.plus")
                }
            
            NavigationView {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "chart.line.uptrend.xyaxis")
            }
            
            // Conditionally show Log tab when enabled
            if waterModel.logViewEnabled {
                LogView()
                    .tabItem {
                        Label("Log", systemImage: "terminal.fill")
                    }
            }
            
            SettingsView()
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
