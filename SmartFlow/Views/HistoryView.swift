import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var waterModel: WaterUsageModel
    @State private var selectedTimeframe: TimeFrame = .week
    @State private var showingExportSheet = false
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with timeframe picker
                    VStack(spacing: 15) {
                        HStack {
                            Text("Usage History")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button("Export") {
                                showingExportSheet = true
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        
                        Picker("Timeframe", selection: $selectedTimeframe) {
                            ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                                Text(timeframe.rawValue).tag(timeframe)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.horizontal)
                    
                    // Statistics cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 15) {
                        StatCard(
                            title: "Total Usage",
                            value: String(format: "%.1f", getTotalUsage()),
                            unitEnum: WaterUnit.liters, // Convert from string to WaterUnit enum
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Daily Average",
                            value: String(format: "%.1f", getDailyAverage()),
                            unitEnum: WaterUnit.liters, // Convert from string to WaterUnit enum
                            color: .green
                        )
                        
                        StatCard(
                            title: "Peak Day",
                            value: String(format: "%.1f", getPeakUsage()),
                            unitEnum: WaterUnit.liters, // Convert from string to WaterUnit enum
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Efficiency",
                            value: getEfficiencyPercentage(),
                            unitText: "%",
                            color: getEfficiencyColor()
                        )
                    }
                    .padding(.horizontal)
                    
                    // Chart section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Usage Trends")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // Custom bar chart
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .bottom, spacing: 12) {
                                ForEach(getChartData().indices, id: \.self) { index in
                                    let data = getChartData()[index]
                                    
                                    VStack(spacing: 8) {
                                        // Usage bar
                                        VStack(spacing: 2) {
                                            if data.value > 0 {
                                                // Limit line indicator
                                                if data.value >= waterModel.usageLimit {
                                                    Rectangle()
                                                        .fill(.red.opacity(0.3))
                                                        .frame(width: 40, height: 2)
                                                }
                                                
                                                // Main usage bar
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(LinearGradient(
                                                        colors: [getBarColor(for: data.value), getBarColor(for: data.value).opacity(0.7)],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    ))
                                                    .frame(width: 40, height: getBarHeight(value: data.value))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                                    )
                                            } else {
                                                // No data indicator
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(.gray.opacity(0.2))
                                                    .frame(width: 40, height: 20)
                                            }
                                        }
                                        
                                        // Value label
                                        Text(data.value > 0 ? String(format: "%.1f", data.value) : "-")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        
                                        // Date label
                                        Text(data.label)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.gray.opacity(0.05))
                        )
                        .padding(.horizontal)
                    }
                    
                    // Insights section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Insights")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(getInsights(), id: \.title) { insight in
                                InsightCard(insight: insight)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataView()
                .environmentObject(waterModel)
        }
    }
    
    // MARK: - Helper Functions
    
    private func getChartData() -> [(label: String, value: Double)] {
        switch selectedTimeframe {
        case .week:
            return getWeeklyData()
        case .month:
            return getMonthlyData()
        case .year:
            return getYearlyData()
        }
    }
    
    private func getWeeklyData() -> [(label: String, value: Double)] {
        let calendar = Calendar.current
        let today = Date()
        var data: [(label: String, value: Double)] = []
        
        for i in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "E"
            
            let value = i < waterModel.dailyHistory.count ? waterModel.dailyHistory[waterModel.dailyHistory.count - 1 - i] : 0.0
            data.append((label: dayFormatter.string(from: date), value: value))
        }
        
        return data
    }
    
    private func getMonthlyData() -> [(label: String, value: Double)] {
        // Simulate monthly data - in a real app, this would come from waterModel
        let calendar = Calendar.current
        let today = Date()
        var data: [(label: String, value: Double)] = []
        
        for i in (0..<4).reversed() {
            let date = calendar.date(byAdding: .weekOfYear, value: -i, to: today) ?? today
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            
            // Simulate weekly totals
            let weekTotal = waterModel.dailyHistory.reduce(0, +) * Double.random(in: 0.7...1.3)
            data.append((label: formatter.string(from: date), value: weekTotal))
        }
        
        return data
    }
    
    private func getYearlyData() -> [(label: String, value: Double)] {
        // Simulate yearly data - in a real app, this would come from waterModel
        let calendar = Calendar.current
        let today = Date()
        var data: [(label: String, value: Double)] = []
        
        for i in (0..<12).reversed() {
            let date = calendar.date(byAdding: .month, value: -i, to: today) ?? today
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            
            // Simulate monthly totals
            let monthTotal = waterModel.dailyHistory.reduce(0, +) * 4 * Double.random(in: 0.8...1.2)
            data.append((label: formatter.string(from: date), value: monthTotal))
        }
        
        return data
    }
    
    private func getTotalUsage() -> Double {
        switch selectedTimeframe {
        case .week:
            return waterModel.dailyHistory.reduce(0, +)
        case .month:
            return waterModel.dailyHistory.reduce(0, +) * 4
        case .year:
            return waterModel.dailyHistory.reduce(0, +) * 52
        }
    }
    
    private func getDailyAverage() -> Double {
        let total = getTotalUsage()
        switch selectedTimeframe {
        case .week:
            return total / 7
        case .month:
            return total / 30
        case .year:
            return total / 365
        }
    }
    
    private func getPeakUsage() -> Double {
        return waterModel.dailyHistory.max() ?? 0
    }
    
    private func getEfficiencyPercentage() -> String {
        let average = getDailyAverage()
        let efficiency = max(0, min(100, (1 - (average / waterModel.usageLimit)) * 100))
        return String(format: "%.0f", efficiency)
    }
    
    private func getEfficiencyColor() -> Color {
        let average = getDailyAverage()
        let ratio = average / waterModel.usageLimit
        
        if ratio <= 0.7 {
            return .green
        } else if ratio <= 0.9 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func getBarHeight(value: Double) -> CGFloat {
        let maxValue = max(waterModel.dailyHistory.max() ?? 100, waterModel.usageLimit)
        return max(20, CGFloat(value / maxValue) * 150)
    }
    
    private func getBarColor(for value: Double) -> Color {
        if value >= waterModel.usageLimit {
            return .red
        } else if value >= waterModel.usageLimit * 0.8 {
            return .orange
        } else {
            return .blue
        }
    }
    
    private func getInsights() -> [Insight] {
        var insights: [Insight] = []
        
        let average = getDailyAverage()
        let peak = getPeakUsage()
        
        // Usage trend insight
        if average < waterModel.usageLimit * 0.7 {
            insights.append(Insight(
                title: "Excellent Water Conservation",
                description: "You're using 30% less water than your daily limit. Keep up the great work!",
                icon: "leaf.fill",
                color: .green
            ))
        } else if average > waterModel.usageLimit {
            insights.append(Insight(
                title: "Consider Reducing Usage",
                description: "You're exceeding your daily limit. Try shorter showers or check for leaks.",
                icon: "exclamationmark.triangle.fill",
                color: .red
            ))
        }
        
        // Peak usage insight
        if peak > waterModel.usageLimit * 1.5 {
            insights.append(Insight(
                title: "High Peak Usage Detected",
                description: "Your highest usage day was \(String(format: "%.1f", peak)) \(waterModel.unit). Consider spreading usage more evenly.",
                icon: "chart.line.uptrend.xyaxis",
                color: .orange
            ))
        }
        
        // Connection status insight
        if waterModel.isConnectedToESP32 {
            insights.append(Insight(
                title: "Real-Time Monitoring Active",
                description: "Your ESP32 sensor is connected and providing live water usage data.",
                icon: "wifi",
                color: .blue
            ))
        } else {
            insights.append(Insight(
                title: "Connect Your Flow Sensor",
                description: "Connect your ESP32 water flow sensor for real-time monitoring and more accurate data.",
                icon: "sensor.fill",
                color: .gray
            ))
        }
        
        return insights
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    private let unitText: String
    let color: Color
    
    // Regular initializer with WaterUnit enum - use distinct label 'unitEnum' to avoid ambiguity
    init(title: String, value: String, unitEnum: WaterUnit, color: Color) {
        self.title = title
        self.value = value
        self.unitText = unitEnum.rawValue
        self.color = color
    }
    
    // Overloaded initializer for String units (like "%") - use distinct label 'unitText' for clarity
    init(title: String, value: String, unitText: String, color: Color) {
        self.title = title
        self.value = value
        self.unitText = unitText
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unitText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

struct Insight {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct InsightCard: View {
    let insight: Insight
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: insight.icon)
                .font(.title2)
                .foregroundColor(insight.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

struct ExportDataView: View {
    @EnvironmentObject var waterModel: WaterUsageModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export your water usage data")
                    .font(.headline)
                    .padding()
                
                VStack(spacing: 15) {
                    ExportButton(title: "Export as CSV", icon: "doc.text") {
                        exportAsCSV()
                    }
                    
                    ExportButton(title: "Export as PDF Report", icon: "doc.richtext") {
                        exportAsPDF()
                    }
                    
                    ExportButton(title: "Share Summary", icon: "square.and.arrow.up") {
                        shareData()
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func exportAsCSV() {
        // Implementation for CSV export
    }
    
    private func exportAsPDF() {
        // Implementation for PDF export
    }
    
    private func shareData() {
        // Implementation for sharing
    }
}

struct ExportButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
        .foregroundColor(.primary)
    }
}
