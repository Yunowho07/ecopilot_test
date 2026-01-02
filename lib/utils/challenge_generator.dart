// lib/utils/challenge_generator.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// A comprehensive challenge pool organized by category and difficulty
class ChallengeGenerator {
  // Challenge categories with varying point values
  static const Map<String, List<Map<String, dynamic>>> _challengePool = {
    'recycling': [
      {
        'title': 'Recycle all plastic waste generated today',
        'points': 10,
        'difficulty': 'medium',
        'icon': '♻️',
      },
      {
        'title': 'Separate and recycle paper, plastic, and glass',
        'points': 10,
        'difficulty': 'hard',
        'icon': '🗑️',
      },
      {
        'title': 'Clean and recycle 5 items before disposal',
        'points': 10,
        'difficulty': 'easy',
        'icon': '🧼',
      },
      {
        'title': 'Find a recycling center for electronic waste',
        'points': 10,
        'difficulty': 'medium',
        'icon': '🔌',
      },
      {
        'title': 'Compost your organic kitchen waste',
        'points': 10,
        'difficulty': 'easy',
        'icon': '🌿',
      },
    ],
    'transportation': [
      {
        'title': 'Use public transport or cycle for one trip',
        'points': 10,
        'difficulty': 'easy',
        'icon': '🚲',
      },
      {
        'title': 'Walk or bike to your destination today',
        'points': 10,
        'difficulty': 'medium',
        'icon': '🚶',
      },
      {
        'title': 'Carpool with friends or colleagues',
        'points': 10,
        'difficulty': 'easy',
        'icon': '🚗',
      },
      {
        'title': 'Avoid using a car for the entire day',
        'points': 10,
        'difficulty': 'hard',
        'icon': '🛑',
      },
      {
        'title': 'Take stairs instead of elevator 3 times',
        'points': 10,
        'difficulty': 'easy',
        'icon': '🪜',
      },
    ],
    'consumption': [
      {
        'title': 'Use a reusable water bottle instead of plastic',
        'points': 10,
        'difficulty': 'easy',
        'icon': '💧',
      },
      {
        'title': 'Bring your own shopping bag',
        'points': 10,
        'difficulty': 'easy',
        'icon': '🛍️',
      },
      {
        'title': 'Choose products with minimal packaging',
        'points': 10,
        'difficulty': 'medium',
        'icon': '📦',
      },
      {
        'title': 'Buy local or organic produce',
        'points': 10,
        'difficulty': 'medium',
        'icon': '🥬',
      },
      {
        'title': 'Avoid single-use plastics for the day',
        'points': 10,
        'difficulty': 'hard',
        'icon': '🚫',
      },
      {
        'title': 'Use a reusable coffee cup or mug',
        'points': 10,
        'difficulty': 'easy',
        'icon': '☕',
      },
    ],
    'energy': [
      {
        'title': 'Turn off lights in unused rooms',
        'points': 10,
        'difficulty': 'easy',
        'icon': '💡',
      },
      {
        'title': 'Unplug devices when not in use',
        'points': 10,
        'difficulty': 'easy',
        'icon': '🔌',
      },
      {
        'title': 'Take a 5-minute shower to save water',
        'points': 10,
        'difficulty': 'medium',
        'icon': '🚿',
      },
      {
        'title': 'Air-dry clothes instead of using dryer',
        'points': 10,
        'difficulty': 'medium',
        'icon': '👕',
      },
      {
        'title': 'Use natural light instead of artificial lighting',
        'points': 10,
        'difficulty': 'easy',
        'icon': '☀️',
      },
    ],
    'awareness': [
      {
        'title': 'Learn about one endangered species',
        'points': 10,
        'difficulty': 'easy',
        'icon': '🐼',
      },
      {
        'title': 'Share an eco-tip with 3 friends',
        'points': 10,
        'difficulty': 'medium',
        'icon': '📢',
      },
      {
        'title': 'Watch a documentary about sustainability',
        'points': 10,
        'difficulty': 'medium',
        'icon': '📺',
      },
      {
        'title': 'Research eco-friendly alternatives for daily products',
        'points': 10,
        'difficulty': 'easy',
        'icon': '🔍',
      },
      {
        'title': 'Join an online environmental community',
        'points': 10,
        'difficulty': 'easy',
        'icon': '🌍',
      },
    ],
    'food': [
      {
        'title': 'Have one plant-based meal today',
        'points': 10,
        'difficulty': 'easy',
        'icon': '🥗',
      },
      {
        'title': 'Avoid food waste - finish all meals',
        'points': 10,
        'difficulty': 'easy',
        'icon': '🍽️',
      },
      {
        'title': 'Cook at home instead of ordering takeout',
        'points': 10,
        'difficulty': 'medium',
        'icon': '👨‍🍳',
      },
      {
        'title': 'Buy imperfect produce to reduce waste',
        'points': 10,
        'difficulty': 'easy',
        'icon': '🥕',
      },
      {
        'title': 'Meal prep to reduce packaging waste',
        'points': 10,
        'difficulty': 'medium',
        'icon': '🍱',
      },
    ],
  };

  /// Generate 2 unique challenges for a given date
  /// Returns a list of challenge maps suitable for Firestore
  static List<Map<String, dynamic>> generateDailyChallenges(DateTime date) {
    final List<Map<String, dynamic>> allChallenges = [];

    // Flatten all challenges from all categories
    _challengePool.forEach((category, challenges) {
      for (var challenge in challenges) {
        allChallenges.add({
          'id': '${category}_${challenges.indexOf(challenge)}',
          'title': challenge['title'],
          'points': challenge['points'],
          'difficulty': challenge['difficulty'],
          'icon': challenge['icon'],
          'category': category,
        });
      }
    });

    // Use date as seed for consistent daily challenges
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final random = Random(seed);

    // Shuffle and select 2 unique challenges
    allChallenges.shuffle(random);
    return allChallenges.take(2).toList();
  }

  /// Create or update today's challenges in Firestore
  static Future<void> ensureTodayChallengesExist() async {
    final today = DateTime.now();
    final dateString = DateFormat('yyyy-MM-dd').format(today);

    try {
      final challengeDoc = FirebaseFirestore.instance
          .collection('challenges')
          .doc(dateString);

      final snapshot = await challengeDoc.get();

      // Only create if doesn't exist
      if (!snapshot.exists) {
        final challenges = generateDailyChallenges(today);

        await challengeDoc.set({
          'date': dateString,
          'challenges': challenges,
          'createdAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Created challenges for $dateString');
      }
    } catch (e) {
      debugPrint('❌ Error ensuring challenges exist: $e');
    }
  }

  /// Batch create challenges for the next 7 days
  static Future<void> generateWeeklyChallenges() async {
    final today = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = today.add(Duration(days: i));
      final dateString = DateFormat('yyyy-MM-dd').format(date);

      final challengeDoc = FirebaseFirestore.instance
          .collection('challenges')
          .doc(dateString);

      final snapshot = await challengeDoc.get();

      if (!snapshot.exists) {
        final challenges = generateDailyChallenges(date);

        await challengeDoc.set({
          'date': dateString,
          'challenges': challenges,
          'createdAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Created challenges for $dateString');
      }
    }
  }

  /// Get challenge statistics
  static Map<String, int> getChallengeStats() {
    int totalChallenges = 0;
    int totalPoints = 0;
    final Map<String, int> categoryCounts = {};

    _challengePool.forEach((category, challenges) {
      totalChallenges += challenges.length;
      categoryCounts[category] = challenges.length;

      for (var challenge in challenges) {
        totalPoints += challenge['points'] as int;
      }
    });

    return {
      'totalChallenges': totalChallenges,
      'totalPoints': totalPoints,
      'categories': categoryCounts.length,
    };
  }
}
