//
//  AchievementsView.swift
//  SmartFlow
//
//  Created by Raudel Alejandro on 30-10-2025.
//

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var gamification: GamificationManager
    @State private var selectedCategory: AchievementCategory?
    @State private var showingShop = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // User Level Card
                    UserLevelCard(level: gamification.userLevel, droplets: gamification.dropletBalance.total)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Streak Card
                    StreakCard(streakData: gamification.streakData)
                        .padding(.horizontal)
                    
                    // Daily Challenge Card
                    if let challenge = gamification.dailyChallenge {
                        DailyChallengeCard(challenge: challenge)
                            .padding(.horizontal)
                    }
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryFilterButton(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )
                            
                            ForEach(AchievementCategory.allCases, id: \.self) { category in
                                CategoryFilterButton(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Achievements Grid
                    let filteredAchievements = selectedCategory == nil ? 
                        gamification.achievements : 
                        gamification.achievements.filter { $0.category == selectedCategory }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredAchievements) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Achievements")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingShop = true
                        HapticFeedback.light()
                    }) {
                        Image(systemName: "bag.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .sheet(isPresented: $showingShop) {
                ShopView()
                    .environmentObject(gamification)
            }
        }
        .overlay(
            CelebrationOverlay(
                isShowing: $gamification.showCelebration,
                message: gamification.celebrationMessage,
                achievements: gamification.recentUnlocks
            )
        )
    }
}

// MARK: - User Level Card
struct UserLevelCard: View {
    let level: UserLevel
    let droplets: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(level.level)")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\(level.xp) / \(level.xpToNextLevel) XP")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(droplets)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Image(systemName: "drop.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * level.progress)
                }
            }
            .frame(height: 12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Streak Card
struct StreakCard: View {
    let streakData: StreakData
    
    var body: some View {
        HStack(spacing: 20) {
            // Current Streak
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                    
                    Text("\(streakData.currentStreak)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                Text("Day Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
            
            // Longest Streak
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundColor(.yellow)
                    
                    Text("\(streakData.longestStreak)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Text("Best Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            if streakData.streakFreezeAvailable {
                Divider()
                
                VStack(spacing: 8) {
                    Image(systemName: "snowflake")
                        .font(.title2)
                        .foregroundColor(.cyan)
                    
                    Text("Freeze")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Daily Challenge Card
struct DailyChallengeCard: View {
    let challenge: DailyChallenge
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: challenge.icon)
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Challenge")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(challenge.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                if challenge.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    HStack(spacing: 4) {
                        Text("+\(challenge.dropletReward)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        Image(systemName: "drop.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Text(challenge.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(challenge.progressPercentage / 100, 1.0))
                }
            }
            .frame(height: 8)
            
            Text("\(Int(challenge.progressPercentage))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Category Filter Button
struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
        }
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? categoryColor(achievement.category).opacity(0.2) : Color(.systemGray5))
                    .frame(width: 70, height: 70)
                
                Image(systemName: achievement.icon)
                    .font(.title)
                    .foregroundColor(achievement.isUnlocked ? categoryColor(achievement.category) : .gray)
            }
            
            Text(achievement.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
            
            Text(achievement.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if !achievement.isUnlocked {
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(categoryColor(achievement.category))
                            .frame(width: geometry.size.width * min(achievement.progressPercentage / 100, 1.0))
                    }
                }
                .frame(height: 6)
                
                Text("\(Int(achievement.progressPercentage))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 4) {
                    Text("+\(achievement.dropletReward)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .opacity(achievement.isUnlocked ? 1.0 : 0.7)
    }
    
    private func categoryColor(_ category: AchievementCategory) -> Color {
        switch category {
        case .conservation: return .green
        case .consistency: return .blue
        case .milestones: return .orange
        case .streaks: return .red
        }
    }
}

// MARK: - Celebration Overlay
struct CelebrationOverlay: View {
    @Binding var isShowing: Bool
    let message: String
    let achievements: [Achievement]
    
    var body: some View {
        if isShowing {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isShowing = false
                        }
                    }
                
                VStack(spacing: 20) {
                    Text(message)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    if !achievements.isEmpty {
                        ForEach(achievements) { achievement in
                            HStack(spacing: 12) {
                                Image(systemName: achievement.icon)
                                    .font(.largeTitle)
                                    .foregroundColor(.yellow)
                                
                                VStack(alignment: .leading) {
                                    Text(achievement.title)
                                        .font(.headline)
                                    
                                    Text("+\(achievement.dropletReward) 💧")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                        }
                    }
                    
                    Button("Awesome!") {
                        withAnimation {
                            isShowing = false
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 20)
                )
                .padding(40)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }
}

#Preview {
    AchievementsView()
        .environmentObject(GamificationManager())
}
