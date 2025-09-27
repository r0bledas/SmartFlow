//
//  ActionsView.swift
//  SmartFlow Watch App
//
//  Created by Raudel Alejandro on 14-08-2025.
//

import SwiftUI
import WatchKit

struct ActionsView: View {
    @EnvironmentObject var waterModel: WatchWaterUsageModel
    @State private var showingLimitSheet = false
    private let connectivityManager = WatchConnectivityManager.shared
    
    // Predefined limit options for quick selection
    private let limitOptions = [50.0, 100.0, 150.0, 200.0]
    
    var body: some View {
        VStack(spacing: 10) {
            // Title
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Reset usage button
            Button(action: {
                // Provide haptic feedback
                WKInterfaceDevice.current().play(.click)
                
                // Tell the iPhone to reset usage
                connectivityManager.resetUsageOnPhone()
            }) {
                Label("Reset Usage", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            
            // Set limit button
            Button(action: {
                // Provide haptic feedback
                WKInterfaceDevice.current().play(.click)
                
                // Show limit sheet
                showingLimitSheet = true
            }) {
                Label("Set Limit", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(.bordered)
            .tint(.green)
            .sheet(isPresented: $showingLimitSheet) {
                // Quick limit selection sheet
                VStack(spacing: 10) {
                    Text("Set Water Limit")
                        .font(.headline)
                    
                    ForEach(limitOptions, id: \.self) { limit in
                        Button("\(Int(limit)) \(waterModel.unit)") {
                            // Set limit locally
                            waterModel.setQuickLimit(limit)
                            
                            // Send to phone
                            connectivityManager.updateLimitOnPhone(
                                limit: limit,
                                period: waterModel.limitPeriodString
                            )
                            
                            // Haptic feedback
                            WKInterfaceDevice.current().play(.success)
                            
                            // Dismiss sheet
                            showingLimitSheet = false
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Button("Cancel") {
                        showingLimitSheet = false
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 5)
    }
}