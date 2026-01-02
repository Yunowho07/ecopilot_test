# Quick Setup Guide for Redeem Screen

## Step 1: Install Required Packages

Ensure these packages are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^latest
  firebase_auth: ^latest
  cloud_firestore: ^latest
  intl: ^latest
```

Run `flutter pub get` to install.

## Step 2: Add Sample Redemption Offers to Firestore

You have two options to populate offers:

### Option A: Run from Flutter App (Recommended)

Add this to your `main.dart` or create a dedicated setup screen:

```dart
import 'package:ecopilot_test/tools/setup_redemption_offers.dart';

// Add a button in your app or run on first launch
ElevatedButton(
  onPressed: () async {
    await RedemptionOffersSetup.setupSampleOffers();
    print('Offers added successfully!');
  },
  child: Text('Setup Sample Offers'),
)
```

### Option B: Firebase Console

1. Go to Firebase Console → Firestore Database
2. Create collection: `redemption_offers`
3. Add documents with these fields:
   - `title` (string): Offer title
   - `storeName` (string): Partner store name
   - `description` (string): Offer description
   - `category` (string): One of: "Food & Beverage", "Fashion", "Home & Living", "Beauty & Care", "Electronics"
   - `requiredPoints` (number): Points needed (e.g., 100)
   - `imageUrl` (string): Product image URL
   - `expiryDate` (timestamp): Future date
   - `createdAt` (timestamp): Current timestamp

## Step 3: Configure Firestore Security Rules

Add these rules to your `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Redemption offers - read by all authenticated users
    match /redemption_offers/{offerId} {
      allow read: if request.auth != null;
      allow write: if false; // Only admin via backend/console
    }
    
    // User redemptions - read/write by owner only
    match /users/{userId}/redemptions/{redemptionId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 4: Test the Feature

1. Launch your app
2. Earn some Eco Points (or manually add points to your user document in Firestore)
3. Open the app drawer (☰ menu)
4. Tap "Redeem Rewards"
5. Browse and redeem an offer
6. Check "My Vouchers" to see your redemption

## Step 5: Manage Offers

### Add New Offers
Use Firebase Console or run:
```dart
await FirebaseFirestore.instance.collection('redemption_offers').add({
  'title': 'Your Offer Title',
  'storeName': 'Store Name',
  'description': 'Offer description',
  'category': 'Food & Beverage',
  'requiredPoints': 150,
  'imageUrl': 'https://example.com/image.jpg',
  'expiryDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 30))),
  'createdAt': FieldValue.serverTimestamp(),
});
```

### Extend Expiry Dates
```dart
await RedemptionOffersSetup.extendOfferExpiry(30); // Extend by 30 days
```

### Clear All Offers
```dart
await RedemptionOffersSetup.clearAllOffers(); // Use with caution
```

## Troubleshooting

### "No offers available"
- Check Firestore collection name: `redemption_offers`
- Verify offers exist in Firebase Console
- Check Firestore security rules

### "Insufficient Eco Points"
- Add points to user document: `users/{userId}` → field: `ecoPoints`
- Or complete activities in the app to earn points

### Image not loading
- Ensure `imageUrl` field contains valid HTTPS URL
- Check image URL is publicly accessible
- Fallback gradient will show if image fails

## Testing Checklist

- [ ] Sample offers appear in Redeem Screen
- [ ] Points balance displays correctly
- [ ] Category filters work
- [ ] "Show only affordable" filter works
- [ ] Expired offers are marked correctly
- [ ] Redemption flow completes successfully
- [ ] Points are deducted after redemption
- [ ] Voucher code is generated
- [ ] My Vouchers screen shows redemptions
- [ ] Insufficient points shows correct message

## Next Steps

1. Add real partner stores and offers
2. Set up admin panel for managing offers
3. Integrate with partner store systems
4. Implement voucher verification system
5. Add analytics tracking
6. Set up email notifications for redemptions

---

**Need Help?** Check `REDEEM_SCREEN_GUIDE.md` for complete documentation.
