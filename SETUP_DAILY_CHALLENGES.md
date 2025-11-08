# Daily Eco Challenge - Quick Setup Guide

## 🚀 Quick Start

### Step 1: Initialize Challenges
Run this once to create today's challenges:

```dart
// In your app initialization (e.g., main.dart or home_screen.dart)
import 'package:ecopilot_test/utils/challenge_generator.dart';

// Ensure today's challenges exist
await ChallengeGenerator.ensureTodayChallengesExist();

// Optional: Generate challenges for the next 7 days
await ChallengeGenerator.generateWeeklyChallenges();
```

### Step 2: Test the System

1. **Open Home Screen**
   - You should see "Your Monthly Eco Points: 0 / 500"
   - Challenge card shows the first daily challenge

2. **Open Daily Challenge Screen**
   - Tap "Go" on the challenge card
   - You'll see 2 challenges for today
   - Each challenge shows points and difficulty

3. **Complete a Challenge**
   - Tap "Mark as Done" on any challenge
   - Points are awarded immediately
   - Monthly points update on Home Screen

4. **Verify Firebase Data**
   - Check Firestore console
   - Look for:
     - `challenges/{today}` - Today's challenge definitions
     - `user_challenges/{uid}-{today}` - Your progress
     - `users/{uid}/monthly_points/{month}` - Monthly total

## 📊 Firestore Setup

### Required Collections

Create these collections in Firebase Console (or they'll auto-create):

1. **challenges**
   - Document ID: `YYYY-MM-DD` (e.g., `2025-11-09`)
   - Auto-created by app

2. **user_challenges**
   - Document ID: `{userId}-YYYY-MM-DD`
   - Auto-created when user completes first challenge

3. **users/{userId}/monthly_points**
   - Document ID: `YYYY-MM` (e.g., `2025-11`)
   - Auto-created on first challenge completion

### Manual Challenge Creation

If you want to manually create challenges in Firestore:

```javascript
// In Firestore Console
challenges/2025-11-09 {
  date: "2025-11-09",
  challenges: [
    {
      id: "recycling_0",
      title: "Recycle all plastic waste generated today",
      points: 15,
      difficulty: "medium",
      icon: "♻️",
      category: "recycling"
    },
    {
      id: "transportation_1",
      title: "Use public transport or cycle for one trip",
      points: 10,
      difficulty: "easy",
      icon: "🚲",
      category: "transportation"
    }
  ],
  createdAt: <timestamp>
}
```

## 🔧 Configuration

### Adjust Monthly Goal

**Default: 500 points/month**

To change:
```dart
// In home_screen.dart, line ~56
int _monthlyGoal = 750; // Set new default
```

Or set per-user in Firestore:
```javascript
users/{userId}/monthly_points/{month} {
  goal: 750  // Custom goal
}
```

### Add Custom Challenges

Edit `lib/utils/challenge_generator.dart`:

```dart
static const Map<String, List<Map<String, dynamic>>> _challengePool = {
  'your_category': [
    {
      'title': 'Your custom challenge',
      'points': 20,
      'difficulty': 'hard',
      'icon': '🌟',
    },
  ],
};
```

## 🧪 Testing Checklist

- [ ] App builds without errors
- [ ] Home Screen shows monthly points (0 / 500 initially)
- [ ] Challenge card displays first challenge
- [ ] Daily Challenge Screen shows 2 challenges
- [ ] "Mark as Done" button works
- [ ] Points update after completion
- [ ] Home Screen refreshes when returning
- [ ] Firestore documents created correctly
- [ ] Streak increments after completing all challenges
- [ ] Monthly points persist across app restarts

## 📱 User Flow Example

```
1. User opens app
   → Home Screen loads
   → Sees "Monthly Eco Points: 0 / 500"
   → Sees first challenge preview

2. User taps "Go" on challenge card
   → Daily Challenge Screen opens
   → Shows 2 challenges for today
   → Shows current streak (0 days initially)

3. User completes first challenge
   → Taps "Mark as Done"
   → SnackBar: "Challenge completed! +15 Points! 😊"
   → Screen returns to Home
   → Monthly points now: 15 / 500
   → Progress bar at 3%

4. User returns to challenges
   → First challenge shows "Done 😊"
   → Second challenge still active

5. User completes second challenge
   → Taps "Mark as Done"
   → SnackBar: "Challenge completed! +10 Points! 😊"
   → Streak increments to 1 day
   → Monthly points now: 25 / 500
   → Progress bar at 5%

6. Next day
   → New challenges automatically generated
   → Streak continues if user completes all challenges
```

## ⚙️ Optional: Firebase Cloud Functions

For production, deploy automatic challenge generation:

```bash
cd functions
npm install firebase-functions firebase-admin
firebase deploy --only functions:generateDailyChallenges
```

This runs daily at midnight UTC to create new challenges.

## 🐛 Troubleshooting

### Issue: No challenges appear
**Solution:**
```dart
await ChallengeGenerator.ensureTodayChallengesExist();
```

### Issue: Points not updating
**Check:**
- User is authenticated (FirebaseAuth.instance.currentUser != null)
- Firestore permissions allow writes
- No network errors in console

### Issue: Streak not incrementing
**Check:**
- Both challenges must be completed
- Check Firestore `user_challenges` document
- Verify `completed` array is `[true, true]`

### Issue: Monthly points reset
**Note:** 
- Monthly points are per-month (YYYY-MM)
- Each month starts fresh
- Intentional design for monthly goals

## 📈 Analytics Setup (Optional)

Track these events for insights:

```dart
// After challenge completion
FirebaseAnalytics.instance.logEvent(
  name: 'challenge_completed',
  parameters: {
    'challenge_id': challengeId,
    'points': points,
    'category': category,
  },
);

// After monthly goal reached
FirebaseAnalytics.instance.logEvent(
  name: 'monthly_goal_reached',
  parameters: {
    'points': monthlyPoints,
    'month': monthKey,
  },
);
```

## 🎯 Success Metrics

Your system is working correctly when:

✅ New challenges appear daily  
✅ Challenges are consistent for all users on same day  
✅ Points are awarded immediately  
✅ Monthly totals update in real-time  
✅ Streaks increment correctly  
✅ Progress bars animate smoothly  
✅ Data persists across sessions  

---

**Need Help?** Check `DAILY_CHALLENGE_SYSTEM.md` for detailed documentation.
