#if !os(watchOS)
import Foundation
import CoreBluetooth
import SwiftUI
import Combine

// Extension of WaterUsageModel to add ESP32 integration functionality
extension WaterUsageModel {
    
    // Call this method in your init() to set up ESP32 integration
    func setupESP32Integration() {
        // Create Bluetooth manager if not already created
        let bluetoothManager = BluetoothManager()
        
        // Set up callback for data received from ESP32
        bluetoothManager.onDataReceived = { [weak self] flowRate, totalVolume in
            guard let self = self else { return }
            
            // Update the currentFlowRate (can be displayed in UI)
            DispatchQueue.main.async {
                // If we're connected to actual hardware
                if self.flowMeterConnected { // property exists in iOS model
                    // Update usage based on flow rate (L/min)
                    // This is a simplified calculation - for a 1-second update interval
                    let minutesFraction = 1.0 / 60.0 // Convert seconds to minutes
                    let volumeIncrement = flowRate * minutesFraction
                    
                    // Add the volume to the current usage
                    self.currentUsage += volumeIncrement
                    
                    // Check if we need to show notifications
                    self.checkUsageLimits()
                    
                    // Save the updated data
                    self.saveDataFromExtension()
                    
                    // Sync to watch if applicable
                    self.syncToWatch()
                }
            }
        }
        
        // Store the bluetooth manager as a property for later use
        objc_setAssociatedObject(self, &BluetoothManagerKey, bluetoothManager, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    // Get the bluetooth manager instance
    var esp32BluetoothManager: BluetoothManager {
        if let manager = objc_getAssociatedObject(self, &BluetoothManagerKey) as? BluetoothManager {
            return manager
        }
        
        // Create new if it doesn't exist
        let manager = BluetoothManager()
        objc_setAssociatedObject(self, &BluetoothManagerKey, manager, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return manager
    }
    
    // Start searching for ESP32 devices
    func startESP32Search() {
        esp32BluetoothManager.startScanning()
    }
    
    // Connect to an ESP32 flow meter device
    func connectToESP32FlowMeter(_ peripheral: CBPeripheral) {
        esp32BluetoothManager.connectToDevice(peripheral)
        
        // Set flow meter as connected when BLE connection succeeds
        esp32BluetoothManager.$isConnected
            .sink { [weak self] connected in
                if connected {
                    self?.flowMeterConnected = true
                    self?.saveDataFromExtension()
                }
            }
            .store(in: &esp32Cancellables)
    }
    
    // Get the current flow rate from ESP32 (in L/min)
    var currentFlowRate: Double {
        return esp32BluetoothManager.latestFlowRate
    }
    
    // Storage for ESP32-specific cancellables
    private var esp32Cancellables: Set<AnyCancellable> {
        get {
            if let cancellables = objc_getAssociatedObject(self, &ESP32CancellablesKey) as? Set<AnyCancellable> {
                return cancellables
            }
            let cancellables = Set<AnyCancellable>()
            objc_setAssociatedObject(self, &ESP32CancellablesKey, cancellables, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return cancellables
        }
        set {
            objc_setAssociatedObject(self, &ESP32CancellablesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// Keys for associated objects
private var BluetoothManagerKey: UInt8 = 0
private var ESP32CancellablesKey: UInt8 = 1
#endif
