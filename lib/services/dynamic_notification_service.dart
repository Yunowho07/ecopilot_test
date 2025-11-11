import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/notification_screen.dart';

/// Dynamic Notification Service
/// Handles real-time notifications using:
/// - Firebase Cloud Messaging (FCM) for push notifications
/// - Firestore listeners for real-time updates
/// - Local notifications for scheduled reminders
/// - Automatic triggers based on user activity
class DynamicNotificationService {
  DynamicNotificationService._();

  static final DynamicNotificationService _instance =
      DynamicNotificationService._();
  factory DynamicNotificationService() => _instance;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot>? _notificationListener;
  bool _initialized = false;

  static const String _prefsKey = 'app_notifications_v1';
  static const String _fcmTokenKey = 'fcm_token';

  /// Initialize the dynamic notification system
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Initialize FCM
      await _initializeFCM();

      // 2. Initialize Local Notifications
      await _initializeLocalNotifications();

      // 3. Listen to Firestore for new notifications
      _listenToFirestoreNotifications();

      // 4. Handle background/terminated state messages
      _setupBackgroundMessageHandler();

      _initialized = true;
      debugPrint('✅ Dynamic Notification Service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    // Request permission (iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('📱 FCM Permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('🔑 FCM Token: $token');
        await _saveFCMToken(token);
        await _updateUserFCMToken(token);
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed: $newToken');
        _saveFCMToken(newToken);
        _updateUserFCMToken(newToken);
      });
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Initialize Local Notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );
  }

  /// Setup background message handler
  void _setupBackgroundMessageHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Listen to Firestore notifications collection for real-time updates
  void _listenToFirestoreNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('⚠️ User not logged in, skipping Firestore listener');
      return;
    }

    // Listen to user-specific notifications
    _notificationListener = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen(
          (snapshot) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                _handleFirestoreNotification(change.doc);
              }
            }
          },
          onError: (error) {
            debugPrint('❌ Firestore listener error: $error');
          },
        );

    debugPrint('👂 Listening to Firestore notifications for user: $userId');
  }

  /// Handle Firestore notification document
  Future<void> _handleFirestoreNotification(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final title = data['title'] as String? ?? 'EcoPilot';
      final body = data['body'] as String? ?? 'New notification';
      final category = data['category'] as String? ?? 'general';
      final notificationData = data['data'] as Map<String, dynamic>?;

      // Save to local storage
      await _saveNotificationLocally(
        id: doc.id,
        category: category,
        title: title,
        body: body,
        data: notificationData,
      );

      // Show local notification
      await _showLocalNotification(
        id: doc.id.hashCode,
        title: title,
        body: body,
        payload: jsonEncode({'docId': doc.id, 'category': category}),
      );

      debugPrint('📬 New Firestore notification: $title');
    } catch (e) {
      debugPrint('❌ Error handling Firestore notification: $e');
    }
  }

  /// Handle foreground FCM message
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📨 Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification != null) {
      // Show local notification
      await _showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? 'EcoPilot',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
      );

      // Save to local storage
      await _saveNotificationLocally(
        id:
            message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        category: message.data['category'] ?? 'general',
        title: notification.title ?? 'EcoPilot',
        body: notification.body ?? '',
        data: message.data,
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.notification?.title}');
    // Navigate to appropriate screen based on message data
    // This will be handled by the app's navigation system
  }

  /// Handle local notification tap
  void _handleLocalNotificationTap(NotificationResponse response) {
    debugPrint('👆 Local notification tapped: ${response.payload}');
    // Navigate based on payload
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ecopilot_dynamic',
      'Dynamic Notifications',
      channelDescription: 'Real-time EcoPilot notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// Save notification to local storage
  Future<void> _saveNotificationLocally({
    required String id,
    required String category,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);

      List<AppNotification> notifications = [];
      if (raw != null) {
        try {
          final List parsed = jsonDecode(raw) as List;
          notifications = parsed
              .map(
                (e) => AppNotification.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
        } catch (e) {
          debugPrint('Error parsing saved notifications: $e');
        }
      }

      // Add new notification
      final notification = AppNotification(
        id: id,
        category: _parseCategory(category),
        title: title,
        body: body,
        time: DateTime.now(),
        read: false,
        data: data,
      );

      notifications.insert(0, notification);

      // Keep only last 100 notifications
      if (notifications.length > 100) {
        notifications = notifications.sublist(0, 100);
      }

      // Save back
      final encoded = jsonEncode(notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_prefsKey, encoded);

      debugPrint('💾 Notification saved locally: $title');
    } catch (e) {
      debugPrint('❌ Error saving notification locally: $e');
    }
  }

  /// Parse category string to enum
  NotificationCategory _parseCategory(String category) {
    switch (category.toLowerCase()) {
      case 'dailychallenge':
      case 'daily_challenge':
        return NotificationCategory.dailyChallenge;
      case 'ecotip':
      case 'eco_tip':
        return NotificationCategory.ecoTip;
      case 'milestone':
        return NotificationCategory.milestone;
      case 'scaninsight':
      case 'scan_insight':
        return NotificationCategory.scanInsight;
      case 'localalert':
      case 'local_alert':
        return NotificationCategory.localAlert;
      default:
        return NotificationCategory.ecoTip;
    }
  }

  /// Save FCM token to local storage
  Future<void> _saveFCMToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }

  /// Update user's FCM token in Firestore
  Future<void> _updateUserFCMToken(String token) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ FCM token updated in Firestore');
    } catch (e) {
      debugPrint('❌ Error updating FCM token: $e');
    }
  }

  /// Send notification to Firestore (triggers Cloud Function)
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String category,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'category': category,
        'data': data ?? {},
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Notification sent to Firestore: $title');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  /// Trigger milestone notification
  Future<void> triggerMilestoneNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      category: 'milestone',
      data: data,
    );
  }

  /// Trigger scan insight notification
  Future<void> triggerScanInsightNotification({
    required String productName,
    required int ecoScore,
    Map<String, dynamic>? data,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    String body;
    if (ecoScore >= 80) {
      body =
          '🌟 Great choice! $productName has an excellent eco-score of $ecoScore/100!';
    } else if (ecoScore >= 60) {
      body =
          '✅ Good pick! $productName scored $ecoScore/100. Consider eco-friendly alternatives!';
    } else {
      body =
          '⚠️ $productName has a low eco-score of $ecoScore/100. Check suggestions for greener options!';
    }

    await sendNotificationToUser(
      userId: userId,
      title: 'Scan Insight',
      body: body,
      category: 'scan_insight',
      data: data,
    );
  }

  /// Trigger daily challenge notification
  Future<void> triggerDailyChallengeNotification({
    required String challengeTitle,
    required int points,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await sendNotificationToUser(
      userId: userId,
      title: 'New Daily Challenge!',
      body: '🌞 $challengeTitle - Complete it to earn +$points points!',
      category: 'daily_challenge',
      data: {'challengeTitle': challengeTitle, 'points': points},
    );
  }

  /// Dispose listeners
  void dispose() {
    _notificationListener?.cancel();
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    debugPrint('✅ Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    debugPrint('✅ Unsubscribed from topic: $topic');
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message: ${message.notification?.title}');
  // Handle background message
}
