//
//  WatchConnectivityManager.swift
//  SmartFlow
//
//  Created by Raudel Alejandro on 14-08-2025.
//

import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var receivedData: [String: Any]?
    private let session = WCSession.default
    
    // Keys for data synchronization - must match on both iOS and watchOS
    enum DataKeys {
        static let currentUsage = "currentUsage"
        static let usageLimit = "usageLimit"
        static let limitPeriod = "limitPeriod"
        static let unit = "unit"
        static let dailyHistory = "dailyHistory"
        static let resetUsage = "resetUsage"
    }
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // Helper for shared UserDefaults
    static func getSharedUserDefaults() -> UserDefaults? {
        return UserDefaults(suiteName: "group.com.raudel.smartflow")
    }
    
    // Method to start the session (called from the app)
    func startSession() {
        // Session is already activated in init(), but keeping this method
        // for explicit control and future enhancements
        if session.activationState != .activated {
            session.activate()
        }
    }
    
    func sendWaterData(currentUsage: Double, usageLimit: Double, limitPeriod: String, unit: String, dailyHistory: [Double]) {
        guard session.activationState == .activated else { return }
        
        let data: [String: Any] = [
            DataKeys.currentUsage: currentUsage,
            DataKeys.usageLimit: usageLimit,
            DataKeys.limitPeriod: limitPeriod,
            DataKeys.unit: unit,
            DataKeys.dailyHistory: dailyHistory
        ]
        
        // Also save to shared UserDefaults for Watch app to access
        // when it launches or if connectivity is poor
        let sharedDefaults = WatchConnectivityManager.getSharedUserDefaults()
        sharedDefaults?.set(currentUsage, forKey: DataKeys.currentUsage)
        sharedDefaults?.set(usageLimit, forKey: DataKeys.usageLimit)
        sharedDefaults?.set(limitPeriod, forKey: DataKeys.limitPeriod)
        sharedDefaults?.set(unit, forKey: DataKeys.unit)
        sharedDefaults?.set(dailyHistory, forKey: DataKeys.dailyHistory)
        
        // Send the data to the Watch
        if session.isReachable {
            session.sendMessage(data, replyHandler: nil) { error in
                print("Error sending data to Watch: \(error.localizedDescription)")
            }
        } else {
            // If Watch is not reachable, update the application context
            // so the data will be available when the Watch app is opened
            do {
                try session.updateApplicationContext(data)
                print("Updated application context for Watch")
            } catch {
                print("Error updating application context: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated successfully: \(activationState.rawValue)")
        }
    }
    
    // Required for iOS
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated")
        session.activate()
    }
    
    // Handle messages from Watch
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("iPhone: Received message from Watch: \(message)")
        
        if let action = message["action"] as? String {
            switch action {
            case "requestData":
                // Send current water usage data to Watch
                let currentData = getCurrentWaterData()
                replyHandler(currentData)
                
            case "resetCounter":
                // Handle reset request from Watch
                NotificationCenter.default.post(name: NSNotification.Name("ResetWaterUsage"), object: nil)
                replyHandler(["status": "reset"])
                
            default:
                replyHandler(["error": "Unknown action"])
            }
        }
    }
    
    private func getCurrentWaterData() -> [String: Any] {
        // Get current data from the app's water usage model
        let defaults = UserDefaults.standard
        
        return [
            DataKeys.currentUsage: defaults.double(forKey: "currentUsage"),
            DataKeys.usageLimit: defaults.double(forKey: "usageLimit") != 0 ? defaults.double(forKey: "usageLimit") : 100.0,
            DataKeys.limitPeriod: defaults.string(forKey: "limitPeriod") ?? "daily",
            DataKeys.unit: defaults.string(forKey: "unit") ?? "L",
            DataKeys.dailyHistory: defaults.array(forKey: "dailyHistory") ?? [0, 0, 0, 0, 0, 0, 0]
        ]
    }
    
    // Receive updated application context
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.receivedData = applicationContext
            
            // Process context updates from Watch
            if let resetUsage = applicationContext[DataKeys.resetUsage] as? Bool, resetUsage {
                NotificationCenter.default.post(name: Notification.Name("ResetWaterUsage"), object: nil)
            }
        }
    }
}
