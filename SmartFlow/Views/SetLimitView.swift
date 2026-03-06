//
//  SetLimitView.swift
//  SmartFlow
//
//  Created by Raudel Alejandro on 27-09-2025.
//

import SwiftUI

struct SetLimitView: View {
    @EnvironmentObject var waterModel: WaterUsageModel
    @State private var tempLimit: Double = 100.0
    @State private var showingSaveConfirmation = false
    @State private var isEditing = false
    
    // Predefined common water limits
    private let commonLimits: [Double] = [50, 75, 100, 125, 150, 200, 250, 300]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Current Usage vs Limit Visual
                    currentUsageCard
                    
                    // Quick Preset Buttons
                    presetButtonsSection
                    
                    // Custom Limit Slider
                    customLimitSection
                    
                    // Period Selection
                    periodSelectionSection
                    
                    // Unit Selection
                    unitSelectionSection
                    
                    // Advanced Settings
                    advancedSettingsSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .navigationTitle("Water Limit")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLimit()
                    }
                    .disabled(!hasChanges)
                    .foregroundColor(hasChanges ? .blue : .gray)
                }
            }
        }
        .onAppear {
            tempLimit = waterModel.usageLimit
        }
        .alert("Limit Saved", isPresented: $showingSaveConfirmation) {
            Button("OK") {}
        } message: {
            Text("Your new water limit of \(Int(tempLimit))\(waterModel.unit) has been saved.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "drop.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Set Your Daily Water Limit")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Choose a daily water usage target to help manage your consumption effectively.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Current Usage Card
    private var currentUsageCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Usage")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(String(format: "%.1f", waterModel.currentUsage))\(waterModel.unit)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 8)
                        .fill(progressBarColor)
                        .frame(width: min(geometry.size.width * progressPercentage, geometry.size.width), height: 12)
                        .animation(.easeInOut(duration: 0.3), value: progressPercentage)
                }
            }
            .frame(height: 12)
            
            HStack {
                Text("0\(waterModel.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Target: \(Int(tempLimit))\(waterModel.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Usage percentage
            Text("\(Int(progressPercentage * 100))% of target used")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(progressPercentage > 1.0 ? .red : .blue)
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Preset Buttons
    private var presetButtonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Select")
                .font(.headline)
                .fontWeight(.medium)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(commonLimits, id: \.self) { limit in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            tempLimit = limit
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text("\(Int(limit))")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(waterModel.unit)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(minHeight: 50)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(tempLimit == limit ? Color.blue : Color(.systemGray5))
                        )
                        .foregroundColor(tempLimit == limit ? .white : .primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Custom Limit Section
    private var customLimitSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Custom Limit")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(tempLimit))\(waterModel.unit)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Slider(value: $tempLimit, in: 10...500, step: 5) {
                    Text("Water Limit")
                } minimumValueLabel: {
                    Text("10")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("500")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accentColor(.blue)
                
                HStack {
                    Text("Conservative")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Generous")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Period Selection
    private var periodSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Limit Period")
                .font(.headline)
                .fontWeight(.medium)
            
            HStack(spacing: 8) {
                ForEach(LimitPeriod.allCases, id: \.self) { period in
                    Button(action: {
                        waterModel.limitPeriod = period
                    }) {
                        Text(period.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(waterModel.limitPeriod == period ? Color.blue : Color(.systemGray5))
                            )
                            .foregroundColor(waterModel.limitPeriod == period ? .white : .primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Unit Selection
    private var unitSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Measurement Unit")
                .font(.headline)
                .fontWeight(.medium)
            
            HStack(spacing: 12) {
                Button(action: {
                    waterModel.unit = "L"
                    waterModel.useMetricSystem = true
                }) {
                    HStack {
                        Image(systemName: "drop.fill")
                        Text("Liters (L)")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(waterModel.unit == "L" ? Color.blue : Color(.systemGray5))
                    )
                    .foregroundColor(waterModel.unit == "L" ? .white : .primary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    waterModel.unit = "gal"
                    waterModel.useMetricSystem = false
                }) {
                    HStack {
                        Image(systemName: "drop.fill")
                        Text("Gallons (gal)")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(waterModel.unit == "gal" ? Color.blue : Color(.systemGray5))
                    )
                    .foregroundColor(waterModel.unit == "gal" ? .white : .primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Advanced Settings
    private var advancedSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tips & Recommendations")
                .font(.headline)
                .fontWeight(.medium)
            
            VStack(spacing: 12) {
                recommendationRow(
                    icon: "person.fill",
                    title: "Daily Recommended",
                    subtitle: "Adults: 2-3 liters per day",
                    color: .green
                )
                
                recommendationRow(
                    icon: "house.fill",
                    title: "Household Average",
                    subtitle: "Person: 150-300 liters per day",
                    color: .orange
                )
                
                recommendationRow(
                    icon: "leaf.fill",
                    title: "Conservation Goal",
                    subtitle: "Reduce usage by 10-15%",
                    color: .blue
                )
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Views
    private func recommendationRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    private var progressPercentage: Double {
        guard tempLimit > 0 else { return 0 }
        return min(waterModel.currentUsage / tempLimit, 1.5) // Cap at 150% for visual purposes
    }
    
    private var progressBarColor: Color {
        let percentage = waterModel.currentUsage / tempLimit
        if percentage >= 1.0 {
            return .red
        } else if percentage >= 0.8 {
            return .orange
        } else if percentage >= 0.6 {
            return .yellow
        } else {
            return .blue
        }
    }
    
    private var hasChanges: Bool {
        return tempLimit != waterModel.usageLimit
    }
    
    // MARK: - Actions
    private func saveLimit() {
        waterModel.usageLimit = tempLimit
        waterModel.saveData()
        showingSaveConfirmation = true
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

#Preview {
    SetLimitView()
        .environmentObject(WaterUsageModel())
}
