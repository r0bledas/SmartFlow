//
//  SmartFlowWatchInterface.swift
//  SmartFlowWatchApp Watch App
//
//  Created by Raudel Alejandro on 14-08-2025.
//

import SwiftUI
import WatchKit
import Combine
import WatchConnectivity
import Foundation

// Model for water usage tracking
class WatchWaterUsageModel: ObservableObject {
    @Published var currentUsage: Double = 0.0
    @Published var usageLimit: Double = 100.0
    @Published var limitPeriodString: String = "day"
    @Published var unit: String = "liters"
    @Published var dailyHistory: [Double] = [0, 0, 0, 0, 0, 0, 0]
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSubscribers()
        loadSavedData() // Load saved data on initialization
    }
    
    // Computed properties
    var percentUsed: Double {
        min(currentUsage / max(1, usageLimit), 2.0) // Cap at 200% for UI
    }
    
    var usageColor: Color {
        if percentUsed < 0.8 {
            return .blue
        } else if percentUsed < 1.0 {
            return .orange
        } else {
            return .red
        }
    }
    
    var weeklyTotal: Double {
        dailyHistory.reduce(0, +)
    }
    
    var weeklyAverage: Double {
        weeklyTotal / 7
    }
    
    // Setup subscribers to save data when values change
    private func setupSubscribers() {
        // Watch for changes to each property separately to avoid type conflicts
        $currentUsage.dropFirst()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveData() }
            .store(in: &cancellables)
        
        $usageLimit.dropFirst()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveData() }
            .store(in: &cancellables)
        
        $limitPeriodString.dropFirst()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveData() }
            .store(in: &cancellables)
        
        $unit.dropFirst()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveData() }
            .store(in: &cancellables)
        
        $dailyHistory.dropFirst()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveData() }
            .store(in: &cancellables)
    }
    
    // Load saved data from UserDefaults
    func loadSavedData() {
        // Try shared container first (for sync with iPhone)
        if let sharedDefaults = UserDefaults(suiteName: "group.com.raudel.smartflow") {
            if let usage = sharedDefaults.object(forKey: "currentUsage") as? Double {
                self.currentUsage = usage
            }
            
            if let limit = sharedDefaults.object(forKey: "usageLimit") as? Double {
                self.usageLimit = limit
            }
            
            if let period = sharedDefaults.string(forKey: "limitPeriod") {
                self.limitPeriodString = period
            }
            
            if let unit = sharedDefaults.string(forKey: "unit") {
                self.unit = unit
            }
            
            if let history = sharedDefaults.array(forKey: "dailyHistory") as? [Double] {
                self.dailyHistory = history
            }
        } else {
            // Fallback to standard UserDefaults
            let defaults = UserDefaults.standard
            
            if let usage = defaults.object(forKey: "currentUsage") as? Double {
                self.currentUsage = usage
            }
            
            if let limit = defaults.object(forKey: "usageLimit") as? Double {
                self.usageLimit = limit
            }
            
            if let period = defaults.string(forKey: "limitPeriod") {
                self.limitPeriodString = period
            }
            
            if let unit = defaults.string(forKey: "unit") {
                self.unit = unit
            }
            
            if let history = defaults.array(forKey: "dailyHistory") as? [Double] {
                self.dailyHistory = history
            }
        }
    }
    
    // Save data to UserDefaults
    func saveData() {
        // Save to shared container (for sync with iPhone)
        if let sharedDefaults = UserDefaults(suiteName: "group.com.raudel.smartflow") {
            sharedDefaults.set(currentUsage, forKey: "currentUsage")
            sharedDefaults.set(usageLimit, forKey: "usageLimit")
            sharedDefaults.set(limitPeriodString, forKey: "limitPeriod")
            sharedDefaults.set(unit, forKey: "unit")
            sharedDefaults.set(dailyHistory, forKey: "dailyHistory")
        }
        
        // Also save to standard UserDefaults as backup
        let defaults = UserDefaults.standard
        defaults.set(currentUsage, forKey: "currentUsage")
        defaults.set(usageLimit, forKey: "usageLimit")
        defaults.set(limitPeriodString, forKey: "limitPeriod")
        defaults.set(unit, forKey: "unit")
        defaults.set(dailyHistory, forKey: "dailyHistory")
    }
    
    // Update data received from iPhone
    func updateFromPhoneData(data: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let usage = data["currentUsage"] as? Double {
                self.currentUsage = usage
            }
            
            if let limit = data["usageLimit"] as? Double {
                self.usageLimit = limit
            }
            
            if let period = data["limitPeriod"] as? String {
                self.limitPeriodString = period
            }
            
            if let unit = data["unit"] as? String {
                self.unit = unit
            }
            
            if let history = data["dailyHistory"] as? [Double] {
                self.dailyHistory = history
            }
            
            // Save the data to ensure persistence
            self.saveData()
            
            // Provide haptic feedback to indicate data was received
            WKInterfaceDevice.current().play(.notification)
        }
    }
    
    // Reset water usage for the current day
    func resetUsage() {
        currentUsage = 0.0
        saveData()
        
        // Send reset command to phone
        WatchConnectivityManager.shared.sendMessage(["command": "resetUsage"])
        
        // Provide haptic feedback
        WKInterfaceDevice.current().play(.success)
    }
    
    // Set a new water usage limit
    func setLimit(_ newLimit: Double) {
        usageLimit = newLimit
        saveData()
        
        // Send new limit to phone
        WatchConnectivityManager.shared.sendMessage([
            "command": "setLimit",
            "limit": newLimit,
            "period": limitPeriodString
        ])
        
        // Provide haptic feedback
        WKInterfaceDevice.current().play(.success)
    }
}

// WatchConnectivityManager for handling communication with the iPhone app
class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    @Published var isReachable = false
    private var session: WCSession?
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
        }
    }
    
    func startSession() {
        session?.activate()
    }
    
    func sendMessage(_ message: [String: Any]) {
        guard let session = session, session.isReachable else {
            // Store the message for later delivery if iPhone is not reachable
            if let sharedDefaults = UserDefaults(suiteName: "group.com.raudel.smartflow") {
                if var pendingMessages = sharedDefaults.array(forKey: "pendingMessages") as? [[String: Any]] {
                    pendingMessages.append(message)
                    sharedDefaults.set(pendingMessages, forKey: "pendingMessages")
                } else {
                    sharedDefaults.set([message], forKey: "pendingMessages")
                }
            }
            return
        }
        
        session.sendMessage(message, replyHandler: nil) { error in
            print("Error sending message to iPhone: \(error.localizedDescription)")
        }
    }
    
    // WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
            
            // Try to send any pending messages
            if session.isReachable {
                if let sharedDefaults = UserDefaults(suiteName: "group.com.raudel.smartflow"),
                   let pendingMessages = sharedDefaults.array(forKey: "pendingMessages") as? [[String: Any]] {
                    
                    for message in pendingMessages {
                        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
                    }
                    
                    // Clear pending messages
                    sharedDefaults.removeObject(forKey: "pendingMessages")
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            // Update the water usage model with data from iPhone
            NotificationCenter.default.post(
                name: Notification.Name("ReceivedPhoneData"),
                object: nil,
                userInfo: message
            )
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
        }
    }
    
    // Helper for shared UserDefaults
    static func getSharedUserDefaults() -> UserDefaults? {
        return UserDefaults(suiteName: "group.com.raudel.smartflow")
    }
}
