# Streak System Fix

## Problem
The streak counter was not updating when days changed. Users would see the same streak number even after missing days or starting a new consecutive streak.

## Root Cause
The original implementation had **no date tracking mechanism**:
- ✅ Streak incremented when challenges completed
- ❌ No check for missed days
- ❌ No validation on app load
- ❌ No `lastChallengeDate` field in Firestore

## Solution Implemented

### 1. Added `lastChallengeDate` Tracking
**File**: `lib/auth/firebase_service.dart`

The user profile now includes:
```dart
{
  'streak': 0,
  'lastChallengeDate': null, // Stores 'yyyy-MM-dd' format
}
```

### 2. Smart Streak Calculation Logic
When completing challenges (`completeChallenge` method):

```dart
if (allCompleted) {
  final yesterday = DateFormat('yyyy-MM-dd')
      .format(DateTime.now().subtract(const Duration(days: 1)));

  if (lastCompletedDate == null) {
    // First time completing challenges
    updatedStreak = 1;
  } else if (lastCompletedDate == yesterday) {
    // Consecutive day - increment streak
    updatedStreak = currentStreak + 1;
  } else if (lastCompletedDate == today) {
    // Already completed today - keep current streak
    updatedStreak = currentStreak;
  } else {
    // Missed a day - reset streak to 1
    updatedStreak = 1;
  }
}
```

### 3. Automatic Streak Validation on App Load
When `getUserSummary()` is called (on Home/Challenge screen load):

```dart
if (streak > 0 && lastChallengeDate != null) {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final yesterday = DateFormat('yyyy-MM-dd')
      .format(DateTime.now().subtract(const Duration(days: 1)));
  
  // Reset streak if user missed a day
  if (lastChallengeDate != today && lastChallengeDate != yesterday) {
    streak = 0;
    // Update Firestore immediately
    await _firestore.collection('users').doc(uid).set({
      'streak': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
```

## Behavior Examples

### Scenario 1: Consecutive Days ✅
- **Day 1**: Complete challenges → Streak = 1, `lastChallengeDate = 2025-11-10`
- **Day 2**: Complete challenges → Streak = 2, `lastChallengeDate = 2025-11-11`
- **Day 3**: Complete challenges → Streak = 3, `lastChallengeDate = 2025-11-12`

### Scenario 2: Missed a Day ❌→✅
- **Day 1**: Complete challenges → Streak = 5, `lastChallengeDate = 2025-11-10`
- **Day 2**: *No activity (missed day)*
- **Day 3**: Open app → Streak **reset to 0** (validated by `getUserSummary()`)
- **Day 3**: Complete challenges → Streak = 1, `lastChallengeDate = 2025-11-12`

### Scenario 3: Same Day Multiple Completions
- Complete challenge 1 → Streak = 5
- Complete challenge 2 (all done) → Streak = 5 (no increment)
- `lastChallengeDate` updated to today

### Scenario 4: Streak Reset After Gap
- **Nov 10**: Streak = 10, `lastChallengeDate = 2025-11-10`
- **Nov 15**: Open app → Streak **reset to 0** automatically
- **Nov 15**: Complete challenges → Streak = 1, fresh start

## Database Schema Update

### User Document (`users/{uid}`)
```json
{
  "ecoPoints": 120,
  "streak": 5,
  "lastChallengeDate": "2025-11-10",  // NEW FIELD
  "updatedAt": Timestamp,
  ...
}
```

## Migration for Existing Users
- Existing users without `lastChallengeDate` will have it set to `null`
- First challenge completion sets the date
- No data migration script needed (graceful handling)

## Testing Checklist
- [ ] Complete challenge today → Streak increments
- [ ] Complete challenge yesterday (simulate) → Streak increments
- [ ] Open app after 2+ days → Streak resets to 0
- [ ] Complete both challenges same day → Streak increments only once
- [ ] New user → Streak starts at 1 after first completion

## Files Modified
1. `lib/auth/firebase_service.dart`:
   - Updated `completeChallenge()` method with date-based streak logic
   - Updated `getUserSummary()` with automatic validation
   - Updated `createUserProfile()` to include `lastChallengeDate` field

## Benefits
✅ Accurate streak tracking across days  
✅ Automatic reset when users miss days  
✅ No manual intervention needed  
✅ Real-time validation on app load  
✅ Maintains streak integrity

## Future Enhancements (Optional)
- Add streak history tracking (longest streak ever)
- Push notification reminder before streak expires
- Streak freeze/recovery mechanic (e.g., use points to save streak)
- Streak leaderboard
