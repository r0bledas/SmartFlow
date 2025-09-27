import SwiftUI

struct HomeView: View {
    @EnvironmentObject var waterModel: WaterUsageModel
    
    var body: some View {
        VStack {
            // Header
            VStack(spacing: 0) {
                Text("SmartFlow")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("beta")
                    .font(.caption)
                    .foregroundColor(.blue.opacity(0.7))
                    .padding(.top, -5)
            }
            .padding(.top, 20)
            
            // Connection status indicator
            HStack {
                Image(systemName: waterModel.flowMeterConnected ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundColor(waterModel.flowMeterConnected ? .green : .red)
                Text(waterModel.connectionStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Spacer()
            
            // Centered Usage Section
            VStack(spacing: 30) {
                // Usage Progress Ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 20)
                    
                    // Progress ring
                    Circle()
                        .trim(from: 0, to: min(CGFloat(waterModel.currentUsage / waterModel.usageLimit), 1.0))
                        .stroke(
                            waterModel.currentUsage >= waterModel.usageLimit ? Color.red :
                                waterModel.currentUsage >= waterModel.usageLimit * 0.8 ? Color.orange : Color.blue,
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut, value: waterModel.currentUsage)
                    
                    // Usage and limit text - Improved layout
                    VStack(spacing: 8) {
                        Text(String(format: "%.1f", waterModel.currentUsage))
                            .font(.system(size: 50, weight: .bold))
                            .minimumScaleFactor(0.7)
                        
                        Text("\(waterModel.unit)")
                            .font(.title3)
                        
                        // More concise limit text
                        HStack(spacing: 4) {
                            Text("Limit:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(waterModel.usageLimit))")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("(\(waterModel.limitPeriod.rawValue))")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    .frame(width: 200) // Constrain width to prevent overflow
                }
                .frame(width: 280, height: 280)
                .padding(.horizontal)
                
                // Usage percentage
                let percentage = (waterModel.currentUsage / waterModel.usageLimit) * 100
                Text("\(Int(percentage))% of \(waterModel.limitPeriod.rawValue) Limit")
                    .font(.title2)
                    .foregroundColor(
                        percentage >= 100 ? .red :
                            percentage >= 80 ? .orange : .blue
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
            
            Spacer()
            
            // Quick actions
            HStack(spacing: 20) {
                Button(action: {
                    waterModel.resetWaterCounter()
                    HapticFeedback.medium()
                }) {
                    VStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title)
                        Text("Reset")
                            .font(.caption)
                    }
                    .frame(width: 80, height: 80)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    waterModel.toggleFlowMeterConnection()
                    HapticFeedback.medium()
                }) {
                    VStack {
                        if waterModel.isSearchingForESP32 {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: waterModel.flowMeterConnected ? "wifi.slash" : "wifi")
                                .font(.title)
                        }
                        Text(waterModel.flowMeterConnected ? "Disconnect" : "Connect")
                            .font(.caption)
                    }
                    .frame(width: 80, height: 80)
                    .background(waterModel.flowMeterConnected ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                    .foregroundColor(waterModel.flowMeterConnected ? .red : .blue)
                    .cornerRadius(10)
                }
                .disabled(waterModel.isSearchingForESP32)
            }
            .padding(.bottom, 30)
        }
        .padding()
    }
}
