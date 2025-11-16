import 'package:flutter/material.dart';
import 'package:ecopilot_test/auth/firebase_service.dart';
import 'package:ecopilot_test/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecopilot_test/utils/rank_utils.dart' as rank_utils;

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
  String _selectedFilter = 'All time';

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    final currentUid = _service.currentUser?.uid;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kPrimaryGreen.withOpacity(0.9),
              kPrimaryGreen.withOpacity(0.7),
              kPrimaryGreen.withOpacity(0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              _loadLeaderboard();
              await _future;
            },
            color: Colors.white,
            child: CustomScrollView(
              slivers: [
                // Header with Title and Filter Tabs
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                    child: Column(
                      children: [
                        // Trophy icon with title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.emoji_events,
                                color: kPrimaryYellow,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'LEADERBOARD',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Filter tabs with better design
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildFilterTab('All time', true),
                              _buildFilterTab('This Week', false),
                              _buildFilterTab('This Month', false),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content
                SliverToBoxAdapter(
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
                        for (int i = 0; i < list.length; i++) {
                          if (list[i]['uid'] == currentUid) {
                            _currentUserRank = i + 1;
                            break;
                          }
                        }
                      }

                      return Column(
                        children: [
                          _buildTopThreePodium(list),
                          const SizedBox(height: 8),
                          // Section divider
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'ALL RANKINGS',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withOpacity(0.7),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Column(
                              children: [
                                for (int i = 0; i < list.length; i++)
                                  _buildRankingCard(list[i], i + 1, currentUid),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, bool isSelected) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            'Unable to Load Leaderboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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
              backgroundColor: Colors.white,
              foregroundColor: kPrimaryGreen,
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
            ),
            child: const Icon(
              Icons.emoji_events,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Rankings Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Start earning points to see rankings!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildTopThreePodium(List<Map<String, dynamic>> list) {
    final first = list.isNotEmpty ? list[0] : null;
    final second = list.length > 1 ? list[1] : null;
    final third = list.length > 2 ? list[2] : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          // Crown icon with glow effect
          if (first != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimaryYellow.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: kPrimaryYellow,
                size: 48,
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'TOP PERFORMERS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          // Podium layout - reordered to show 2, 1, 3
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Second Place (left)
              if (second != null)
                Expanded(child: _buildPodiumItem(second, 2, 75)),
              const SizedBox(width: 16),
              // First Place (center - larger)
              if (first != null)
                Expanded(child: _buildPodiumItem(first, 1, 100)),
              const SizedBox(width: 16),
              // Third Place (right)
              if (third != null)
                Expanded(child: _buildPodiumItem(third, 3, 75)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
    Map<String, dynamic> item,
    int rank,
    double avatarSize,
  ) {
    final name = (item['name'] ?? 'Anonymous') as String;
    final photo = (item['photoUrl'] ?? '') as String;
    final points = (item['ecoScore'] ?? 0) as int;

    // Extract username from full name or email
    String displayName = name;
    if (name.contains('@')) {
      displayName = '@${name.split('@')[0]}';
    } else if (name.contains(' ')) {
      displayName = '@${name.split(' ')[0].toLowerCase()}';
    } else {
      displayName = '@$name';
    }

    // Medal emoji based on rank
    final medal = rank == 1
        ? '🥇'
        : rank == 2
        ? '🥈'
        : '🥉';

    // Border color
    final borderColor = rank == 1
        ? kPrimaryYellow
        : rank == 2
        ? Colors.grey.shade300
        : Colors.orange.shade300;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Medal badge
        Text(medal, style: TextStyle(fontSize: rank == 1 ? 32 : 28)),
        const SizedBox(height: 8),
        // Profile Picture with shadow
        Stack(
          alignment: Alignment.center,
          children: [
            // Shadow/glow effect
            Container(
              width: avatarSize + 8,
              height: avatarSize + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Avatar
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: rank == 1 ? 4 : 3,
                ),
                color: Colors.white,
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
                        size: avatarSize * 0.5,
                      )
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Username
        Text(
          displayName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: rank == 1 ? 15 : 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        // Points badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                size: rank == 1 ? 14 : 12,
                color: kPrimaryYellow,
              ),
              const SizedBox(width: 4),
              Text(
                '$points',
                style: TextStyle(
                  fontSize: rank == 1 ? 13 : 11,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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

    // Skip top 3 as they're shown in podium
    if (rank <= 3) return const SizedBox.shrink();

    // Extract username
    String displayName = name;
    if (name.contains('@')) {
      displayName = '@${name.split('@')[0]}';
    } else if (name.contains(' ')) {
      displayName = '@${name.split(' ')[0].toLowerCase()}';
    } else {
      displayName = '@$name';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isCurrent ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent ? kPrimaryYellow : Colors.white.withOpacity(0.15),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Profile Picture
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent
                      ? kPrimaryYellow
                      : Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                backgroundImage: photo.isNotEmpty
                    ? CachedNetworkImageProvider(photo)
                    : null,
                child: photo.isEmpty
                    ? Icon(Icons.person, color: Colors.grey.shade600, size: 24)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            // Name and points
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrent) const SizedBox(width: 8),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimaryYellow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: kPrimaryYellow),
                      const SizedBox(width: 4),
                      Text(
                        '$points points',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Chevron icon
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.3),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
