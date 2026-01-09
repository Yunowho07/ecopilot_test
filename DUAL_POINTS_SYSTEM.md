# Dual Points System Documentation

## Overview

EcoPilot uses a dual points system to separately track **total earned points** (for leaderboard rankings) and **spendable points** (for redemptions).

## System Design

### Two Point Fields

1. **`ecoPoints`** - Total Accumulated Points
   - Never decreases
   - Used for leaderboard rankings
   - Used for user rank calculations
   - Represents lifetime achievement
   - Display name: "Total Eco Points" or "Eco Score"

2. **`availablePoints`** - Spendable Points
   - Can decrease through redemptions
   - Used in redeem screen
   - Starts equal to ecoPoints for new actions
   - Display name: "Available Points" or "Redeemable Points"

## Implementation Details

### Point Earning Flow

When a user earns points (scanning, challenges, activities):

```dart
// FirebaseService.addEcoPoints()
await _firestore.collection('users').doc(uid).set({
  'ecoPoints': newOverallPoints,        // Total earned ↑
  'availablePoints': newAvailablePoints, // Spendable ↑
  'updatedAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));
```

**Result**: Both fields increase equally

### Redemption Flow

When a user redeems a reward:

```dart
// RedeemScreen._redeemOffer()
transaction.update(userRef, {
  'availablePoints': FieldValue.increment(-requiredPoints), // Spendable ↓
  // ecoPoints remains unchanged ← Total earned stays
});
```

**Result**: Only `availablePoints` decreases, `ecoPoints` stays the same

## Screen Usage

### Leaderboard Screen
```dart
// Uses ecoPoints (total earned)
final points = (summary['ecoScore'] ?? summary['ecoPoints'] ?? 0) as int;
```
- Displays total earned points
- Ranks users by lifetime achievement
- Never affected by redemptions

### Profile Screen
```dart
// Uses ecoPoints (total earned) for rank calculation
final points = (summary['ecoScore'] ?? summary['ecoPoints'] ?? 0) as int;
final rankInfo = rankForPoints(points);
```
- Calculates rank based on total earned
- Shows achievements and milestones
- Independent of redemptions

### Home Screen
```dart
// Monthly points tracked separately
_monthlyEcoPoints // From monthly_points collection
```
- Shows monthly progress
- Separate tracking for monthly goals

### Redeem Screen
```dart
// Uses availablePoints (spendable)
_userEcoPoints = data?['availablePoints'] ?? 0;
```
- Displays points available for redemption
- Deducts from availablePoints on redemption
- Shows realistic balance for purchases

### Daily Challenge Screen
```dart
// Uses ecoPoints (total earned) for display
_userEcoPoints = result['totalEcoPoints'];
```
- Shows total earned points
- Motivates users with full achievement count

## Benefits

### For Users
✅ **Leaderboard integrity**: Redemptions don't affect rankings  
✅ **Clear achievement tracking**: Total earned shows real progress  
✅ **Honest spending**: Available points show what can be spent  
✅ **Fair competition**: Everyone's total earned is comparable  

### For App
✅ **Better analytics**: Track both earning and spending separately  
✅ **Fraud prevention**: Can't game leaderboard by avoiding redemptions  
✅ **User retention**: Users keep high ranks even after redemptions  
✅ **Balanced economy**: Spending doesn't punish achievements  

## Migration

For existing users, run the migration script once:

```dart
// tools/migrate_available_points.dart
await migrateUserPointsToAvailablePoints();
```

This initializes `availablePoints` equal to current `ecoPoints` for all users.

## Data Structure

```javascript
users/{userId} {
  ecoPoints: 1500,        // Total earned (for leaderboard/ranks)
  availablePoints: 800,   // Spendable (after redeeming 700 points)
  updatedAt: Timestamp,
  // ... other fields
}
```

## Example Scenario

**User Journey:**
1. New user starts: `ecoPoints: 0`, `availablePoints: 0`
2. Completes challenge (+50): `ecoPoints: 50`, `availablePoints: 50`
3. Scans product (+30): `ecoPoints: 80`, `availablePoints: 80`
4. Redeems RM 0.50 voucher (-50): `ecoPoints: 80`, `availablePoints: 30`
5. Completes another challenge (+50): `ecoPoints: 130`, `availablePoints: 80`

**Leaderboard shows**: 130 points (their true achievement)  
**Redeem screen shows**: 80 points available  
**Profile rank based on**: 130 points (higher rank maintained)

## Testing

To verify the system works correctly:

1. Check leaderboard after redemption → Points unchanged ✓
2. Check available points → Reduced by redemption amount ✓
3. Earn new points → Both fields increase ✓
4. Profile rank → Based on total earned ✓

## Notes

- The system is backward compatible via migration
- All new point awards update both fields
- Only redemptions affect availablePoints
- Leaderboard always uses ecoPoints
- This matches standard gamification best practices
