//
//  SmartFlowApp.swift
//  SmartFlow
//
//  Created by Raudel Alejandro on 14-08-2025.
//

import SwiftUI
import WatchConnectivity

@main
struct SmartFlowApp: App {
    @StateObject private var waterUsageModel = WaterUsageModel()
    let connectivityManager = WatchConnectivityManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(waterUsageModel)
                .onAppear {
                    // Initialize connectivity with Watch
                    connectivityManager.startSession()
                    
                    // Automatically search for ESP32 on app launch
                    if !waterUsageModel.flowMeterConnected {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            waterUsageModel.searchForESP32()
                        }
                    }
                }
                .onOpenURL { url in
                    // Handle URL scheme launches
                    print("App launched with URL: \(url)")
                    
                    // You can parse the URL and take specific actions
                    // Example: smartflow://reset would reset the water usage
                    if url.host == "reset" {
                        waterUsageModel.resetWaterCounter()
                    }
                }
        }
    }
}
