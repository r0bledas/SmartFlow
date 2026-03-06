//
//  ShopView.swift
//  SmartFlow
//
//  Created by Raudel Alejandro on 30-10-2025.
//

import SwiftUI

struct ShopView: View {
    @EnvironmentObject var gamification: GamificationManager
    @State private var showingPurchaseAlert = false
    @State private var selectedItem: ShopItem?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Balance Card
                    BalanceCard(droplets: gamification.dropletBalance.total)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Shop Items
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Power-Ups")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(ShopItem.powerUps) { item in
                            ShopItemCard(item: item) {
                                selectedItem = item
                                purchaseItem(item)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Customizations")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(ShopItem.customizations) { item in
                            ShopItemCard(item: item) {
                                selectedItem = item
                                purchaseItem(item)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                    
                    Spacer(minLength: 40)
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Shop")
        }
        .alert(isPresented: $showingPurchaseAlert) {
            if let item = selectedItem, canPurchase(item) {
                return Alert(
                    title: Text("Purchase \(item.name)?"),
                    message: Text("This will cost \(item.cost) droplets."),
                    primaryButton: .default(Text("Buy")) {
                        completePurchase(item)
                    },
                    secondaryButton: .cancel()
                )
            } else {
                return Alert(
                    title: Text("Not Enough Droplets"),
                    message: Text("You need \(selectedItem?.cost ?? 0) droplets but only have \(gamification.dropletBalance.total)."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func purchaseItem(_ item: ShopItem) {
        showingPurchaseAlert = true
    }
    
    private func canPurchase(_ item: ShopItem) -> Bool {
        return gamification.dropletBalance.total >= item.cost
    }
    
    private func completePurchase(_ item: ShopItem) {
        if gamification.dropletBalance.spend(item.cost) {
            gamification.celebrateEvent(message: "🎉 \(item.name) purchased!")
            HapticFeedback.success()
        }
    }
}

// MARK: - Shop Item Model
struct ShopItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let cost: Int
    let category: Category
    let isImplemented: Bool
    
    enum Category {
        case powerUp, customization
    }
    
    static let powerUps: [ShopItem] = [
        ShopItem(name: "Streak Freeze", description: "Protect your streak for one day", icon: "snowflake", cost: 50, category: .powerUp, isImplemented: true),
        ShopItem(name: "Double XP", description: "Earn double XP for 24 hours", icon: "star.fill", cost: 75, category: .powerUp, isImplemented: false),
        ShopItem(name: "Instant Achievement", description: "Unlock a random locked achievement", icon: "gift.fill", cost: 100, category: .powerUp, isImplemented: false),
    ]
    
    static let customizations: [ShopItem] = [
        ShopItem(name: "Rainbow Theme", description: "Colorful app theme", icon: "paintpalette.fill", cost: 150, category: .customization, isImplemented: false),
        ShopItem(name: "Custom Badge", description: "Exclusive profile badge", icon: "shield.fill", cost: 200, category: .customization, isImplemented: false),
        ShopItem(name: "Pro Stats", description: "Advanced analytics", icon: "chart.bar.xaxis", cost: 250, category: .customization, isImplemented: false),
    ]
}

// MARK: - Balance Card
struct BalanceCard: View {
    let droplets: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Balance")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Text("\(droplets)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Image(systemName: "drop.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            Image(systemName: "bag.fill")
                .font(.largeTitle)
                .foregroundColor(.blue.opacity(0.3))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.1), .blue.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

// MARK: - Shop Item Card
struct ShopItemCard: View {
    let item: ShopItem
    let onPurchase: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: item.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: onPurchase) {
                if item.isImplemented {
                    HStack(spacing: 4) {
                        Text("\(item.cost)")
                            .fontWeight(.semibold)
                        Image(systemName: "drop.fill")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
                } else {
                    Text("Coming Soon")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray5))
                        )
                }
            }
            .disabled(!item.isImplemented)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
    }
}

#Preview {
    ShopView()
        .environmentObject(GamificationManager())
}
