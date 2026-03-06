//
//  SmartFlowApp.swift
//  SmartFlow
//
//  Created by Raudel Alejandro on 14-08-2025.
//

import SwiftUI
import WatchConnectivity
import GoogleMobileAds
import AppTrackingTransparency

@main
struct SmartFlowApp: App {
    @StateObject private var waterUsageModel = WaterUsageModel()
    @StateObject private var gamificationManager = GamificationManager()
    let connectivityManager = WatchConnectivityManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(waterUsageModel)
                .environmentObject(gamificationManager)
                .onAppear {
                    // Initialize Google Mobile Ads SDK immediately
                    MobileAds.shared.start()
                    
                    // Request ATT authorization after a short delay (best practice)
                    // The SDK automatically respects the user's tracking choice
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        ATTrackingManager.requestTrackingAuthorization { status in
                            print("ATT status: \(status.rawValue)")
                        }
                    }
                    
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
