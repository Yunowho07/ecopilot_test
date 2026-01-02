# TikTok-Style Streak Reminder System 🔥

## Overview

This implementation provides a comprehensive streak reminder system similar to TikTok's engagement features. It combines **local scheduled notifications** with **server-triggered push notifications** to keep users engaged and motivated to maintain their eco challenge streaks.

## Features ✨

### 1. Local Scheduled Notifications (Always Available)
- **Morning Encouragement** (8:00 AM): Daily motivation to start the eco journey
- **Mid-Day Reminder** (12:00 PM): Gentle nudge to maintain momentum
- **Evening Warning** (6:00 PM): Alert when streak is at risk
- **Last Chance** (10:00 PM): Final urgent reminder before day ends

### 2. Server-Triggered Push Notifications (FCM)
- **Real-time Streak Warnings**: Sent at 9:00 PM to users who haven't completed today's challenge
- **Milestone Celebrations**: Automatic notifications when users reach 7, 14, 30, 50, 100, or 200-day streaks
- **Re-engagement Notifications**: Sent at 10:00 AM to users inactive for 3+ days

### 3. Smart Notification Messages
Messages adapt based on streak length:
- **0 days**: "Start your first streak today!"
- **1-6 days**: "Don't lose your X-day streak!"
- **7-29 days**: "Your amazing X-day streak is at risk!"
- **30+ days**: "Don't let your legendary X-day streak die!"

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Flutter App                         │
├─────────────────────────────────────────────────────────┤
│  StreakNotificationManager (Local Notifications)         │
│  - Schedule daily reminders                              │
│  - Show milestone celebrations                           │
│  - Check completion status                               │
├─────────────────────────────────────────────────────────┤
│  FCMService (Push Notifications)                         │
│  - Initialize Firebase Messaging                         │
│  - Handle foreground/background messages                 │
│  - Save FCM tokens to Firestore                          │
├─────────────────────────────────────────────────────────┤
│  NotificationScreen (UI Controls)                        │
│  - Toggle streak reminders on/off                        │
│  - View notification history                             │
│  - Configure notification preferences                    │
└─────────────────────────────────────────────────────────┘
                           ↕
┌─────────────────────────────────────────────────────────┐
│                   Firebase Services                      │
├─────────────────────────────────────────────────────────┤
│  Firestore Database                                      │
│  - users/{uid}                                           │
│    - fcmToken: string                                    │
│    - streak: number                                      │
│    - lastChallengeDate: string (YYYY-MM-DD)              │
│  - user_challenges/{uid}-{date}                          │
│    - completed: boolean[]                                │
├─────────────────────────────────────────────────────────┤
│  Cloud Functions (Server-Side)                           │
│  - checkStreaksAndSendReminders (9:00 PM daily)          │
│  - sendReEngagementNotifications (10:00 AM daily)        │
│  - sendMilestoneNotification (on streak update)          │
└─────────────────────────────────────────────────────────┘
```

## Setup Instructions

### Step 1: Firebase Configuration

#### 1.1 Enable Firebase Cloud Messaging
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Navigate to your project
3. Go to **Project Settings** → **Cloud Messaging**
4. Enable Cloud Messaging API

#### 1.2 Add FCM Dependencies (Already Done)
Your `pubspec.yaml` already includes:
```yaml
dependencies:
  firebase_messaging: ^16.0.3
```

### Step 2: Deploy Cloud Functions

#### 2.1 Install Firebase Tools (if not already installed)
```powershell
npm install -g firebase-tools
```

#### 2.2 Initialize Functions (if not already done)
```powershell
cd c:\Flutter_Project\ecopilot_test
firebase login
firebase init functions
```

#### 2.3 Install Function Dependencies
```powershell
cd functions
npm install
```

#### 2.4 Add Streak Notifications to Index
Edit `functions/index.js` and add:
```javascript
// Import streak notification functions
const streakNotifications = require('./streak_notifications');

// Export all streak notification functions
exports.checkStreaksAndSendReminders = streakNotifications.checkStreaksAndSendReminders;
exports.sendReEngagementNotifications = streakNotifications.sendReEngagementNotifications;
exports.sendMilestoneNotification = streakNotifications.sendMilestoneNotification;
exports.manualStreakCheck = streakNotifications.manualStreakCheck;
```

#### 2.5 Deploy Functions
```powershell
firebase deploy --only functions
```

### Step 3: Initialize Services in App

#### 3.1 Initialize in Main App
Update your `main.dart`:
```dart
import 'package:ecopilot_test/services/notification_service.dart';
import 'package:ecopilot_test/services/streak_notification_manager.dart';
import 'package:ecopilot_test/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize notification services
  await NotificationService().init();
  await StreakNotificationManager().initializeStreakNotifications();
  await FCMService().initialize();
  
  runApp(MyApp());
}
```

#### 3.2 Request Notification Permissions
On first app open, request permissions:
```dart
// In your home screen or onboarding
final settings = await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);
```

### Step 4: Configure Android

#### 4.1 Update AndroidManifest.xml
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    
    <application>
        <!-- FCM Default Channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="ecopilot_streak_reminders" />
    </application>
</manifest>
```

#### 4.2 Create Notification Channels (Already Implemented)
The `NotificationService` automatically creates channels on initialization.

### Step 5: Configure iOS

#### 5.1 Update Info.plist
Edit `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

#### 5.2 Enable Push Notifications in Xcode
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **Push Notifications**
6. Add **Background Modes** (enable Remote notifications)

### Step 6: Testing

#### 6.1 Test Local Notifications
```dart
// In your app, trigger a test notification
await StreakNotificationManager().scheduleMorningEncouragement();
```

#### 6.2 Test FCM Push Notifications
Use the manual trigger function:
```bash
curl "https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/manualStreakCheck?userId=USER_ID_HERE"
```

#### 6.3 Test from Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Click **Send test message**
3. Enter your FCM token (shown in app logs)
4. Send test notification

## Notification Types & Messages

### Morning Encouragement (8:00 AM)
```
Streak 0: "Good morning! 🌞 Start your eco journey today!"
Streak 1-6: "Good morning! 🌱 Keep your X-day streak alive!"
Streak 7-29: "Good morning! 🔥 Amazing X-day streak! Keep it going!"
Streak 30+: "Good morning! 🏆 Legendary X-day streak! You're inspiring!"
```

### Mid-Day Reminder (12:00 PM)
```
Streak 0: "Start your first streak today! Complete your eco challenge now 🌍"
Streak 1: "Keep it going! Complete today's challenge to reach day 2 🌱"
Streak 2+: "Don't lose your X-day streak! Complete today's challenge 🔥"
```

### Evening Warning (6:00 PM)
```
Streak 0: "Evening reminder! Complete your eco challenge before bed 🌙"
Streak 1: "Your 1-day streak is waiting! Don't let it reset ⚠️"
Streak 2-6: "⚠️ Your X-day streak is at risk! Complete today's challenge now!"
Streak 7+: "🚨 Don't lose your amazing X-day streak! Act now!"
```

### Last Chance (10:00 PM)
```
Streak 0: "Last chance to start your eco journey today! 2 hours left 🕙"
Streak 1-6: "🕙 LAST CHANCE! Your X-day streak ends in 2 hours!"
Streak 7+: "🚨 URGENT! Your epic X-day streak ends in 2 hours! Don't give up now!"
```

### Milestone Celebrations
```
7 days:   "🔥 7-Day Streak! One week of eco-consciousness!"
14 days:  "🌟 2-Week Streak! Two weeks strong!"
30 days:  "🏆 1-Month Streak! You're an eco champion!"
50 days:  "💎 50-Day Streak! You're unstoppable!"
100 days: "👑 100-Day Streak! LEGENDARY dedication!"
200 days: "🌍 200-Day Streak! WORLD-CLASS eco warrior!"
```

### Re-engagement (Inactive 3+ Days)
```
Old Streak 0: "🌱 Ready to Start? Begin your eco journey today!"
Old Streak 1-6: "💚 We Miss You! You had a X-day streak going! Come back!"
Old Streak 7+: "🔥 Your X-Day Streak Awaits! Come back and rebuild!"
```

## User Experience Flow

### Day 1: New User
1. **8:00 AM**: "Good morning! 🌞 Start your eco journey today!"
2. User completes challenge → Streak = 1
3. **Instant**: No milestone notification (first day)

### Day 7: First Milestone
1. **8:00 AM**: "Good morning! 🌱 Keep your 7-day streak alive!"
2. User completes challenge → Streak = 7
3. **Instant**: "🔥 7-Day Streak Milestone! One week of eco-consciousness!"

### Day X: Missed Challenge
1. **9:00 PM**: Server checks - user hasn't completed challenge
2. **Push Notification**: "⚠️ Your X-day streak is at risk!"
3. **10:00 PM**: "🕙 LAST CHANCE! Your X-day streak ends in 2 hours!"

### Day X+2: Inactive User
1. **10:00 AM**: Re-engagement notification sent
2. "💚 We Miss You! You had a X-day streak going! Come back!"

## Customization

### Change Notification Times
Edit `streak_notification_manager.dart`:
```dart
// Change morning notification time
await NotificationService().scheduleDaily(
  id: _morningEncouragementId,
  hour: 9,  // Change from 8 to 9 AM
  minute: 0,
  // ...
);
```

### Adjust Server Check Times
Edit `functions/streak_notifications.js`:
```javascript
// Change from 9:00 PM to 8:00 PM
exports.checkStreaksAndSendReminders = functions.pubsub
  .schedule('0 20 * * *') // 8:00 PM UTC
  .timeZone('UTC')
  // ...
```

### Add Custom Milestones
Edit `streak_notification_manager.dart`:
```dart
bool _isMilestone(int streak) {
  return streak == 7 || 
         streak == 14 || 
         streak == 21 ||  // Add 3-week milestone
         streak == 30 || 
         streak == 50 || 
         streak == 75 ||  // Add 75-day milestone
         streak == 100 || 
         streak == 200;
}
```

## Troubleshooting

### Notifications Not Showing

**Local Notifications:**
1. Check if permissions granted:
   ```dart
   final pending = await NotificationService().pending();
   print('Pending: ${pending.length}');
   ```
2. Verify timezone initialization in `notification_service.dart`
3. Check device notification settings

**Push Notifications:**
1. Verify FCM token is saved to Firestore:
   ```dart
   final token = await FCMService().fcmToken;
   print('FCM Token: $token');
   ```
2. Check Cloud Functions logs:
   ```bash
   firebase functions:log
   ```
3. Verify APNs certificates (iOS) or FCM configuration (Android)

### Cloud Functions Not Triggering

1. **Check deployment:**
   ```bash
   firebase functions:list
   ```

2. **View logs:**
   ```bash
   firebase functions:log --only checkStreaksAndSendReminders
   ```

3. **Verify schedule:**
   ```bash
   firebase functions:config:get
   ```

### FCM Token Issues

**Token not saving:**
1. Check Firestore permissions
2. Verify user is authenticated
3. Check logs for FCM initialization errors

**Token not refreshing:**
1. Listen to `onTokenRefresh` stream
2. Update Firestore on token change

## Performance Considerations

- **Local Notifications**: Minimal battery impact (scheduled by OS)
- **FCM**: Efficient push delivery (uses device's existing connection)
- **Cloud Functions**: Only runs on schedule or trigger events
- **Firestore Reads**: Optimized queries with indexed fields

## Privacy & Permissions

- **Android 13+**: Requires `POST_NOTIFICATIONS` permission
- **iOS 10+**: Requests notification permission on first use
- **FCM Token**: Stored securely in Firestore (user-specific)
- **Data**: Only streak and completion status tracked

## Cost Estimation

### Firebase Cloud Functions
- **Free Tier**: 2M invocations/month
- **Estimated Usage**: ~3 functions × 1000 users × 30 days = 90K/month
- **Cost**: FREE (well within limits)

### Firebase Cloud Messaging
- **Completely FREE** (no message limits)

### Firestore
- **Reads**: ~1000 users × 2 checks/day × 30 days = 60K reads/month
- **Cost**: FREE (50K reads included, $0.06 per 100K after)

## Next Steps

1. ✅ Deploy Cloud Functions
2. ✅ Test local notifications
3. ✅ Test FCM push notifications
4. ✅ Configure notification UI in app
5. 🔄 Monitor analytics and adjust timings
6. 🔄 A/B test message variations
7. 🔄 Add more engagement features

## Support

For issues or questions:
- Check Firebase Console logs
- Review notification permissions
- Test with manual trigger endpoints
- Monitor user feedback

---

**Created**: December 5, 2025  
**Version**: 1.0.0  
**Status**: Production Ready ✅
