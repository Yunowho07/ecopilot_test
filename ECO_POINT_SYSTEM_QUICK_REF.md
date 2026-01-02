# 🎯 Eco Point System - Quick Reference

## ✅ What's Been Updated

### Point Values (All Correct)
| Activity | Old Points | New Points | Status |
|----------|-----------|-----------|--------|
| Daily Challenge | 5 | **20** | ✅ Updated |
| Product Scan | 5 | **5** | ✅ Correct |
| Disposal | 10 | **10** | ✅ Correct |
| Verified Disposal Bonus | 0 | **5** | ✅ Added |
| Streak Milestones | 10 | **10** | ✅ Correct |
| Daily Tip | N/A | **3** | 🔄 To Implement |
| First-Time Scan Bonus | N/A | **5** | 🔄 To Implement |
| Add New Product | N/A | **30** | 🔄 To Implement |
| Weekly Goal | N/A | **30** | 🔄 To Implement |
| Monthly Goal | N/A | **50** | 🔄 To Implement |

### Files Modified ✅

1. **`lib/utils/rank_utils.dart`**
   - Updated to 12-tier rank system
   - New thresholds: 0-299, 300-799, 800-1499, etc. up to 40,000+

2. **`lib/utils/eco_point_constants.dart`** ✨ NEW
   - All point values defined
   - Daily/weekly limits defined
   - Activity type constants

3. **`lib/auth/firebase_service.dart`**
   - ✅ `addEcoPoints()` - Now accepts `activityType` parameter
   - ✅ `checkActivityLimit()` - New method to enforce limits
   - ✅ `checkStreakBonus()` - Updated for 7, 14, 30, 50, 100, 200 days
   - ✅ Product scan - Uses activity tracking
   - ✅ Challenge completion - Uses activity tracking

4. **`lib/screens/disposal_guidance_screen.dart`**
   - ✅ Base disposal: 10 points
   - ✅ Verified location bonus: 5 points

5. **`lib/screens/profile_screen.dart`**
   - ✅ Uses `rankForPoints()` from rank_utils
   - ✅ Dynamic rank progression display

6. **`lib/screens/daily_challenge_screen.dart`**
   - ✅ Already using 20 points per challenge

### Documentation Created 📚

1. **`ECO_POINT_SYSTEM_V2.md`** - Complete implementation guide
2. **`ECO_POINT_SYSTEM_QUICK_REF.md`** - This file

---

## 🎯 Current Point System

### Daily Challenges
```dart
- Each challenge: 20 points
- 2 challenges per day
- Daily max from challenges: 40 points
- Streak bonuses at: 7, 14, 30, 50, 100, 200 days (+10 points each)
```

### Product Scanning
```dart
- Per scan: 5 points
- Daily limit: 10 scans (50 points max)
- Weekly limit: 50 scans (250 points max)
```

### Disposal
```dart
- Base disposal: 10 points
- Verified location bonus: +5 points
- Total per disposal: 15 points (if verified)
- Daily limit: 5 disposals
- Weekly limit: 20 disposals
```

---

## 🔄 What Still Needs Implementation

### 1. Daily Eco Tip Viewing
```dart
// Location: Create new screen or add to home screen
await FirebaseService().addEcoPoints(
  points: 3,
  reason: 'Viewed daily eco tip',
  activityType: 'view_daily_tip',
);
// Daily limit: 1, Weekly limit: 7
```

### 2. First-Time Product Scan Bonus
```dart
// Location: scan_screen.dart or firebase_service.dart
// After scanning, check if product is new for user
if (isFirstTimeScanningThisProduct) {
  await FirebaseService().addEcoPoints(
    points: 5,
    reason: 'First-time product scan bonus',
    activityType: 'first_time_scan_bonus',
  );
}
// Daily limit: 5, Weekly limit: 20
```

### 3. Add New Product
```dart
// Location: When user contributes new product data
await FirebaseService().addEcoPoints(
  points: 30,
  reason: 'Added new product to database',
  activityType: 'add_new_product',
);
// Daily limit: 3, Weekly limit: 10
```

### 4. Weekly/Monthly Goals
```dart
// Location: Create goals tracking system
// When weekly goal completed:
await FirebaseService().addEcoPoints(
  points: 30,
  reason: 'Weekly eco goal completed',
  activityType: 'weekly_goal_completion',
);
// When monthly goal completed:
await FirebaseService().addEcoPoints(
  points: 50,
  reason: 'Monthly eco goal completed',
  activityType: 'monthly_goal_completion',
);
```

### 5. Rank Promotion Bonus
```dart
// Location: firebase_service.dart or profile screen
// After rank update, check if rank increased
if (newRank > oldRank) {
  final bonus = calculateRankBonus(newRank); // 20-50 based on tier
  await FirebaseService().addEcoPoints(
    points: bonus,
    reason: 'Rank promotion to ${newRankTitle}',
    activityType: 'rank_promotion_bonus',
  );
}
```

### 6. Enforce Activity Limits
```dart
// Before awarding points, check limits:
final canScan = await FirebaseService().checkActivityLimit(
  activityType: 'scan_product',
  dailyLimit: 10,
  weeklyLimit: 50,
);

if (canScan) {
  await FirebaseService().addEcoPoints(
    points: 5,
    reason: 'Product scan',
    activityType: 'scan_product',
  );
} else {
  // Show message: "Daily/weekly scan limit reached"
}
```

---

## 📊 Point Earning Examples

### Example 1: Active User (One Day)
```
✅ View daily tip: 3 pts
✅ Complete challenge #1: 20 pts
✅ Complete challenge #2: 20 pts
✅ Scan 5 products: 25 pts (5×5)
✅ Dispose 2 products (verified): 30 pts (2×15)
━━━━━━━━━━━━━━━━━━━━
Total: 98 points
```

### Example 2: Very Active User (One Week)
```
Day 1-6: ~98 pts/day = 588 pts
Day 7: 98 pts + 10 (streak bonus) = 108 pts
━━━━━━━━━━━━━━━━━━━━
Weekly Total: 696 points
```

### Example 3: Reaching Seedling Rank
```
Starting points: 0
Week 1: 696 pts → 696 total
Week 2: 500 pts → 1,196 total (Sprout rank unlocked at 800)
Time to Seedling (300 pts): ~3 days of active use
```

---

## 🏆 Rank Progression Timeline

| Rank | Points Needed | Active User Timeline |
|------|--------------|---------------------|
| Green Beginner | 0-299 | Starting rank |
| Seedling | 300-799 | 2-4 weeks |
| Sprout | 800-1,499 | 1-2 months |
| Eco Explorer | 1,500-2,999 | 2-3 months |
| Eco Advocate | 3,000-4,999 | 3-5 months |
| Sustainability Champion | 5,000-7,999 | 6-8 months |
| Planet Protector | 8,000-11,999 | 9-12 months |
| Eco Guardian | 12,000-16,999 | 1-1.5 years |
| Earth Guardian | 17,000-22,999 | 1.5-2 years |
| Climate Champion | 23,000-29,999 | 2+ years |
| Eco Legend | 30,000-39,999 | Long-term commitment |
| Global Sustainability Icon | 40,000+ | Elite achievement |

---

## ✅ Testing Checklist

Current working features:
- [x] Daily challenges award 20 points each
- [x] Product scans award 5 points
- [x] Disposal awards 10 points
- [x] Verified disposal awards +5 bonus
- [x] Points update weekly, monthly, and all-time simultaneously
- [x] Streak bonuses at 7, 14, 30, 50, 100, 200 days
- [x] Rank system with 12 tiers
- [x] Profile screen shows correct rank

Features to test after implementation:
- [ ] Daily tip viewing awards 3 points
- [ ] First-time scan bonus awards 5 points
- [ ] Activity limits are enforced
- [ ] Weekly/monthly goals work
- [ ] Rank promotion bonuses work

---

## 🚀 How to Use

### Award Points in Your Code
```dart
// Import the service
import 'package:ecopilot_test/auth/firebase_service.dart';

// Award points with tracking
await FirebaseService().addEcoPoints(
  points: 20,
  reason: 'Daily challenge completed',
  activityType: 'complete_daily_challenge',
);
```

### Check Before Awarding (Optional - Anti-Abuse)
```dart
final canProceed = await FirebaseService().checkActivityLimit(
  activityType: 'scan_product',
  dailyLimit: 10,
  weeklyLimit: 50,
);

if (canProceed) {
  await FirebaseService().addEcoPoints(
    points: 5,
    reason: 'Product scan',
    activityType: 'scan_product',
  );
}
```

---

**Last Updated**: January 2, 2026  
**Status**: Core system implemented, optional features remain
