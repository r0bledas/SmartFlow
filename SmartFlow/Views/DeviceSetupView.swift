//
//  DeviceSetupView.swift
//  SmartFlow
//
//  Created by Raudel Alejandro on 05-03-2026.
//

import SwiftUI

struct DeviceSetupView: View {
    @EnvironmentObject var waterModel: WaterUsageModel
    @StateObject private var provisioning = WiFiProvisioningManager()
    @Environment(\.dismiss) var dismiss
    
    @State private var wifiSSID = ""
    @State private var wifiPassword = ""
    @State private var showPassword = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                progressBar
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                ScrollView {
                    VStack(spacing: 24) {
                        switch provisioning.state {
                        case .idle:
                            startView
                        case .scanning:
                            scanningView
                        case .deviceFound, .connecting:
                            connectingView
                        case .connected:
                            credentialsView
                        case .sendingCredentials, .waitingForWiFi, .searchingNetwork:
                            provisioningView
                        case .success(let ipAddress):
                            successView(ipAddress: ipAddress)
                        case .failed(let message):
                            failedView(message: message)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle(L("Setup Device"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("Cancel")) {
                        provisioning.reset()
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Bar
    
    private var currentStep: Int {
        switch provisioning.state {
        case .idle: return 0
        case .scanning, .deviceFound, .connecting: return 1
        case .connected: return 2
        case .sendingCredentials, .waitingForWiFi, .searchingNetwork: return 3
        case .success: return 4
        case .failed: return 0
        }
    }
    
    private var stepLabels: [String] { [L("Find"), L("Connect"), L("WiFi"), L("Done")] }
    
    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { index in
                let step = index + 1
                VStack(spacing: 4) {
                    Text(stepLabels[index])
                        .font(.system(size: 10, weight: step == currentStep ? .bold : .regular))
                        .foregroundColor(step <= currentStep ? .blue : .secondary)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(step <= currentStep ? Color.blue : Color(.systemGray4))
                        .frame(height: 4)
                }
            }
        }
    }
    
    // MARK: - Step Views
    
    private var startView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sensor.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text(L("Set Up Your Sensor"))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(L("Make sure your ESP32 is powered on and the LED is blinking. This means it's ready for setup."))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                instructionRow(number: "1", text: L("Power on your ESP32 board"))
                instructionRow(number: "2", text: L("Wait for the LED to start blinking"))
                instructionRow(number: "3", text: L("Keep it within Bluetooth range"))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Button(action: {
                provisioning.startScanning()
            }) {
                Text(L("Start Setup"))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
    
    private var scanningView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 3)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .stroke(Color.blue.opacity(0.4), lineWidth: 2)
                    .frame(width: 90, height: 90)
                    .scaleEffect(1.0)
                
                ProgressView()
                    .scaleEffect(2.0)
            }
            .padding()
            
            Text(L("Searching for Sensor..."))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(L("Looking for your SmartFlow sensor via Bluetooth. Make sure the LED on your ESP32 is blinking."))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(L("Cancel")) {
                provisioning.stopScanning()
            }
            .foregroundColor(.red)
        }
    }
    
    private var connectingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2.0)
                .padding()
            
            Text(L("Connecting..."))
                .font(.title2)
                .fontWeight(.bold)
            
            if let name = provisioning.discoveredDeviceName {
                Text("\(L("Found:")) \(name)")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var credentialsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text(L("Sensor Connected!"))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(L("Now enter your WiFi network details so the sensor can connect to your network."))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("WiFi Network Name"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField(L("Enter WiFi SSID"), text: $wifiSSID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("WiFi Password"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        if showPassword {
                            TextField(L("Enter password"), text: $wifiPassword)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField(L("Enter password"), text: $wifiPassword)
                        }
                        
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(10)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .cornerRadius(6)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Button(action: {
                provisioning.sendWiFiCredentials(ssid: wifiSSID, password: wifiPassword)
            }) {
                Text(L("Connect to WiFi"))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSubmit ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!canSubmit)
        }
    }
    
    private var provisioningView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2.0)
                .padding()
            
            Text(L("Connecting to WiFi..."))
                .font(.title2)
                .fontWeight(.bold)
            
            // Dynamic progress message from the manager
            Text(provisioning.progressMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut, value: provisioning.progressMessage)
            
            if case .searchingNetwork = provisioning.state {
                Text(L("Sensor is joining your network..."))
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                Text(L("Please don't close the app."))
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
    
    private func successView(ipAddress: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text(L("Setup Complete!"))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(L("Your SmartFlow sensor is connected to WiFi and ready to monitor water usage."))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                HStack {
                    Text(L("Network"))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(wifiSSID)
                        .fontWeight(.medium)
                }
                Divider()
                HStack {
                    Text(L("IP Address"))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(ipAddress)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Button(action: {
                // Connect the water model to the ESP32
                waterModel.connectToESP32(ip: ipAddress)
                dismiss()
            }) {
                Text(L("Done"))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
    
    private func failedView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text(L("Setup Failed"))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                provisioning.reset()
                wifiSSID = ""
                wifiPassword = ""
            }) {
                Text(L("Try Again"))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Button(L("Cancel")) {
                provisioning.reset()
                dismiss()
            }
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Helpers
    
    private var canSubmit: Bool {
        !wifiSSID.isEmpty && !wifiPassword.isEmpty
    }
    
    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
        }
    }
}
