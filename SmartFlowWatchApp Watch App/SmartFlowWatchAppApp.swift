//
//  SmartFlowWatchAppApp.swift
//  SmartFlowWatchApp Watch App
//
//  Created by Raudel Alejandro on 14-08-2025.
//

import SwiftUI
import WatchConnectivity

@main
struct SmartFlowWatchApp_Watch_AppApp: App {
    // Create the water usage model that will be shared across views
    @StateObject private var waterModel = WatchWaterUsageModel()
    
    // Get the connectivity manager from SmartFlowWatchInterface
    var connectivityManager: WatchConnectivityManager {
        return WatchConnectivityManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(waterModel)
                .onAppear {
                    // Set up Watch-iPhone connectivity
                    connectivityManager.startSession()
                    
                    // Load any saved data
                    waterModel.loadSavedData()
                }
        }
    }
}
