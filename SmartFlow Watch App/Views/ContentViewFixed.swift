//
//  ContentView.swift
//  SmartFlow Watch App
//
//  Created by Raudel Alejandro on 14-08-2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var waterModel: WatchWaterUsageModel
    
    var body: some View {
        TabView {
            // Main Usage View
            UsageView()
                .tabItem {
                    Image(systemName: "drop.fill")
                    Text("Usage")
                }
            
            // Quick Actions View
            ActionsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Actions")
                }
            
            // History View
            HistoryView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("History")
                }
        }
        .onAppear {
            // Request data sync when the app appears
            waterModel.requestSync()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchWaterUsageModel())
}