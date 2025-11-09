# Migration Guide: ecoScore → ecoPoints

## Overview

This guide helps you migrate existing Firestore data from the old field name `ecoScore` to the new standardized field name `ecoPoints`.

## What Changed?

- **Old field name:** `ecoScore`
- **New field name:** `ecoPoints`
- **Reason:** Consistency with the database schema and improved clarity

## Affected Collections

- `users` collection - Main user profile data

## Migration Steps

### Option 1: Using Firebase Console (Manual)

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Navigate to your project
3. Go to Firestore Database
4. Open the `users` collection
5. For each user document:
   - If they have an `ecoScore` field, rename it to `ecoPoints`
   - Or add a new `ecoPoints` field with the same value

### Option 2: Using Cloud Functions (Automated)

Create a one-time migration Cloud Function:

```javascript
// functions/migrate_eco_score.js
const admin = require('firebase-admin');
const functions = require('firebase-functions');

exports.migrateEcoScore = functions.https.onRequest(async (req, res) => {
  const db = admin.firestore();
  const usersRef = db.collection('users');
  
  try {
    const snapshot = await usersRef.get();
    const batch = db.batch();
    let updateCount = 0;
    
    snapshot.forEach(doc => {
      const data = doc.data();
      
      // If user has ecoScore but not ecoPoints, migrate it
      if (data.ecoScore !== undefined && data.ecoPoints === undefined) {
        batch.update(doc.ref, {
          ecoPoints: data.ecoScore,
          // Optionally remove old field
          // ecoScore: admin.firestore.FieldValue.delete()
        });
        updateCount++;
      }
    });
    
    await batch.commit();
    res.json({ success: true, updated: updateCount });
  } catch (error) {
    console.error('Migration failed:', error);
    res.status(500).json({ error: error.message });
  }
});
```

Deploy and run:
```bash
firebase deploy --only functions:migrateEcoScore
# Then visit: https://YOUR_PROJECT.cloudfunctions.net/migrateEcoScore
```

### Option 3: Using Firestore Rules (No Migration)

The code now handles both field names automatically:

```javascript
// In getUserSummary()
const ecoPoints = data['ecoPoints'] ?? 0;

// In getLeaderboard()
const points = data['ecoPoints'] ?? 0;
```

So existing users with `ecoScore` will show 0 points until they earn new points.

## What Happens to New Users?

All new users created after this update will have:
- ✅ `ecoPoints` field set to 0
- ✅ Proper point tracking in `ecoPoints`
- ✅ Point history in subcollections

## Testing Checklist

After migration, verify:

- [ ] Profile screen shows correct eco points
- [ ] Leaderboard displays users with points > 0
- [ ] Completing challenges awards points correctly
- [ ] Scanning products awards 2 points
- [ ] Points update in real-time on profile screen

## Rollback Plan

If you need to rollback:

1. Keep the `ecoScore` field (don't delete it)
2. Revert code changes to use `ecoScore` instead of `ecoPoints`
3. Update Firestore rules to reference `ecoScore`

## Support

If you encounter issues:

1. Check Firebase Console logs
2. Verify Firestore indexes are deployed
3. Check user document structure in Firestore
4. Review browser console for errors

---

**Status:** ✅ Migration complete  
**Date:** November 9, 2025  
**Version:** 2.0
