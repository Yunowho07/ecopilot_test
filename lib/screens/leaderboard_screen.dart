import 'package:flutter/material.dart';
import 'package:ecopilot_test/auth/firebase_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Define a placeholder for kPrimaryGreen if it's not in constants.dart
// I will assume kPrimaryGreen is a constant Color object in your constants.dart
// For this example, I'll define a suitable green color.
// const Color kPrimaryGreen = Color(0xFF4CAF50); // Example Green

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
    final currentUser = _service.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header with Green Theme
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1db954),
                    const Color(0xFF1db954).withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1db954).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leaderboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Top eco-warriors',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  // User profile picture
                  if (currentUser != null)
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: currentUser.photoURL != null
                            ? CachedNetworkImageProvider(currentUser.photoURL!)
                            : null,
                        child: currentUser.photoURL == null
                            ? const Icon(
                                Icons.person,
                                color: Colors.grey,
                                size: 24,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ),

            // Leaderboard List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _loadLeaderboard();
                  await _future;
                },
                color: const Color(0xFF1db954),
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

                    return ListView.builder(
                      itemCount: list.length,
                      padding: const EdgeInsets.only(top: 16, bottom: 16),
                      itemBuilder: (context, index) {
                        // Show podium for top 3, then list for the rest
                        if (index == 0) {
                          return Column(
                            children: [
                              _buildPodium(list),
                              const SizedBox(height: 24),
                              // Start showing rank 4 and below
                              if (list.length > 3)
                                _buildRankingCard(list[3], 4, currentUid),
                            ],
                          );
                        } else if (index <= 3) {
                          // Skip indices 1-3 as they're in the podium
                          return const SizedBox.shrink();
                        } else {
                          return _buildRankingCard(
                            list[index],
                            index + 1,
                            currentUid,
                          );
                        }
                      },
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

  // NOTE: The filter/loading/error/empty state widgets from the previous code
  // are largely incompatible with the new design's colors/structure.
  // I will simplify them to fit the new white background theme.

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF1db954)),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFF1db954)),
          const SizedBox(height: 16),
          const Text(
            'Unable to Load Leaderboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _loadLeaderboard());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1db954),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 60, color: Color(0xFF1db954)),
          SizedBox(height: 24),
          Text(
            'No Rankings Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> list) {
    if (list.length < 3) {
      // If less than 3 users, just show regular cards
      return Column(
        children: [
          for (int i = 0; i < list.length; i++)
            _buildRankingCard(list[i], i + 1, _service.currentUser?.uid),
        ],
      );
    }

    final first = list[0];
    final second = list[1];
    final third = list[2];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1db954),
            const Color(0xFF1db954).withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1db954).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              const Text(
                'TOP PERFORMERS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.emoji_events, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 24),
          // Podium
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place (Left)
              Expanded(
                child: _buildPodiumUser(
                  second,
                  2,
                  120,
                  const Color(0xFFC0C0C0), // Silver
                  '🥈',
                ),
              ),
              const SizedBox(width: 12),
              // 1st Place (Center - Tallest)
              Expanded(
                child: _buildPodiumUser(
                  first,
                  1,
                  160,
                  const Color(0xFFFFD700), // Gold
                  '🥇',
                ),
              ),
              const SizedBox(width: 12),
              // 3rd Place (Right)
              Expanded(
                child: _buildPodiumUser(
                  third,
                  3,
                  100,
                  const Color(0xFFCD7F32), // Bronze
                  '🥉',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumUser(
    Map<String, dynamic> user,
    int rank,
    double podiumHeight,
    Color podiumColor,
    String medal,
  ) {
    final name = (user['name'] ?? 'Anonymous') as String;
    final photo = (user['photoUrl'] ?? '') as String;
    final points = (user['ecoScore'] ?? 0) as int;

    // Extract display name
    String displayName = name;
    if (name.contains('@')) {
      displayName = name.split('@')[0];
    } else if (name.contains(' ')) {
      final parts = name.split(' ');
      displayName = parts.length > 1 ? '${parts[0]} ${parts[1][0]}.' : parts[0];
    }

    final avatarSize = rank == 1 ? 70.0 : 60.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Medal
        Text(medal, style: TextStyle(fontSize: rank == 1 ? 32 : 28)),
        const SizedBox(height: 8),
        // Avatar
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: Colors.grey.shade300,
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
        const SizedBox(height: 8),
        // Name
        Text(
          displayName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: rank == 1 ? 14 : 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        // Points
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Text(
            '$points pts',
            style: TextStyle(
              fontSize: rank == 1 ? 13 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Podium Base
        Container(
          height: podiumHeight,
          decoration: BoxDecoration(
            color: podiumColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: podiumColor.withOpacity(0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color: podiumColor.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: rank == 1 ? 48 : 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
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

    // Extract display name
    String displayName = name;
    if (name.contains('@')) {
      displayName = name.split('@')[0];
    } else if (name.contains(' ')) {
      final parts = name.split(' ');
      displayName = parts.length > 1 ? '${parts[0]} ${parts[1][0]}.' : parts[0];
    }

    // Medal for top 3
    String? medal;
    if (rank == 1) {
      medal = '🥇';
    } else if (rank == 2) {
      medal = '🥈';
    } else if (rank == 3) {
      medal = '🥉';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1db954),
            const Color(0xFF1db954).withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? Colors.white : Colors.transparent,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1db954).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank number with medal
            SizedBox(
              width: 45,
              child: Column(
                children: [
                  if (medal != null)
                    Text(medal, style: const TextStyle(fontSize: 24)),
                  if (medal == null)
                    Text(
                      '$rank',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Profile picture
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                backgroundImage: photo.isNotEmpty
                    ? CachedNetworkImageProvider(photo)
                    : null,
                child: photo.isEmpty
                    ? Icon(Icons.person, color: Colors.grey.shade600, size: 26)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            // Player info
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
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
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
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1db954),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.eco, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '$points points',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow or trophy icon
            const Icon(Icons.emoji_events, color: Colors.white70, size: 26),
          ],
        ),
      ),
    );
  }
}
