import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'streak_notification_manager.dart';

/// Handle Firebase Cloud Messaging (FCM) push notifications
///
/// This service enables server-triggered notifications for:
/// - Streak warnings when user is about to lose their streak
/// - Re-engagement notifications for inactive users
/// - Real-time milestone celebrations
/// - Dynamic personalized messages based on user behavior
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message received: ${message.messageId}');
  debugPrint('Notification: ${message.notification?.title}');
  debugPrint('Data: ${message.data}');
}

class FCMService {
  FCMService._();

  static final FCMService _instance = FCMService._();
  factory FCMService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission for iOS
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ FCM permission granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('⚠️ FCM provisional permission granted');
      } else {
        debugPrint('❌ FCM permission denied');
        return;
      }

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        debugPrint('✅ FCM Token: $_fcmToken');
        await _saveTokenToFirestore(_fcmToken!);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveTokenToFirestore(newToken);
        debugPrint('🔄 FCM Token refreshed: $newToken');
      });

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
      debugPrint('✅ FCM Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize FCM: $e');
    }
  }

  /// Save FCM token to Firestore for server-side notifications
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ FCM token saved to Firestore');
    } catch (e) {
      debugPrint('❌ Failed to save FCM token: $e');
    }
  }

  /// Handle messages received while app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Foreground message received: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      // Show local notification when app is in foreground
      await _showLocalNotification(
        title: notification.title ?? 'EcoPilot',
        body: notification.body ?? '',
        payload: data['type'] ?? '',
      );

      // Handle streak-specific notifications
      await _handleStreakNotification(data);
    }
  }

  /// Handle notification tap (when user opens notification)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped: ${message.messageId}');

    final data = message.data;
    final type = data['type'];

    // Navigate based on notification type
    switch (type) {
      case 'streak_warning':
      case 'streak_milestone':
      case 'daily_challenge':
        // Navigate to daily challenge screen
        debugPrint('➡️ Navigate to Daily Challenge screen');
        break;
      case 're_engagement':
        // Navigate to home screen
        debugPrint('➡️ Navigate to Home screen');
        break;
      case 'leaderboard_update':
        // Navigate to leaderboard
        debugPrint('➡️ Navigate to Leaderboard screen');
        break;
      default:
        debugPrint('➡️ Navigate to Home screen (default)');
    }
  }

  /// Handle streak-specific notification logic
  Future<void> _handleStreakNotification(Map<String, dynamic> data) async {
    final type = data['type'];

    switch (type) {
      case 'streak_milestone':
        final streak = int.tryParse(data['streak'] ?? '0') ?? 0;
        if (streak > 0) {
          await StreakNotificationManager().showMilestoneCelebration(streak);
        }
        break;

      case 'streak_warning':
        debugPrint('⚠️ Streak warning received');
        // Could trigger additional UI feedback
        break;

      case 're_engagement':
        debugPrint('🔄 Re-engagement notification received');
        // Could show special offers or challenges
        break;
    }
  }

  /// Show local notification (for foreground messages)
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ecopilot.fcm',
      'Push Notifications',
      channelDescription: 'Server-triggered push notifications',
      importance: Importance.high,
      priority: Priority.high,
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

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Subscribe to streak reminder topic
  Future<void> subscribeToStreakReminders() async {
    try {
      await _messaging.subscribeToTopic('streak_reminders');
      debugPrint('✅ Subscribed to streak reminders topic');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from streak reminder topic
  Future<void> unsubscribeFromStreakReminders() async {
    try {
      await _messaging.unsubscribeFromTopic('streak_reminders');
      debugPrint('✅ Unsubscribed from streak reminders topic');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from topic: $e');
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if FCM is initialized
  bool get isInitialized => _initialized;
}
