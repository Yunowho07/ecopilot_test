# Daily Challenges Setup Guide

## Overview
The Daily Challenge system now generates **unique challenges every day** based on the current date. Each day will have 2 different challenges selected from a pool of 35+ eco-friendly activities across 6 categories.

## How It Works

### 1. **Date-Based Challenge Generation**
- Challenges are generated using the current date as a seed
- The same date will always produce the same 2 challenges (consistent across devices)
- Different dates will produce different challenges
- Automatically rotates through recycling, transportation, consumption, energy, food, and awareness challenges

### 2. **Challenge Categories**
- **Recycling** (5 challenges): Waste management and recycling activities
- **Transportation** (5 challenges): Eco-friendly travel options
- **Consumption** (6 challenges): Sustainable purchasing habits
- **Energy** (5 challenges): Energy and water conservation
- **Food** (5 challenges): Sustainable eating practices
- **Awareness** (5 challenges): Learning and sharing eco-knowledge

### 3. **Fallback System**
If Firestore is unavailable or challenges aren't pre-generated:
- The app will automatically generate challenges locally using the date-based algorithm
- This ensures users always see different challenges each day, even without internet

## Setup Instructions

### Option 1: Deploy Firebase Cloud Functions (Recommended)

1. **Install Firebase CLI** (if not already installed):
```bash
npm install -g firebase-tools
```

2. **Login to Firebase**:
```bash
firebase login
```

3. **Deploy the Cloud Function**:
```bash
cd functions
npm install
firebase deploy --only functions:generateDailyChallenges
```

4. **Verify Deployment**:
- Go to Firebase Console > Functions
- You should see `generateDailyChallenges` scheduled to run daily at midnight UTC

### Option 2: Generate Challenges Manually

1. **Setup the generation script**:
```bash
cd tools
npm install firebase-admin
```

2. **Download Firebase Service Account Key**:
   - Go to Firebase Console
   - Project Settings > Service Accounts
   - Click "Generate New Private Key"
   - Save as `serviceAccountKey.json` in the `tools/` folder

3. **Run the generator**:
```bash
node generate_challenges.js
```

This will create challenges for today and the next 7 days.

### Option 3: Use the App's Built-in Fallback

If you don't set up Firestore challenges:
- The app will automatically generate unique daily challenges locally
- No setup required, works offline
- Challenges will still change every day

## Testing Different Days

To test that challenges change daily:

1. **Change device date**:
   - Go to Settings > Date & Time
   - Turn off "Automatic date & time"
   - Set date to tomorrow
   - Open the app and check Daily Challenges screen

2. **Use the refresh button**:
   - Tap the refresh icon in the Daily Challenges screen
   - This will reload challenges for the current date

3. **Check the console logs**:
   - Look for debug messages like:
   ```
   📅 Fetching challenges for date: 2025-11-12
   ✅ Loaded 2 challenges from Firestore for 2025-11-12
   ```

## Challenge Points

Each challenge awards different points based on difficulty:
- **Easy challenges**: 8-12 points
- **Medium challenges**: 12-15 points  
- **Hard challenges**: 20-25 points

**Bonus**: Complete ALL daily challenges to earn +10 bonus points!

## Troubleshooting

### Challenges Not Changing

1. **Check if Firestore has challenges**:
   - Firebase Console > Firestore Database
   - Look for `challenges` collection
   - Check if there's a document for today's date (format: `2025-11-11`)

2. **Verify date format**:
   - The app uses `yyyy-MM-dd` format (e.g., `2025-11-11`)
   - Make sure your system date is correct

3. **Clear app cache**:
   - Uninstall and reinstall the app
   - Or clear app data in device settings

### Debug Mode

The app includes debug logs to help troubleshoot:
- `📅 Fetching challenges for date: [date]` - Shows which date is being queried
- `✅ Loaded X challenges from Firestore` - Confirms successful fetch
- `⚠️ Using date-based fallback` - Falls back to local generation
- `❌ Error fetching challenges: [error]` - Shows any errors

## Future Enhancements

Consider adding:
- **Weekly challenges** with higher point rewards
- **Seasonal challenges** based on time of year
- **Community challenges** where users work together
- **Custom challenges** where users can create their own
- **Challenge streaks** with multiplier bonuses

## Files Modified

- `lib/screens/daily_challenge_screen.dart`: Main challenge screen with dynamic date handling
- `functions/daily_challenges.js`: Firebase Cloud Function for automatic generation
- `tools/generate_challenges.js`: Manual challenge generation script

## Support

If you encounter issues:
1. Check the debug console for error messages
2. Verify Firebase connection and permissions
3. Ensure Firestore rules allow reading from `challenges` collection
4. Test with the manual generation script first
