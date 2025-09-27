//
//  UsageView.swift
//  SmartFlow Watch App
//
//  Created by Raudel Alejandro on 14-08-2025.
//

import SwiftUI

struct UsageView: View {
    @EnvironmentObject var waterModel: WatchWaterUsageModel
    
    var body: some View {
        VStack(spacing: 8) {
            // Header with connection status
            HStack {
                Image(systemName: waterModel.isConnectedToPhone ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundColor(waterModel.isConnectedToPhone ? .green : .red)
                    .font(.caption)
                
                if let lastSync = waterModel.lastSyncTime {
                    Text("Synced \(lastSync, format: .dateTime.hour().minute())")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("No sync")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 4)
            
            // Usage Progress Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 8)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: min(CGFloat(waterModel.percentUsed), 1.0))
                    .stroke(waterModel.usageColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: waterModel.currentUsage)
                
                // Usage text
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", waterModel.currentUsage))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(waterModel.unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 100, height: 100)
            
            // Usage percentage
            let percentage = Int(waterModel.percentUsed * 100)
            Text("\(percentage)% of limit")
                .font(.caption)
                .foregroundColor(waterModel.usageColor)
            
            // Limit info
            Text("Limit: \(Int(waterModel.usageLimit)) \(waterModel.unit)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .navigationTitle("SmartFlow")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            // Tap to refresh data
            waterModel.requestSync()
        }
    }
}

#Preview {
    UsageView()
        .environmentObject(WatchWaterUsageModel())
}