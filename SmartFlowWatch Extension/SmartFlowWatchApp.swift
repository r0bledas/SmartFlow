import SwiftUI
import WatchKit

struct ActionsView: View {
    @ObservedObject var waterModel: WaterUsageModel
    @State private var showLimitSheet = false
    private let connectivity = WaterUsageConnectivity.shared
    
    var body: some View {
        VStack {
            // Title
            Text("Actions")
                .font(.headline)
            
            Spacer()
            
            // Reset button
            Button(action: {
                waterModel.resetUsage()
                WKInterfaceDevice.current().play(.success)
                
                // Send reset command to iPhone
                connectivity.sendWaterData(
                    usageLimit: waterModel.usageLimit,
                    limitPeriod: waterModel.limitPeriod.rawValue,
                    resetUsage: true
                )
            }) {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Set Limit button
            Button(action: {
                showLimitSheet = true
                WKInterfaceDevice.current().play(.click)
            }) {
                Label("Set Limit", systemImage: "slider.horizontal.3")
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showLimitSheet) {
                QuickLimitView(waterModel: waterModel, connectivity: connectivity)
            }
            
            Spacer()
        }
        .padding()
    }
}

// Quick limit view for setting limits on the watch
struct QuickLimitView: View {
    @ObservedObject var waterModel: WaterUsageModel
    let connectivity: WaterUsageConnectivity
    @Environment(\.presentationMode) var presentationMode
    
    let limitOptions = [50, 75, 100, 150, 200]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Set Limit")
                    .font(.headline)
                
                ForEach(limitOptions, id: \.self) { limit in
                    Button(action: {
                        waterModel.setLimit(to: Double(limit), for: .day)
                        WKInterfaceDevice.current().play(.success)
                        
                        // Send new limit to iPhone
                        connectivity.sendWaterData(
                            usageLimit: Double(limit),
                            limitPeriod: LimitPeriod.day.rawValue
                        )
                        
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("\(limit) \(waterModel.unit)")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding(.top)
            }
            .padding()
        }
    }
}
