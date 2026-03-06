//
//  GamificationModel.swift
//  SmartFlow
//
//  Created by Raudel Alejandro on 30-10-2025.
//

import Foundation
import SwiftUI

// MARK: - Achievement Types
enum AchievementCategory: String, Codable, CaseIterable {
    case conservation = "Conservation"
    case consistency = "Consistency"
    case milestones = "Milestones"
    case streaks = "Streaks"
}

// MARK: - Achievement Definition
struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let requirement: Double
    let dropletReward: Int
    var isUnlocked: Bool = false
    var unlockedDate: Date?
    var progress: Double = 0.0
    
    var progressPercentage: Double {
        min(progress / requirement * 100, 100)
    }
    
    var isCompleted: Bool {
        progress >= requirement
    }
}

// MARK: - Droplet Currency (Like Duolingo Lingots)
struct DropletBalance: Codable {
    var total: Int = 0
    var earned: Int = 0
    var spent: Int = 0
    
    mutating func add(_ amount: Int, reason: String) {
        total += amount
        earned += amount
    }
    
    mutating func spend(_ amount: Int) -> Bool {
        guard total >= amount else { return false }
        total -= amount
        spent += amount
        return true
    }
}

// MARK: - Streak Tracking
struct StreakData: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastActivityDate: Date?
    var streakFreezeAvailable: Bool = true
    var streakFreezeCount: Int = 0
    
    mutating func updateStreak(for date: Date = Date()) {
        let calendar = Calendar.current
        
        if let lastDate = lastActivityDate {
            let daysDifference = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: date)).day ?? 0
            
            if daysDifference == 0 {
                // Same day, no change
                return
            } else if daysDifference == 1 {
                // Consecutive day
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else if daysDifference > 1 {
                // Streak broken, check for freeze
                if streakFreezeAvailable && daysDifference == 2 {
                    streakFreezeAvailable = false
                    streakFreezeCount += 1
                } else {
                    currentStreak = 1
                }
            }
        } else {
            // First time
            currentStreak = 1
            longestStreak = 1
        }
        
        lastActivityDate = date
    }
    
    mutating func breakStreak() {
        currentStreak = 0
        lastActivityDate = nil
    }
}

// MARK: - Daily Challenge
struct DailyChallenge: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let target: Double
    let dropletReward: Int
    var progress: Double = 0.0
    var isCompleted: Bool = false
    var date: Date
    
    var progressPercentage: Double {
        min(progress / target * 100, 100)
    }
}

// MARK: - User Level System
struct UserLevel: Codable {
    var level: Int = 1
    var xp: Int = 0
    var xpToNextLevel: Int = 100
    
    var progress: Double {
        Double(xp) / Double(xpToNextLevel)
    }
    
    mutating func addXP(_ amount: Int) -> Bool {
        xp += amount
        
        if xp >= xpToNextLevel {
            level += 1
            xp -= xpToNextLevel
            xpToNextLevel = Int(Double(xpToNextLevel) * 1.5) // Exponential growth
            return true // Level up!
        }
        return false
    }
}

// MARK: - Gamification Manager
class GamificationManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var dropletBalance: DropletBalance = DropletBalance()
    @Published var streakData: StreakData = StreakData()
    @Published var dailyChallenge: DailyChallenge?
    @Published var userLevel: UserLevel = UserLevel()
    @Published var recentUnlocks: [Achievement] = []
    @Published var showCelebration: Bool = false
    @Published var celebrationMessage: String = ""
    
    private let achievementsKey = "gamification_achievements"
    private let dropletsKey = "gamification_droplets"
    private let streakKey = "gamification_streak"
    private let challengeKey = "gamification_challenge"
    private let levelKey = "gamification_level"
    
    init() {
        loadData()
        initializeAchievements()
        generateDailyChallenge()
    }
    
    // MARK: - Data Persistence
    func loadData() {
        let defaults = UserDefaults.standard
        
        if let achievementsData = defaults.data(forKey: achievementsKey),
           let savedAchievements = try? JSONDecoder().decode([Achievement].self, from: achievementsData) {
            achievements = savedAchievements
        }
        
        if let dropletsData = defaults.data(forKey: dropletsKey),
           let savedDroplets = try? JSONDecoder().decode(DropletBalance.self, from: dropletsData) {
            dropletBalance = savedDroplets
        }
        
        if let streakDataRaw = defaults.data(forKey: streakKey),
           let savedStreak = try? JSONDecoder().decode(StreakData.self, from: streakDataRaw) {
            streakData = savedStreak
        }
        
        if let challengeData = defaults.data(forKey: challengeKey),
           let savedChallenge = try? JSONDecoder().decode(DailyChallenge.self, from: challengeData) {
            dailyChallenge = savedChallenge
        }
        
        if let levelData = defaults.data(forKey: levelKey),
           let savedLevel = try? JSONDecoder().decode(UserLevel.self, from: levelData) {
            userLevel = savedLevel
        }
    }
    
    func saveData() {
        let defaults = UserDefaults.standard
        
        if let achievementsData = try? JSONEncoder().encode(achievements) {
            defaults.set(achievementsData, forKey: achievementsKey)
        }
        
        if let dropletsData = try? JSONEncoder().encode(dropletBalance) {
            defaults.set(dropletsData, forKey: dropletsKey)
        }
        
        if let streakData = try? JSONEncoder().encode(streakData) {
            defaults.set(streakData, forKey: streakKey)
        }
        
        if let challengeData = try? JSONEncoder().encode(dailyChallenge) {
            defaults.set(challengeData, forKey: challengeKey)
        }
        
        if let levelData = try? JSONEncoder().encode(userLevel) {
            defaults.set(levelData, forKey: levelKey)
        }
    }
    
    // MARK: - Initialize Achievements
    private func initializeAchievements() {
        if achievements.isEmpty {
            achievements = createDefaultAchievements()
        }
    }
    
    private func createDefaultAchievements() -> [Achievement] {
        return [
            // Conservation Achievements
            Achievement(id: "save50", title: "Water Saver", description: "Save 50L in a day", icon: "drop.fill", category: .conservation, requirement: 50, dropletReward: 10),
            Achievement(id: "save100", title: "Conservation Hero", description: "Save 100L in a day", icon: "drop.triangle.fill", category: .conservation, requirement: 100, dropletReward: 25),
            Achievement(id: "save500", title: "Eco Warrior", description: "Save 500L total", icon: "leaf.fill", category: .conservation, requirement: 500, dropletReward: 50),
            Achievement(id: "save1000", title: "Planet Protector", description: "Save 1000L total", icon: "globe.americas.fill", category: .conservation, requirement: 1000, dropletReward: 100),
            
            // Streak Achievements
            Achievement(id: "streak3", title: "Getting Started", description: "Maintain a 3-day streak", icon: "flame.fill", category: .streaks, requirement: 3, dropletReward: 15),
            Achievement(id: "streak7", title: "Weekly Warrior", description: "Maintain a 7-day streak", icon: "flame.fill", category: .streaks, requirement: 7, dropletReward: 30),
            Achievement(id: "streak30", title: "Monthly Master", description: "Maintain a 30-day streak", icon: "flame.fill", category: .streaks, requirement: 30, dropletReward: 100),
            Achievement(id: "streak100", title: "Streak Legend", description: "Maintain a 100-day streak", icon: "star.fill", category: .streaks, requirement: 100, dropletReward: 500),
            
            // Milestone Achievements
            Achievement(id: "first_day", title: "First Drop", description: "Complete your first day of tracking", icon: "trophy.fill", category: .milestones, requirement: 1, dropletReward: 5),
            Achievement(id: "week_complete", title: "Week Complete", description: "Track water for 7 days", icon: "calendar", category: .milestones, requirement: 7, dropletReward: 20),
            Achievement(id: "month_complete", title: "Monthly Monitor", description: "Track water for 30 days", icon: "calendar.badge.checkmark", category: .milestones, requirement: 30, dropletReward: 75),
            Achievement(id: "under_limit_10", title: "Consistent Saver", description: "Stay under limit 10 times", icon: "checkmark.seal.fill", category: .consistency, requirement: 10, dropletReward: 40),
            Achievement(id: "under_limit_50", title: "Master of Control", description: "Stay under limit 50 times", icon: "crown.fill", category: .consistency, requirement: 50, dropletReward: 150),
            
            // Special Achievements
            Achievement(id: "perfect_week", title: "Perfect Week", description: "Stay under limit every day for a week", icon: "star.circle.fill", category: .consistency, requirement: 7, dropletReward: 75),
            Achievement(id: "early_bird", title: "Early Bird", description: "Check the app before 8 AM", icon: "sunrise.fill", category: .milestones, requirement: 1, dropletReward: 10),
        ]
    }
    
    // MARK: - Daily Challenge Generation
    func generateDailyChallenge() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if we need a new challenge
        if let existingChallenge = dailyChallenge,
           calendar.isDate(existingChallenge.date, inSameDayAs: today) {
            return // Already have today's challenge
        }
        
        // Generate new challenge
        let challenges = [
            DailyChallenge(id: UUID().uuidString, title: "Shower Sprint", description: "Keep shower under 5 minutes", icon: "shower.fill", target: 30, dropletReward: 20, date: today),
            DailyChallenge(id: UUID().uuidString, title: "Conservation Champion", description: "Stay 20% under your daily limit", icon: "target", target: 80, dropletReward: 25, date: today),
            DailyChallenge(id: UUID().uuidString, title: "Morning Saver", description: "Use less than 15L before noon", icon: "sunrise.fill", target: 15, dropletReward: 15, date: today),
            DailyChallenge(id: UUID().uuidString, title: "Eco Explorer", description: "Check your stats 3 times today", icon: "chart.bar.fill", target: 3, dropletReward: 10, date: today),
        ]
        
        dailyChallenge = challenges.randomElement()
        saveData()
    }
    
    // MARK: - Progress Updates
    func updateProgress(waterUsed: Double, daysTracked: Int, daysUnderLimit: Int) {
        var unlocked: [Achievement] = []
        
        // Update streak
        streakData.updateStreak()
        
        for index in achievements.indices {
            if achievements[index].isUnlocked { continue }
            
            let achievement = achievements[index]
            var newProgress = achievement.progress
            
            switch achievement.id {
            case "save50", "save100":
                let saved = max(0, 100 - waterUsed) // Assuming 100L daily limit
                newProgress = saved
            case "save500", "save1000":
                // Track cumulative savings (need to add this to WaterUsageModel)
                break
            case "streak3", "streak7", "streak30", "streak100":
                newProgress = Double(streakData.currentStreak)
            case "first_day", "week_complete", "month_complete":
                newProgress = Double(daysTracked)
            case "under_limit_10", "under_limit_50":
                newProgress = Double(daysUnderLimit)
            default:
                break
            }
            
            achievements[index].progress = newProgress
            
            // Check if unlocked
            if achievements[index].isCompleted && !achievements[index].isUnlocked {
                achievements[index].isUnlocked = true
                achievements[index].unlockedDate = Date()
                unlocked.append(achievements[index])
                
                // Award droplets
                dropletBalance.add(achievement.dropletReward, reason: achievement.title)
                
                // Award XP
                let leveledUp = userLevel.addXP(achievement.dropletReward)
                
                if leveledUp {
                    celebrateEvent(message: "🎉 Level Up! You're now Level \(userLevel.level)!")
                }
            }
        }
        
        // Show celebrations
        if !unlocked.isEmpty {
            recentUnlocks = unlocked
            celebrateEvent(message: "🏆 Achievement Unlocked!")
        }
        
        saveData()
    }
    
    func celebrateEvent(message: String) {
        celebrationMessage = message
        showCelebration = true
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showCelebration = false
        }
    }
    
    // MARK: - Daily Challenge Progress
    func updateDailyChallengeProgress(_ progress: Double) {
        guard var challenge = dailyChallenge, !challenge.isCompleted else { return }
        
        challenge.progress = progress
        
        if challenge.progress >= challenge.target && !challenge.isCompleted {
            challenge.isCompleted = true
            dropletBalance.add(challenge.dropletReward, reason: "Daily Challenge")
            let leveledUp = userLevel.addXP(challenge.dropletReward)
            
            if leveledUp {
                celebrateEvent(message: "🎉 Level Up! You're now Level \(userLevel.level)!")
            } else {
                celebrateEvent(message: "✅ Daily Challenge Complete! +\(challenge.dropletReward) 💧")
            }
        }
        
        dailyChallenge = challenge
        saveData()
    }
    
    // MARK: - Shop System (Future)
    func purchaseStreakFreeze() -> Bool {
        if dropletBalance.spend(50) {
            streakData.streakFreezeAvailable = true
            saveData()
            return true
        }
        return false
    }
}
