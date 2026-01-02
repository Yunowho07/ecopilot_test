# Eco Point System Implementation Guide

## Overview

The eco point system rewards users for completing eco-friendly activities with points that contribute simultaneously to **weekly**, **monthly**, and **all-time** leaderboards.

---

## 📊 Point Values & Limits

| No. | Activity | Eco Points | Daily Limit | Weekly Limit | Leaderboard |
|-----|----------|------------|-------------|--------------|-------------|
| 1 | View Daily Eco Tip | **3** | 1 | 7 | Weekly, Monthly, All-Time |
| 2 | Complete Daily Eco Challenge | **20** | 1 | 7 | Weekly, Monthly, All-Time |
| 3 | Daily Streak Bonus | **10** | 1 | 7 | Weekly, Monthly, All-Time |
| 4 | Scan Product (Image/Barcode) | **5** | 10 | 50 | Weekly, Monthly, All-Time |
| 5 | First-Time Product Scan Bonus | **5** | 5 | 20 | Weekly, Monthly, All-Time |
| 6 | Add New Product | **30** | 3 | 10 | Weekly, Monthly, All-Time |
| 7 | Dispose/Recycle Product | **10** | 5 | 20 | Weekly, Monthly, All-Time |
| 8 | Verified Disposal Bonus | **5** | 5 | 20 | Weekly, Monthly, All-Time |
| 9 | Weekly Eco Goal Completion | **30** | – | 1 | Weekly, Monthly, All-Time |
| 10 | Monthly Eco Goal Completion | **50** | – | – | Monthly, All-Time |
| 11 | Rank Promotion Bonus | **20-50** | – | – | All-Time |
| 12 | Eco Campaign/Event | **20-50** | Campaign-based | Campaign-based | Weekly, Monthly, All-Time |

---

## 🚦 Anti-Abuse Measures

### Daily Point Cap
- Maximum daily points: **~120 points**
- Prevents point farming

### Weekly Point Cap
- Maximum weekly points: **~700 points**
- Ensures fair competition

### Activity-Specific Controls
- Disposal actions require **location verification**
- Each product disposal can only be claimed **once**
- New products require **manual or automated validation**
- Campaign rewards are **time-limited and monitored**

---

## 🏆 Leaderboard Logic

### Weekly Leaderboard
- **Calculation**: Sum of eco points earned within current week
- **Reset Rule**: Resets every week (Monday 00:00)
- **Collection**: `users/{uid}/weekly_points/{weekKey}`

### Monthly Leaderboard
- **Calculation**: Sum of eco points earned within current month
- **Reset Rule**: Resets every month (1st day 00:00)
- **Collection**: `users/{uid}/monthly_points/{monthKey}`

### All-Time Leaderboard
- **Calculation**: Total accumulated eco points
- **Reset Rule**: Never resets (cumulative)
- **Collection**: `users/{uid}.ecoPoints`

### Simultaneous Updates
When a user earns eco points, **all three totals are updated simultaneously**:
1. Weekly points (resets weekly)
2. Monthly points (resets monthly)
3. Overall points (never resets)

---

## 🎯 Implementation Details

### Core File: `firebase_service.dart`

#### Main Method: `addEcoPoints()`
```dart
await FirebaseService().addEcoPoints(
  points: 20,
  reason: 'Daily challenge completed',
  activityType: 'complete_daily_challenge',
);
```

**What it does:**
1. Updates overall eco points in `users/{uid}`
2. Updates monthly points in `users/{uid}/monthly_points/{monthKey}`
3. Updates weekly points in `users/{uid}/weekly_points/{weekKey}`
4. Logs activity in `users/{uid}/point_history` for tracking
5. Checks daily/weekly limits (to be implemented)

### Activity Types (Constants)

Defined in `lib/utils/eco_point_constants.dart`:

```dart
- view_daily_tip
- complete_daily_challenge
- daily_streak_bonus
- scan_product
- first_time_scan_bonus
- add_new_product
- dispose_product
- verified_disposal_bonus
- weekly_goal_completion
- monthly_goal_completion
- rank_promotion_bonus
- eco_campaign_event
```

---

## 📈 Rank Progression

| Rank | Eco Points | Expected Time (Active User) |
|------|------------|----------------------------|
| Green Beginner | 0 – 299 | 1–2 weeks |
| Seedling | 300 – 799 | 2–4 weeks |
| Sprout | 800 – 1,499 | 1–2 months |
| Eco Explorer | 1,500 – 2,999 | 2–3 months |
| Eco Advocate | 3,000 – 4,999 | 3–5 months |
| Sustainability Champion | 5,000 – 7,999 | 6–8 months |
| Planet Protector | 8,000 – 11,999 | 9–12 months |
| Eco Guardian | 12,000 – 16,999 | 1–1.5 years |
| Earth Guardian | 17,000 – 22,999 | 1.5–2 years |
| Climate Champion | 23,000 – 29,999 | 2+ years |
| Eco Legend | 30,000 – 39,999 | Long-term |
| Global Sustainability Icon | 40,000+ | Elite users |

---

## 🔄 Updated Files

### 1. **`lib/utils/eco_point_constants.dart`** ✨ NEW
- Defines all point values
- Defines daily/weekly limits
- Defines activity type constants

### 2. **`lib/auth/firebase_service.dart`** ✅ UPDATED
- `addEcoPoints()` - Updated with `activityType` parameter
- `completeChallenge()` - Uses 20 points per challenge
- `checkStreakBonus()` - Updated streak bonuses (7, 14, 30, 50, 100, 200 days)
- Product scan - Uses 5 points with activity tracking

### 3. **`lib/screens/disposal_guidance_screen.dart`** ✅ UPDATED
- Disposal: 10 points (`dispose_product`)
- Verified location bonus: 5 points (`verified_disposal_bonus`)
- Total: 15 points when location verified

### 4. **`lib/screens/daily_challenge_screen.dart`** ✅ ALREADY CORRECT
- Each challenge: 20 points
- Challenges are properly tracked

### 5. **`lib/utils/rank_utils.dart`** ✅ ALREADY UPDATED
- 12-tier rank system
- Updated point thresholds (0-299, 300-799, etc.)

---

## 📝 Example Point Earnings (Typical Day)

| Activity | Points | Running Total |
|----------|--------|---------------|
| View daily eco tip | 3 | 3 |
| Complete challenge #1 | 20 | 23 |
| Complete challenge #2 | 20 | 43 |
| Scan 3 products | 15 (3×5) | 58 |
| Dispose 1 product (verified) | 15 (10+5) | 73 |
| **Daily Total** | **73** | **73** |

After 7 consecutive days with similar activity:
- Daily points: ~73 pts/day
- 7-day streak bonus: +10 pts
- **Weekly total**: ~521 points

---

## 🎯 Next Steps (Optional Enhancements)

1. **Implement Daily/Weekly Limit Checks**
   - Create `checkActivityLimit()` method in `firebase_service.dart`
   - Query `point_history` to count activities by type
   - Prevent points if limit exceeded

2. **Add First-Time Product Scan Bonus**
   - Track scanned product IDs in user profile
   - Award 5 bonus points for new products

3. **Implement Weekly/Monthly Goals**
   - Define goals (e.g., scan 20 products, complete all challenges)
   - Award 30/50 points on completion

4. **Rank Promotion Bonuses**
   - Detect rank changes
   - Award 20-50 points based on new rank tier

5. **Campaign System**
   - Create `campaigns` collection
   - Time-limited participation
   - Custom point rewards (20-50 pts)

---

## 📚 Summary

The eco point system rewards users for completing eco-friendly activities with points that contribute simultaneously to weekly, monthly, and all-time leaderboards. Each activity grants a predefined number of eco points with daily and weekly limits to prevent misuse. Eco points are used to determine user ranks, encouraging long-term engagement and sustainable behavior through visible progression and competitive leaderboards.

---

## 🛠️ Testing Checklist

- [ ] Daily challenge awards 20 points per challenge
- [ ] Product scan awards 5 points
- [ ] Disposal awards 10 points + 5 verified bonus
- [ ] Streak bonuses work (7, 14, 30, 50, 100, 200 days)
- [ ] Points update all three leaderboards simultaneously
- [ ] Weekly leaderboard resets correctly
- [ ] Monthly leaderboard resets correctly
- [ ] All-time points accumulate correctly
- [ ] Rank updates based on total points
- [ ] Point history logs activity types

---

**Last Updated**: January 2, 2026  
**Version**: 2.0
