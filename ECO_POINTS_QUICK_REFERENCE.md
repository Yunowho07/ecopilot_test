# 🎯 Quick Reference: Eco Point System

## Point Values

| Action | Points | Notes |
|--------|--------|-------|
| **Product Scan** | +2 | Main Scan or Disposal Scan |
| **Daily Challenge (Task 1)** | +5 | Complete first challenge |
| **Daily Challenge (Task 2)** | +5 | Complete second challenge |
| **Both Challenges Bonus** | +10 | Extra points when both completed |
| **10-Day Streak** | +5 | Milestone bonus |
| **30-Day Streak** | +15 | Milestone bonus |
| **100-Day Streak** | +30 | Milestone bonus |
| **200-Day Streak** | +50 | Milestone bonus |
| **Disposal Guidance** | +3 | Follow proper disposal |
| **Explore Alternatives** | +5 | Discover greener products |
| **Read Eco Tips** | +2-5 | Learn sustainability |
| **Eco Quizzes** | +2-5 | Test knowledge |
| **Weekly Engagement** | +10 | Stay active |
| **Monthly Leaderboard** | up to +20 | Top performers |

---

## Rank Progression

| Rank | Points | Emoji | Color |
|------|--------|-------|-------|
| **Green Beginner** | 0-50 | 🌱 | Green |
| **Eco Explorer** | 51-150 | 🌻 | Amber |
| **Planet Protector** | 151-300 | 🌳 | Dark Green |
| **Sustainability Hero** | 301-500 | 🌎 | Orange |
| **Earth Guardian** | 501-800 | 💧 | Blue |
| **Climate Champion** | 801-1200 | 🔥 | Pink |
| **Eco Legend** | 1201-2000 | ⭐ | Purple |
| **Global Sustainability Icon** | 2000+ | 🏆 | Gold |

---

## Daily Maximum Points

**Perfect Day Scenario:**
- Complete both challenges: 20 points (5 + 5 + 10 bonus)
- Scan 5 products: 10 points (5 × 2)
- Read eco tip: 5 points
- Explore alternative: 5 points
- Follow disposal guide: 3 points
- **Total: 43 points per day**

**With Streak Bonus:**
- Day 10: +5 bonus = 48 points
- Day 30: +15 bonus = 58 points
- Day 100: +30 bonus = 73 points
- Day 200: +50 bonus = 93 points

---

## Time to Reach Each Rank

**Average Progress (30 points/day):**
- Green Beginner → Eco Explorer: 2 days
- Eco Explorer → Planet Protector: 5 days
- Planet Protector → Sustainability Hero: 5 days
- Sustainability Hero → Earth Guardian: 10 days
- Earth Guardian → Climate Champion: 13 days
- Climate Champion → Eco Legend: 17 days
- Eco Legend → Global Icon: 27 days
- **Total to max rank: ~79 days**

**Optimal Progress (43 points/day):**
- Reach Eco Explorer: 2 days
- Reach Planet Protector: 4 days
- Reach Sustainability Hero: 7 days
- Reach Earth Guardian: 12 days
- Reach Climate Champion: 19 days
- Reach Eco Legend: 28 days
- Reach Global Icon: 47 days
- **Total to max rank: ~47 days**

---

## Implementation Files

### Modified Files:
1. **`lib/utils/rank_utils.dart`**
   - 8-tier rank system
   - Emoji and color for each rank
   - Rank descriptions
   - Progress calculation functions

2. **`lib/utils/constants.dart`**
   - Added new rank colors
   - Color definitions for all 8 tiers

3. **`lib/auth/firebase_service.dart`**
   - `addEcoPoints()` method
   - `checkStreakBonus()` method
   - Updated `completeChallenge()` with bonus points
   - Updated `saveUserScan()` to award 2 points
   - Point history logging

4. **`lib/screens/daily_challenge_screen.dart`**
   - Enhanced rank display with emoji
   - Progress bar to next rank
   - Rank description display
   - Bonus points notification
   - Visual rank progression

### New Files:
1. **`ECO_POINT_REWARD_SYSTEM.md`**
   - Complete documentation
   - User guide
   - Implementation details
   - Future enhancements

2. **`ECO_POINTS_QUICK_REFERENCE.md`** (this file)
   - Quick lookup tables
   - Point values
   - Rank progression
   - Time estimates

---

## Firebase Structure

```
users/
  {uid}/
    ecoPoints: number           // Total lifetime points
    streak: number              // Current daily streak
    updatedAt: timestamp
    
    scans/                      // Product scans (awards +2 each)
      {scanId}/
        productName: string
        ecoScore: string
        timestamp: timestamp
        
    monthly_points/             // Monthly tracking
      {yyyy-MM}/
        points: number
        goal: number (500)
        month: string
        
    point_history/              // Audit log
      {historyId}/
        points: number
        reason: string
        timestamp: timestamp
        newTotal: number

user_challenges/
  {uid}-{yyyy-MM-dd}/
    completed: boolean[]
    pointsEarned: number
    userId: string
    date: string
    updatedAt: timestamp
```

---

## Testing Checklist

### Point Awards
- [ ] Product scan awards 2 points
- [ ] Challenge 1 awards 5 points
- [ ] Challenge 2 awards 5 points
- [ ] Both challenges award 10 bonus points
- [ ] 10-day streak awards 5 bonus points
- [ ] 30-day streak awards 15 bonus points
- [ ] 100-day streak awards 30 bonus points
- [ ] 200-day streak awards 50 bonus points

### Rank Progression
- [ ] Starts at Green Beginner (0 points)
- [ ] Advances to Eco Explorer (51 points)
- [ ] Advances to Planet Protector (151 points)
- [ ] Advances to Sustainability Hero (301 points)
- [ ] Advances to Earth Guardian (501 points)
- [ ] Advances to Climate Champion (801 points)
- [ ] Advances to Eco Legend (1201 points)
- [ ] Reaches Global Icon (2000 points)

### UI Display
- [ ] Rank emoji displays correctly
- [ ] Rank color matches tier
- [ ] Progress bar calculates correctly
- [ ] Points to next rank shown
- [ ] Rank description displays
- [ ] Bonus points notification shows
- [ ] Monthly goal progress updates

---

## Common Questions

**Q: Do points expire?**
A: No, all points are permanent and accumulate over time.

**Q: Can I lose rank?**
A: No, ranks are permanent achievements based on total points earned.

**Q: What happens to my streak if I miss a day?**
A: Your streak resets to 0, but you keep all earned points.

**Q: Can I earn unlimited points per day?**
A: Daily challenges and streak bonuses have limits, but scanning is unlimited.

**Q: Do I get points for scanning the same product twice?**
A: Yes, each scan awards 2 points regardless of product.

**Q: How are monthly leaderboard bonuses awarded?**
A: Top performers receive bonus points at the end of each month (up to +20).

---

**Version**: 1.0
**Last Updated**: November 9, 2025
**Status**: ✅ Implemented
