//
//  WiFiProvisioningManager.swift
//  SmartFlow
//
//  Created by Raudel Alejandro on 05-03-2026.
//

import Foundation
import CoreBluetooth
import SwiftUI
import Network
import UIKit

// MARK: - Provisioning State
enum ProvisioningState: Equatable {
    case idle
    case scanning
    case deviceFound
    case connecting
    case connected
    case sendingCredentials
    case waitingForWiFi
    case searchingNetwork       // NEW: BLE dropped, polling network for ESP32
    case success(ipAddress: String)
    case failed(message: String)
}

// MARK: - BLE UUIDs (must match ESP32 firmware)
private let provisioningServiceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
private let wifiSSIDCharUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a9")
private let wifiPassCharUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26aa")
private let wifiStatusCharUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26ab")

// MARK: - WiFi Provisioning Manager
class WiFiProvisioningManager: NSObject, ObservableObject {
    @Published var state: ProvisioningState = .idle
    @Published var discoveredDeviceName: String?
    @Published var progressMessage: String = ""
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var ssidCharacteristic: CBCharacteristic?
    private var passCharacteristic: CBCharacteristic?
    private var statusCharacteristic: CBCharacteristic?
    
    private var scanTimeoutWork: DispatchWorkItem?
    private var networkPollTimer: Timer?
    private var networkPollAttempts = 0
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Haptic Feedback
    
    private func hapticSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func hapticLight() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func hapticMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // MARK: - Public API
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            state = .failed(message: "Bluetooth is not available. Please enable Bluetooth in Settings.")
            return
        }
        
        state = .scanning
        progressMessage = "Looking for your sensor..."
        peripheral = nil
        ssidCharacteristic = nil
        passCharacteristic = nil
        statusCharacteristic = nil
        
        centralManager.scanForPeripherals(
            withServices: [provisioningServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        
        // Timeout after 15 seconds
        let timeout = DispatchWorkItem { [weak self] in
            guard let self = self, case .scanning = self.state else { return }
            self.centralManager.stopScan()
            self.state = .failed(message: "Could not find SmartFlow sensor. Make sure the ESP32 is powered on and nearby.")
        }
        scanTimeoutWork = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0, execute: timeout)
    }
    
    func stopScanning() {
        scanTimeoutWork?.cancel()
        centralManager.stopScan()
        if case .scanning = state {
            state = .idle
        }
    }
    
    func sendWiFiCredentials(ssid: String, password: String) {
        guard let ssidChar = ssidCharacteristic,
              let passChar = passCharacteristic,
              let peripheral = peripheral else {
            state = .failed(message: "Not connected to device. Please try again.")
            return
        }
        
        state = .sendingCredentials
        progressMessage = "Sending credentials..."
        hapticLight()
        
        // Write SSID
        if let ssidData = ssid.data(using: .utf8) {
            peripheral.writeValue(ssidData, for: ssidChar, type: .withResponse)
        }
        
        // Write password (slight delay to ensure order)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let passData = password.data(using: .utf8) {
                peripheral.writeValue(passData, for: passChar, type: .withResponse)
            }
            self.hapticMedium()
            self.state = .waitingForWiFi
            self.progressMessage = "Credentials sent ✓"
            
            // After a moment, update message
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if case .waitingForWiFi = self.state {
                    self.progressMessage = "Sensor is connecting to WiFi..."
                }
            }
        }
        
        // Timeout for overall connection (30 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) { [weak self] in
            guard let self = self else { return }
            if case .waitingForWiFi = self.state {
                self.state = .failed(message: "WiFi connection timed out. Please check the credentials and try again.")
            } else if case .searchingNetwork = self.state {
                self.stopNetworkPolling()
                self.state = .failed(message: "Could not verify connection. The sensor may have connected — try checking Settings > Connect Device.")
            }
        }
    }
    
    func disconnect() {
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        stopNetworkPolling()
        state = .idle
    }
    
    func reset() {
        stopScanning()
        stopNetworkPolling()
        disconnect()
        state = .idle
        progressMessage = ""
    }
    
    // MARK: - Network Discovery (after BLE drops)
    
    private func startNetworkPolling() {
        networkPollAttempts = 0
        state = .searchingNetwork
        progressMessage = "Verifying connection..."
        
        // Poll every 2 seconds for the ESP32 HTTP endpoint
        networkPollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.pollForESP32()
        }
        // Also poll immediately
        pollForESP32()
    }
    
    private func stopNetworkPolling() {
        networkPollTimer?.invalidate()
        networkPollTimer = nil
    }
    
    private func pollForESP32() {
        networkPollAttempts += 1
        
        // Update progress message with stages
        DispatchQueue.main.async {
            switch self.networkPollAttempts {
            case 1...2:
                self.progressMessage = "Sensor is connecting to WiFi..."
            case 3...4:
                self.progressMessage = "Almost there..."
            default:
                self.progressMessage = "Still searching..."
            }
        }
        
        // Scan common local network range for the ESP32's /flow endpoint
        // We use the mDNS/Bonjour browser or brute-scan local subnet
        scanLocalNetwork()
    }
    
    private func scanLocalNetwork() {
        // Get the device's current IP to determine the subnet
        guard let localIP = getLocalIPAddress() else { return }
        
        let components = localIP.components(separatedBy: ".")
        guard components.count == 4 else { return }
        let subnet = components[0...2].joined(separator: ".")
        
        // Scan a range of IPs on the local subnet
        let dispatchGroup = DispatchGroup()
        var foundIP: String?
        
        for i in 1...254 {
            let ip = "\(subnet).\(i)"
            dispatchGroup.enter()
            
            guard let url = URL(string: "http://\(ip)/flow") else {
                dispatchGroup.leave()
                continue
            }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 1.5
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                defer { dispatchGroup.leave() }
                
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   json["status"] as? String == "connected" {
                    foundIP = ip
                }
            }.resume()
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            if let ip = foundIP {
                self.stopNetworkPolling()
                self.hapticSuccess()
                self.state = .success(ipAddress: ip)
                self.progressMessage = "Connected!"
            }
        }
    }
    
    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                let interface = ptr!.pointee
                let addrFamily = interface.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    if name == "en0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
}

// MARK: - CBCentralManagerDelegate
extension WiFiProvisioningManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            if case .scanning = state {
                state = .failed(message: "Bluetooth was turned off.")
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        scanTimeoutWork?.cancel()
        centralManager.stopScan()
        
        self.peripheral = peripheral
        self.discoveredDeviceName = peripheral.name ?? "SmartFlow Sensor"
        
        hapticLight()
        progressMessage = "Sensor found!"
        state = .deviceFound
        
        // Auto-connect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.state = .connecting
            self.progressMessage = "Connecting to sensor..."
            self.centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        hapticMedium()
        peripheral.delegate = self
        peripheral.discoverServices([provisioningServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        state = .failed(message: "Failed to connect to device: \(error?.localizedDescription ?? "Unknown error")")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // Only report as failure if we weren't expecting a disconnect
        if case .success = state { return }
        if case .idle = state { return }
        if case .searchingNetwork = state { return }
        
        if case .waitingForWiFi = state {
            // ESP32 shuts down BLE before WiFi — this is expected
            // Start polling the network to find the ESP32's new IP
            startNetworkPolling()
            return
        }
        
        if case .sendingCredentials = state {
            // Credentials were being sent, ESP32 is switching to WiFi
            startNetworkPolling()
            return
        }
    }
}

// MARK: - CBPeripheralDelegate
extension WiFiProvisioningManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            state = .failed(message: "No services found on device.")
            return
        }
        
        for service in services {
            peripheral.discoverCharacteristics(
                [wifiSSIDCharUUID, wifiPassCharUUID, wifiStatusCharUUID],
                for: service
            )
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            switch characteristic.uuid {
            case wifiSSIDCharUUID:
                ssidCharacteristic = characteristic
            case wifiPassCharUUID:
                passCharacteristic = characteristic
            case wifiStatusCharUUID:
                statusCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            default:
                break
            }
        }
        
        if ssidCharacteristic != nil && passCharacteristic != nil && statusCharacteristic != nil {
            hapticSuccess()
            progressMessage = "Ready for WiFi setup"
            state = .connected
        } else {
            state = .failed(message: "Device is missing required setup characteristics. It may need a firmware update.")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == wifiStatusCharUUID,
              let data = characteristic.value,
              let statusString = String(data: data, encoding: .utf8) else { return }
        
        let components = statusString.components(separatedBy: ",")
        guard let statusCode = Int(components[0]) else { return }
        
        DispatchQueue.main.async {
            switch statusCode {
            case 1:
                self.state = .waitingForWiFi
                self.progressMessage = "Sensor is connecting to WiFi..."
            case 2:
                let ipAddress = components.count > 1 ? components[1] : "unknown"
                self.hapticSuccess()
                self.state = .success(ipAddress: ipAddress)
                self.progressMessage = "Connected!"
            case 3:
                self.state = .failed(message: "WiFi connection failed. Please check your credentials and try again.")
            default:
                break
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("BLE write error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.state = .failed(message: "Failed to send credentials: \(error.localizedDescription)")
            }
        }
    }
}
