//
//  ActionsView.swift
//  SmartFlow Watch App
//
//  Created by Raudel Alejandro on 14-08-2025.
//

import SwiftUI

struct ActionsView: View {
    @EnvironmentObject var waterModel: WatchWaterUsageModel
    @State private var showingResetConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Reset Usage Button
                Button(action: {
                    showingResetConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset Usage")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                }
                .confirmationDialog("Reset water usage?", isPresented: $showingResetConfirmation) {
                    Button("Reset", role: .destructive) {
                        waterModel.resetUsage()
                    }
                    Button("Cancel", role: .cancel) { }
                }
                
                // Quick Limit Presets
                Text("Quick Limits")
                    .font(.headline)
                    .padding(.top)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach([50, 100, 150, 200], id: \.self) { limit in
                        Button(action: {
                            waterModel.setQuickLimit(Double(limit))
                        }) {
                            VStack {
                                Text("\(limit)")
                                    .font(.headline)
                                Text(waterModel.unit)
                                    .font(.caption2)
                            }
                            .frame(width: 60, height: 50)
                            .background(waterModel.usageLimit == Double(limit) ? Color.blue : Color.blue.opacity(0.1))
                            .foregroundColor(waterModel.usageLimit == Double(limit) ? .white : .blue)
                            .cornerRadius(8)
                        }
                    }
                }
                
                // Sync Button
                Button(action: {
                    waterModel.requestSync()
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Sync Now")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Actions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ActionsView()
        .environmentObject(WatchWaterUsageModel())
}
