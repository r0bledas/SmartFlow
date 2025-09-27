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