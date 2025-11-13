# Streak Indicator Fixes

## Issues Fixed

### 1. Home Screen - Always Shows 4 Days ✅
**File:** `lib/screens/home_screen.dart`

**Root Cause:**
The `_loadDailyChallengeData()` method was using simulated/hardcoded data, including `_userStreak = 4`, instead of fetching the actual streak from Firestore.

**Solution:**
- Removed hardcoded streak value (`_userStreak = 4`)
- Modified `_loadDailyChallengeData()` to properly fetch challenge data from Firestore
- The home screen now relies on `_loadUserData()` which calls `getUserSummary()` to get the actual streak from the user's profile
- Added fallback to default challenge if Firestore fetch fails

**Code Changes:**
```dart
// BEFORE (lines 335-341):
setState(() {
  _dailyChallenge = DailyChallenge(...);
  _userStreak = 4; // ❌ HARDCODED
});

// AFTER:
// Removed hardcoded streak. Now fetches real data from Firestore.
// Streak is updated via _loadUserData() → getUserSummary()
```

---

### 2. Daily Challenge Screen - Streak Stays at 0 ✅
**File:** `lib/screens/daily_challenge_screen.dart`

**Root Cause:**
The `_fetchUserProgress()` method was trying to read the streak from the `user_challenges` document:
```dart
final streak = data['streak'] ?? 0; // ❌ Wrong location
```
However, the streak is actually stored in the `users` collection document, not in `user_challenges`. This meant the streak was always 0 on initial load and never updated to reflect actual progress.

**Solution:**
- Modified `_fetchUserProgress()` to fetch streak from the correct location
- Now fetches from `users/{uid}` document instead of `user_challenges/{uid}-{date}`
- The streak updates properly after completing challenges because:
  1. User completes challenge → `FirebaseService.completeChallenge()` updates `users` document with new streak
  2. Screen displays result with updated streak value
  3. When screen reloads, it fetches the updated streak from `users` document

**Code Changes:**
```dart
// BEFORE (lines 344 & 349):
final doc = await FirebaseFirestore.instance
    .collection('user_challenges')
    .doc('$uid-$today')
    .get();
final streak = data['streak'] ?? 0; // ❌ Wrong location

// AFTER:
// Fetch challenge progress from user_challenges
final challengeDoc = await FirebaseFirestore.instance
    .collection('user_challenges')
    .doc('$uid-$today')
    .get();

// Fetch streak from users profile document ✅ CORRECT LOCATION
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .get();
final userData = userDoc.data() ?? {};
final streak = userData['streak'] ?? 0;
```

---

## Data Flow After Fix

### Home Screen
1. Screen loads → calls `_loadUserData()`
2. `_loadUserData()` → calls `FirebaseService.getUserSummary(uid)`
3. `getUserSummary()` retrieves streak from `users/{uid}` document
4. Streak displays correctly on home screen ✅

### Daily Challenge Screen  
1. Screen loads → calls `_loadChallengeData()` → calls `_fetchUserProgress()`
2. `_fetchUserProgress()` fetches streak from `users/{uid}` document ✅
3. User completes challenge → `FirebaseService.completeChallenge()` updates `users/{uid}` with new streak
4. Screen updates with new streak value via `setState()`
5. Streak increments properly on consecutive days ✅

---

## Testing Recommendations

1. **Complete all challenges on Day 1** → Streak should be 1
2. **Complete all challenges on Day 2** → Streak should be 2
3. **Skip a day, complete on Day 4** → Streak should reset to 1
4. **Navigate between Home and Daily Challenge screens** → Streak should remain consistent
5. **Check after user completes partial challenges** → Streak should not increment until all challenges are complete

---

## Files Modified
- `lib/screens/home_screen.dart` - Removed hardcoded streak value
- `lib/screens/daily_challenge_screen.dart` - Fixed streak data source location
