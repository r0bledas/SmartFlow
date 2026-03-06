import SwiftUI

struct LogView: View {
    @EnvironmentObject var waterModel: WaterUsageModel
    @State private var isAutoScrolling = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with controls
                HStack {
                    Text("ESP32 Log Console")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    HStack(spacing: 15) {
                        // Auto-scroll toggle
                        Button(action: {
                            isAutoScrolling.toggle()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: isAutoScrolling ? "arrow.down.circle.fill" : "arrow.down.circle")
                                    .foregroundColor(isAutoScrolling ? .green : .gray)
                                Text("Auto")
                                    .font(.caption)
                                    .foregroundColor(isAutoScrolling ? .green : .gray)
                            }
                        }
                        
                        // Clear logs button
                        Button(action: {
                            waterModel.clearLogs()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "trash.circle.fill")
                                    .foregroundColor(.red)
                                Text("Clear")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Console background info
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(waterModel.flowMeterConnected ? .green : .red)
                            .frame(width: 8, height: 8)
                        Text(waterModel.flowMeterConnected ? "Connected to \(waterModel.esp32IPAddress)" : "No ESP32 connection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(waterModel.logs.count)/100 entries")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                Divider()
                
                // Console log area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            if waterModel.logs.isEmpty {
                                // Empty state
                                VStack(spacing: 10) {
                                    Image(systemName: "terminal")
                                        .font(.system(size: 40))
                                        .foregroundColor(.green.opacity(0.5))
                                    
                                    Text("Console Ready")
                                        .font(.headline)
                                        .foregroundColor(.green.opacity(0.8))
                                    
                                    Text("ESP32 logs will appear here when connected")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.top, 50)
                            } else {
                                ForEach(Array(waterModel.logs.enumerated()), id: \.offset) { index, log in
                                    HStack(alignment: .top, spacing: 0) {
                                        // Line number
                                        Text("\(String(format: "%03d", index + 1))")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.green.opacity(0.6))
                                            .frame(width: 35, alignment: .trailing)
                                            .padding(.trailing, 8)
                                        
                                        // Log content
                                        Text(log)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.green)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .textSelection(.enabled)
                                    }
                                    .id(index)
                                    .padding(.vertical, 1)
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .background(Color.black)
                    .onChange(of: waterModel.logs.count) { oldValue, newValue in
                        if isAutoScrolling && !waterModel.logs.isEmpty {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(waterModel.logs.count - 1, anchor: .bottom)
                            }
                        }
                    }
                }
                .background(Color.black)
                
                // Footer with connection actions
                if !waterModel.flowMeterConnected {
                    VStack(spacing: 8) {
                        Divider()
                        
                        HStack {
                            Text("Connect to ESP32 to see live logs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                waterModel.searchForESP32()
                            }) {
                                HStack(spacing: 5) {
                                    if waterModel.isSearchingForESP32 {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "wifi")
                                            .font(.caption)
                                    }
                                    Text(waterModel.isSearchingForESP32 ? "Searching..." : "Connect")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .disabled(waterModel.isSearchingForESP32)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
        }
        .onAppear {
            // Add welcome log entry
            if waterModel.logs.isEmpty {
                waterModel.addLog("🚀 SmartFlow ESP32 Console initialized")
                waterModel.addLog("📱 Waiting for ESP32 connection...")
            }
        }
    }
}

#Preview {
    LogView()
        .environmentObject(WaterUsageModel())
}
