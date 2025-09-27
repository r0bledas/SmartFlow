import SwiftUI

struct UsageView: View {
    @ObservedObject var waterModel: WaterUsageModel
    
    var body: some View {
        VStack {
            // Title
            Text("SmartFlow")
                .font(.headline)
            
            Spacer()
            
            // Water usage progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: min(CGFloat(waterModel.currentUsage / waterModel.usageLimit), 1.0))
                    .stroke(
                        waterModel.currentUsage >= waterModel.usageLimit ? Color.red :
                            waterModel.currentUsage >= waterModel.usageLimit * 0.8 ? Color.orange : Color.blue,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: waterModel.currentUsage)
                    .frame(width: 120, height: 120)
                
                // Usage text
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", waterModel.currentUsage))
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text(waterModel.unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Usage percentage
            let percentage = (waterModel.currentUsage / waterModel.usageLimit) * 100
            Text("\(Int(percentage))% of limit")
                .font(.footnote)
                .foregroundColor(
                    percentage >= 100 ? .red :
                        percentage >= 80 ? .orange : .blue
                )
                .padding(.top, 5)
            
            Spacer()
            
            // Swipe indication
            Text("Swipe for more")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.bottom, 5)
        }
        .padding()
    }
}