import SwiftUI

struct ConnectDeviceView: View {
    @EnvironmentObject var waterModel: WaterUsageModel
    @State private var manualIPAddress = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Connect Flow Meter")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            // Connection status
            HStack {
                Image(systemName: waterModel.flowMeterConnected ? 
                      "checkmark.circle.fill" : "xmark.circle")
                    .foregroundColor(waterModel.flowMeterConnected ? .green : .red)
                VStack(alignment: .leading) {
                    Text(waterModel.flowMeterConnected ? 
                         "Connected to ESP32" : "Not Connected")
                        .fontWeight(.medium)
                    if !waterModel.esp32IPAddress.isEmpty {
                        Text("IP: \(waterModel.esp32IPAddress)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(waterModel.connectionStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(waterModel.flowMeterConnected ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Auto-discovery section
            VStack(spacing: 15) {
                Text("Automatic Discovery")
                    .font(.headline)
                
                Button(action: {
                    waterModel.searchForESP32()
                }) {
                    HStack {
                        if waterModel.isSearchingForESP32 {
                            ProgressView()
                                .scaleEffect(0.8)
                                .padding(.trailing, 5)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                        Text(waterModel.isSearchingForESP32 ? "Searching..." : "Search for ESP32")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(waterModel.isSearchingForESP32)
                
                Text("This will scan your local network for the ESP32 water flow sensor")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.horizontal)
            
            // Manual connection section
            VStack(spacing: 15) {
                Text("Manual Connection")
                    .font(.headline)
                
                TextField("Enter ESP32 IP Address (e.g., 192.168.1.100)", text: $manualIPAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numbersAndPunctuation)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Button(action: {
                    if !manualIPAddress.isEmpty {
                        waterModel.connectToESP32(ip: manualIPAddress)
                    }
                }) {
                    Text("Connect to IP")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(manualIPAddress.isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(manualIPAddress.isEmpty)
            }
            .padding(.horizontal)
            
            // Connected device actions
            if waterModel.flowMeterConnected {
                VStack(spacing: 10) {
                    Divider()
                        .padding(.horizontal)
                    
                    Text("Device Actions")
                        .font(.headline)
                    
                    HStack(spacing: 15) {
                        Button(action: {
                            waterModel.resetESP32Counter()
                        }) {
                            VStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Reset Counter")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            waterModel.toggleFlowMeterConnection()
                        }) {
                            VStack {
                                Image(systemName: "xmark.circle")
                                Text("Disconnect")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Instructions
            VStack(spacing: 10) {
                Text("Setup Instructions:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("1.")
                            .fontWeight(.bold)
                        Text("Upload the provided Arduino code to your ESP32")
                    }
                    HStack {
                        Text("2.")
                            .fontWeight(.bold)
                        Text("Update Wi-Fi credentials in the code")
                    }
                    HStack {
                        Text("3.")
                            .fontWeight(.bold)
                        Text("Connect flow sensor to pin 27")
                    }
                    HStack {
                        Text("4.")
                            .fontWeight(.bold)
                        Text("Ensure ESP32 and phone are on same network")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Connection Status", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}
