# Points and Streak System Fixes

## Issues Fixed

### 1. ❌ **Double Points Bug**
**Problem**: Completing 2 challenges (5 points each) awarded 20 points instead of expected 10 points.

**Root Cause**: The system was awarding a **10-point completion bonus** when all daily challenges were completed:
- Challenge 1: 5 points
- Challenge 2: 5 points
- **Bonus**: 10 points (for completing both)
- **Total**: 20 points ❌

**Solution**: **Removed the completion bonus**. Now the points are straightforward:
```dart
// BEFORE (with bonus):
int bonusPoints = 0;
if (allCompleted && totalChallenges == 2) {
  bonusPoints = 10; // ❌ This was doubling the expected points
}

// AFTER (no bonus):
int bonusPoints = 0;
// Users expect: 2 challenges × 5 points = 10 total (no bonus)
```

**Expected Behavior Now**:
- Complete Challenge 1 → +5 points
- Complete Challenge 2 → +5 points
- **Total**: 10 points ✅

---

### 2. ❌ **Streak Not Resetting**
**Problem**: Streak showed 3-4 days even after not completing challenges, instead of resetting to 0.

**Root Cause**: Old user accounts created before the `lastChallengeDate` field was added had:
- `streak: 3-4` (from old data)
- `lastChallengeDate: null` (field didn't exist)

The validation logic required `lastChallengeDate` to exist, so it never reset old streaks.

**Solution**: Added **migration logic** that automatically resets streaks without a date:

```dart
// MIGRATION: If streak exists but no lastChallengeDate, reset to 0
if (streak > 0 && lastChallengeDate == null) {
  debugPrint(
    '⚠️ Streak exists ($streak) but no lastChallengeDate found. Resetting to 0 for migration.',
  );
  streak = 0;
  await _firestore.collection('users').doc(uid).set({
    'streak': 0,
    'lastChallengeDate': null,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
```

**Expected Behavior Now**:
1. **First app open**: Streak resets to 0 (migration)
2. **Complete all challenges today**: Streak becomes 1, date saved
3. **Complete all challenges tomorrow**: Streak becomes 2
4. **Skip a day**: Streak resets to 0 automatically
5. **Complete challenges again**: Streak restarts at 1

---

## How Streak System Works Now

### Streak Rules:
- ✅ **Day 1**: Complete all challenges → Streak = 1
- ✅ **Day 2** (next day): Complete all challenges → Streak = 2
- ✅ **Day 3** (next day): Complete all challenges → Streak = 3
- ❌ **Day 5** (skipped Day 4): App opens → Streak resets to 0
- ✅ **Day 5**: Complete challenges → Streak restarts at 1

### Validation Triggers:
1. **On app load**: `getUserSummary()` checks if last completion date is today or yesterday
2. **On challenge completion**: Calculates new streak based on consecutive days
3. **Migration**: Auto-resets old streaks without dates

---

## Testing the Fixes

### Test 1: Points Calculation
1. ✅ Complete Challenge 1 → Check points increased by 5
2. ✅ Complete Challenge 2 → Check points increased by 5 (total +10)
3. ✅ Verify total eco points = previous + 10 (not +20)
4. ✅ Check monthly points also = previous + 10

### Test 2: Streak Reset (Migration)
1. ✅ Open app → Check debug logs for "Resetting to 0 for migration"
2. ✅ Home screen shows Streak = 0
3. ✅ Daily Challenge screen shows Streak = 0
4. ✅ Profile screen shows Streak = 0

### Test 3: Streak Increment
1. ✅ Complete all challenges today → Streak = 1
2. ✅ Check Firestore: `lastChallengeDate` = today's date (YYYY-MM-DD)
3. ✅ Close and reopen app → Streak still = 1
4. ✅ (Tomorrow) Complete all challenges → Streak = 2

### Test 4: Streak Validation
1. ✅ Complete challenges today → Streak = 1
2. ✅ Manually change `lastChallengeDate` in Firestore to 3 days ago
3. ✅ Reopen app → Streak should reset to 0 automatically

---

## Database Schema

### User Document (`users/{uid}`)
```json
{
  "ecoPoints": 10,              // Total lifetime points
  "streak": 1,                  // Current consecutive days
  "lastChallengeDate": "2025-11-10",  // Last completion date (YYYY-MM-DD)
  "updatedAt": Timestamp
}
```

### User Challenge Document (`user_challenges/{uid}-{date}`)
```json
{
  "completed": [true, true],    // Array of completed challenges
  "pointsEarned": 10,           // Points from this day's challenges (no bonus)
  "userId": "user123",
  "date": "2025-11-10",
  "updatedAt": Timestamp
}
```

### Monthly Points Document (`users/{uid}/monthly_points/{YYYY-MM}`)
```json
{
  "points": 10,                 // Points earned this month
  "goal": 500,                  // Monthly goal
  "month": "2025-11",
  "updatedAt": Timestamp
}
```

---

## Files Modified

### `lib/auth/firebase_service.dart`

**Changes**:
1. **Line ~1008**: Removed completion bonus logic
   ```dart
   // BEFORE: bonusPoints = 10 when all completed
   // AFTER: bonusPoints = 0 always
   ```

2. **Line ~550**: Added migration logic for old streaks
   ```dart
   // Reset streak to 0 if lastChallengeDate is null
   if (streak > 0 && lastChallengeDate == null) {
     streak = 0;
     // Update Firestore...
   }
   ```

---

## Expected Output

### Before Fix:
```
Challenge 1 completed: +5 points
Challenge 2 completed: +5 points
Bonus for completion: +10 points
Total: 20 points ❌
Streak: 3 days (incorrect, should be 0)
```

### After Fix:
```
Challenge 1 completed: +5 points
Challenge 2 completed: +5 points
Total: 10 points ✅
Streak: 0 days (reset from old data) → Will become 1 after first completion
```

---

## Migration Notes

- **Existing users**: Streaks will automatically reset to 0 on next app open
- **New users**: Start with streak = 0, lastChallengeDate = null
- **Points**: No retroactive changes (users keep existing points)
- **Challenges**: Only affects future completions (no bonus awarded)

---

## Future Enhancements (Optional)

If you want to **re-enable the completion bonus** but make it clearer to users:
1. Add UI text: "Complete both challenges for +10 bonus!"
2. Show breakdown in success message: "+5 pts (challenge) +10 pts (bonus) = +15 pts"
3. Update documentation in app to explain bonus system

Current implementation prioritizes **simplicity**: 1 challenge = 5 points (no hidden bonuses).
