import SwiftUI

struct HistoryView: View {
    @ObservedObject var waterModel: WaterUsageModel
    
    var body: some View {
        VStack {
            // Title
            Text("History")
                .font(.headline)
            
            Spacer()
            
            // Mini chart for last 7 days
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<7, id: \.self) { index in
                    let value = waterModel.dailyHistory[index]
                    let maxValue = waterModel.dailyHistory.max() ?? 100
                    let height = max(5, CGFloat(value / maxValue) * 60)
                    
                    VStack {
                        // Bar
                        Rectangle()
                            .fill(barColor(for: value))
                            .frame(width: 8, height: height)
                            .cornerRadius(2)
                        
                        // Day label
                        Text(getDayAbbreviation(for: index))
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(height: 80)
            .padding(.horizontal)
            
            // Weekly total
            let weekTotal = waterModel.dailyHistory.reduce(0, +)
            VStack(spacing: 2) {
                Text("Weekly Total")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(Int(weekTotal)) \(waterModel.unit)")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
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
    
    // Helper functions
    private func getDayAbbreviation(for index: Int) -> String {
        let days = ["S", "M", "T", "W", "T", "F", "S"]
        let today = Calendar.current.component(.weekday, from: Date())
        var dayIndex = (today - 1) - (6 - index)
        if dayIndex < 0 {
            dayIndex += 7
        }
        return days[dayIndex % 7]
    }
    
    private func barColor(for value: Double) -> Color {
        if value >= waterModel.usageLimit {
            return .red
        } else if value >= waterModel.usageLimit * 0.8 {
            return .orange
        } else {
            return .blue
        }
    }
}