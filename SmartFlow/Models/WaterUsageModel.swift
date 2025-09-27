//
//  WaterUsageModel.swift
//  SmartFlow
//
//  Created by Raudel Alejandro on 14-08-2025.
//

import Foundation
import SwiftUI
import Combine
import UserNotifications
import BackgroundTasks

// MARK: - Main Data Model
class WaterUsageModel: ObservableObject {
    // Core water usage properties
    @Published var currentUsage: Double = 0.0
    @Published var usageLimit: Double = 100.0
    @Published var limitPeriod: LimitPeriod = .daily
    @Published var unit: String = "L"
    
    // Settings
    @Published var useMetricSystem: Bool = true
    
    // Properties for ESP32 connection
    @Published var flowMeterConnected: Bool = false
    @Published var isSearchingForESP32: Bool = false
    @Published var esp32IPAddress: String = ""
    
    // Historical data tracking
    @Published var dailyHistory: [Double] = []
    
    // Settings properties for notifications and watch sync
    @Published var notificationsEnabled: Bool = true
    @Published var notificationThreshold: Double = 0.8
    @Published var watchSyncEnabled: Bool = false
    @Published var logViewEnabled: Bool = false
    
    // Log data for debugging ESP32 communication
    @Published var logs: [String] = []
    
    // Notification throttling properties
    private var lastNotificationTime: Date?
    private var lastNotificationType: NotificationType?
    
    // Simple one-time notification tracking
    private var hasNotifiedThreshold: Bool = false
    private var hasNotifiedExceeded: Bool = false
    
    // Background notification properties
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var backgroundNotificationTimer: Timer?
    
    private enum NotificationType {
        case threshold
        case exceeded
    }
    
    // Last update timestamp for ESP32 data
    @Published var lastUpdateTime: String? = nil
    
    // Computed property for ESP32 connection status
    var isConnectedToESP32: Bool {
        return flowMeterConnected
    }
    
    // Initializer
    init() {
        // Initialize with sample daily history data (last 7 days)
        dailyHistory = [45.2, 52.8, 38.9, 61.3, 49.7, 55.1, 42.6]
        loadData()
        
        // Request notification permissions on first run
        requestNotificationPermissions()
    }

    // Connection status computed property
    var connectionStatus: String {
        if isSearchingForESP32 {
            return "Searching for ESP32..."
        } else if flowMeterConnected {
            return "Connected to ESP32"
        } else {
            return "Disconnected"
        }
    }

    func loadData() {
        // Load saved data from UserDefaults or Core Data
        let defaults = UserDefaults.standard
        currentUsage = defaults.double(forKey: "currentUsage")
        usageLimit = defaults.double(forKey: "usageLimit") != 0 ? defaults.double(forKey: "usageLimit") : 100.0
        unit = defaults.string(forKey: "unit") ?? "L"
        useMetricSystem = defaults.bool(forKey: "useMetricSystem")
        logViewEnabled = defaults.bool(forKey: "logViewEnabled")
        
        if let historyData = defaults.data(forKey: "dailyHistory"),
           let history = try? JSONDecoder().decode([Double].self, from: historyData) {
            dailyHistory = history
        }
    }

    func saveData() {
        // Save data to UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(currentUsage, forKey: "currentUsage")
        defaults.set(usageLimit, forKey: "usageLimit")
        defaults.set(unit, forKey: "unit")
        defaults.set(useMetricSystem, forKey: "useMetricSystem")
        defaults.set(logViewEnabled, forKey: "logViewEnabled")
        
        if let historyData = try? JSONEncoder().encode(dailyHistory) {
            defaults.set(historyData, forKey: "dailyHistory")
        }
    }
    
    func saveDataFromExtension() {
        // Placeholder for saving data from the extension
        print("Saving data from extension...")
        saveData()
    }

    func resetData() {
        // Reset only current usage, keep settings
        currentUsage = 0.0
        saveData()
    }
    
    // Additional methods referenced in HomeView
    func resetWaterCounter() {
        if flowMeterConnected && !esp32IPAddress.isEmpty {
            // If connected to ESP32, reset both ESP32 and local counter
            resetESP32Counter()
        } else {
            // If not connected, just reset local counter
            currentUsage = 0.0
            saveData()
        }
        
        // Reset notification tracking when counter is reset
        lastNotificationTime = nil
        lastNotificationType = nil
        hasNotifiedThreshold = false
        hasNotifiedExceeded = false
        addLog("🔄 Reset notification tracking")
    }
    
    func toggleFlowMeterConnection() {
        if flowMeterConnected {
            // Disconnect from ESP32
            disconnectFromESP32()
        } else {
            // Start searching for ESP32
            searchForESP32()
        }
    }
    
    // Check if usage limits have been exceeded and show notifications
    func checkUsageLimits() {
        guard notificationsEnabled else { return }
        
        let percentage = (currentUsage / usageLimit) * 100
        let userThresholdPercentage = notificationThreshold * 100
        
        // Check threshold notification (80% by default)
        if percentage >= userThresholdPercentage && !hasNotifiedThreshold {
            let title = "Water Usage Alert ⚠️"
            let message = "You've reached \(Int(userThresholdPercentage))% of your daily limit (\(String(format: "%.1f", currentUsage))\(unit) of \(Int(usageLimit))\(unit))"
            
            sendNotification(title: title, message: message)
            hasNotifiedThreshold = true
            addLog("⚠️ Usage threshold reached: \(Int(percentage))% - notification sent")
        }
        
        // Check exceeded notification (100%)
        if percentage >= 100 && !hasNotifiedExceeded {
            let title = "Water Limit Exceeded! 🚨"
            let message = "You've used \(String(format: "%.1f", currentUsage))\(unit) (\(Int(percentage))% of your \(Int(usageLimit))\(unit) limit)"
            
            sendNotification(title: title, message: message)
            hasNotifiedExceeded = true
            addLog("🚨 Usage limit exceeded: \(Int(percentage))% - notification sent")
        }
    }
    
    // Check if we should send a notification (throttling logic)
    private func shouldSendNotification(for type: NotificationType) -> Bool {
        let now = Date()
        
        // If no previous notification, always send
        guard let lastTime = lastNotificationTime,
              let lastType = lastNotificationType else {
            return true
        }
        
        // Different thresholds for different notification types
        let throttleInterval: TimeInterval
        switch type {
        case .threshold:
            throttleInterval = 300 // 5 minutes for threshold notifications
        case .exceeded:
            throttleInterval = 600 // 10 minutes for exceeded notifications
        }
        
        // If it's the same type and within throttle interval, don't send
        if lastType == type && now.timeIntervalSince(lastTime) < throttleInterval {
            return false
        }
        
        // If it's a different type, allow after 1 minute minimum
        if lastType != type && now.timeIntervalSince(lastTime) < 60 {
            return false
        }
        
        return true
    }
    
    // Update notification tracking
    private func updateLastNotification(type: NotificationType) {
        lastNotificationTime = Date()
        lastNotificationType = type
    }
    
    // Sync data to Watch (if applicable)
    func syncToWatch() {
        // Placeholder for Watch connectivity
        print("Syncing data to Watch...")
    }
    
    // ESP32 Connection Methods
    func searchForESP32() {
        isSearchingForESP32 = true
        addLog("Starting ESP32 search on network...")
        
        // First, get the device's current network information to scan intelligently
        let currentNetworkInfo = getCurrentNetworkInfo()
        let smartIPs = generateSmartIPList(from: currentNetworkInfo)
        
        addLog("Device network: \(currentNetworkInfo ?? "Unknown")")
        addLog("Scanning \(smartIPs.count) IP addresses...")
        
        var foundDevice = false
        let group = DispatchGroup()
        
        // Add timeout for the entire search process (reduced to 10 seconds for faster UX)
        let searchTimeout = DispatchWorkItem {
            if !foundDevice {
                DispatchQueue.main.async {
                    self.isSearchingForESP32 = false
                    self.addLog("ESP32 search timed out - no devices found")
                    print("ESP32 search timed out - no devices found")
                }
            }
        }
        
        // Start timeout timer (10 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: searchTimeout)
        
        // Scan IPs in parallel for faster discovery
        let concurrentQueue = DispatchQueue(label: "ESP32Search", attributes: .concurrent)
        
        for ip in smartIPs {
            group.enter()
            concurrentQueue.async {
                self.testESP32Connection(ip: ip) { success in
                    if success && !foundDevice {
                        foundDevice = true
                        searchTimeout.cancel() // Cancel timeout since we found device
                        DispatchQueue.main.async {
                            self.esp32IPAddress = ip
                            self.flowMeterConnected = true
                            self.isSearchingForESP32 = false
                            self.addLog("✅ ESP32 found at IP: \(ip)")
                            self.startDataPolling()
                            print("Found ESP32 at IP: \(ip)")
                        }
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            if !foundDevice {
                searchTimeout.cancel()
                self.isSearchingForESP32 = false
                self.addLog("❌ No ESP32 devices found on network")
                print("No ESP32 devices found on network")
            }
        }
    }
    
    func connectToESP32(ip: String) {
        esp32IPAddress = ip
        isSearchingForESP32 = true
        
        print("Attempting to connect to ESP32 at IP: \(ip)")
        
        testESP32Connection(ip: ip) { success in
            DispatchQueue.main.async {
                self.isSearchingForESP32 = false
                if success {
                    self.flowMeterConnected = true
                    self.startDataPolling()
                    
                    let formatter = DateFormatter()
                    formatter.dateStyle = .short
                    formatter.timeStyle = .short
                    self.lastUpdateTime = formatter.string(from: Date())
                    
                    print("Successfully connected to ESP32 at \(ip)")
                } else {
                    print("Failed to connect to ESP32 at \(ip)")
                }
            }
        }
    }
    
    private func testESP32Connection(ip: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://\(ip)/flow") else {
            completion(false)
            return
        }
        
        // Configure request with short timeout
        var request = URLRequest(url: url)
        request.timeoutInterval = 3.0 // 3 second timeout per request
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data = data {
                
                // Try to parse the JSON to confirm it's our ESP32
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       json["flowRate"] != nil,
                       json["totalMilliLitres"] != nil {
                        completion(true)
                        return
                    }
                } catch {
                    // Not valid JSON or wrong format
                }
            }
            
            completion(false)
        }
        
        task.resume()
    }
    
    private var dataPollingTimer: Timer?
    
    private func startDataPolling() {
        stopDataPolling() // Stop any existing timer
        
        // Poll ESP32 every 2 seconds for new data
        dataPollingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.fetchESP32Data()
        }
        
        // Start background monitoring when we begin polling
        startBackgroundMonitoring()
    }
    
    private func stopDataPolling() {
        dataPollingTimer?.invalidate()
        dataPollingTimer = nil
        
        // Stop background monitoring when we stop polling
        stopBackgroundMonitoring()
    }
    
    private func fetchESP32Data() {
        guard flowMeterConnected, !esp32IPAddress.isEmpty else { return }
        
        guard let url = URL(string: "http://\(esp32IPAddress)/flow") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.addLog("❌ HTTP Error: \(error.localizedDescription)")
                }
                print("Error fetching ESP32 data: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else { 
                DispatchQueue.main.async {
                    self.addLog("❌ No data received from ESP32")
                }
                return 
            }
            
            // Log raw HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                DispatchQueue.main.async {
                    self.addLog("📡 HTTP \(httpResponse.statusCode) from \(self.esp32IPAddress)")
                }
            }
            
            // Log raw JSON response
            if let rawString = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.addLog("📦 Raw ESP32 data: \(rawString)")
                }
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let flowRate = json["flowRate"] as? Double,
                   let totalMilliLitres = json["totalMilliLitres"] as? Int {
                    
                    DispatchQueue.main.async {
                        // Convert from milliliters to liters
                        let totalLitres = Double(totalMilliLitres) / 1000.0
                        
                        // Log parsed data
                        self.addLog("💧 Flow: \(flowRate) L/min, Total: \(totalLitres) L")
                        
                        // Update current usage with total from ESP32
                        self.currentUsage = totalLitres
                        
                        // Update last update time
                        let formatter = DateFormatter()
                        formatter.dateStyle = .short
                        formatter.timeStyle = .short
                        self.lastUpdateTime = formatter.string(from: Date())
                        
                        // Check limits and save data
                        self.checkUsageLimits()
                        self.saveData()
                        
                        print("ESP32 Data - Flow Rate: \(flowRate) L/min, Total: \(totalLitres) L")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.addLog("❌ JSON Parse Error: \(error.localizedDescription)")
                }
                print("Error parsing ESP32 data: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    func resetESP32Counter() {
        guard flowMeterConnected, !esp32IPAddress.isEmpty else { return }
        
        addLog("🔄 Sending reset command to ESP32...")
        print("Resetting ESP32 counter...")
        
        guard let url = URL(string: "http://\(esp32IPAddress)/reset") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.addLog("❌ Reset failed: \(error.localizedDescription)")
                    print("Error resetting ESP32 counter: \(error.localizedDescription)")
                } else {
                    self.addLog("✅ ESP32 reset successful")
                    // Reset local counter as well
                    self.currentUsage = 0.0
                    self.saveData()
                    print("ESP32 counter reset successfully")
                }
            }
        }
        
        task.resume()
    }
    
    // Get current device network information
    private func getCurrentNetworkInfo() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name.contains("wlan") || name.contains("wifi") {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                               &hostname, socklen_t(hostname.count),
                               nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                    break
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return address
    }
    
    // Generate smart IP list based on device's current network
    private func generateSmartIPList(from deviceIP: String?) -> [String] {
        var smartIPs: [String] = []
        
        if let deviceIP = deviceIP {
            let components = deviceIP.split(separator: ".")
            if components.count == 4 {
                let networkBase = "\(components[0]).\(components[1]).\(components[2])"
                
                // Scan the most common device IP ranges in the same subnet first
                let priorityIPs = [
                    "\(networkBase).100", "\(networkBase).101", "\(networkBase).102",
                    "\(networkBase).103", "\(networkBase).104", "\(networkBase).105",
                    "\(networkBase).2", "\(networkBase).3", "\(networkBase).4", "\(networkBase).5"
                ]
                smartIPs.append(contentsOf: priorityIPs)
                
                // Then scan broader range in the same subnet
                for i in 10...50 {
                    smartIPs.append("\(networkBase).\(i)")
                }
            }
        }
        
        // Fallback to common network ranges if device IP detection fails
        let fallbackIPs = [
            // Common router default ranges
            "192.168.1.100", "192.168.1.101", "192.168.1.102", "192.168.1.103",
            "192.168.0.100", "192.168.0.101", "192.168.0.102", "192.168.0.103",
            
            // iPhone/Android hotspot ranges
            "172.20.10.2", "172.20.10.3", "172.20.10.4",
            "10.0.0.100", "10.0.0.101", "10.0.0.102",
            
            // Additional common ranges
            "192.168.4.1", "192.168.4.2", "192.168.4.3", // ESP32 AP mode default
            "10.0.1.100", "10.0.1.101", "10.0.1.102"
        ]
        
        smartIPs.append(contentsOf: fallbackIPs)
        
        // Remove duplicates while preserving order
        var seen = Set<String>()
        return smartIPs.filter { seen.insert($0).inserted }
    }
    
    // Additional methods for SettingsView
    func disconnectFromESP32() {
        stopDataPolling() // Stop polling for data
        flowMeterConnected = false
        isSearchingForESP32 = false
        esp32IPAddress = ""
        lastUpdateTime = nil
        print("Disconnected from ESP32")
    }
    
    func resetAllData() {
        // Reset all usage data
        currentUsage = 0.0
        dailyHistory = []
        
        // Reset settings to defaults
        usageLimit = 100.0
        limitPeriod = .daily
        unit = "L"
        useMetricSystem = true
        
        // Reset notification settings
        notificationsEnabled = true
        notificationThreshold = 0.8
        
        // Reset watch sync
        watchSyncEnabled = false
        
        // Disconnect ESP32
        disconnectFromESP32()
        
        saveData()
        print("All data has been reset")
    }
    
    func sendTestNotification() {
        guard notificationsEnabled else { return }
        
        let thresholdPercentage = Int(notificationThreshold * 100)
        
        // Send actual iOS notification
        sendNotification(
            title: "Test Notification 🧪",
            message: "Your alert threshold is set to \(thresholdPercentage)% of your \(Int(usageLimit))\(unit) daily limit."
        )
        
        // Also add to log
        addLog("🧪 Test notification sent (threshold: \(thresholdPercentage)%)")
        print("Test notification sent: You're using \(thresholdPercentage)% of your daily water limit!")
    }
    
    // Log management methods
    func addLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        
        let logEntry = "[\(timestamp)] \(message)"
        
        DispatchQueue.main.async {
            self.logs.append(logEntry)
            // Keep only last 100 log entries to prevent memory issues
            if self.logs.count > 100 {
                self.logs.removeFirst(self.logs.count - 100)
            }
        }
    }
    
    func clearLogs() {
        logs.removeAll()
    }
    
    // MARK: - Notifications
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permissions granted")
            } else if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
            }
        }
    }
    
    private func sendNotification(title: String, message: String) {
        guard notificationsEnabled else { 
            addLog("🚫 Notifications disabled - skipping notification")
            return 
        }
        
        addLog("🔔 Attempting to send notification: \(title)")
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default
        
        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.addLog("❌ Notification error: \(error.localizedDescription)")
                    print("Error sending notification: \(error.localizedDescription)")
                } else {
                    self.addLog("✅ Notification scheduled successfully: \(title)")
                    print("Notification scheduled successfully: \(title)")
                }
            }
        }
    }
    
    // Legacy background task methods (kept for backward compatibility but now simplified)
    func startBackgroundMonitoring() {
        // Simple background monitoring - notifications are handled by the simple checkUsageLimits() method
        guard notificationsEnabled && flowMeterConnected else { return }
        addLog("🔄 Background monitoring active")
    }
    
    func stopBackgroundMonitoring() {
        // Clean up any scheduled notifications when disconnecting
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        addLog("⏹️ Background monitoring stopped")
    }
}

// MARK: - Enums
enum LimitPeriod: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    
    var id: String { self.rawValue }
}

enum WaterUnit: String, CaseIterable, Identifiable {
    case liters = "Liters"
    case gallons = "Gallons"
    
    var id: String { self.rawValue }
    
    var abbreviation: String {
        switch self {
        case .liters:
            return "L"
        case .gallons:
            return "gal"
        }
    }
}
