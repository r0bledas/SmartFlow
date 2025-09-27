//
//  ContentView.swift
//  SmartFlowWatchApp Watch App
//
//  Created by Raudel Alejandro on 14-08-2025.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @EnvironmentObject var waterModel: WatchWaterUsageModel
    
    var body: some View {
        TabView {
            // Usage view with water consumption progress ring
            UsageView()
                .environmentObject(waterModel)
                .tag(0)
            
            // History view with 7-day usage chart
            HistoryView()
                .environmentObject(waterModel)
                .tag(1)
            
            // Quick actions view
            ActionsView()
                .environmentObject(waterModel)
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle())
        .onAppear {
            // Force a refresh of the UI
            let _ = waterModel.percentUsed
            
            // Register for notification updates from iPhone
            NotificationCenter.default.addObserver(
                forName: Notification.Name("ReceivedPhoneData"),
                object: nil,
                queue: .main
            ) { notification in
                if let userInfo = notification.userInfo,
                   let stringKeyedDict = userInfo as? [String: Any] {
                    waterModel.updateFromPhoneData(data: stringKeyedDict)
                }
            }
            
            // Provide haptic feedback when the app loads
            WKInterfaceDevice.current().play(.click)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(WatchWaterUsageModel())
    }
}

// MARK: - Usage View
struct UsageView: View {
    @EnvironmentObject var waterModel: WatchWaterUsageModel
    
    var body: some View {
        VStack(spacing: 8) {
            // Title
            Text("Water Usage")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: CGFloat(waterModel.percentUsed))
                    .stroke(waterModel.usageColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: waterModel.percentUsed)
                
                // Usage text
                VStack(spacing: 2) {
                    Text("\(Int(waterModel.currentUsage))")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    Text("Limit: \(Int(waterModel.usageLimit))")
                        .font(.system(size: 12))
                    
                    Text(waterModel.unit)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(5)
            
            // Usage percentage
            Text("\(Int(waterModel.percentUsed * 100))%")
                .font(.system(.body, design: .rounded))
                .foregroundColor(waterModel.usageColor)
                .fontWeight(.bold)
        }
        .padding(.top, 5)
    }
}

// MARK: - History View
struct HistoryView: View {
    @EnvironmentObject var waterModel: WatchWaterUsageModel
    
    // Day abbreviations for compact display on Watch
    private let days = ["M", "T", "W", "T", "F", "S", "S"]
    
    // Maximum value for scaling bars
    private var maxValue: Double {
        return max(waterModel.dailyHistory.max() ?? 1.0, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 5) {
            // Title
            Text("7-Day History")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Bar chart
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<7, id: \.self) { index in
                    VStack {
                        // Bar
                        Rectangle()
                            .fill(barColor(for: waterModel.dailyHistory[index], limit: waterModel.usageLimit))
                            .frame(width: 12, height: CGFloat(min(50, 50 * waterModel.dailyHistory[index] / maxValue)))
                        
                        // Day label
                        Text(days[index])
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 60)
            .padding(.vertical, 5)
            
            // Summary data
            VStack(spacing: 2) {
                Text("Weekly: \(Int(waterModel.weeklyTotal)) \(waterModel.unit)")
                    .font(.system(size: 12))
                
                Text("Avg: \(Int(waterModel.weeklyAverage)) \(waterModel.unit)/day")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 5)
    }
    
    // Color bars based on usage compared to limit
    private func barColor(for value: Double, limit: Double) -> Color {
        let ratio = value / limit
        if ratio < 0.8 {
            return .blue
        } else if ratio < 1.0 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Actions View
struct ActionsView: View {
    @EnvironmentObject var waterModel: WatchWaterUsageModel
    @State private var showingLimitSheet = false
    
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
                
                // Reset usage (demo only)
                waterModel.currentUsage = 0
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
                            // Update limit
                            waterModel.usageLimit = limit
                            
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

#Preview {
    ContentView()
        .environmentObject(WatchWaterUsageModel())
}
