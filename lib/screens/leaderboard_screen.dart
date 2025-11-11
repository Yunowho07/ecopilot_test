import 'package:flutter/material.dart';
import 'package:ecopilot_test/auth/firebase_service.dart';
import 'package:ecopilot_test/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecopilot_test/utils/rank_utils.dart' as rank_utils;
import 'dart:math' as math;

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FirebaseService _service = FirebaseService();
  late Future<List<Map<String, dynamic>>> _future;
  int _currentUserRank = 0;
  int _currentUserPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload leaderboard when coming back to this screen
    _loadLeaderboard();
  }

  void _loadLeaderboard() {
    setState(() {
      _future = _service.getLeaderboard(limit: 100);
    });

    _future
        .then((list) {
          debugPrint('✅ Leaderboard loaded: ${list.length} users');
          if (list.isNotEmpty) {
            debugPrint(
              '📊 Top users: ${list.take(3).map((u) => '${u['name']}:${u['ecoScore']}pts').join(', ')}',
            );
          } else {
            debugPrint('⚠️ Leaderboard is empty - no users found in database');
          }
        })
        .catchError((error) {
          debugPrint('❌ Error loading leaderboard: $error');
        });
    _loadCurrentUserStats();
  }

  Future<void> _loadCurrentUserStats() async {
    try {
      final currentUser = _service.currentUser;
      if (currentUser != null) {
        final userSummary = await _service.getUserSummary(currentUser.uid);
        if (mounted) {
          setState(() {
            _currentUserPoints = userSummary['ecoPoints'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUid = _service.currentUser?.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          _loadLeaderboard();
          await _future;
        },
        color: kPrimaryGreen,
        child: CustomScrollView(
          slivers: [
            // Stunning Animated Hero Header
            SliverAppBar(
              expandedHeight: 240,
              floating: false,
              pinned: true,
              backgroundColor: kPrimaryGreen,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Leaderboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                background: Stack(
                  children: [
                    // Animated Gradient Background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1DB954),
                            kPrimaryGreen,
                            kPrimaryGreen.withOpacity(0.85),
                          ],
                        ),
                      ),
                    ),
                    // Decorative circles
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    // Trophy Icon with glow effect
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 50),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glow effect
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.withOpacity(0.5),
                                        blurRadius: 30,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.emoji_events,
                                  color: Colors.amber.shade300,
                                  size: 56,
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Points',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '$_currentUserPoints',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.stars,
                                      color: Colors.amber.shade300,
                                      size: 24,
                                    ),
                                  ],
                                ),
                                if (_currentUserRank > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      'Rank #$_currentUserRank',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
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
              ),
            ),

            // Content Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }
                    if (snap.hasError) {
                      return _buildErrorState(snap.error.toString());
                    }
                    final list = snap.data ?? [];
                    if (list.isEmpty) {
                      return _buildEmptyState();
                    }

                    // Find current user rank
                    if (currentUid != null) {
                      final userIndex = list.indexWhere(
                        (item) => item['uid'] == currentUid,
                      );
                      if (userIndex >= 0) {
                        _currentUserRank = userIndex + 1;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top 3 Podium
                        if (list.length >= 3) _buildTopThreePodium(list),
                        const SizedBox(height: 30),

                        // Section Header
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'ALL RANKINGS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                        // Rest of Rankings
                        ...List.generate(
                          list.length,
                          (idx) =>
                              _buildRankingCard(list[idx], idx + 1, currentUid),
                        ),

                        const SizedBox(height: 80),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Loading State Widget
  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          CircularProgressIndicator(color: kPrimaryGreen),
          const SizedBox(height: 24),
          Text(
            'Loading rankings...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Error State Widget
  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          const Text(
            'Unable to Load Leaderboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your internet connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _loadLeaderboard();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Empty State Widget
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimaryGreen.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kPrimaryGreen.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          // Animated Trophy Icon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.amber.withOpacity(0.3),
                      Colors.amber.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimaryGreen.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.emoji_events,
                  size: 60,
                  color: Colors.amber.shade400,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Title
          const Text(
            'Be the First Champion! 🏆',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            'Start earning points and compete with others!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 32),

          // Action Cards
          _buildActionCard(
            icon: Icons.qr_code_scanner,
            title: 'Scan Products',
            description: 'Earn points by scanning eco-friendly products',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.emoji_events,
            title: 'Complete Challenges',
            description: 'Take on daily challenges to boost your score',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.eco,
            title: 'Go Green',
            description: 'Make sustainable choices and climb the ranks',
            color: kPrimaryGreen,
          ),

          const SizedBox(height: 24),

          // Info Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Start your eco-journey today and compete with friends!',
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Action Card Helper
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Top 3 Podium Widget - Enhanced Design
  Widget _buildTopThreePodium(List<Map<String, dynamic>> list) {
    final first = list.length > 0 ? list[0] : null;
    final second = list.length > 1 ? list[1] : null;
    final third = list.length > 2 ? list[2] : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withOpacity(0.1),
            kPrimaryGreen.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade400, Colors.amber.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'TOP PERFORMERS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.stars, color: Colors.white, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Podium with better spacing
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Second Place
              if (second != null)
                Expanded(
                  child: _buildEnhancedPodiumItem(
                    second,
                    2,
                    120,
                    Colors.grey.shade400,
                    Colors.grey.shade50,
                  ),
                ),
              const SizedBox(width: 8),
              // First Place (Tallest)
              if (first != null)
                Expanded(
                  child: _buildEnhancedPodiumItem(
                    first,
                    1,
                    150,
                    Colors.amber.shade400,
                    Colors.amber.shade50,
                  ),
                ),
              const SizedBox(width: 8),
              // Third Place
              if (third != null)
                Expanded(
                  child: _buildEnhancedPodiumItem(
                    third,
                    3,
                    100,
                    Colors.orange.shade400,
                    Colors.orange.shade50,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Enhanced Podium Item Widget with better animations and design
  Widget _buildEnhancedPodiumItem(
    Map<String, dynamic> item,
    int rank,
    double height,
    Color medalColor,
    Color backgroundColor,
  ) {
    final name = (item['name'] ?? 'Anonymous') as String;
    final photo = (item['photoUrl'] ?? '') as String;
    final points = (item['ecoScore'] ?? 0) as int;

    return Column(
      children: [
        // Crown for first place
        if (rank == 1)
          Transform.rotate(
            angle: -math.pi / 12,
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.amber,
              size: 28,
            ),
          ),
        if (rank == 1) const SizedBox(height: 4),
        // Profile Picture with Medal and Glow
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: rank == 1 ? 90 : 70,
              height: rank == 1 ? 90 : 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: medalColor.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
            // Profile picture container
            Container(
              width: rank == 1 ? 80 : 60,
              height: rank == 1 ? 80 : 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: medalColor, width: 3),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
                ),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                backgroundImage: photo.isNotEmpty
                    ? CachedNetworkImageProvider(photo)
                    : null,
                child: photo.isEmpty
                    ? Icon(
                        Icons.person,
                        color: Colors.grey.shade600,
                        size: rank == 1 ? 36 : 28,
                      )
                    : null,
              ),
            ),
            // Medal badge
            Positioned(
              bottom: -8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [medalColor, medalColor.withOpacity(0.8)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: medalColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  rank == 1
                      ? '🥇'
                      : rank == 2
                      ? '🥈'
                      : '🥉',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Name
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: rank == 1 ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        // Points badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [medalColor, medalColor.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: medalColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stars, color: Colors.white, size: rank == 1 ? 16 : 14),
              const SizedBox(width: 4),
              Text(
                '$points',
                style: TextStyle(
                  fontSize: rank == 1 ? 13 : 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Podium base
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [backgroundColor, backgroundColor.withOpacity(0.7)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: medalColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: medalColor.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: rank == 1 ? 40 : 32,
                fontWeight: FontWeight.bold,
                color: medalColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Enhanced Ranking Card Widget with modern design
  Widget _buildRankingCard(
    Map<String, dynamic> item,
    int rank,
    String? currentUid,
  ) {
    final uid = item['uid'] as String? ?? '';
    final name = (item['name'] ?? 'Anonymous') as String;
    final photo = (item['photoUrl'] ?? '') as String;
    final points = (item['ecoScore'] ?? 0) as int;
    final isCurrent = (currentUid != null && currentUid == uid);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get rank color based on points
    final rankColor = getRankColor(points);
    final rankTitle = getRankTitle(points);

    // Skip top 3 as they're shown in podium
    if (rank <= 3) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isCurrent
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kPrimaryGreen.withOpacity(0.15),
                  kPrimaryGreen.withOpacity(0.05),
                ],
              )
            : null,
        color: isCurrent ? null : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? kPrimaryGreen
              : isDark
              ? Colors.grey.shade800
              : Colors.grey.shade200,
          width: isCurrent ? 2.5 : 1,
        ),
        boxShadow: [
          if (isCurrent)
            BoxShadow(
              color: kPrimaryGreen.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank Badge with gradient
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getRankBadgeColor(rank),
                    _getRankBadgeColor(rank).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _getRankBadgeColor(rank).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Profile Picture with rank-colored border
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: rankColor, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: rankColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade100,
                backgroundImage: photo.isNotEmpty
                    ? CachedNetworkImageProvider(photo)
                    : null,
                child: photo.isEmpty
                    ? Icon(Icons.person, color: Colors.grey.shade600, size: 26)
                    : null,
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCurrent ? kPrimaryGreen : Colors.black87,
                ),
              ),
            ),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryGreen, kPrimaryGreen.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  'YOU',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.eco, size: 14, color: rankColor),
              const SizedBox(width: 4),
              Text(
                rankTitle,
                style: TextStyle(
                  fontSize: 13,
                  color: rankColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isCurrent ? kPrimaryGreen : Colors.grey.shade100,
                isCurrent
                    ? kPrimaryGreen.withOpacity(0.8)
                    : Colors.grey.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent ? kPrimaryGreen : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars,
                    size: 18,
                    color: isCurrent ? Colors.white : Colors.amber.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$points',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: isCurrent ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              Text(
                'points',
                style: TextStyle(
                  fontSize: 11,
                  color: isCurrent ? Colors.white70 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Get rank badge color based on position
  Color _getRankBadgeColor(int rank) {
    if (rank == 1) return Colors.amber.shade600;
    if (rank == 2) return Colors.grey.shade600;
    if (rank == 3) return Colors.orange.shade600;
    if (rank <= 10) return kPrimaryGreen;
    return Colors.grey.shade400;
  }

  // Get rank color based on points
  Color getRankColor(int points) {
    final rankInfo = rank_utils.rankForPoints(points);
    return rankInfo.color;
  }

  // Get rank title based on points
  String getRankTitle(int points) {
    final rankInfo = rank_utils.rankForPoints(points);
    return rankInfo.title;
  }
}
