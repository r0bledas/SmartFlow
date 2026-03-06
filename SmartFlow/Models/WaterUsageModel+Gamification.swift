//
//  WaterUsageModel+Gamification.swift
//  SmartFlow
//
//  Created by Raudel Alejandro on 30-10-2025.
//

import Foundation

// MARK: - Gamification Integration Extension
extension WaterUsageModel {
    
    // Gamification tracking properties
    var daysTracked: Int {
        return dailyHistory.count
    }
    
    var daysUnderLimit: Int {
        return dailyHistory.filter { $0 < usageLimit }.count
    }
    
    var totalWaterSaved: Double {
        return dailyHistory.reduce(0) { total, usage in
            total + max(0, usageLimit - usage)
        }
    }
    
    // Call this method whenever water usage is updated
    func updateGamification(gamificationManager: GamificationManager) {
        // Update streak
        gamificationManager.streakData.updateStreak()
        
        // Update achievements progress
        gamificationManager.updateProgress(
            waterUsed: currentUsage,
            daysTracked: daysTracked,
            daysUnderLimit: daysUnderLimit
        )
        
        // Update daily challenge (example: track usage)
        if let challenge = gamificationManager.dailyChallenge {
            switch challenge.title {
            case "Shower Sprint":
                // Track if current usage is under target
                gamificationManager.updateDailyChallengeProgress(currentUsage)
            case "Conservation Champion":
                // Track if staying under 80% of limit
                let targetUsage = usageLimit * 0.8
                if currentUsage <= targetUsage {
                    gamificationManager.updateDailyChallengeProgress(targetUsage)
                }
            case "Morning Saver":
                // This would need time-based logic
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: Date())
                if hour < 12 {
                    gamificationManager.updateDailyChallengeProgress(currentUsage)
                }
            default:
                break
            }
        }
        
        // Check for early bird achievement (before 8 AM)
        checkEarlyBirdAchievement(gamificationManager: gamificationManager)
        
        // Save gamification state
        gamificationManager.saveData()
    }
    
    // Check for early bird achievement
    private func checkEarlyBirdAchievement(gamificationManager: GamificationManager) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        if hour < 8 {
            if let index = gamificationManager.achievements.firstIndex(where: { $0.id == "early_bird" }) {
                if !gamificationManager.achievements[index].isUnlocked {
                    gamificationManager.achievements[index].progress = 1
                    gamificationManager.updateProgress(
                        waterUsed: currentUsage,
                        daysTracked: daysTracked,
                        daysUnderLimit: daysUnderLimit
                    )
                }
            }
        }
    }
    
    // Call when a day ends or resets
    func recordDailyUsage(gamificationManager: GamificationManager) {
        // Add today's usage to history
        dailyHistory.append(currentUsage)
        
        // Keep only last 365 days
        if dailyHistory.count > 365 {
            dailyHistory.removeFirst()
        }
        
        // Update gamification
        updateGamification(gamificationManager: gamificationManager)
        
        // Check if under limit
        if currentUsage < usageLimit {
            // Award bonus droplets for staying under limit
            gamificationManager.dropletBalance.add(5, reason: "Under daily limit")
            gamificationManager.celebrateEvent(message: "🎉 Daily goal achieved! +5 💧")
        }
        
        // Generate new daily challenge for tomorrow
        gamificationManager.generateDailyChallenge()
        
        // Save data
        saveData()
        gamificationManager.saveData()
    }
}
