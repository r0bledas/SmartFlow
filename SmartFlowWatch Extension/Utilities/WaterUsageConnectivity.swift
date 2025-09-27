import SwiftUI
import WatchConnectivity

@main
struct SmartFlowWatch: App {
    @StateObject private var waterModel = WaterUsageModel()
    @ObservedObject private var connectivity = WaterUsageConnectivity.shared
    
    init() {
        // Initialize the connectivity when the app starts
        _ = WaterUsageConnectivity.shared
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView(waterModel: waterModel)
            }
            .onReceive(connectivity.$receivedData) { data in
                // Update the model with data received from iPhone
                updateModelFromPhone(data: data)
            }
        }
    }
    
    private func updateModelFromPhone(data: [String: Any]?) {
        guard let data = data else { return }
        
        // Update the water usage model with data from the phone
        if let currentUsage = data["currentUsage"] as? Double {
            waterModel.currentUsage = currentUsage
        }
        
        if let usageLimit = data["usageLimit"] as? Double {
            waterModel.usageLimit = usageLimit
        }
        
        if let periodString = data["limitPeriod"] as? String,
           let period = LimitPeriod(rawValue: periodString) {
            waterModel.limitPeriod = period
        }
        
        if let unit = data["unit"] as? String {
            waterModel.unit = unit
        }
        
        if let history = data["dailyHistory"] as? [Double] {
            waterModel.dailyHistory = history
        }
    }
}
