# 🎯 Eco Point Reward System

## Overview
The Eco Point Reward System motivates users to take meaningful eco-friendly actions while using the EcoPilot app. Every interaction contributes to building a more sustainable lifestyle and rewards users for their consistency and positive impact.

---

## 🌟 How to Earn Points

### Daily Actions
- **Product Scanning** (+2 points per scan)
  - Scan products in the main Scan Screen
  - Scan products in the Disposal Scan Screen
  - Promotes environmental awareness through discovery

- **Daily Eco Challenges** (Total: 25 points/day)
  - Complete Task 1: +5 points
  - Complete Task 2: +5 points
  - **Bonus for Both**: +10 points extra (Total: 20 points when both completed)
  - Encourages daily participation and habit formation

### Streak Bonuses 🔥
Consistency is rewarded with milestone bonuses:
- **10-day streak**: +5 points
- **30-day streak**: +15 points
- **100-day streak**: +30 points
- **200-day streak**: +50 points

### Additional Activities
- **Disposal Guidance**: +3 points
  - Following proper disposal instructions
- **Exploring Alternatives**: +5 points
  - Discovering greener product alternatives
- **Reading Eco Tips**: +2-5 points
  - Learning about sustainability
- **Eco Quizzes**: +2-5 points
  - Testing environmental knowledge
- **Weekly Engagement**: +10 points
  - Maintaining active participation

### Competitive Rewards
- **Monthly Leaderboard**: Up to +20 bonus points
  - Top performers receive recognition
  - Exceptional commitment to sustainability

---

## 🏆 Eco Rank Tiers

### 🌱 Green Beginner (0-50 points)
**Description**: You're just starting your eco journey! Every scan and challenge helps you grow greener.

**Color**: Primary Green (#1db954)

**What to Focus On**:
- Complete daily challenges
- Scan products to learn about eco-friendliness
- Build your first streak

---

### 🌻 Eco Explorer (51-150 points)
**Description**: You're exploring sustainable habits and discovering new eco-friendly choices.

**Color**: Amber (#FFC107)

**Achievements Unlocked**:
- Established daily routine
- Understanding product eco-scores
- Building sustainable awareness

---

### 🌳 Planet Protector (151-300 points)
**Description**: You're taking real action to protect the planet through responsible decisions.

**Color**: Dark Green (#388E3C)

**Impact Level**:
- Active environmental participation
- Consistent eco-friendly choices
- Influencing positive change

---

### 🌎 Sustainability Hero (301-500 points)
**Description**: You've made sustainability a daily commitment — inspiring others to do the same.

**Color**: Orange (#F57C00)

**Leadership Qualities**:
- Role model for eco-conscious living
- Long-term streak maintenance
- Community influence

---

### 💧 Earth Guardian (501-800 points)
**Description**: You actively reduce waste and carbon impact through consistent eco engagement.

**Color**: Blue (#2196F3)

**Advanced Impact**:
- Measurable environmental contribution
- Expert-level eco knowledge
- Sustainable lifestyle integration

---

### 🔥 Climate Champion (801-1200 points)
**Description**: You lead by example, combining knowledge, action, and influence to protect the environment.

**Color**: Pink (#E91E63)

**Champion Status**:
- Environmental advocate
- Maximum daily engagement
- Inspiring global action

---

### ⭐ Eco Legend (1201-2000 points)
**Description**: You've reached the elite level — your efforts have made a lasting mark on the planet's future.

**Color**: Purple (#9C27B0)

**Legendary Achievements**:
- Elite environmental warrior
- Sustained long-term commitment
- Transformative impact

---

### 🏆 Global Sustainability Icon (2000+ points)
**Description**: The ultimate eco rank. You embody environmental leadership and inspire global change.

**Color**: Gold (#FFD700)

**Ultimate Recognition**:
- Pinnacle of eco achievement
- Global environmental leader
- Inspiring worldwide change

---

## 📊 Point Tracking Features

### Real-Time Updates
- Points awarded immediately after each action
- Visible progress bars on Daily Challenge Screen
- Rank changes reflected instantly

### Monthly Goals
- Default goal: 500 points per month
- Visual progress tracking
- Leaderboard competition

### Point History
- All point awards logged with timestamps
- Detailed reason for each point award
- Accessible via user profile

### Progress Visualization
- Current rank display with emoji
- Rank description and achievements
- Progress bar to next rank
- Points needed for rank advancement

---

## 🎮 Gamification Elements

### Visual Feedback
- **Color-coded ranks**: Each tier has unique color scheme
- **Emoji badges**: Visual representation of achievement
- **Progress animations**: Smooth transitions between ranks
- **Celebration effects**: Special animations for milestones

### Competitive Features
- **Monthly Leaderboard**: See top performers
- **Rank Comparison**: Compare with friends
- **Achievement Badges**: Special recognition for milestones
- **Streak Tracking**: Fire emoji for active streaks

### Motivation System
- **Next Rank Preview**: See what's coming next
- **Achievement Descriptions**: Understand rank significance
- **Bonus Notifications**: Celebrate streak milestones
- **Leaderboard Position**: Track competitive standing

---

## 🔄 Implementation Details

### Firebase Integration
- **User Points**: Stored in `users/{uid}/ecoPoints`
- **Monthly Tracking**: `users/{uid}/monthly_points/{month}`
- **Point History**: `users/{uid}/point_history`
- **Streak Data**: `users/{uid}/streak`

### Point Award Methods
```dart
// Award points for any action
await FirebaseService().addEcoPoints(
  points: 2,
  reason: 'Product scan',
);
```

### Streak Bonuses
```dart
// Automatically awarded at milestones
await FirebaseService().checkStreakBonus(currentStreak);
```

### Challenge Completion
```dart
// Handles individual task points + bonus
await FirebaseService().completeChallenge(
  challengeIndex: 0,
  points: 5,
  totalChallenges: 2,
  currentCompleted: [false, false],
);
```

---

## 📈 Success Metrics

### User Engagement
- Daily active users completing challenges
- Average streak length
- Scan frequency per user

### Environmental Impact
- Total products scanned
- Eco-friendly alternatives discovered
- Proper disposal guidance followed

### Community Growth
- Monthly leaderboard participation
- Rank tier distribution
- Point accumulation rate

---

## 🎯 Strategic Benefits

### For Users
- **Clear Goals**: Know exactly what to do to progress
- **Instant Gratification**: Points awarded immediately
- **Long-term Motivation**: Streak bonuses encourage consistency
- **Social Recognition**: Leaderboard and rank visibility
- **Educational Value**: Learn while earning

### For the App
- **Increased Retention**: Daily challenges bring users back
- **Feature Discovery**: Points encourage exploration
- **Data Collection**: Track user behavior and preferences
- **Community Building**: Competitive leaderboard fosters community
- **Viral Growth**: Achievement sharing drives new users

---

## 🚀 Future Enhancements

### Potential Additions
- **Team Challenges**: Collaborate for bonus points
- **Special Events**: Double points weekends
- **Achievement Badges**: Visual collection system
- **Point Shop**: Redeem points for rewards
- **Social Sharing**: Share achievements on social media
- **Rank Celebrations**: Animated rank-up sequences
- **Seasonal Themes**: Special challenges and bonuses
- **Carbon Offset Tracking**: Convert points to real-world impact

---

## 📱 User Experience Flow

1. **New User** → Green Beginner (0 points)
   - Complete tutorial
   - Scan first product (+2 points)
   - Complete first challenge (+5 points)

2. **Daily Routine** → Build Streak
   - Open app daily
   - Complete both challenges (+20 points with bonus)
   - Scan 3-5 products (+6-10 points)

3. **Milestone Achievement** → Rank Up
   - Reach point threshold
   - Animated rank-up celebration
   - New rank badge and description
   - Share achievement

4. **Long-term Engagement** → Top Ranks
   - Maintain streak (bonus points)
   - Compete on leaderboard
   - Influence community
   - Reach Global Sustainability Icon

---

## 💡 Tips for Users

### Maximize Points
- ✅ Complete both daily challenges every day (20 points)
- ✅ Maintain your streak for bonus rewards
- ✅ Scan products regularly (2 points each)
- ✅ Explore alternative products (+5 points)
- ✅ Read daily eco tips (+2-5 points)
- ✅ Aim for monthly leaderboard top spots (+20 points)

### Build Sustainable Habits
- Set daily app reminder notifications
- Make challenges part of morning routine
- Track your carbon footprint reduction
- Share progress with friends
- Celebrate milestones

### Community Engagement
- Compare ranks with friends
- Challenge others to beat your score
- Share eco tips you discover
- Participate in monthly competitions
- Inspire others with your achievements

---

**Last Updated**: November 9, 2025
**Version**: 1.0
**Status**: ✅ Fully Implemented
