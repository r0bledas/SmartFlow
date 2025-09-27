import Foundation
import WatchConnectivity

class WaterUsageConnectivity: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WaterUsageConnectivity()
    
    private var session: WCSession?
    
    @Published var receivedData: [String: Any]?
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // Send water usage data to the counterpart device
    func sendWaterData(currentUsage: Double, usageLimit: Double, limitPeriod: String, unit: String, dailyHistory: [Double]) {
        guard let session = session, session.activationState == .activated else {
            print("WCSession not available or not activated")
            return
        }
        
        let data: [String: Any] = [
            "currentUsage": currentUsage,
            "usageLimit": usageLimit,
            "limitPeriod": limitPeriod,
            "unit": unit,
            "dailyHistory": dailyHistory
        ]
        
        // On iOS, check if the counterpart app is installed
        #if os(iOS)
        guard session.isWatchAppInstalled else {
            print("Watch app is not installed")
            return
        }
        #endif
        
        // Send the data
        session.transferUserInfo(data)
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    // Handle receiving data from the counterpart device
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async {
            self.receivedData = userInfo
        }
    }
    
    // Required delegate methods for iOS
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession did deactivate")
        // Reactivate the session if needed
        WCSession.default.activate()
    }
    #endif
}