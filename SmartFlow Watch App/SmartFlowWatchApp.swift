//
//  SmartFlowWatchApp.swift
//  SmartFlow Watch App
//
//  Created by Raudel Alejandro on 14-08-2025.
//

import SwiftUI
import WatchKit
import WatchConnectivity

@main
struct SmartFlowWatchApp: App {
    @StateObject private var waterModel = WatchWaterUsageModel()
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(waterModel)
                .onReceive(connectivityManager.$receivedData) { data in
                    processPhoneData(data)
                }
        }
    }
    
    // Process data received from the iPhone
    private func processPhoneData(_ data: [String: Any]?) {
        guard let data = data else { return }
        
        // Update the watch's water model based on data from phone
        if let currentUsage = data["currentUsage"] as? Double {
            waterModel.currentUsage = currentUsage
        }
        
        if let usageLimit = data["usageLimit"] as? Double {
            waterModel.usageLimit = usageLimit
        }
        
        if let limitPeriodString = data["limitPeriod"] as? String {
            waterModel.limitPeriodString = limitPeriodString
        }
        
        if let unit = data["unit"] as? String {
            waterModel.unit = unit
        }
        
        if let dailyHistory = data["dailyHistory"] as? [Double] {
            waterModel.dailyHistory = dailyHistory
        }
    }
}