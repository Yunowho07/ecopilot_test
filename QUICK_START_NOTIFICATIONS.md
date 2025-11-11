# Quick Start: Dynamic Notifications 🚀

## ⚡ 5-Minute Setup

### **Step 1: Install (Already Done!)**
```bash
flutter pub get  # ✅ Done - firebase_messaging installed
```

### **Step 2: Initialize in Your App**

Add to `lib/main.dart`:

```dart
import 'package:ecopilot_test/services/dynamic_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 🔔 Initialize Dynamic Notifications
  await DynamicNotificationService().initialize();
  
  runApp(const MyApp());
}
```

### **Step 3: Deploy Cloud Functions**
```bash
cd functions
npm install
firebase deploy --only functions
```

### **Step 4: Test It!**
```bash
flutter run
```

---

## 🎯 What You Get Immediately

### **Automatic Notifications For:**

1. ✅ **Streak Milestones** (3, 7, 30, 100 days)
2. ✅ **Points Milestones** (100, 250, 500, 1000+)
3. ✅ **Product Scans** (eco-score feedback)
4. ✅ **Rank Achievements** (level up)
5. ✅ **Daily Challenges** (8 AM reminder)
6. ✅ **Eco Tips** (12 PM daily)

---

## 📱 How to Trigger Test Notifications

### **Method 1: From Code**
```dart
// In any screen, add a test button:
ElevatedButton(
  onPressed: () async {
    await DynamicNotificationService().triggerMilestoneNotification(
      title: 'Test Achievement! 🏆',
      body: 'You just tested a notification!',
    );
  },
  child: Text('Test Notification'),
)
```

### **Method 2: From Firestore Console**
1. Go to Firebase Console → Firestore
2. Open `users` collection
3. Find your user document
4. Update `streak` to `7`
5. → Notification triggers automatically!

### **Method 3: From Cloud Functions**
```bash
# Update user streak
firebase firestore:update users/YOUR_USER_ID "streak=7"

# View logs
firebase functions:log
```

---

## 🔍 Quick Troubleshooting

### **No notifications showing?**

**Check 1: FCM Token**
```dart
// Add this in your app
String? token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');
```

**Check 2: Permissions**
- Android: Granted automatically
- iOS: Check Settings → Notifications → EcoPilot

**Check 3: Firestore**
- Go to Firebase Console → Firestore
- Check if `notifications` collection exists
- Check if your user has `fcmToken` field

---

## 📊 See It Working

### **Console Logs to Look For:**
```
✅ Dynamic Notification Service initialized
📱 FCM Permission: authorized
🔑 FCM Token: fR3D5g7H...
👂 Listening to Firestore notifications for user: abc123
📬 New Firestore notification: 7-Day Streak!
```

### **Firebase Console:**
1. Cloud Messaging → View tokens (see your device)
2. Firestore → `notifications` → See real-time docs
3. Functions → Logs → See trigger activity

---

## 🎨 Customize Notification Times

Edit `functions/dynamic_notifications.js`:

```javascript
// Change daily challenge time
exports.sendDailyChallengeReminder = functions.pubsub
  .schedule('every day 07:00')  // ← Change this
  .timeZone('America/New_York')  // ← Change this
  ...

// Change eco tip time
exports.sendDailyEcoTip = functions.pubsub
  .schedule('every day 18:00')  // ← Change this
  .timeZone('America/New_York')  // ← Change this
  ...
```

Then redeploy:
```bash
firebase deploy --only functions
```

---

## 🔔 Notification Examples

### **What Users See:**

#### **Morning (8 AM):**
```
📬 Today's Eco Challenge! 🌞
"Complete today's challenge and earn +20 points!"
```

#### **After Scanning:**
```
📬 Excellent Choice! 🌟
"Organic Almond Milk has an eco-score of 85/100!"
```

#### **7-Day Streak:**
```
📬 7-Day Streak! 🔥
"Amazing! You've earned the 'Week Warrior' badge!"
```

---

## ⚙️ Advanced Features

### **Subscribe to Topics:**
```dart
// All users get general announcements
await DynamicNotificationService().subscribeToTopic('general');

// Premium users get exclusive tips
await DynamicNotificationService().subscribeToTopic('premium_tips');
```

### **Send Custom Notification:**
```dart
await DynamicNotificationService().sendNotificationToUser(
  userId: 'user123',
  title: 'Custom Notification',
  body: 'Your custom message',
  category: 'general',
  data: {'key': 'value'},
);
```

### **Broadcast to All Users:**
```dart
// Call Cloud Function (requires admin auth)
await FirebaseFunctions.instance
  .httpsCallable('sendBroadcastNotification')
  .call({
    'title': 'New Feature!',
    'body': 'Check out our latest eco-challenge!',
    'category': 'local_alert',
  });
```

---

## 📱 Platform-Specific Setup

### **Android (Optional Configuration)**

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
  ...
  <!-- Notification Icon -->
  <meta-data
      android:name="com.google.firebase.messaging.default_notification_icon"
      android:resource="@mipmap/ic_launcher" />

  <!-- Notification Color -->
  <meta-data
      android:name="com.google.firebase.messaging.default_notification_color"
      android:resource="@color/colorPrimary" />

  <!-- Notification Channel -->
  <meta-data
      android:name="com.google.firebase.messaging.default_notification_channel_id"
      android:value="ecopilot_dynamic" />
</application>
```

### **iOS (Required Configuration)**

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Go to "Signing & Capabilities"
4. Add "+ Capability"
5. Add "Push Notifications"
6. Add "Background Modes" → Check "Remote notifications"

---

## 📈 Monitoring & Analytics

### **Check Notification Delivery:**
```bash
# View Cloud Function logs
firebase functions:log --only onStreakMilestone

# View all notification logs
firebase functions:log | grep "notification"
```

### **Track Engagement:**
```dart
// Count unread notifications
final unreadCount = await FirebaseFirestore.instance
  .collection('notifications')
  .where('userId', isEqualTo: userId)
  .where('read', isEqualTo: false)
  .count()
  .get();

print('Unread: ${unreadCount.count}');
```

---

## 🎯 Next Steps

1. **Test locally** with `flutter run`
2. **Deploy Cloud Functions** with `firebase deploy`
3. **Monitor logs** for first notification
4. **Customize times** to match your timezone
5. **Track metrics** to optimize engagement

---

## 📚 Full Documentation

- **Complete Guide:** `DYNAMIC_NOTIFICATIONS_GUIDE.md`
- **Implementation Summary:** `DYNAMIC_NOTIFICATIONS_SUMMARY.md`
- **Service Code:** `lib/services/dynamic_notification_service.dart`
- **Cloud Functions:** `functions/dynamic_notifications.js`

---

## ✅ You're Ready!

Your app now has **world-class dynamic notifications**! 🎉

Users will receive:
- ✅ Real-time achievement celebrations
- ✅ Daily eco-tips and challenges
- ✅ Instant scan feedback
- ✅ Motivational milestones

All **completely automatic** - no manual work needed! 🚀✨

---

**Questions?** Check the full guide: `DYNAMIC_NOTIFICATIONS_GUIDE.md`
