# Daily Eco Challenge System

## Overview
The Daily Eco Challenge system dynamically generates two eco-friendly tasks each day, tracks user progress, rewards Eco Points upon completion, and maintains daily streaks to encourage consistent engagement.

## Features

### 1. **Dynamic Challenge Generation**
- **2 challenges per day** selected from a pool of 30+ eco-friendly tasks
- **6 categories**: Recycling, Transportation, Consumption, Energy, Awareness, Food
- **3 difficulty levels**: Easy (8-12 points), Medium (12-15 points), Hard (20-25 points)
- Challenges are **consistent for all users** on the same day (date-seeded randomization)

### 2. **Challenge Pool**
The system includes 30+ diverse challenges across categories:

**Recycling:**
- Recycle all plastic waste (15 pts)
- Separate paper, plastic, glass (20 pts)
- Clean 5 items before recycling (10 pts)
- Find e-waste recycling center (15 pts)
- Compost organic waste (12 pts)

**Transportation:**
- Use public transport/cycle (10 pts)
- Walk or bike (15 pts)
- Carpool (12 pts)
- No car for entire day (25 pts)
- Take stairs 3x (8 pts)

**Consumption:**
- Reusable water bottle (10 pts)
- Bring shopping bag (8 pts)
- Minimal packaging (12 pts)
- Buy local/organic (15 pts)
- Avoid single-use plastics (20 pts)

**Energy:**
- Turn off unused lights (8 pts)
- Unplug devices (10 pts)
- 5-minute shower (12 pts)
- Air-dry clothes (15 pts)
- Use natural light (10 pts)

**Awareness:**
- Learn about endangered species (10 pts)
- Share eco-tips (12 pts)
- Watch sustainability documentary (15 pts)
- Research eco-alternatives (10 pts)
- Join environmental community (12 pts)

**Food:**
- One plant-based meal (12 pts)
- Avoid food waste (10 pts)
- Cook at home (15 pts)
- Buy imperfect produce (12 pts)
- Meal prep (15 pts)

### 3. **Points & Progress Tracking**

**Eco Points System:**
- Each challenge awards points upon completion
- Points are added to:
  - **Total Eco Points** (lifetime)
  - **Monthly Eco Points** (current month goal)
  - **Daily Points** (today's challenges)

**Monthly Goal System:**
- Default goal: 500 points/month
- Progress bar shows completion percentage
- Motivational messages based on progress:
  - 0-49%: "Let's reach your goal! 🚀"
  - 50-79%: "Great progress! Keep going! 💪"
  - 80-100%: "You're doing amazing! 🌱"

### 4. **Streak System**
- **Daily streak** increments when ALL daily challenges are completed
- Visual streak indicator with fire icon (🔥) for streaks ≥ 3 days
- Streak is stored per user in Firestore
- Encourages daily engagement

### 5. **Real-time Updates**
- Challenge completion updates immediately
- Monthly points refresh when returning to Home Screen
- Progress bars animate to show new totals
- Success notifications with earned points

## Firebase Data Structure

### Collections

**1. `challenges` (Daily Challenge Definitions)**
```
challenges/
  {YYYY-MM-DD}/
    date: "2025-11-09"
    challenges: [
      {
        id: "recycling_0"
        title: "Recycle all plastic waste generated today"
        points: 15
        difficulty: "medium"
        icon: "♻️"
        category: "recycling"
      },
      {
        id: "transportation_1"
        title: "Use public transport or cycle for one trip"
        points: 10
        difficulty: "easy"
        icon: "🚲"
        category: "transportation"
      }
    ]
    createdAt: Timestamp
```

**2. `user_challenges` (User Progress)**
```
user_challenges/
  {userId}-{YYYY-MM-DD}/
    completed: [false, true]
    pointsEarned: 10
    createdAt: Timestamp
    updatedAt: Timestamp
```

**3. `users/{userId}` (User Summary)**
```
users/
  {userId}/
    ecoPoints: 250        // Total lifetime points
    streak: 5             // Current daily streak
    createdAt: Timestamp
```

**4. `users/{userId}/monthly_points` (Monthly Tracking)**
```
users/
  {userId}/
    monthly_points/
      {YYYY-MM}/
        points: 120       // Points earned this month
        goal: 500         // Monthly goal
        month: "2025-11"
        createdAt: Timestamp
        updatedAt: Timestamp
```

## Implementation Details

### Client-Side (Flutter)

**1. Challenge Generator (`lib/utils/challenge_generator.dart`)**
- Contains the complete challenge pool
- `generateDailyChallenges(DateTime date)` - Generates 2 challenges for any date
- `ensureTodayChallengesExist()` - Creates today's challenges if missing
- `generateWeeklyChallenges()` - Batch creates challenges for next 7 days
- Uses date-seeded randomization for consistency

**2. Home Screen (`lib/screens/home_screen.dart`)**
- Displays Monthly Eco Points card with real-time data
- Shows challenge preview (first challenge)
- Refreshes monthly points when challenges completed
- `_loadMonthlyEcoPoints()` - Fetches current month's points
- `_buildModernScoreCard()` - Dynamic progress visualization

**3. Daily Challenge Screen (`lib/screens/daily_challenge_screen.dart`)**
- Shows both daily challenges
- Tracks completion status
- Updates 3 Firestore collections on completion:
  - `user_challenges` - Daily progress
  - `users` - Total points & streak
  - `users/{uid}/monthly_points` - Monthly total
- Returns success to Home Screen for refresh

### Server-Side (Firebase Functions)

**Optional Cloud Functions (`functions/daily_challenges.js`):**

**1. Scheduled Generation**
```javascript
exports.generateDailyChallenges
// Runs daily at midnight UTC
// Auto-creates challenges for the new day
```

**2. Manual Trigger**
```javascript
exports.manualGenerateChallenges
// HTTP endpoint for testing/manual generation
```

**3. Streak Auto-Update**
```javascript
exports.updateUserStreak
// Firestore trigger on user_challenges update
// Auto-increments streak when all challenges completed
```

## User Flow

### Completing a Challenge

1. **User opens Home Screen**
   - Sees Monthly Eco Points (e.g., "120 / 500")
   - Sees first daily challenge preview
   - Taps "Go" to view all challenges

2. **Daily Challenge Screen**
   - Shows 2 challenges for today
   - Displays current streak
   - Shows progress bar for daily completion

3. **Mark Challenge Complete**
   - User taps "Mark as Done"
   - Firestore transaction updates:
     - Daily progress (completed: [true, false])
     - Total eco points (+15)
     - Monthly points (+15)
   - Success notification shown
   - Returns to Home Screen

4. **Home Screen Updates**
   - Monthly Eco Points: "120 / 500" → "135 / 500"
   - Progress bar animates to new percentage
   - Challenge card shows updated completion

5. **Complete All Challenges**
   - Streak increments by 1
   - Special celebration notification
   - Rank may increase based on total points

## Benefits

### For Users:
✅ **Daily Engagement** - Fresh challenges every day  
✅ **Clear Progress** - Visual monthly goal tracking  
✅ **Gamification** - Points, streaks, and achievements  
✅ **Variety** - 30+ different eco-friendly tasks  
✅ **Motivation** - Dynamic encouragement messages  
✅ **Consistency** - Streak system rewards daily participation  

### For App:
✅ **User Retention** - Daily check-ins increase engagement  
✅ **Behavioral Change** - Encourages sustainable habits  
✅ **Data Collection** - Track which challenges are most popular  
✅ **Scalable** - Auto-generation via Cloud Functions  
✅ **Flexible** - Easy to add new challenges to pool  

## Configuration

### Adjust Monthly Goal
Edit in `home_screen.dart`:
```dart
int _monthlyGoal = 500; // Change default goal
```

Or set per-user in Firestore:
```dart
await monthlyPointsDoc.set({
  'goal': 750, // Custom goal for this user
  // ...
});
```

### Add New Challenges
Edit `challenge_generator.dart`:
```dart
static const Map<String, List<Map<String, dynamic>>> _challengePool = {
  'new_category': [
    {
      'title': 'Your new challenge',
      'points': 15,
      'difficulty': 'medium',
      'icon': '🌟',
    },
  ],
};
```

### Change Daily Challenge Count
Edit in `generateDailyChallenges()`:
```dart
return allChallenges.take(3).toList(); // 3 challenges instead of 2
```

## Testing

### Manual Challenge Generation
```dart
// In app initialization or debug screen
await ChallengeGenerator.ensureTodayChallengesExist();
await ChallengeGenerator.generateWeeklyChallenges();
```

### View Generated Challenges
Check Firestore console:
```
challenges > {today's date} > challenges array
```

### Test Challenge Completion
1. Open Daily Challenge screen
2. Mark challenge as done
3. Check Firestore updates:
   - `user_challenges/{uid}-{date}` - completed array
   - `users/{uid}` - ecoPoints, streak
   - `users/{uid}/monthly_points/{month}` - points

## Future Enhancements

### Potential Features:
- **Weekly/Monthly Challenges** - Longer-term goals
- **Bonus Challenges** - Weekend specials with 2x points
- **Challenge Categories Filter** - Let users choose preferred categories
- **Social Challenges** - Team challenges with friends
- **Challenge History** - View past completed challenges
- **Achievements** - Unlock badges for streaks, categories
- **Custom Challenges** - Users create and share challenges
- **Challenge Reminders** - Push notifications for incomplete challenges
- **Leaderboard Integration** - Rank users by monthly points
- **Difficulty Selection** - Users choose easy/medium/hard preference

## Troubleshooting

### Challenges not appearing?
```dart
// Manually trigger generation
await ChallengeGenerator.ensureTodayChallengesExist();
```

### Monthly points not updating?
- Check Firestore transaction in `_completeChallenge()`
- Verify monthKey format: "YYYY-MM"
- Check user authentication

### Streak not incrementing?
- Ensure BOTH challenges are completed
- Check `allCompleted` logic in `_completeChallenge()`
- Verify Firestore user document exists

## Performance Considerations

- **Cached Challenges**: Challenges are created once per day, not per user
- **Batch Reads**: Monthly points loaded once on screen init
- **Transaction Safety**: All point updates use Firestore transactions
- **Optimistic UI**: Local state updates before Firestore confirmation
- **Index Required**: May need composite index on `user_challenges` for queries

## Analytics Tracking

Recommended events to track:
- `challenge_completed` - Which challenges users complete
- `streak_milestone` - 7-day, 30-day, 100-day streaks
- `monthly_goal_reached` - When users hit their goal
- `category_preference` - Most completed challenge categories
- `daily_challenge_viewed` - Screen impressions

---

**Created**: November 9, 2025  
**Version**: 1.0.0  
**Status**: Production Ready ✅
