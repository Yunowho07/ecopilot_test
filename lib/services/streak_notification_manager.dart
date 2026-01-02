import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import '../utils/constants.dart';

/// Manages streak-based notifications similar to TikTok's engagement system.
///
/// Features:
/// - Daily encouragement notifications
/// - Streak warning alerts (when user hasn't completed today's challenge)
/// - Milestone celebrations (7, 14, 30, 100 day streaks)
/// - Re-engagement notifications for inactive users
/// - Last-minute reminders (before day ends)
class StreakNotificationManager {
  StreakNotificationManager._();

  static final StreakNotificationManager _instance =
      StreakNotificationManager._();
  factory StreakNotificationManager() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Notification IDs (must be unique)
  static const int _morningEncouragementId = 2000;
  static const int _midDayReminderId = 2001;
  static const int _eveningWarningId = 2002;
  static const int _lastChanceReminderId = 2003;
  static const int _milestoneId = 2004;
  // Re-engagement notification ID reserved for future use
  // static const int _reEngagementId = 2005;

  // Preferences keys
  static const String _prefKeyMorningEnabled = 'streak_notif_morning_enabled';
  static const String _prefKeyMidDayEnabled = 'streak_notif_midday_enabled';
  static const String _prefKeyEveningEnabled = 'streak_notif_evening_enabled';
  static const String _prefKeyLastChanceEnabled =
      'streak_notif_lastchance_enabled';
  static const String _prefKeyMilestoneEnabled =
      'streak_notif_milestone_enabled';
  static const String _prefKeyReEngagementEnabled =
      'streak_notif_reengagement_enabled';

  /// Initialize all streak notifications based on user preferences
  Future<void> initializeStreakNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Schedule each notification type if enabled
      if (prefs.getBool(_prefKeyMorningEnabled) ?? true) {
        await scheduleMorningEncouragement();
      }

      if (prefs.getBool(_prefKeyMidDayEnabled) ?? true) {
        await scheduleMidDayReminder();
      }

      if (prefs.getBool(_prefKeyEveningEnabled) ?? true) {
        await scheduleEveningWarning();
      }

      if (prefs.getBool(_prefKeyLastChanceEnabled) ?? true) {
        await scheduleLastChanceReminder();
      }

      debugPrint('✅ Streak notifications initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize streak notifications: $e');
    }
  }

  /// Schedule daily morning encouragement (8:00 AM)
  /// "Good morning! 🌞 Start your day with today's eco challenge!"
  Future<void> scheduleMorningEncouragement() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get current streak
      final streak = await _getCurrentStreak(user.uid);

      String message;
      if (streak == 0) {
        message = "Good morning! 🌞 Start your eco journey today!";
      } else if (streak < 7) {
        message = "Good morning! 🌱 Keep your $streak-day streak alive!";
      } else if (streak < 30) {
        message = "Good morning! 🔥 Amazing $streak-day streak! Keep it going!";
      } else {
        message =
            "Good morning! 🏆 Legendary $streak-day streak! You're inspiring!";
      }

      await NotificationService().scheduleDaily(
        id: _morningEncouragementId,
        title: 'Daily Eco Challenge',
        body: message,
        hour: 8,
        minute: 0,
        color: kPrimaryGreen,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyMorningEnabled, true);

      debugPrint('✅ Scheduled morning encouragement (8:00 AM)');
    } catch (e) {
      debugPrint('❌ Failed to schedule morning encouragement: $e');
    }
  }

  /// Schedule mid-day reminder (12:00 PM)
  /// "Don't forget your eco challenge! ♻️"
  Future<void> scheduleMidDayReminder() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final streak = await _getCurrentStreak(user.uid);

      String message;
      if (streak == 0) {
        message =
            "Start your first streak today! Complete your eco challenge now 🌍";
      } else if (streak == 1) {
        message = "Keep it going! Complete today's challenge to reach day 2 🌱";
      } else {
        message =
            "Don't lose your $streak-day streak! Complete today's challenge 🔥";
      }

      await NotificationService().scheduleDaily(
        id: _midDayReminderId,
        title: 'Streak Reminder',
        body: message,
        hour: 12,
        minute: 0,
        color: kPrimaryGreen,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyMidDayEnabled, true);

      debugPrint('✅ Scheduled mid-day reminder (12:00 PM)');
    } catch (e) {
      debugPrint('❌ Failed to schedule mid-day reminder: $e');
    }
  }

  /// Schedule evening warning (6:00 PM)
  /// "Your streak is at risk! ⚠️ Complete today's challenge before midnight."
  Future<void> scheduleEveningWarning() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final streak = await _getCurrentStreak(user.uid);

      String message;
      if (streak == 0) {
        message = "Evening reminder! Complete your eco challenge before bed 🌙";
      } else if (streak == 1) {
        message = "Your 1-day streak is waiting! Don't let it reset ⚠️";
      } else if (streak < 7) {
        message =
            "⚠️ Your $streak-day streak is at risk! Complete today's challenge now!";
      } else {
        message = "🚨 Don't lose your amazing $streak-day streak! Act now!";
      }

      await NotificationService().scheduleDaily(
        id: _eveningWarningId,
        title: 'Streak Warning',
        body: message,
        hour: 18,
        minute: 0,
        color: kPrimaryGreen,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyEveningEnabled, true);

      debugPrint('✅ Scheduled evening warning (6:00 PM)');
    } catch (e) {
      debugPrint('❌ Failed to schedule evening warning: $e');
    }
  }

  /// Schedule last chance reminder (10:00 PM)
  /// "Last chance! Complete your challenge in the next 2 hours! 🕙"
  Future<void> scheduleLastChanceReminder() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final streak = await _getCurrentStreak(user.uid);

      String message;
      if (streak == 0) {
        message =
            "Last chance to start your eco journey today! 2 hours left 🕙";
      } else if (streak < 7) {
        message = "🕙 LAST CHANCE! Your $streak-day streak ends in 2 hours!";
      } else {
        message =
            "🚨 URGENT! Your epic $streak-day streak ends in 2 hours! Don't give up now!";
      }

      await NotificationService().scheduleDaily(
        id: _lastChanceReminderId,
        title: 'Final Reminder',
        body: message,
        hour: 22,
        minute: 0,
        color: kPrimaryGreen,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyLastChanceEnabled, true);

      debugPrint('✅ Scheduled last chance reminder (10:00 PM)');
    } catch (e) {
      debugPrint('❌ Failed to schedule last chance reminder: $e');
    }
  }

  /// Show immediate milestone celebration notification
  /// Called when user reaches 7, 14, 30, 50, 100, 200 day streaks
  Future<void> showMilestoneCelebration(int streak) async {
    if (!_isMilestone(streak)) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_prefKeyMilestoneEnabled) ?? true;
      if (!enabled) return;

      String title;
      String message;

      switch (streak) {
        case 7:
          title = '🔥 7-Day Streak!';
          message =
              'One week of eco-consciousness! You\'re building a great habit!';
          break;
        case 14:
          title = '🌟 2-Week Streak!';
          message = 'Two weeks strong! You\'re making a real difference!';
          break;
        case 30:
          title = '🏆 1-Month Streak!';
          message = 'A full month! You\'re an eco champion! Keep going!';
          break;
        case 50:
          title = '💎 50-Day Streak!';
          message = '50 days of consistency! You\'re unstoppable!';
          break;
        case 100:
          title = '👑 100-Day Streak!';
          message =
              'LEGENDARY! 100 days of dedication! You\'re inspiring the planet!';
          break;
        case 200:
          title = '🌍 200-Day Streak!';
          message = 'WORLD-CLASS! 200 days! You\'re a true eco warrior!';
          break;
        default:
          title = '🎉 $streak-Day Streak!';
          message = 'Keep up the amazing work!';
      }

      await NotificationService().showImmediate(
        id: _milestoneId,
        title: title,
        body: message,
        payload: 'milestone_$streak',
      );

      debugPrint('🎉 Milestone notification sent for $streak-day streak');
    } catch (e) {
      debugPrint('❌ Failed to show milestone celebration: $e');
    }
  }

  /// Cancel all streak notifications
  Future<void> cancelAllStreakNotifications() async {
    try {
      await NotificationService().cancel(_morningEncouragementId);
      await NotificationService().cancel(_midDayReminderId);
      await NotificationService().cancel(_eveningWarningId);
      await NotificationService().cancel(_lastChanceReminderId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyMorningEnabled, false);
      await prefs.setBool(_prefKeyMidDayEnabled, false);
      await prefs.setBool(_prefKeyEveningEnabled, false);
      await prefs.setBool(_prefKeyLastChanceEnabled, false);

      debugPrint('✅ Cancelled all streak notifications');
    } catch (e) {
      debugPrint('❌ Failed to cancel streak notifications: $e');
    }
  }

  /// Cancel specific notification type
  Future<void> cancelNotification(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      switch (type) {
        case 'morning':
          await NotificationService().cancel(_morningEncouragementId);
          await prefs.setBool(_prefKeyMorningEnabled, false);
          break;
        case 'midday':
          await NotificationService().cancel(_midDayReminderId);
          await prefs.setBool(_prefKeyMidDayEnabled, false);
          break;
        case 'evening':
          await NotificationService().cancel(_eveningWarningId);
          await prefs.setBool(_prefKeyEveningEnabled, false);
          break;
        case 'lastchance':
          await NotificationService().cancel(_lastChanceReminderId);
          await prefs.setBool(_prefKeyLastChanceEnabled, false);
          break;
      }

      debugPrint('✅ Cancelled $type notification');
    } catch (e) {
      debugPrint('❌ Failed to cancel $type notification: $e');
    }
  }

  /// Check if all streak notifications are enabled
  Future<Map<String, bool>> getNotificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'morning': prefs.getBool(_prefKeyMorningEnabled) ?? true,
      'midday': prefs.getBool(_prefKeyMidDayEnabled) ?? true,
      'evening': prefs.getBool(_prefKeyEveningEnabled) ?? true,
      'lastchance': prefs.getBool(_prefKeyLastChanceEnabled) ?? true,
      'milestone': prefs.getBool(_prefKeyMilestoneEnabled) ?? true,
      'reengagement': prefs.getBool(_prefKeyReEngagementEnabled) ?? true,
    };
  }

  /// Toggle milestone notifications on/off
  Future<void> toggleMilestoneNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyMilestoneEnabled, enabled);
    debugPrint('✅ Milestone notifications ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Get current user streak from Firestore
  Future<int> _getCurrentStreak(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      if (data == null) return 0;

      final streak = data['streak'] ?? 0;
      final lastChallengeDate = data['lastChallengeDate'] as String?;

      // Validate streak
      if (streak > 0 && lastChallengeDate != null) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final yesterday = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now().subtract(const Duration(days: 1)));

        // If last completion was not today or yesterday, streak should be 0
        if (lastChallengeDate != today && lastChallengeDate != yesterday) {
          return 0;
        }
      }

      return streak;
    } catch (e) {
      debugPrint('❌ Failed to get current streak: $e');
      return 0;
    }
  }

  /// Check if streak value is a milestone
  bool _isMilestone(int streak) {
    return streak == 7 ||
        streak == 14 ||
        streak == 30 ||
        streak == 50 ||
        streak == 100 ||
        streak == 200;
  }

  /// Check if user completed today's challenge
  Future<bool> hasCompletedTodaysChallenge(String uid) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final doc = await _firestore
          .collection('user_challenges')
          .doc('$uid-$today')
          .get();

      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      final completed = data['completed'] as List<dynamic>?;
      if (completed == null || completed.isEmpty) return false;

      // Check if all challenges are completed
      return completed.every((c) => c == true);
    } catch (e) {
      debugPrint('❌ Failed to check today\'s challenge completion: $e');
      return false;
    }
  }
}
