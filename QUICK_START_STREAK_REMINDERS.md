# Quick Start: TikTok-Style Streak Reminders 🚀

## What You Get

✅ **4 Daily Local Notifications** - Morning boost, mid-day check, evening warning, last chance  
✅ **Smart FCM Push Notifications** - Server-triggered reminders even when app is closed  
✅ **Milestone Celebrations** - Automatic notifications at 7, 14, 30, 50, 100, 200 days  
✅ **Re-engagement System** - Bring back inactive users automatically  
✅ **User Controls** - Full UI for toggling notifications on/off  

## 5-Minute Setup

### 1. Initialize Services (2 min)

Update your `main.dart`:

```dart
import 'package:ecopilot_test/services/notification_service.dart';
import 'package:ecopilot_test/services/streak_notification_manager.dart';
import 'package:ecopilot_test/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // ✨ Add these 3 lines
  await NotificationService().init();
  await StreakNotificationManager().initializeStreakNotifications();
  await FCMService().initialize();
  
  runApp(const MyApp());
}
```

### 2. Deploy Cloud Functions (2 min)

```powershell
cd c:\Flutter_Project\ecopilot_test\functions
npm install
firebase deploy --only functions
```

### 3. Test It! (1 min)

Run your app:
```powershell
cd c:\Flutter_Project\ecopilot_test
flutter run -d edge
```

Navigate to **Notifications Screen** and toggle streak reminders on!

## How It Works

### User Journey Example

**Day 1 - New User**
```
8:00 AM → "Good morning! Start your eco journey today!"
         (User completes challenge)
         Streak = 1 ✅
```

**Day 7 - First Milestone**
```
8:00 AM → "Good morning! Keep your 7-day streak alive!"
         (User completes challenge)
         🎉 INSTANT: "7-Day Streak Milestone!"
         Streak = 7 ✅
```

**Day 15 - At Risk**
```
8:00 AM → "Good morning! Your 15-day streak!"
9:00 PM → Server checks - no completion yet
         🔔 PUSH: "Your 15-day streak is at risk!"
10:00 PM → "LAST CHANCE! 2 hours left!"
         (User completes challenge)
         Streak = 15 ✅
```

**Day 18 - Inactive**
```
(User hasn't opened app for 3 days)
10:00 AM → 🔔 PUSH: "We miss you! You had a 15-day streak!"
```

## Notification Schedule

| Time | Type | Trigger | Message |
|------|------|---------|---------|
| **8:00 AM** | Local | Daily | Morning encouragement |
| **12:00 PM** | Local | Daily | Mid-day reminder |
| **6:00 PM** | Local | Daily | Evening warning |
| **9:00 PM** | Server | If incomplete | Streak at risk alert |
| **10:00 PM** | Local | Daily | Last chance reminder |
| **10:00 AM** | Server | If inactive 3+ days | Re-engagement |
| **Instant** | Server | On milestone | Celebration |

## User Controls

Users can toggle each notification type from the **Notifications Screen**:

```
Streak Reminders
├─ Morning Boost (8:00 AM)      [ON/OFF]
├─ Mid-Day Check (12:00 PM)     [ON/OFF]
├─ Evening Warning (6:00 PM)    [ON/OFF]
└─ Last Chance (10:00 PM)       [ON/OFF]
```

## Testing Commands

### Test Local Notification
```dart
// Add to your test screen
await StreakNotificationManager().scheduleMorningEncouragement();
```

### Test Push Notification
```bash
# Replace with your Cloud Function URL and user ID
curl "https://REGION-PROJECT.cloudfunctions.net/manualStreakCheck?userId=USER_ID"
```

### Check Scheduled Notifications
```dart
final pending = await NotificationService().pending();
print('Scheduled: ${pending.length} notifications');
```

### View FCM Token
```dart
final token = FCMService().fcmToken;
print('FCM Token: $token');
```

## Customization Examples

### Change Notification Time
```dart
// In streak_notification_manager.dart
await NotificationService().scheduleDaily(
  hour: 9,  // Change to 9:00 AM
  minute: 30, // At 9:30 AM
  // ...
);
```

### Add New Milestone
```dart
bool _isMilestone(int streak) {
  return streak == 7 || 
         streak == 14 || 
         streak == 21 ||  // ✨ Add 3-week milestone
         // ...
}
```

### Adjust Server Timing
```javascript
// In functions/streak_notifications.js
.schedule('0 20 * * *') // 8:00 PM instead of 9:00 PM
```

## Troubleshooting

### ❌ Notifications Not Showing

**Check permissions:**
```dart
final settings = await FirebaseMessaging.instance.getNotificationSettings();
print('Status: ${settings.authorizationStatus}');
```

**Check scheduled:**
```dart
final pending = await NotificationService().pending();
print('Pending: ${pending.length}');
```

### ❌ Push Notifications Not Working

**Check FCM token:**
```dart
final token = FCMService().fcmToken;
print('Token: $token'); // Should not be null
```

**Check Firestore:**
```
users/{uid}
  └─ fcmToken: "your-token-here" ✅
```

### ❌ Cloud Functions Not Deploying

```powershell
# Check functions
firebase functions:list

# View logs
firebase functions:log

# Redeploy
firebase deploy --only functions --force
```

## Files Created

```
lib/services/
├─ streak_notification_manager.dart  ✅ Local notification logic
├─ fcm_service.dart                  ✅ FCM push notification handler
└─ notification_service.dart         (already exists)

lib/screens/
└─ notification_screen.dart          ✅ Updated with streak controls

functions/
├─ streak_notifications.js           ✅ Cloud Functions for server triggers
└─ index.js                          (export functions here)

Documentation/
├─ TIKTOK_STREAK_REMINDERS.md       ✅ Full documentation
└─ QUICK_START_STREAK_REMINDERS.md  ✅ This file
```

## Next Steps

1. ✅ Test local notifications (should work immediately)
2. ⏳ Deploy Cloud Functions for server-triggered notifications
3. ⏳ Test push notifications with manual trigger
4. ⏳ Monitor user engagement analytics
5. ⏳ Adjust notification messages based on user feedback

## Support

- **Local Notifications**: Check device notification settings
- **Push Notifications**: Verify Firebase Cloud Messaging is enabled
- **Cloud Functions**: Check Firebase Console → Functions tab
- **Debugging**: Enable debug mode and check logs

---

**Ready to launch!** 🚀  
Your users will now get TikTok-style streak reminders to keep them engaged!

**Created**: December 5, 2025  
**Version**: 1.0.0
