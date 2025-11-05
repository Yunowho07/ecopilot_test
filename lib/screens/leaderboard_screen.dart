import 'package:flutter/material.dart';
import 'package:ecopilot_test/auth/firebase_service.dart';
import 'package:ecopilot_test/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FirebaseService _service = FirebaseService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getLeaderboard(limit: 100);
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _service.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Leaderboard',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: kPrimaryGreen,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Failed to load leaderboard: ${snap.error}'),
            );
          }
          final list = snap.data ?? [];
          if (list.isEmpty)
            return const Center(child: Text('No leaderboard data yet'));

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, idx) {
              final item = list[idx];
              final uid = item['uid'] as String? ?? '';
              final name = (item['name'] ?? 'Anonymous') as String;
              final photo = (item['photoUrl'] ?? '') as String;
              final points = (item['ecoScore'] ?? 0) as int;
              final title = (item['title'] ?? '') as String;

              final isCurrent = (currentUid != null && currentUid == uid);

              return ListTile(
                tileColor: isCurrent ? kPrimaryGreen.withOpacity(0.08) : null,
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: photo.isNotEmpty
                      ? CachedNetworkImageProvider(photo)
                      : null,
                  child: photo.isEmpty
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                title: Row(
                  children: [
                    Text(
                      '#${idx + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(title),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$points',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'pts',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                onTap: () {},
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: list.length,
          );
        },
      ),
    );
  }
}
