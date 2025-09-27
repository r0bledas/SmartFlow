import Foundation
import CoreBluetooth

// Define Bluetooth service and characteristic UUIDs - must match ESP32 code
let smartFlowServiceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
let flowDataCharacteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")

class BluetoothManager: NSObject, ObservableObject {
    // Published properties for SwiftUI binding
    @Published var isScanning = false
    @Published var isConnected = false
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var latestFlowRate: Double = 0.0
    @Published var latestTotalVolume: Double = 0.0
    @Published var errorMessage: String?
    
    // CoreBluetooth objects
    private var centralManager: CBCentralManager!
    private var flowMeterPeripheral: CBPeripheral?
    private var flowDataCharacteristic: CBCharacteristic?
    
    // Callback for when data is received
    var onDataReceived: ((Double, Double) -> Void)?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // Start scanning for SmartFlow devices
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            errorMessage = "Bluetooth is not available"
            return
        }
        
        isScanning = true
        discoveredDevices = []
        // Scan for devices with our service UUID
        centralManager.scanForPeripherals(withServices: [smartFlowServiceUUID], options: nil)
        
        // Timeout after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.stopScanning()
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }
    
    func connectToDevice(_ peripheral: CBPeripheral) {
        stopScanning()
        flowMeterPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnectDevice() {
        if let peripheral = flowMeterPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
        case .poweredOff:
            errorMessage = "Bluetooth is powered off"
            isConnected = false
        case .unsupported:
            errorMessage = "Bluetooth is not supported on this device"
        case .unauthorized:
            errorMessage = "Bluetooth is not authorized"
        case .resetting:
            errorMessage = "Bluetooth is resetting"
        case .unknown:
            errorMessage = "Bluetooth state is unknown"
        @unknown default:
            errorMessage = "Unknown Bluetooth state"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredDevices.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unknown Device")")
        isConnected = true
        
        // Now that we're connected, let's discover the services
        peripheral.delegate = self
        peripheral.discoverServices([smartFlowServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        errorMessage = "Failed to connect: \(error?.localizedDescription ?? "Unknown error")"
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        if let error = error {
            errorMessage = "Disconnected: \(error.localizedDescription)"
        }
        
        // Try to reconnect
        if flowMeterPeripheral == peripheral {
            centralManager.connect(peripheral, options: nil)
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            errorMessage = "Error discovering services: \(error.localizedDescription)"
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            // Discover characteristics for the flow data service
            peripheral.discoverCharacteristics([flowDataCharacteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            errorMessage = "Error discovering characteristics: \(error.localizedDescription)"
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == flowDataCharacteristicUUID {
                flowDataCharacteristic = characteristic
                
                // Subscribe to notifications for this characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                
                // Read initial value
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            errorMessage = "Error reading characteristic: \(error.localizedDescription)"
            return
        }
        
        if characteristic.uuid == flowDataCharacteristicUUID,
           let data = characteristic.value,
           let dataString = String(data: data, encoding: .utf8) {
            
            // Parse the data format: "flowRate,totalVolume"
            let components = dataString.components(separatedBy: ",")
            
            if components.count == 2,
               let flowRate = Double(components[0]),
               let totalVolume = Double(components[1]) {
                
                // Update the published properties
                DispatchQueue.main.async {
                    self.latestFlowRate = flowRate
                    self.latestTotalVolume = totalVolume
                    
                    // Call the callback if set
                    self.onDataReceived?(flowRate, totalVolume)
                }
            }
        }
    }
}