import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ecopilot_test/utils/constants.dart';
import 'package:ecopilot_test/auth/firebase_service.dart';
import 'package:ecopilot_test/utils/rank_utils.dart';

// Placeholder data structure for challenge and user progress
class Challenge {
  final String title;
  final int points;
  final String id;

  Challenge(this.id, this.title, this.points);
}

class UserChallengeProgress {
  final List<bool> completed;
  final int pointsEarned;
  final int streakCount;
  final int totalChallengePoints;

  UserChallengeProgress({
    required this.completed,
    this.pointsEarned = 0,
    this.streakCount = 0,
    required this.totalChallengePoints,
  });

  double get progressPercentage {
    // Prefer point-based progress if total points is available
    if (totalChallengePoints > 0) {
      return (pointsEarned / totalChallengePoints).clamp(0.0, 1.0);
    }
    if (completed.isEmpty) return 0.0;
    final completedCount = completed.where((c) => c).length;
    return completedCount / completed.length;
  }

  bool get allCompleted => completed.every((c) => c);
}

extension UserChallengeProgressExt on UserChallengeProgress {
  UserChallengeProgress copyWith({
    List<bool>? completed,
    int? pointsEarned,
    int? streakCount,
    int? totalChallengePoints,
  }) {
    return UserChallengeProgress(
      completed: completed ?? this.completed,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      streakCount: streakCount ?? this.streakCount,
      totalChallengePoints: totalChallengePoints ?? this.totalChallengePoints,
    );
  }
}

class DailyChallengeScreen extends StatefulWidget {
  final String userName;
  final Color primaryGreen;

  const DailyChallengeScreen({
    super.key,
    required this.userName,
    required this.primaryGreen,
  });

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  // Use simulated data or fetch streams in a real app
  late List<Challenge> _challenges;
  late UserChallengeProgress _progress;
  final FirebaseService _firebaseService = FirebaseService();
  int _userEcoPoints = 0;
  String _userRank = 'Green Beginner';
  Color _rankColor = kRankGreenBeginner;
  final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadChallengeData();
    _loadUserRank();
  }

  Future<void> _loadUserRank() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return;
      final summary = await _firebaseService.getUserSummary(user.uid);
      final points = (summary['ecoScore'] ?? summary['ecoPoints'] ?? 0) as int;
      final rankInfo = rankForPoints(points);
      if (mounted) {
        setState(() {
          _userEcoPoints = points;
          _userRank = rankInfo.title;
          _rankColor = rankInfo.color;
        });
      }
    } catch (e) {
      debugPrint('Failed to load user rank: $e');
    }
  }

  // Rank logic moved to lib/utils/rank_utils.dart

  void _loadChallengeData() {
    // ⚠️ CONCEPTUAL: Replace this with Firestore streams/futures
    // Simulate fetching daily challenge structure
    _challenges = [
      Challenge('c1', 'Recycle all plastic waste generated today', 15),
      Challenge('c2', 'Use public transport or cycle for one trip', 10),
    ];

    // Simulate fetching user progress
    _progress = UserChallengeProgress(
      completed: [false, false],
      pointsEarned: 0,
      streakCount: 3, // Simulate a streak
      totalChallengePoints: 25,
    );

    // In a real app, you'd merge the two Firestore documents here:

    _fetchChallengesFromFirestore().then((challenges) {
      _fetchUserProgress().then((progress) {
        final totalPoints = challenges.fold<int>(
          0,
          (int sum, Challenge c) => sum + c.points,
        );
        setState(() {
          _challenges = challenges;
          _progress = progress.copyWith(totalChallengePoints: totalPoints);
        });
      });
    });
  }

  /// Fetch challenge definitions for today from Firestore.
  /// Falls back to the in-memory `_challenges` if nothing found.
  Future<List<Challenge>> _fetchChallengesFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('challenges')
          .doc(today)
          .get();
      if (!doc.exists) return _challenges;
      final data = doc.data();
      if (data == null) return _challenges;
      final list = List.from(data['challenges'] ?? []);
      return list
          .map(
            (e) => Challenge(
              e['id'] ?? e['title'],
              e['title'] ?? '',
              e['points'] ?? 0,
            ),
          )
          .toList();
    } catch (e) {
      // On error, return the simulated list
      return _challenges;
    }
  }

  /// Fetch the user's progress for today's challenges from Firestore.
  /// If no progress document exists, return a default [UserChallengeProgress].
  Future<UserChallengeProgress> _fetchUserProgress() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return _progress;
      final doc = await FirebaseFirestore.instance
          .collection('user_challenges')
          .doc('$uid-$today')
          .get();
      if (!doc.exists) return _progress;
      final data = doc.data() ?? {};
      final completed =
          (data['completed'] as List<dynamic>?)
              ?.map((e) => e == true)
              .toList() ??
          List<bool>.filled(_challenges.length, false);
      final pointsEarned = data['pointsEarned'] ?? 0;
      final streak = data['streak'] ?? _progress.streakCount;
      final total = _challenges.fold<int>(0, (sum, c) => sum + c.points);
      return UserChallengeProgress(
        completed: completed.cast<bool>(),
        pointsEarned: pointsEarned,
        streakCount: streak,
        totalChallengePoints: total,
      );
    } catch (e) {
      return _progress;
    }
  }

  Future<void> _completeChallenge(int index) async {
    try {
      // Prevent double completion
      if (_progress.completed[index]) return;

      // 1. Prepare data updates
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to complete challenges'),
          ),
        );
        return;
      }
      final userId = user.uid;

      final challengePoints = _challenges[index].points;
      final newCompleted = List<bool>.from(_progress.completed);
      newCompleted[index] = true;
      final newPointsEarned = _progress.pointsEarned + challengePoints;

      final allCompleted = newCompleted.every((c) => c);

      // Get current month key for monthly points
      final now = DateTime.now();
      final monthKey = DateFormat('yyyy-MM').format(now);

      // 2. Execute Firestore updates without transaction (simpler and more reliable)
      try {
        // Update user challenge progress
        await FirebaseFirestore.instance
            .collection('user_challenges')
            .doc('$userId-$today')
            .set({
              'completed': newCompleted,
              'pointsEarned': newPointsEarned,
              'userId': userId,
              'date': today,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        // Get current user data
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        final currentEcoPoints = userDoc.data()?['ecoPoints'] ?? 0;
        final currentStreak = userDoc.data()?['streak'] ?? 0;
        int updatedStreak = currentStreak;
        if (allCompleted) updatedStreak = currentStreak + 1;

        // Update user document
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'ecoPoints': currentEcoPoints + challengePoints,
          'streak': updatedStreak,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Update monthly points
        final monthlyDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('monthly_points')
            .doc(monthKey)
            .get();

        final currentMonthlyPoints = monthlyDoc.data()?['points'] ?? 0;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('monthly_points')
            .doc(monthKey)
            .set({
              'points': currentMonthlyPoints + challengePoints,
              'goal': 500,
              'month': monthKey,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        // 3. Update local state
        if (mounted) {
          setState(() {
            _progress = _progress.copyWith(
              completed: newCompleted,
              pointsEarned: newPointsEarned,
              streakCount: updatedStreak,
            );
            _userEcoPoints = currentEcoPoints + challengePoints;
          });
          _loadUserRank(); // Refresh rank
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Challenge completed! +$challengePoints Points!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (firestoreError) {
        debugPrint('Firestore operation failed: $firestoreError');
        throw Exception('Database error: $firestoreError');
      }
    } catch (e) {
      debugPrint('completeChallenge failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete challenge. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // --- UI Builder Widgets ---

  @override
  Widget build(BuildContext context) {
    final streak = _progress.streakCount;
    final progressPercent = (_progress.progressPercentage * 100).toInt();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Modern Hero Header with Gradient
          SliverAppBar(
            expandedHeight: 260,
            floating: false,
            pinned: true,
            backgroundColor: kPrimaryGreen,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1db954),
                      const Color(0xFF1db954).withOpacity(0.8),
                      kPrimaryGreen,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat(
                                  'EEEE, MMMM d',
                                ).format(DateTime.now()),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Welcome Text
                        Text(
                          'Hello ${widget.userName}! 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Complete today\'s eco-challenges',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Spacer(),

                        // Streak and Points Row
                        Row(
                          children: [
                            // Streak Badge
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      streak >= 3
                                          ? Icons.local_fire_department
                                          : Icons.emoji_events_outlined,
                                      color: streak >= 3
                                          ? Colors.orange.shade300
                                          : Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 6),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$streak Days',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Streak',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Points Badge
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.stars_rounded,
                                      color: Colors.amber,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 6),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_progress.pointsEarned}/${_progress.totalChallengePoints}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Points',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kPrimaryGreen, kPrimaryGreen.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryGreen.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Daily Progress',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$progressPercent%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _progress.progressPercentage,
                            minHeight: 12,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          progressPercent == 100
                              ? '🎉 Amazing! All challenges completed!'
                              : progressPercent >= 50
                              ? '💪 You\'re halfway there! Keep going!'
                              : '🚀 Let\'s complete these challenges!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Section Header
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: kPrimaryGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Today\'s Challenges',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Challenge List
                  ..._challenges.asMap().entries.map((entry) {
                    return _buildModernChallengeTile(entry.value, entry.key);
                  }),

                  const SizedBox(height: 32),

                  // Rank Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _rankColor.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _rankColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.emoji_events,
                            color: _rankColor,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Rank',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userRank,
                                style: TextStyle(
                                  color: _rankColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_userEcoPoints eco points total',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modern Challenge Tile Widget
  Widget _buildModernChallengeTile(Challenge challenge, int index) {
    final isCompleted = _progress.completed[index];

    // Determine challenge category icon (basic detection from title)
    IconData getChallengeIcon() {
      final title = challenge.title.toLowerCase();
      if (title.contains('recycle') || title.contains('plastic'))
        return Icons.recycling;
      if (title.contains('transport') ||
          title.contains('cycle') ||
          title.contains('walk'))
        return Icons.directions_bike;
      if (title.contains('bottle') || title.contains('water'))
        return Icons.water_drop;
      if (title.contains('energy') || title.contains('light'))
        return Icons.lightbulb_outline;
      if (title.contains('food') || title.contains('meal'))
        return Icons.restaurant;
      return Icons.eco;
    }

    Color getChallengeColor() {
      final title = challenge.title.toLowerCase();
      if (title.contains('recycle')) return Colors.green;
      if (title.contains('transport') || title.contains('cycle'))
        return Colors.blue;
      if (title.contains('bottle') || title.contains('water'))
        return Colors.cyan;
      if (title.contains('energy') || title.contains('light'))
        return Colors.amber;
      if (title.contains('food') || title.contains('meal'))
        return Colors.orange;
      return kPrimaryGreen;
    }

    final challengeColor = getChallengeColor();
    final challengeIcon = getChallengeIcon();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? Colors.green.shade200 : Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? Colors.green.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCompleted ? null : () => _completeChallenge(index),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.shade50
                        : challengeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : challengeIcon,
                    color: isCompleted ? Colors.green : challengeColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Challenge Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? Colors.grey.shade600
                              : Colors.black87,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.stars,
                                  color: Colors.amber.shade700,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '+${challenge.points} pts',
                                  style: TextStyle(
                                    color: Colors.amber.shade900,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCompleted) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check,
                                    color: Colors.green.shade700,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Completed',
                                    style: TextStyle(
                                      color: Colors.green.shade900,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Action Button
                if (!isCompleted)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPrimaryGreen,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
