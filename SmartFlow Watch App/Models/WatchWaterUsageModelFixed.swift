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
        
        // Try to load cached data from UserDefaults
        loadCachedData()
        
        // Request initial sync
        requestSync()
    }
    
    private func setupConnectivityObserver() {
        // Observe connectivity status
        connectivityManager.$isConnected
            .assign(to: \.isConnectedToPhone, on: self)
            .store(in: &cancellables)
        
        connectivityManager.$lastSyncTime
            .assign(to: \.lastSyncTime, on: self)
            .store(in: &cancellables)
        
        // Observe received data
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
        
        // Cache the data locally
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
    
    // Computed properties for UI
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