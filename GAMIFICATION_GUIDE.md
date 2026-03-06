# 🎮 SmartFlow Gamification System

## Overview
The SmartFlow gamification system transforms water conservation into an engaging, Duolingo-style experience. Users earn rewards, unlock achievements, maintain streaks, and level up as they track and reduce their water usage.

## 🌟 Key Features

### 1. **Achievements System**
Users can unlock 15+ achievements across 4 categories:

#### **Conservation** 🌿
- **Water Saver**: Save 50L in a day (10 💧)
- **Conservation Hero**: Save 100L in a day (25 💧)
- **Eco Warrior**: Save 500L total (50 💧)
- **Planet Protector**: Save 1000L total (100 💧)

#### **Streaks** 🔥
- **Getting Started**: Maintain a 3-day streak (15 💧)
- **Weekly Warrior**: Maintain a 7-day streak (30 💧)
- **Monthly Master**: Maintain a 30-day streak (100 💧)
- **Streak Legend**: Maintain a 100-day streak (500 💧)

#### **Milestones** 🏆
- **First Drop**: Complete your first day of tracking (5 💧)
- **Week Complete**: Track water for 7 days (20 💧)
- **Monthly Monitor**: Track water for 30 days (75 💧)
- **Early Bird**: Check the app before 8 AM (10 💧)

#### **Consistency** ⭐
- **Consistent Saver**: Stay under limit 10 times (40 💧)
- **Master of Control**: Stay under limit 50 times (150 💧)
- **Perfect Week**: Stay under limit every day for a week (75 💧)

---

### 2. **Droplet Currency** 💧
Like Duolingo's "Lingots," SmartFlow uses **Droplets** as in-app currency:

#### **Earning Droplets:**
- Unlock achievements
- Complete daily challenges
- Stay under daily limit (+5 💧 bonus)
- Level up rewards

#### **Spending Droplets:**
- **Streak Freeze** (50 💧): Protect your streak for one missed day
- **Double XP** (75 💧): Earn 2x XP for 24 hours
- **Instant Achievement** (100 💧): Unlock a random achievement
- **Rainbow Theme** (150 💧): Colorful app theme
- **Custom Badge** (200 💧): Exclusive profile badge
- **Pro Stats** (250 💧): Advanced analytics

---

### 3. **Level System** ⭐
Users gain XP and level up by:
- Unlocking achievements
- Completing daily challenges
- Consistent water conservation

**Level Formula:**
- Level 1 → 2: 100 XP
- Each subsequent level: 1.5× previous requirement
- Level 10: ~5,767 XP total

**Display:**
- Current level badge on Home screen
- XP progress bar
- Level-up celebrations with animations

---

### 4. **Streak Tracking** 🔥
Inspired by Duolingo's famous streak system:

#### **Features:**
- Current streak counter (days in a row)
- Longest streak record
- Streak freeze power-up (one-time protection)
- Streak animations and celebrations
- Daily activity requirement: Open app and track water

#### **Streak Rules:**
- Track water usage each day to maintain streak
- Miss a day = streak resets to 0
- Use Streak Freeze to protect against one missed day
- Earn streak-based achievements

---

### 5. **Daily Challenges** 🎯
New challenge every day at midnight:

#### **Examples:**
- **Shower Sprint**: Keep shower under 5 minutes (30L target, 20 💧)
- **Conservation Champion**: Stay 20% under daily limit (25 💧)
- **Morning Saver**: Use less than 15L before noon (15 💧)
- **Eco Explorer**: Check stats 3 times today (10 💧)

**Display:**
- Challenge card on Achievements tab
- Progress bar showing completion
- Reward indicator
- Completion celebration

---

### 6. **User Interface Elements**

#### **Home Screen Integration:**
Quick stats bar showing:
- 🔥 Current streak
- ⭐ User level
- 💧 Droplet balance

#### **Achievements Tab:**
- User level card with XP progress
- Streak display with freeze indicator
- Daily challenge card
- Category filters (All, Conservation, Consistency, Milestones, Streaks)
- Achievement grid with progress bars
- Shop button (💼) in toolbar

#### **Shop Tab:**
- Balance display
- Power-ups section
- Customizations section
- Purchase confirmations
- "Not enough droplets" alerts

---

## 🔧 Technical Implementation

### **Core Files:**

1. **GamificationModel.swift**
   - `GamificationManager` (ObservableObject)
   - `Achievement` struct with progress tracking
   - `DropletBalance` for currency management
   - `StreakData` for streak logic
   - `DailyChallenge` generation and tracking
   - `UserLevel` with XP system

2. **AchievementsView.swift**
   - Main achievements UI
   - Category filtering
   - Achievement cards with animations
   - Celebration overlay
   - Shop integration

3. **ShopView.swift**
   - Droplet shop UI
   - Purchase logic
   - Balance display
   - Shop items catalog

4. **WaterUsageModel+Gamification.swift**
   - Integration extension
   - Auto-updates gamification on water usage changes
   - Daily reset logic
   - Achievement progress tracking

### **Data Persistence:**
All gamification data is saved to UserDefaults:
- `gamification_achievements` - Achievement progress
- `gamification_droplets` - Currency balance
- `gamification_streak` - Streak data
- `gamification_challenge` - Daily challenge
- `gamification_level` - User level and XP

---

## 🎨 Design Principles

### **Visual Feedback:**
- **Animations**: Level-ups, achievement unlocks, streak milestones
- **Color Coding**: 
  - Green = Conservation
  - Blue = Consistency
  - Orange = Milestones
  - Red/Orange = Streaks
- **Icons**: SF Symbols for consistent iOS design
- **Celebrations**: Full-screen overlays for major achievements

### **User Engagement:**
- **Immediate Feedback**: Updates in real-time as water usage changes
- **Clear Goals**: Each achievement shows progress percentage
- **Rewards**: Visible currency that can be spent
- **Competition**: Longest streak vs. current streak
- **Daily Habit**: Daily challenges encourage regular app usage

---

## 📊 Achievement Tracking Logic

### **Auto-Updates:**
The system automatically tracks progress when:
- Water usage changes (via `onChange` in HomeView)
- User stays under daily limit
- App is opened before 8 AM
- Daily challenge criteria are met

### **Progress Calculation:**
```swift
// Example: Conservation achievements
let saved = max(0, usageLimit - currentUsage)
achievement.progress = saved

// Example: Streak achievements  
achievement.progress = Double(streakData.currentStreak)

// Example: Milestone achievements
achievement.progress = Double(daysTracked)
```

### **Unlock Conditions:**
```swift
if achievement.progress >= achievement.requirement && !achievement.isUnlocked {
    achievement.isUnlocked = true
    achievement.unlockedDate = Date()
    awardDroplets(achievement.dropletReward)
    awardXP(achievement.dropletReward)
    showCelebration()
}
```

---

## 🚀 Future Enhancements

### **Potential Features:**
1. **Leaderboards**: Compare with friends or global users
2. **Social Sharing**: Share achievements on social media
3. **Seasonal Events**: Limited-time challenges and rewards
4. **Team Challenges**: Compete with other households
5. **Smart Notifications**: "You're close to an achievement!"
6. **Apple Watch Integration**: Track streaks and challenges on wrist
7. **Widgets**: Home screen widget showing streak and daily challenge
8. **iCloud Sync**: Backup progress across devices
9. **More Shop Items**: Themes, sounds, custom goal types
10. **Achievement Badges**: Display earned badges on profile

---

## 📱 User Experience Flow

### **First-Time User:**
1. Opens app → Automatically earns "First Drop" achievement (5 💧)
2. Sets water limit → Sees daily challenge
3. Tracks water → Progress bar fills, earns XP
4. Stays under limit → Earns droplets, starts streak
5. Returns next day → Streak increments, new challenge appears
6. Unlocks achievement → Celebration animation, earns more droplets
7. Opens shop → Purchases streak freeze for peace of mind

### **Daily Routine:**
1. Morning: Open app (maintains streak, checks daily challenge)
2. Throughout day: Water usage updates automatically via ESP32
3. Evening: Check progress, review achievements
4. Before bed: Verify stayed under limit, earn bonus droplets

---

## 🎯 Alignment with STEM Document

The gamification system directly addresses the paper's claims:

### **Document Quote:**
> "The mobile app is designed to be attractive and to generate awareness through milestones and goals, also known as 'gamification.' As an example, the language learning app Duolingo uses a similar method."

### **Implementation:**
✅ **Milestones**: 15+ achievements across 4 categories  
✅ **Goals**: Daily challenges and custom water limits  
✅ **Duolingo-style**: Streaks, currency (droplets vs lingots), levels, daily goals  
✅ **Attractive Design**: Modern iOS design with animations and celebrations  
✅ **Awareness**: Real-time feedback on water conservation impact  

---

## 📈 Success Metrics

The gamification system success can be measured by:
- **Engagement**: Daily active users, streak retention
- **Behavior Change**: % users staying under limit
- **Achievement Unlock Rate**: Which achievements are most popular
- **Droplet Economy**: Earning vs. spending patterns
- **Challenge Completion**: Daily challenge participation rate

---

## 🔗 Integration Points

### **With Main App:**
- `HomeView`: Quick stats display, water usage tracking
- `HistoryView`: Environmental object injection
- `SmartFlowApp`: Gamification manager initialization
- `ContentView`: Achievements tab in TabView

### **With ESP32:**
- Real-time water usage triggers gamification updates
- Achievement progress recalculates on every data point
- Leak detection can trigger special warnings

### **With Notifications:**
- Achievement unlocks can trigger push notifications
- Daily challenge reminders at configured time
- Streak maintenance reminders

---

## 💡 Tips for Users

1. **Check app daily** to maintain your streak
2. **Complete daily challenges** for bonus droplets
3. **Stay under your limit** for +5 💧 daily bonus
4. **Save up droplets** for big purchases like themes
5. **Use streak freeze wisely** - you only get one!
6. **Track early in the day** to unlock "Early Bird"
7. **Watch your progress bars** - you're closer than you think!

---

**Last Updated**: October 30, 2025  
**Version**: 1.0  
**Author**: SmartFlow Team (UANL Preparatoria 7)
