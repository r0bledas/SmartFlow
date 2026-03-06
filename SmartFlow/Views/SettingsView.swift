//
//  SettingsView.swift
//  SmartFlow
//
//  Created by Raudel Alejandro on 27-09-2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var waterModel: WaterUsageModel
    @State private var showingConnectionSheet = false
    @State private var showingLimitSheet = false
    @State private var showingResetAlert = false
    @State private var showingAbout = false
    @State private var showingExportData = false
    @State private var isConnecting = false
    @State private var connectingDots = ""
    @State private var connectingTimer: Timer?
    @State private var showingManualIP = false
    @State private var manualIP = ""
    @State private var connectionFailed = false
    @State private var testNotificationCountdown = 0
    @State private var testNotificationTimer: Timer?
    @State private var showingDeviceSetup = false
    
    var body: some View {
        NavigationStack {
            List {
                // Flow Sensor Section
                Section(L("Flow Sensor")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("Water Flow Sensor"))
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            if isConnecting {
                                Text("Connecting\(connectingDots)")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            } else if waterModel.flowMeterConnected {
                                Text(L("Connected"))
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            } else if connectionFailed {
                                Text(L("Connection Failed"))
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            } else {
                                Text(L("Disconnected"))
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if waterModel.flowMeterConnected {
                                // Use the correct method to disconnect from ESP32
                                waterModel.flowMeterConnected = false
                                waterModel.esp32IPAddress = ""
                                connectionFailed = false
                            } else {
                                startConnecting()
                            }
                        }) {
                            Text(isConnecting ? L("Connecting") : (waterModel.flowMeterConnected ? L("Disconnect") : L("Connect")))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .frame(minWidth: 130, minHeight: 32)
                                .background(isConnecting ? Color.orange : (waterModel.flowMeterConnected ? Color.red : Color.blue))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isConnecting)
                    }
                    .padding(.vertical, 8)
                    
                    // Manual IP Section - Show when connection failed or user wants manual control
                    if connectionFailed || showingManualIP {
                        VStack(spacing: 12) {
                            HStack {
                                Text(L("Manual Connection"))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            
                            HStack(spacing: 8) {
                                TextField("Enter ESP32 IP (e.g., 192.168.1.100)", text: $manualIP)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numbersAndPunctuation)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                
                                Button(L("Connect")) {
                                    connectToManualIP()
                                }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(6)
                                .disabled(manualIP.isEmpty || isConnecting)
                            }
                            
                            if !showingManualIP {
                                Button(L("Cancel Manual Setup")) {
                                    connectionFailed = false
                                    manualIP = ""
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    } else if !waterModel.flowMeterConnected && !isConnecting {
                        // Show manual IP toggle when disconnected
                        Button(L("Enter IP Manually")) {
                            showingManualIP = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                    }
                    
                    // BLE Setup button — always visible when disconnected
                    if !waterModel.flowMeterConnected {
                        Button(action: {
                            showingDeviceSetup = true
                        }) {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                Text(L("Setup New Device"))
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(Color.green)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 4)
                    }
                }
                
                // Device Information Section
                Section(L("Device Information")) {
                    if waterModel.flowMeterConnected {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Device Status")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("Connected")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text("Device IP")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(waterModel.esp32IPAddress.isEmpty ? "Unknown" : waterModel.esp32IPAddress)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("ESP32 Status")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(waterModel.connectionStatus)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Total Usage Today")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(String(format: "%.1f", waterModel.currentUsage)) \(waterModel.unit)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let lastUpdate = waterModel.lastUpdateTime {
                                HStack {
                                    Text("Last Update")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(lastUpdate)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    } else {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Device Status")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("No device connected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("Disconnected")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Daily Limit Section
                Section(L("Daily Limit")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Limit")
                                .font(.headline)
                                .fontWeight(.medium)
                            Text("\(Int(waterModel.usageLimit))\(waterModel.unit)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingLimitSheet = true
                        }) {
                            Text("Change")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .frame(minWidth: 130, minHeight: 32)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 8)
                }
                
                // Unit Selection Section
                Section(L("Units & Display")) {
                    HStack {
                        Text("Measurement Unit")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Picker("Units", selection: $waterModel.unit) {
                            Text("Liters").tag("L")
                            Text("Gallons").tag("gal")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 140)
                    }
                    .padding(.vertical, 4)
                }
                
                // Notifications Section
                Section(L("Notifications")) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        Text(L("Usage Alerts"))
                        
                        Spacer()
                        
                        Toggle("", isOn: $waterModel.notificationsEnabled)
                            .labelsHidden()
                    }
                    
                    if waterModel.notificationsEnabled {
                        HStack {
                            Image(systemName: "percent")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            
                            Text("Alert at \(Int(waterModel.notificationThreshold * 100))% of limit")
                            
                            Spacer()
                        }
                        
                        VStack {
                            HStack {
                                Text("Alert Threshold")
                                Spacer()
                                Text("\(Int(waterModel.notificationThreshold * 100))%")
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $waterModel.notificationThreshold, in: 0.5...1.0, step: 0.1)
                                .accentColor(.purple)
                        }
                        
                        Button(action: {
                            // Start the test notification with countdown
                            startTestNotificationCountdown()
                        }) {
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(.purple)
                                    .frame(width: 24)
                                
                                Text("Send Test Notification")
                                
                                Spacer()
                                
                                if testNotificationCountdown > 0 {
                                    Text("\(testNotificationCountdown)")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                        .disabled(testNotificationCountdown > 0)
                    }
                }
                
                // Developer Section
                Section("Developer") {
                    NavigationLink(destination: LogView()) {
                        HStack {
                            Image(systemName: "terminal.fill")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Debug Console")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                Text("View ESP32 connection logs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Apple Watch Section
                Section(L("Apple Watch")) {
                    HStack {
                        Image(systemName: "applewatch")
                            .foregroundColor(.black)
                            .frame(width: 24)
                        
                        Text(L("Sync with Apple Watch"))
                        
                        Spacer()
                        
                        Toggle("", isOn: $waterModel.watchSyncEnabled)
                            .labelsHidden()
                    }
                    
                    if waterModel.watchSyncEnabled {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text(L("Auto-sync enabled"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                }
                
                // Developer Options Section
                Section(L("Developer Options")) {
                    Toggle(L("Always Show Onboarding"), isOn: Binding(
                        get: { !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") },
                        set: { UserDefaults.standard.set(!$0, forKey: "hasSeenOnboarding") }
                    ))
                }
            }
            .navigationTitle(L("Settings"))
            .navigationBarTitleDisplayMode(.large)
        }
        .alert(L("Reset All Data"), isPresented: $showingResetAlert) {
            Button(L("Cancel"), role: .cancel) { }
            Button(L("Reset"), role: .destructive) {
                waterModel.resetAllData()
            }
        } message: {
            Text(L("This will permanently delete all your water usage history and reset your settings. This action cannot be undone."))
        }
        .sheet(isPresented: $showingAbout) {
            AboutSettingsView()
        }
        .sheet(isPresented: $showingExportData) {
            ExportDataView()
                .environmentObject(waterModel)
        }
        .sheet(isPresented: $showingLimitSheet) {
            SetLimitView()
        }
        .sheet(isPresented: $showingDeviceSetup) {
            DeviceSetupView()
                .environmentObject(waterModel)
        }
    }
    
    private func startConnecting() {
        isConnecting = true
        connectingDots = ""
        
        // Start the dots animation
        connectingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            switch connectingDots {
            case "":
                connectingDots = "."
            case ".":
                connectingDots = ".."
            case "..":
                connectingDots = "..."
            case "...":
                connectingDots = ""
            default:
                connectingDots = ""
            }
        }
        
        // Start the actual ESP32 search
        waterModel.searchForESP32()
        
        // Monitor connection status
        let connectionMonitor = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if waterModel.flowMeterConnected {
                // Connection successful
                stopConnecting()
                timer.invalidate()
            } else if !waterModel.isSearchingForESP32 && !waterModel.flowMeterConnected {
                // Connection failed/timed out
                connectionFailed = true
                stopConnecting()
                timer.invalidate()
            }
        }
        
        // Failsafe timeout after 15 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            if isConnecting {
                stopConnecting()
                connectionMonitor.invalidate()
            }
        }
    }
    
    private func stopConnecting() {
        isConnecting = false
        connectingDots = ""
        connectingTimer?.invalidate()
        connectingTimer = nil
    }
    
    private func connectToManualIP() {
        guard !manualIP.isEmpty else { return }
        
        isConnecting = true
        connectionFailed = false
        connectingDots = ""
        
        // Start the dots animation
        connectingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            switch connectingDots {
            case "":
                connectingDots = "."
            case ".":
                connectingDots = ".."
            case "..":
                connectingDots = "..."
            case "...":
                connectingDots = ""
            default:
                connectingDots = ""
            }
        }
        
        // Use the actual ESP32 connection method from WaterUsageModel
        waterModel.connectToESP32(ip: manualIP)
        
        // Monitor connection status for manual IP connection
        let connectionMonitor = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if waterModel.flowMeterConnected {
                // Connection successful
                connectionFailed = false
                showingManualIP = false
                manualIP = ""
                stopConnecting()
                timer.invalidate()
            } else if !waterModel.isSearchingForESP32 && !waterModel.flowMeterConnected {
                // Connection failed - IP was invalid or ESP32 not responding
                connectionFailed = true
                stopConnecting()
                timer.invalidate()
            }
        }
        
        // Failsafe timeout for manual connection (10 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if isConnecting && !waterModel.flowMeterConnected {
                connectionFailed = true
                stopConnecting()
                connectionMonitor.invalidate()
            }
        }
    }
    
    private func startTestNotificationCountdown() {
        testNotificationCountdown = 3
        
        testNotificationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            testNotificationCountdown -= 1
            
            if testNotificationCountdown <= 0 {
                timer.invalidate()
                testNotificationTimer = nil
                
                // Send the test notification after countdown completes
                waterModel.sendTestNotification()
            }
        }
    }
}

struct AboutSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    VStack(spacing: 15) {
                        Image(systemName: "drop.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("SmartFlow")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Smart Water Usage Monitoring")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Features")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            SettingsFeatureRow(icon: "sensor.fill", title: "ESP32 Integration", description: "Real-time water flow monitoring")
                            SettingsFeatureRow(icon: "chart.bar.fill", title: "Usage Analytics", description: "Detailed insights and tracking")
                            SettingsFeatureRow(icon: "target", title: "Smart Limits", description: "Set and track daily goals")
                            SettingsFeatureRow(icon: "bell.fill", title: "Smart Alerts", description: "Usage notifications")
                            SettingsFeatureRow(icon: "applewatch", title: "Apple Watch", description: "Monitor from your wrist")
                        }
                        .padding(.horizontal)
                    }
                    
                    VStack(spacing: 10) {
                        Text("Developed with ❤️ for water conservation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer(minLength: 30)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct SensorConnectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var waterModel: WaterUsageModel
    @State private var isConnecting = false
    @State private var connectionProgress: Double = 0.0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Sensor Icon
                Image(systemName: "sensor.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    Text("Connect Water Flow Sensor")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text("Make sure your ESP32 sensor is powered on and within Bluetooth range.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                VStack(spacing: 20) {
                    if isConnecting {
                        VStack(spacing: 16) {
                            ProgressView(value: connectionProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(width: 200)
                            
                            Text("Connecting... \(Int(connectionProgress * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button(action: {
                            connectToSensor()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "bluetooth")
                                Text("Connect Sensor")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 40)
                    }
                }
                
                VStack(spacing: 12) {
                    Text("Connection Tips:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 12) {
                            Text("•")
                                .foregroundColor(.blue)
                                .fontWeight(.bold)
                            Text("Ensure your device has Bluetooth enabled")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Text("•")
                                .foregroundColor(.blue)
                                .fontWeight(.bold)
                            Text("Keep the sensor within 10 meters range")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Text("•")
                                .foregroundColor(.blue)
                                .fontWeight(.bold)
                            Text("Check that the sensor LED is blinking")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Sensor Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isConnecting)
                }
            }
        }
    }
    
    private func connectToSensor() {
        isConnecting = true
        connectionProgress = 0.0
        
        // Simulate connection process with progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            connectionProgress += 0.05
            
            if connectionProgress >= 1.0 {
                timer.invalidate()
                
                // Simulate successful connection
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    waterModel.flowMeterConnected = true
                    isConnecting = false
                    dismiss()
                    
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            }
        }
    }
}

struct SettingsFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

#Preview {
    SettingsView()
        .environmentObject(WaterUsageModel())
}
