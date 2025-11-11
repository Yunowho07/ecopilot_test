# Dynamic Notifications System 🔔✨

## Complete Implementation Guide

### **Overview**
This system implements real-time, personalized notifications using Firebase Cloud Messaging (FCM), Firestore, and Cloud Functions to keep users engaged with their eco-journey!

---

## 🎯 **Features Implemented**

### **1. Real-Time Push Notifications** 📱
- Firebase Cloud Messaging (FCM) for instant delivery
- Works in foreground, background, and terminated states
- iOS and Android support

### **2. Firestore-Driven Notifications** 🔥
- Real-time listeners for instant updates
- Persistent storage in `notifications` collection
- User-specific notification streams

### **3. Auto-Triggered Notifications** 🤖
- **Streak Milestones** (3, 7, 30, 100 days)
- **Points Milestones** (100, 250, 500, 1000+ points)
- **Scan Insights** (eco-score feedback)
- **Rank Achievements** (level up notifications)
- **Daily Challenges** (8 AM reminder)
- **Eco Tips** (12 PM daily tip)

### **4. Local Notifications** 📬
- Scheduled daily reminders
- Instant visual feedback
- Custom categories and icons

---

## 📦 **What's Been Added**

### **New Files Created:**

#### **1. `lib/services/dynamic_notification_service.dart`**
- Complete FCM integration
- Firestore listener for real-time notifications
- Local notification display
- Background message handling
- FCM token management

#### **2. `functions/dynamic_notifications.js`**
- Cloud Functions for auto-triggers:
  - `onStreakMilestone` - Triggers on streak achievements
  - `onPointsMilestone` - Triggers on point milestones
  - `onProductScanned` - Triggers when scanning products
  - `onRankUpdate` - Triggers on rank changes
  - `sendDailyChallengeReminder` - Scheduled daily at 8 AM
  - `sendDailyEcoTip` - Scheduled daily at 12 PM
  - `sendBroadcastNotification` - Admin broadcast function

### **Updated Files:**

#### **1. `pubspec.yaml`**
- Added `firebase_messaging: ^15.1.5`

---

## 🚀 **Installation Steps**

### **Step 1: Install Dependencies**
```bash
cd C:\Flutter_Project\ecopilot_test
flutter pub get
```

### **Step 2: Configure Firebase Cloud Messaging**

#### **For Android:**
1. Open `android/app/src/main/AndroidManifest.xml`
2. Add inside `<application>` tag:
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="ecopilot_dynamic" />

<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@mipmap/ic_launcher" />

<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/colorPrimary" />
```

3. Add notification permissions:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

#### **For iOS:**
1. Open `ios/Runner/Info.plist`
2. Request notification permissions (already handled in code)
3. Enable Push Notifications in Xcode:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner target
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add "Push Notifications"
   - Add "Background Modes" and check "Remote notifications"

### **Step 3: Deploy Cloud Functions**
```bash
cd functions
npm install

# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:onStreakMilestone
```

### **Step 4: Initialize in Main App**

Update `lib/main.dart`:
```dart
import 'package:ecopilot_test/services/dynamic_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Dynamic Notifications
  await DynamicNotificationService().initialize();
  
  runApp(const MyApp());
}
```

### **Step 5: Subscribe to Topics (Optional)**
```dart
// Subscribe all users to general announcements
await DynamicNotificationService().subscribeToTopic('general');

// Subscribe based on user preferences
await DynamicNotificationService().subscribeToTopic('eco_tips');
await DynamicNotificationService().subscribeToTopic('challenges');
```

---

## 📊 **Firestore Structure**

### **Collection: `notifications`**
```javascript
{
  "userId": "abc123",
  "title": "7-Day Streak!",
  "body": "🎉 Amazing! You've earned the 'Week Warrior' badge!",
  "category": "milestone",
  "data": {
    "streak": 7,
    "badge": "🔥 Week Warrior"
  },
  "read": false,
  "timestamp": Timestamp,
  "createdAt": "2025-11-11T10:30:00.000Z"
}
```

### **User Document Fields (Added):**
```javascript
{
  ...existing fields...
  "fcmToken": "fR3D5g7H...",
  "fcmTokenUpdatedAt": Timestamp
}
```

---

## 🎨 **Notification Categories**

### **1. Daily Challenge** 🏆
- **Trigger:** Scheduled daily at 8 AM
- **Title:** "Today's Eco Challenge! 🌞"
- **Body:** "Complete today's challenge and earn +20 points!"
- **Icon:** Flag
- **Color:** Orange

### **2. Eco Tip** 💡
- **Trigger:** Scheduled daily at 12 PM
- **Title:** "Eco Tip of the Day 💡"
- **Body:** Random sustainability tip
- **Icon:** Lightbulb
- **Color:** Green

### **3. Milestone** 🎖️
- **Trigger:** Streak, points, or rank achievement
- **Examples:**
  - "3-Day Streak!"
  - "100 Points Milestone!"
  - "Rank Up to Eco Warrior!"
- **Icon:** Trophy
- **Color:** Amber

### **4. Scan Insight** 🔍
- **Trigger:** Product scanned
- **Title:** Based on eco-score
- **Body:** Personalized feedback
- **Icon:** QR Scanner
- **Color:** Teal

### **5. Local Alert** 📍
- **Trigger:** Manual/admin
- **Examples:** New features, events
- **Icon:** Location
- **Color:** Indigo

---

## 🔧 **How to Trigger Notifications**

### **From Code (Programmatically):**

#### **Milestone Notification:**
```dart
await DynamicNotificationService().triggerMilestoneNotification(
  title: 'Achievement Unlocked! 🏆',
  body: 'You\'ve completed 50 scans!',
  data: {'achievement': 'scanner_pro'},
);
```

#### **Scan Insight:**
```dart
await DynamicNotificationService().triggerScanInsightNotification(
  productName: 'Organic Almond Milk',
  ecoScore: 85,
  data: {'productId': 'abc123'},
);
```

#### **Daily Challenge:**
```dart
await DynamicNotificationService().triggerDailyChallengeNotification(
  challengeTitle: 'Use reusable bags',
  points: 20,
);
```

### **From Cloud Functions (Automatic):**

Notifications are automatically triggered when:

1. **User's streak increases** → `onStreakMilestone` fires
2. **User earns points** → `onPointsMilestone` fires
3. **User scans product** → `onProductScanned` fires
4. **User ranks up** → `onRankUpdate` fires
5. **Daily at 8 AM** → `sendDailyChallengeReminder` fires
6. **Daily at 12 PM** → `sendDailyEcoTip` fires

---

## 📱 **Testing Notifications**

### **Test 1: Local Notification**
```dart
// In notification_screen.dart or any screen
await DynamicNotificationService().showLocalNotification(
  id: 1,
  title: 'Test Notification',
  body: 'This is a test!',
  payload: '{"test": true}',
);
```

### **Test 2: Firestore Notification**
```dart
await DynamicNotificationService().sendNotificationToUser(
  userId: FirebaseAuth.instance.currentUser!.uid,
  title: 'Test Firestore Notification',
  body: 'Testing real-time updates!',
  category: 'general',
);
```

### **Test 3: Cloud Function Test**
```bash
# Test streak milestone (update user's streak)
firebase firestore:update users/YOUR_USER_ID "streak=7"

# View logs
firebase functions:log --only onStreakMilestone
```

### **Test 4: FCM Test Message**
Use Firebase Console:
1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter title and body
4. Select your app
5. Send test message to your device token

---

## 🎯 **User Flow Examples**

### **Example 1: New User Journey**
```
1. User signs up → FCM token saved to Firestore
2. User completes first scan → "Great start! +10 points" notification
3. User hits 100 points → "100 Points Milestone! 🎯" notification
4. Day 3 → "3-Day Streak! 🌱" notification
5. Daily at 8 AM → "Today's Eco Challenge" notification
6. Daily at 12 PM → "Eco Tip" notification
```

### **Example 2: Active User**
```
1. User scans low eco-score product → "Low Eco-Score ⚠️" notification
2. User completes challenge → Points increase → Check for milestone
3. User reaches 7-day streak → "7-Day Streak! 🔥 Week Warrior" notification
4. User ranks up → "Rank Up! 🎖️ Now Eco Warrior!" notification
```

---

## 🔍 **Debugging**

### **Check FCM Token:**
```dart
String? token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');
```

### **Check Firestore Listener:**
```dart
// In dynamic_notification_service.dart
// Debug logs show:
✅ Dynamic Notification Service initialized
📱 FCM Permission: authorized
🔑 FCM Token: fR3D5g7H...
👂 Listening to Firestore notifications for user: abc123
```

### **Check Cloud Function Logs:**
```bash
firebase functions:log
```

### **Common Issues:**

**1. Notifications not appearing:**
- Check FCM token is saved to Firestore
- Verify notification permissions granted
- Check Cloud Function logs for errors

**2. Firestore listener not working:**
- Ensure user is logged in
- Check Firestore security rules
- Verify collection name is correct

**3. Background notifications not showing:**
- Android: Check notification channel settings
- iOS: Verify Background Modes enabled in Xcode

---

## 📋 **Firestore Security Rules**

Add to `firestore.rules`:
```javascript
match /notifications/{notificationId} {
  // Users can only read their own notifications
  allow read: if request.auth != null && 
    resource.data.userId == request.auth.uid;
  
  // Only cloud functions can write
  allow write: if false;
}
```

---

## 🎨 **Customization**

### **Change Notification Schedule:**
```javascript
// In functions/dynamic_notifications.js
exports.sendDailyChallengeReminder = functions.pubsub
  .schedule('every day 07:00') // Change time here
  .timeZone('America/Los_Angeles') // Change timezone
  .onRun(...)
```

### **Add New Notification Category:**

1. **Update enum in `notification_screen.dart`:**
```dart
enum NotificationCategory {
  ...
  newFeature, // Add new category
}
```

2. **Add icon and color:**
```dart
IconData get icon {
  switch (this) {
    ...
    case NotificationCategory.newFeature:
      return Icons.new_releases;
  }
}
```

3. **Create Cloud Function:**
```javascript
exports.onNewFeature = functions.firestore
  .document('features/{featureId}')
  .onCreate(async (snapshot, context) => {
    // Send notification to all users
  });
```

---

## 📊 **Analytics & Monitoring**

### **Track Notification Metrics:**
```dart
// Count unread notifications
int unreadCount = await FirebaseFirestore.instance
  .collection('notifications')
  .where('userId', isEqualTo: userId)
  .where('read', isEqualTo: false)
  .count()
  .get()
  .then((snapshot) => snapshot.count);
```

### **Monitor Cloud Function Performance:**
```bash
firebase functions:log --only onStreakMilestone --limit 100
```

---

## 🚀 **Production Checklist**

- [ ] FCM configured for Android & iOS
- [ ] Cloud Functions deployed
- [ ] Firestore security rules updated
- [ ] Notification icons added
- [ ] Timezone configured correctly
- [ ] FCM token refresh handled
- [ ] Background mode enabled (iOS)
- [ ] Notification channels created (Android)
- [ ] Testing completed on both platforms
- [ ] Analytics integrated

---

## 📝 **Summary**

### **What Users Get:**
✅ **Real-time notifications** when they achieve milestones  
✅ **Daily reminders** for challenges and tips  
✅ **Instant feedback** on scanned products  
✅ **Motivation** through achievement notifications  
✅ **Engagement** with personalized messages  

### **What Happens Automatically:**
🤖 Streak milestone notifications (3, 7, 30, 100 days)  
🤖 Points milestone notifications (100, 250, 500, 1000+)  
🤖 Scan insight notifications (after every product scan)  
🤖 Rank up notifications (when user levels up)  
🤖 Daily challenge reminders (8 AM)  
🤖 Daily eco tips (12 PM)  

### **Technical Stack:**
- **Firebase Cloud Messaging** - Push notifications
- **Cloud Firestore** - Real-time database
- **Cloud Functions** - Automated triggers
- **Flutter Local Notifications** - In-app display
- **Scheduled Functions** - Daily reminders

---

## 🎉 **Result**

Users are now **constantly engaged** with personalized, timely notifications that:
- Celebrate their achievements 🏆
- Provide helpful tips 💡
- Give instant feedback 📊
- Motivate continued use 🔥
- Keep them connected 📱

The system runs **completely automatically** - no manual intervention needed! 🚀✨
