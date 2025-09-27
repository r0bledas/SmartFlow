#!/bin/bash

# Script to fix corrupted Watch app files
# The Watch app files are mixed up with incorrect content

WATCH_APP_DIR="/Users/raudel/Documents/Xcode Projects/SmartFlow/SmartFlow Watch App"

echo "Fixing corrupted Watch app files..."

# Replace WatchConnectivityManager with correct content
cat > "$WATCH_APP_DIR/Connectivity/WatchConnectivityManager.swift" << 'EOF'
//
//  WatchConnectivityManager.swift
//  SmartFlow Watch App
//
//  Created by Raudel Alejandro on 14-08-2025.
//

import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isConnected = false
    @Published var receivedData: [String: Any]?
    @Published var lastSyncTime: Date?
    
    private let session = WCSession.default
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    func requestDataFromPhone() {
        guard session.isReachable else {
            print("Watch: Phone is not reachable")
            return
        }
        
        let message = ["action": "requestData"]
        session.sendMessage(message, replyHandler: { [weak self] reply in
            DispatchQueue.main.async {
                self?.receivedData = reply
                self?.lastSyncTime = Date()
                print("Watch: Received data from phone: \(reply)")
            }
        }) { error in
            print("Watch: Failed to send message: \(error)")
        }
    }
    
    func sendResetRequest() {
        guard session.isReachable else {
            print("Watch: Phone is not reachable for reset")
            return
        }
        
        let message = ["action": "resetCounter"]
        session.sendMessage(message, replyHandler: nil) { error in
            print("Watch: Failed to send reset request: \(error)")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
            print("Watch: Session activation completed with state: \(activationState)")
        }
        
        if let error = error {
            print("Watch: Session activation failed with error: \(error)")
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
            print("Watch: Session reachability changed: \(session.isReachable)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.receivedData = message
            self.lastSyncTime = Date()
            print("Watch: Received message: \(message)")
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.receivedData = applicationContext
            self.lastSyncTime = Date()
            print("Watch: Received application context: \(applicationContext)")
        }
    }
}
EOF

echo "Fixed WatchConnectivityManager"

# Replace WatchWaterUsageModel with correct content
cat > "$WATCH_APP_DIR/Models/WatchWaterUsageModel.swift" << 'EOF'
//
//  WatchWaterUsageModel.swift
//  SmartFlow Watch App
//
//  Created by Raudel Alejandro on 14-08-2025.
//

import Foundation
import SwiftUI
import Combine

class WatchWaterUsageModel: ObservableObject {
    @Published var currentUsage: Double = 0.0
    @Published var usageLimit: Double = 100.0
    @Published var limitPeriodString: String = "daily"
    @Published var unit: String = "L"
    @Published var dailyHistory: [Double] = [0, 0, 0, 0, 0, 0, 0]
    @Published var isConnectedToPhone: Bool = false
    @Published var lastSyncTime: Date?
    
    private let connectivityManager = WatchConnectivityManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupConnectivityObserver()
        loadCachedData()
        requestSync()
    }
    
    private func setupConnectivityObserver() {
        connectivityManager.$isConnected
            .assign(to: \.isConnectedToPhone, on: self)
            .store(in: &cancellables)
        
        connectivityManager.$lastSyncTime
            .assign(to: \.lastSyncTime, on: self)
            .store(in: &cancellables)
        
        connectivityManager.$receivedData
            .compactMap { $0 }
            .sink { [weak self] data in
                self?.processReceivedData(data)
            }
            .store(in: &cancellables)
    }
    
    func requestSync() {
        connectivityManager.requestDataFromPhone()
    }
    
    func resetCounter() {
        connectivityManager.sendResetRequest()
    }
    
    private func processReceivedData(_ data: [String: Any]) {
        if let currentUsage = data["currentUsage"] as? Double {
            self.currentUsage = currentUsage
        }
        
        if let usageLimit = data["usageLimit"] as? Double {
            self.usageLimit = usageLimit
        }
        
        if let limitPeriod = data["limitPeriod"] as? String {
            self.limitPeriodString = limitPeriod
        }
        
        if let unit = data["unit"] as? String {
            self.unit = unit
        }
        
        if let history = data["dailyHistory"] as? [Double] {
            self.dailyHistory = history
        }
        
        cacheData()
    }
    
    private func loadCachedData() {
        let defaults = UserDefaults.standard
        
        currentUsage = defaults.double(forKey: "watch_currentUsage")
        usageLimit = defaults.double(forKey: "watch_usageLimit") != 0 ? defaults.double(forKey: "watch_usageLimit") : 100.0
        limitPeriodString = defaults.string(forKey: "watch_limitPeriod") ?? "daily"
        unit = defaults.string(forKey: "watch_unit") ?? "L"
        
        if let historyData = defaults.array(forKey: "watch_dailyHistory") as? [Double] {
            dailyHistory = historyData
        }
    }
    
    private func cacheData() {
        let defaults = UserDefaults.standard
        
        defaults.set(currentUsage, forKey: "watch_currentUsage")
        defaults.set(usageLimit, forKey: "watch_usageLimit")
        defaults.set(limitPeriodString, forKey: "watch_limitPeriod")
        defaults.set(unit, forKey: "watch_unit")
        defaults.set(dailyHistory, forKey: "watch_dailyHistory")
    }
    
    var percentUsed: Double {
        guard usageLimit > 0 else { return 0 }
        return min(currentUsage / usageLimit, 1.0)
    }
    
    var usageColor: Color {
        let percentage = percentUsed
        if percentage < 0.6 {
            return .blue
        } else if percentage < 0.8 {
            return .orange
        } else {
            return .red
        }
    }
    
    var weeklyTotal: Double {
        return dailyHistory.reduce(0, +)
    }
    
    var dailyAverage: Double {
        let nonZeroDays = dailyHistory.filter { $0 > 0 }.count
        return nonZeroDays > 0 ? weeklyTotal / Double(nonZeroDays) : 0
    }
}
EOF

echo "Fixed WatchWaterUsageModel"

echo "Watch app files have been fixed!"