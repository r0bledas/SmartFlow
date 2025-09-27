import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    // Create a singleton instance
    static let shared = WatchConnectivityManager()
    
    // Published property to observe data changes
    @Published var receivedData: [String: Any]?
    
    // WCSession instance
    private var session: WCSession?
    
    // Private initializer for the singleton
    private override init() {
        super.init()
        
        // Check if WatchConnectivity is supported
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - Data Transfer Methods
    
    // Send data to the counterpart device (iPhone to Watch or Watch to iPhone)
    func sendWaterData(currentUsage: Double, usageLimit: Double, limitPeriod: String, unit: String, dailyHistory: [Double]) {
        guard let session = session, session.activationState == .activated else {
            print("Session not active")
            return
        }
        
        let data: [String: Any] = [
            "currentUsage": currentUsage,
            "usageLimit": usageLimit,
            "limitPeriod": limitPeriod,
            "unit": unit,
            "dailyHistory": dailyHistory
        ]
        
        // Check if this is an iOS device and the Watch app is installed
        #if os(iOS)
        guard session.isWatchAppInstalled else {
            print("Watch app is not installed")
            return
        }
        #endif
        
        // Send the data
        session.transferUserInfo(data)
        print("Data sent to counterpart device")
    }
    
    // MARK: - WCSessionDelegate Methods
    
    // Called when session activation is completed
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Session activation failed with error: \(error.localizedDescription)")
            return
        }
        print("Session activated with state: \(activationState.rawValue)")
    }
    
    // Called when user info is received
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        DispatchQueue.main.async {
            self.receivedData = userInfo
            print("Received data from counterpart device")
        }
    }
    
    // Additional required delegate methods for iOS
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("Session deactivated")
        // Reactivate the session (usually after an Apple Watch switching)
        WCSession.default.activate()
    }
    #endif
}
