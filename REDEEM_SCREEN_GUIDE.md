# Redeem Screen - User Guide

## Overview

The **Redeem Screen** is a new feature in EcoPilot that allows users to redeem eco-friendly products and services from partner stores using their accumulated Eco Points. This feature incentivizes sustainable behavior by offering tangible rewards for eco-conscious actions.

---

## Features

### 🎁 **Redemption Offers**
- Browse a wide range of redeemable products from partner stores
- Filter offers by category (Food & Beverage, Fashion, Home & Living, Beauty & Care, Electronics)
- View detailed information including:
  - Product/service title and description
  - Partner store name
  - Required Eco Points
  - Product images
  - Expiry date/validity period
  - Category classification

### 💰 **Points Management**
- View your current Eco Points balance at the top of the screen
- See required points for each offer
- Filter to show only offers you can afford
- Get notified if you need more points for specific offers

### ⏰ **Validity & Expiration**
- Each offer displays its expiration date
- Active offers are clearly marked with green badges
- Expired offers are visually indicated and cannot be redeemed
- "Valid until" dates shown for transparency

### ✅ **Redemption Process**
1. Browse available offers
2. Select an offer you want to redeem
3. Confirm redemption in the dialog
4. Points are automatically deducted from your balance
5. Receive a unique voucher code
6. Access your voucher in "My Vouchers" section

### 🎫 **My Vouchers**
- View all your redeemed vouchers in one place
- Each voucher includes:
  - Unique voucher code
  - Offer title and store name
  - Points spent
  - Redemption date
  - Current status (Active/Used/Expired)

---

## How to Use

### Accessing the Redeem Screen

1. Open the EcoPilot app
2. Tap the **menu icon** (☰) in the top-left corner
3. Select **"Redeem Rewards"** from the navigation drawer
4. Or navigate from any screen that links to the redemption feature

### Browsing Offers

1. View your available Eco Points at the top
2. Scroll through the list of available offers
3. Use category filters to narrow down options:
   - All
   - Food & Beverage
   - Fashion
   - Home & Living
   - Beauty & Care
   - Electronics
4. Enable "Show only offers I can afford" to filter by your point balance

### Redeeming an Offer

1. Find an offer you want to redeem
2. Ensure you have enough Eco Points (indicator shown on card)
3. Check that the offer hasn't expired (Active badge)
4. Tap the **"Redeem Now"** button
5. Review the confirmation dialog showing:
   - Offer details
   - Points to be spent
   - Your remaining balance after redemption
6. Tap **"Confirm"** to complete redemption
7. Your voucher code will be generated and saved

### Viewing Your Vouchers

1. After successful redemption, tap **"View Vouchers"** in the success dialog
2. Or access "My Vouchers" from the redemption success screen
3. See all your redeemed vouchers with:
   - Unique voucher codes
   - Redemption dates
   - Status indicators
   - Points spent

### Using Your Vouchers

1. Show your voucher code to the partner store
2. Store staff will verify and apply your discount/reward
3. Enjoy your eco-friendly product or service!

---

## Point Requirements

Offers range from **80 to 300 Eco Points**, depending on the value and type of reward:

- **80-120 points**: Small discounts, single items
- **150-200 points**: Medium rewards, free products
- **220-300 points**: Premium rewards, high-value items

### Earning Eco Points

You can earn Eco Points through:
- Scanning products and learning about their environmental impact
- Completing daily eco challenges
- Maintaining activity streaks
- Proper disposal of products
- Choosing eco-friendly alternatives

---

## Categories

### 🍽️ Food & Beverage
- Discounts at organic cafés and restaurants
- Meal kits with sustainable ingredients
- Coffee shop promotions

### 👕 Fashion
- Sustainable clothing discounts
- Eco-friendly accessories
- Ethical fashion brands

### 🏠 Home & Living
- Reusable household items
- Sustainable home products
- Zero-waste essentials

### 💄 Beauty & Care
- Natural skincare products
- Organic beauty items
- Cruelty-free cosmetics

### 📱 Electronics
- Solar-powered devices
- Energy-efficient gadgets
- Eco-friendly tech accessories

---

## Offer Status Indicators

### ✅ **Active (Green Badge)**
- Offer is valid and can be redeemed
- You can claim this reward if you have enough points

### ❌ **Expired (Red Badge)**
- Offer validity period has ended
- Cannot be redeemed
- Check back for new offers

### 🔒 **Insufficient Points (Gray Button)**
- You don't have enough Eco Points yet
- Shows how many more points you need
- Keep earning to unlock this offer

---

## Tips for Success

1. **Save Points for High-Value Rewards**: Consider saving for bigger rewards rather than redeeming immediately
2. **Check Expiry Dates**: Prioritize offers that are expiring soon
3. **Use Filters**: Make browsing easier by filtering by category and affordability
4. **Complete Challenges**: Earn more points by completing daily eco challenges
5. **Track Progress**: Monitor your monthly Eco Points goal on the home screen

---

## Troubleshooting

### "Insufficient Eco Points" message
- You need more points to redeem this offer
- Complete more activities to earn points
- The card shows how many more points you need

### "Offer Expired" button
- The redemption period for this offer has ended
- New offers are added regularly
- Check back for fresh opportunities

### Redemption fails
- Check your internet connection
- Ensure you're signed in
- Try again or contact support

### Can't find my voucher
- Open the drawer menu
- Navigate to "My Vouchers" (accessible from success dialog)
- All redeemed vouchers are stored in your account

---

## Developer Setup

### Setting Up Sample Offers

To populate your Firebase Firestore with sample redemption offers:

1. Navigate to your project root
2. Run the setup script:

```dart
import 'tools/setup_redemption_offers.dart';

// In your main.dart or a separate utility file
void setupOffers() async {
  await RedemptionOffersSetup.setupSampleOffers();
}
```

3. This will create 12 sample offers across different categories
4. All offers will have expiry dates 20-90 days in the future

### Database Structure

#### Collection: `redemption_offers`
```dart
{
  'title': String,
  'storeName': String,
  'description': String,
  'category': String,
  'requiredPoints': int,
  'imageUrl': String,
  'expiryDate': Timestamp,
  'createdAt': Timestamp
}
```

#### Collection: `users/{userId}/redemptions`
```dart
{
  'offerId': String,
  'offerTitle': String,
  'storeName': String,
  'pointsSpent': int,
  'redeemedAt': Timestamp,
  'voucherCode': String,
  'status': String // 'active', 'used', 'expired'
}
```

### Extending Offer Expiry

```dart
// Extend all offers by 30 days
await RedemptionOffersSetup.extendOfferExpiry(30);
```

### Clearing All Offers

```dart
// Use with caution - removes all offers
await RedemptionOffersSetup.clearAllOffers();
```

---

## Security Considerations

1. **Transaction Safety**: Points deduction and redemption recording happen in a Firestore transaction
2. **Point Verification**: System checks point balance before allowing redemption
3. **Unique Vouchers**: Each redemption generates a unique voucher code
4. **User Authentication**: Must be signed in to access redemption features

---

## Future Enhancements

Potential improvements for future versions:

- [ ] QR code generation for vouchers
- [ ] In-app store locator for partner locations
- [ ] Push notifications for new offers
- [ ] Wishlist/favorites for offers
- [ ] Sharing offers with friends
- [ ] Redemption history analytics
- [ ] Partner store reviews and ratings
- [ ] Limited-time flash offers
- [ ] Point-back programs

---

## Support

If you encounter any issues with the Redeem Screen:

1. Check your internet connection
2. Ensure you're using the latest version of EcoPilot
3. Verify your Eco Points balance
4. Contact support through the app's Support section
5. Email: support@ecopilot.com

---

## Partner Stores

Current partner stores include:
- 7 Eleven
- 99 Speedmart
- KK Mart
- Family Mart
- Zus Coffee
- llao llao
- CU Mart
- Tealive
- Chagee
- Gigi Coffee
- Kopi Saigon

*More partners being added regularly!*

---

**Version**: 1.0  
**Last Updated**: December 2025  
**Feature Status**: ✅ Production Ready
