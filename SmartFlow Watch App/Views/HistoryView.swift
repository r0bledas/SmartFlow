//
//  SmartFlowWatchApp.swift
//  SmartFlow Watch App
//
//  Created by Raudel Alejandro on 14-08-2025.
//

import SwiftUI
import WatchConnectivity

@main
struct SmartFlowWatchApp: App {
    @StateObject private var waterModel = WatchWaterUsageModel()
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(waterModel)
                .onReceive(connectivityManager.$receivedData) { data in
                    if let data = data {
                        waterModel.updateFromPhoneData(data)
                    }
                }
        }
    }
}

// Extension to add updateFromPhoneData method to WatchWaterUsageModel
extension WatchWaterUsageModel {
    func updateFromPhoneData(_ data: [String: Any]) {
        // Handle reset command from phone
        if data[WatchConnectivityManager.DataKeys.resetUsage] as? Bool == true {
            currentUsage = 0.0
            return
        }
        
        // Update model with data from phone
        if let usage = data[WatchConnectivityManager.DataKeys.currentUsage] as? Double {
            currentUsage = usage
        }
        
        if let limit = data[WatchConnectivityManager.DataKeys.usageLimit] as? Double {
            usageLimit = limit
        }
        
        if let period = data[WatchConnectivityManager.DataKeys.limitPeriod] as? String {
            limitPeriodString = period
        }
        
        if let unit = data[WatchConnectivityManager.DataKeys.unit] as? String {
            self.unit = unit
        }
        
        if let history = data[WatchConnectivityManager.DataKeys.dailyHistory] as? [Double] {
            dailyHistory = history
        }
        
        lastSyncTime = Date()
        isConnectedToPhone = true
    }
}
