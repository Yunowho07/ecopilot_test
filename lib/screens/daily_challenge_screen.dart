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
  String _userRank = 'Green Explorer';
  Color _rankColor = kRankGreenExplorer;
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

      // 2. Execute Firestore transaction safely (create docs if missing)
      final userChallengeDoc = FirebaseFirestore.instance
          .collection('user_challenges')
          .doc('$userId-$today');
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Ensure user_challenges doc exists or set it
        final ucSnap = await transaction.get(userChallengeDoc);
        if (ucSnap.exists) {
          transaction.update(userChallengeDoc, {
            'completed': newCompleted,
            'pointsEarned': newPointsEarned,
            'updatedAt': Timestamp.now(),
          });
        } else {
          transaction.set(userChallengeDoc, {
            'completed': newCompleted,
            'pointsEarned': newPointsEarned,
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          });
        }

        // Update or create user summary
        final userSnapshot = await transaction.get(userDoc);
        if (userSnapshot.exists) {
          final currentEcoPoints = userSnapshot.data()?['ecoPoints'] ?? 0;
          final currentStreak = userSnapshot.data()?['streak'] ?? 0;
          int updatedStreak = currentStreak;
          if (allCompleted) updatedStreak = currentStreak + 1;
          transaction.update(userDoc, {
            'ecoPoints': currentEcoPoints + challengePoints,
            'streak': updatedStreak,
          });
        } else {
          transaction.set(userDoc, {
            'ecoPoints': challengePoints,
            'streak': allCompleted ? 1 : 0,
            'createdAt': Timestamp.now(),
          });
        }
      });

      // 3. Update local state
      if (mounted) {
        setState(() {
          _progress = _progress.copyWith(
            completed: newCompleted,
            pointsEarned: newPointsEarned,
            streakCount: allCompleted
                ? _progress.streakCount + 1
                : _progress.streakCount,
          );
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Challenge "${_challenges[index].title}" completed! +$challengePoints Points! 😊',
          ),
        ),
      );

      // If this screen was opened from a preview (Home -> Go), return true to indicate completion
      try {
        Navigator.of(context).pop(true);
      } catch (_) {
        // ignore
      }
    } catch (e) {
      debugPrint('completeChallenge failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete challenge: $e')),
        );
      }
    }
  }

  // --- UI Builder Widgets ---

  Widget _buildChallengeTile(Challenge challenge, int index) {
    final isCompleted = _progress.completed[index];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white,
      elevation: 2,
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle_outline : Icons.flag_circle_outlined,
          color: isCompleted ? const Color(0xFF1db954) : widget.primaryGreen,
          size: 30,
        ),
        title: Text(
          challenge.title,
          style: TextStyle(
            decoration: isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: isCompleted ? Colors.grey.shade600 : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text('+${challenge.points} Eco Points'),
        trailing: ElevatedButton(
          onPressed: isCompleted ? null : () => _completeChallenge(index),
          style: ElevatedButton.styleFrom(
            backgroundColor: isCompleted ? Colors.grey : widget.primaryGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            isCompleted ? 'Done 😊' : 'Mark as Done',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streak = _progress.streakCount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Daily Eco Challenge',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFF1db954),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateFormat('EEEE, MMMM d').format(DateTime.now())}',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hello ${widget.userName}!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Streak Display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: streak >= 3
                        ? Colors.orange.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      if (streak >= 3)
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 20,
                        ),
                      Text(
                        ' Streak: $streak days',
                        style: TextStyle(
                          color: streak >= 3 ? Colors.orange : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Progress Bar
            const Text(
              'Daily Goal Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progress.progressPercentage,
                minHeight: 15,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(widget.primaryGreen),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '${(_progress.progressPercentage * 100).toInt()}% completed. You earned ${_progress.pointsEarned}/${_progress.totalChallengePoints} points.',
                style: const TextStyle(color: Colors.grey),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Today\'s Challenges',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            // Challenge List
            ..._challenges.asMap().entries.map((entry) {
              return _buildChallengeTile(entry.value, entry.key);
            }).toList(),

            const SizedBox(height: 30),

            // Ranking Information (Conceptual)
            Card(
              color: widget.primaryGreen.withOpacity(0.1),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.star, color: _rankColor, size: 30),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Rank: $_userRank',
                            style: TextStyle(
                              color: _rankColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'You have $_userEcoPoints eco points — keep going! 🎉',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
