import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var waterModel: WaterUsageModel
    @EnvironmentObject var gamification: GamificationManager
    @State private var selectedTimeframe: TimeFrame = .week
    @State private var showingExportSheet = false
    @State private var demoMode: Bool = false
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Demo Mode Toggle and Timeframe Picker
                    VStack(spacing: 12) {
                        // Demo Mode Toggle Button
                        HStack {
                            if demoMode {
                                HStack(spacing: 4) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.caption)
                                    Text("Demo Mode Active")
                                        .font(.caption)
                                }
                                .foregroundColor(.purple)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.purple.opacity(0.15))
                                )
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    demoMode.toggle()
                                }
                                HapticFeedback.light()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: demoMode ? "wand.and.stars.inverse" : "wand.and.stars")
                                        .font(.caption)
                                    Text(demoMode ? "Demo" : "Live")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(demoMode ? .white : .purple)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(demoMode ? Color.purple : Color.purple.opacity(0.15))
                                )
                            }
                        }
                        
                        // Timeframe Picker
                        Picker("Timeframe", selection: $selectedTimeframe) {
                            ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                                Text(timeframe.rawValue).tag(timeframe)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                        // Statistics cards with better data
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            StatCard(
                                title: "Total Usage",
                                value: String(format: "%.1f", getTotalUsage()),
                                unit: waterModel.unit,
                                color: .blue,
                                icon: "drop.fill"
                            )
                            
                            StatCard(
                                title: "Daily Average",
                                value: String(format: "%.1f", getDailyAverage()),
                                unit: waterModel.unit,
                                color: .green,
                                icon: "chart.bar.fill"
                            )
                            
                            StatCard(
                                title: "Peak Day",
                                value: String(format: "%.1f", getPeakUsage()),
                                unit: waterModel.unit,
                                color: .orange,
                                icon: "arrow.up.circle.fill"
                            )
                            
                            StatCard(
                                title: "Efficiency",
                                value: getEfficiencyPercentage(),
                                unit: "%",
                                color: getEfficiencyColor(),
                                icon: "leaf.fill"
                            )
                        }
                        .padding(.horizontal)
                    
                        // Chart section with improved design
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Usage Trends")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Legend
                                HStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 8, height: 8)
                                        Text("Normal")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color.orange)
                                            .frame(width: 8, height: 8)
                                        Text("High")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 8, height: 8)
                                        Text("Limit")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Chart Container
                            VStack(spacing: 0) {
                                // Chart area
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(alignment: .bottom, spacing: 16) {
                                        ForEach(getChartData().indices, id: \.self) { index in
                                            let data = getChartData()[index]
                                            
                                            VStack(spacing: 6) {
                                                // Value label on top of bar
                                                Text(data.value > 0 ? String(format: "%.0f", data.value) : "-")
                                                    .font(.caption2)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(data.value > 0 ? .primary : .secondary)
                                                    .frame(height: 14)
                                                
                                                // Bar
                                                ZStack(alignment: .bottom) {
                                                    if data.value > 0 {
                                                        // Main bar with gradient
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(LinearGradient(
                                                                colors: [
                                                                    getBarColor(for: data.value),
                                                                    getBarColor(for: data.value).opacity(0.7)
                                                                ],
                                                                startPoint: .top,
                                                                endPoint: .bottom
                                                            ))
                                                            .frame(width: 44, height: getBarHeight(value: data.value))
                                                            .shadow(color: getBarColor(for: data.value).opacity(0.3), radius: 4, x: 0, y: 2)
                                                        
                                                        // Limit indicator line (only show for weekly view)
                                                        if selectedTimeframe == .week && data.value >= waterModel.usageLimit {
                                                            Rectangle()
                                                                .fill(Color.red)
                                                                .frame(width: 44, height: 2)
                                                                .offset(y: -getBarHeight(value: waterModel.usageLimit) + 1)
                                                        }
                                                    } else {
                                                        // Empty state
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(Color.gray.opacity(0.15))
                                                            .frame(width: 44, height: 30)
                                                    }
                                                }
                                                
                                                // Date label
                                                Text(data.label)
                                                    .font(.caption2)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                                    .frame(width: 44)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                }
                                .frame(height: 240)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                            .padding(.horizontal)
                        }
                    
                        // Insights section with better styling
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Insights & Tips")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 10) {
                                ForEach(getInsights(), id: \.title) { insight in
                                    InsightCard(insight: insight)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Export button at bottom
                        Button(action: {
                            showingExportSheet = true
                            HapticFeedback.light()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.body)
                                Text("Export Usage Data")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 20)
                }
            }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
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
        
        if demoMode {
            // Demo mode with realistic water usage patterns
            let demoData = [65.5, 72.3, 58.9, 81.2, 69.7, 75.4, 62.8]
            for i in (0..<7).reversed() {
                let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = "E"
                data.append((label: dayFormatter.string(from: date), value: demoData[6 - i]))
            }
        } else {
            // Real data from waterModel
            for i in (0..<7).reversed() {
                let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = "E"
                
                // Get value from history if available, otherwise 0
                let historyIndex = waterModel.dailyHistory.count - 7 + (6 - i)
                let value = (historyIndex >= 0 && historyIndex < waterModel.dailyHistory.count)
                    ? waterModel.dailyHistory[historyIndex]
                    : 0.0
                
                data.append((label: dayFormatter.string(from: date), value: value))
            }
        }
        
        return data
    }
    
    private func getMonthlyData() -> [(label: String, value: Double)] {
        let calendar = Calendar.current
        let today = Date()
        var data: [(label: String, value: Double)] = []
        
        if demoMode {
            // Demo mode with realistic weekly totals
            let demoWeeklyData = [480.5, 495.8, 467.2, 502.3]
            for i in (0..<4).reversed() {
                let date = calendar.date(byAdding: .weekOfYear, value: -i, to: today) ?? today
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                data.append((label: formatter.string(from: date), value: demoWeeklyData[3 - i]))
            }
        } else {
            // Calculate weekly totals from daily history
            for i in (0..<4).reversed() {
                let date = calendar.date(byAdding: .weekOfYear, value: -i, to: today) ?? today
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                
                // Approximate weekly total (rough calculation)
                let weekTotal = waterModel.dailyHistory.isEmpty ? 0.0 : waterModel.dailyHistory.reduce(0, +) / 7.0 * 7.0
                data.append((label: formatter.string(from: date), value: weekTotal > 0 ? weekTotal : 0))
            }
        }
        
        return data
    }
    
    private func getYearlyData() -> [(label: String, value: Double)] {
        let calendar = Calendar.current
        let today = Date()
        var data: [(label: String, value: Double)] = []
        
        if demoMode {
            // Demo mode with realistic seasonal variations
            let demoMonthlyData = [1820.5, 1765.3, 1890.2, 2015.8, 2180.5, 2250.3,
                                   2310.7, 2295.4, 2140.6, 1995.8, 1850.3, 1920.5]
            for i in (0..<12).reversed() {
                let date = calendar.date(byAdding: .month, value: -i, to: today) ?? today
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                data.append((label: formatter.string(from: date), value: demoMonthlyData[11 - i]))
            }
        } else {
            // Calculate monthly totals from daily history (approximate)
            for i in (0..<12).reversed() {
                let date = calendar.date(byAdding: .month, value: -i, to: today) ?? today
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                
                // Approximate monthly total
                let monthTotal = waterModel.dailyHistory.isEmpty ? 0.0 : waterModel.dailyHistory.reduce(0, +) / 7.0 * 30.0
                data.append((label: formatter.string(from: date), value: monthTotal > 0 ? monthTotal : 0))
            }
        }
        
        return data
    }
    
    private func getTotalUsage() -> Double {
        if demoMode {
            switch selectedTimeframe {
            case .week:
                return 485.8
            case .month:
                return 1945.8
            case .year:
                return 24435.0
            }
        }
        
        let chartData = getChartData()
        return chartData.reduce(0) { $0 + $1.value }
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
        if demoMode {
            return 81.2
        }
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
        // Get the max value from current chart data for proper scaling
        let chartData = getChartData()
        let maxValueInChart = chartData.map { $0.value }.max() ?? 100
        
        // Use the chart's max value for scaling, with a minimum height for visibility
        let scaledHeight = CGFloat(value / maxValueInChart) * 150
        return max(20, scaledHeight)
    }
    
    private func getBarColor(for value: Double) -> Color {
        // Calculate appropriate threshold based on timeframe
        let threshold: Double
        switch selectedTimeframe {
        case .week:
            threshold = waterModel.usageLimit // Daily limit
        case .month:
            threshold = waterModel.usageLimit * 7 // Weekly limit
        case .year:
            threshold = waterModel.usageLimit * 30 // Monthly limit (approximate)
        }
        
        if value >= threshold {
            return .red
        } else if value >= threshold * 0.8 {
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
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                    )
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(unit)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
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
        HStack(spacing: 14) {
            // Icon with colored background
            ZStack {
                Circle()
                    .fill(insight.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: insight.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(insight.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
            }
            
            Spacer(minLength: 8)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
    }
}

struct ExportDataView: View {
    @EnvironmentObject var waterModel: WaterUsageModel
    @Environment(\.dismiss) var dismiss
    @State private var showingShareSheet = false
    @State private var exportType: ExportType?
    
    enum ExportType {
        case csv, pdf, share
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header with icon
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 36))
                                .foregroundColor(.blue)
                        }
                        
                        Text("Export Usage Data")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Choose how you'd like to export your water usage history")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Export options
                    VStack(spacing: 12) {
                        ExportButton(title: "Export as CSV", icon: "doc.text.fill") {
                            exportAsCSV()
                        }
                        
                        ExportButton(title: "Export as PDF Report", icon: "doc.richtext.fill") {
                            exportAsPDF()
                        }
                        
                        ExportButton(title: "Share Text Summary", icon: "text.bubble.fill") {
                            shareData()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Info card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("What's Included")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        
                        Text("• Last 7 days of usage data\n• Daily averages and totals\n• Peak usage information\n• Current settings and limits")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 28)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.systemBackground))
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
    
    private func exportAsCSV() {
        print("CSV export not yet implemented")
        // TODO: Implement CSV export functionality
        HapticFeedback.light()
    }
    
    private func exportAsPDF() {
        print("PDF export not yet implemented")
        // TODO: Implement PDF export functionality
        HapticFeedback.light()
    }
    
    private func shareData() {
        let summary = generateShareText()
        let activityVC = UIActivityViewController(activityItems: [summary], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        
        HapticFeedback.light()
    }
    
    private func generateShareText() -> String {
        let total = waterModel.dailyHistory.reduce(0, +)
        let average = total / Double(max(waterModel.dailyHistory.count, 1))
        let peak = waterModel.dailyHistory.max() ?? 0
        
        return """
        SmartFlow Water Usage Report 💧
        
        Period: Last 7 Days
        Total Usage: \(String(format: "%.1f", total)) \(waterModel.unit)
        Daily Average: \(String(format: "%.1f", average)) \(waterModel.unit)
        Peak Day: \(String(format: "%.1f", peak)) \(waterModel.unit)
        Daily Limit: \(Int(waterModel.usageLimit)) \(waterModel.unit)
        
        Generated by SmartFlow - Smart Water Monitoring
        """
    }
}

struct ExportButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.blue)
                    .frame(width: 28)
                
                Text(title)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            )
        }
    }
}
