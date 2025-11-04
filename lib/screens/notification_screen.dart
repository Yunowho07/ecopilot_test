import 'dart:convert';
import 'dart:math';

import 'package:ecopilot_test/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

const Color kPrimaryGreen = Color(0xFF1db954);

// Notification categories used by the app
enum NotificationCategory {
  dailyChallenge,
  ecoTip,
  milestone,
  scanInsight,
  localAlert,
}

extension NotificationCategoryExt on NotificationCategory {
  String get id => toString().split('.').last;
  String get displayName {
    switch (this) {
      case NotificationCategory.dailyChallenge:
        return 'Daily Challenge';
      case NotificationCategory.ecoTip:
        return 'Eco Tip';
      case NotificationCategory.milestone:
        return 'Milestone';
      case NotificationCategory.scanInsight:
        return 'Scan Insight';
      case NotificationCategory.localAlert:
        return 'Local Alert';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationCategory.dailyChallenge:
        return Icons.flag;
      case NotificationCategory.ecoTip:
        return Icons.lightbulb;
      case NotificationCategory.milestone:
        return Icons.emoji_events;
      case NotificationCategory.scanInsight:
        return Icons.qr_code_scanner;
      case NotificationCategory.localAlert:
        return Icons.location_on;
    }
  }

  Color get color {
    switch (this) {
      case NotificationCategory.dailyChallenge:
        return Colors.orangeAccent;
      case NotificationCategory.ecoTip:
        return Colors.green;
      case NotificationCategory.milestone:
        return Colors.amber;
      case NotificationCategory.scanInsight:
        return Colors.teal;
      case NotificationCategory.localAlert:
        return Colors.indigo;
    }
  }
}

// Simple model for a notification
class AppNotification {
  final String id;
  final NotificationCategory category;
  final String title;
  final String body;
  final DateTime time;
  bool read;
  final Map<String, dynamic>? data; // optional extra payload

  AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        category: NotificationCategory.values.firstWhere(
          (e) => e.id == json['category'],
        ),
        title: json['title'] as String,
        body: json['body'] as String,
        time: DateTime.parse(json['time'] as String),
        read: json['read'] as bool? ?? false,
        data: json['data'] == null
            ? null
            : Map<String, dynamic>.from(json['data'] as Map),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.id,
    'title': title,
    'body': body,
    'time': time.toIso8601String(),
    'read': read,
    'data': data,
  };
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const String _prefsKey = 'app_notifications_v1';

  // IDs used for scheduled local notifications
  static const int _dailyChallengeNotifId = 1000;
  static const int _ecoTipNotifId = 1001;

  bool _dailyScheduled = false;
  bool _ecoTipScheduled = false;

  List<AppNotification> _notifications = [];
  NotificationCategory? _filter; // null = all
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _initSchedules();
  }

  Future<void> _initSchedules() async {
    try {
      final d = await NotificationService().isScheduled(_dailyChallengeNotifId);
      final e = await NotificationService().isScheduled(_ecoTipNotifId);
      setState(() {
        _dailyScheduled = d;
        _ecoTipScheduled = e;
      });
    } catch (err) {
      if (kDebugMode) debugPrint('initSchedules err: $err');
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final List parsed = jsonDecode(raw) as List;
        _notifications = parsed
            .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        debugPrint('Failed to parse notifications: $e');
        _notifications = [];
      }
    } else {
      _notifications = [];
    }
    // Keep newest first
    _notifications.sort((a, b) => b.time.compareTo(a.time));
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  Future<void> _add(AppNotification n, {bool save = true}) async {
    setState(() {
      _notifications.insert(0, n);
    });
    if (save) await _save();
  }

  Future<void> _remove(String id) async {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    await _save();
  }

  Future<void> _markRead(String id, {bool read = true}) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    setState(() {
      _notifications[idx].read = read;
    });
    await _save();
  }

  // Utilities to create sample notifications (for testing & demo)
  AppNotification _makeSample(NotificationCategory cat) {
    final rnd = Random();
    final id =
        DateTime.now().millisecondsSinceEpoch.toString() +
        '_' +
        rnd.nextInt(9999).toString();
    switch (cat) {
      case NotificationCategory.dailyChallenge:
        return AppNotification(
          id: id,
          category: cat,
          title: 'Today\'s Challenge',
          body:
              '🌞 Good morning! Today\'s challenge: Ditch single-use plastics and earn +20 EcoPoints.',
          time: DateTime.now(),
        );
      case NotificationCategory.ecoTip:
        return AppNotification(
          id: id,
          category: cat,
          title: 'Eco Tip of the Day',
          body:
              '♻️ Eco Tip: Switch to reusable water bottles to cut down on waste.',
          time: DateTime.now(),
        );
      case NotificationCategory.milestone:
        return AppNotification(
          id: id,
          category: cat,
          title: 'Milestone Unlocked',
          body:
              '🔥 7-day streak complete! You\'ve earned the \"Green Guardian\" badge.',
          time: DateTime.now(),
        );
      case NotificationCategory.scanInsight:
        return AppNotification(
          id: id,
          category: cat,
          title: 'Scan Insight',
          body:
              '🌍 You saved 0.5kg of CO₂ by choosing this product! Check details in your feed.',
          time: DateTime.now(),
          data: {'productId': 'sample_123'},
        );
      case NotificationCategory.localAlert:
        return AppNotification(
          id: id,
          category: cat,
          title: 'Local Recycling Alert',
          body: '📍 New recycling center opened near you — check it out!',
          time: DateTime.now(),
        );
    }
  }

  // Public helpers (simulate incoming notif)
  Future<void> _simulate(NotificationCategory cat) async {
    final n = _makeSample(cat);
    await _add(n);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notification added')));
  }

  Future<void> _toggleDailySchedule() async {
    try {
      if (_dailyScheduled) {
        await NotificationService().cancel(_dailyChallengeNotifId);
        setState(() => _dailyScheduled = false);
      } else {
        await NotificationService().scheduleDaily(
          id: _dailyChallengeNotifId,
          title: 'Today\'s Eco Challenge',
          color: kPrimaryGreen,
          body:
              '🌞 Good morning! Complete today\'s challenge and earn +20 EcoPoints.',
          hour: 8,
          minute: 0,
        );
        setState(() => _dailyScheduled = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Schedule failed: $e')));
    }
  }

  Future<void> _toggleEcoTipSchedule() async {
    try {
      if (_ecoTipScheduled) {
        await NotificationService().cancel(_ecoTipNotifId);
        setState(() => _ecoTipScheduled = false);
      } else {
        await NotificationService().scheduleDaily(
          id: _ecoTipNotifId,
            title: 'Eco Tip',
            color: Colors.white,
          body:
              '♻️ Eco Tip: Switch to reusable water bottles to cut down on waste.',
          hour: 12,
          minute: 0,
        );
        setState(() => _ecoTipScheduled = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Schedule failed: $e')));
    }
  }

  List<AppNotification> get _visible => _filter == null
      ? _notifications
      : _notifications.where((n) => n.category == _filter).toList();

  int get _unreadCount => _notifications.where((n) => !n.read).length;

  void _showDetails(AppNotification n) {
    // mark read when opened
    _markRead(n.id, read: true);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(n.category.icon, color: n.category.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    n.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatTime(n.time),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(n.body, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _markRead(n.id, read: false);
                  },
                  child: const Text('Mark Unread'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    // Navigate based on category or payload
                    if (n.category == NotificationCategory.scanInsight &&
                        n.data != null &&
                        n.data!['productId'] != null) {
                      // Example: navigate to product details (app-specific)
                      // Navigator.of(context).pushNamed('/product', arguments: n.data!['productId']);
                    }
                  },
                  child: const Text('View'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${t.month}/${t.day}/${t.year}';
  }

  Widget _buildFilterChips() {
    final categories = <NotificationCategory?>[
      null,
      ...NotificationCategory.values,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: categories.map((c) {
          final selected = c == _filter;
          final label = c == null ? 'All' : c.displayName;
          final icon = c == null ? Icons.list : c.icon;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(label),
              avatar: Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : Colors.black54,
              ),
              selected: selected,
              selectedColor: kPrimaryGreen,
              onSelected: (_) => setState(() => _filter = c),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              ),
            );
          },
        ),
        actions: [
          Center(
            child: Text(
              'Unread: $_unreadCount',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Mark all read',
            icon: const Icon(Icons.mark_email_read, color: Colors.white),
            onPressed: () async {
              setState(() {
                for (var n in _notifications) n.read = true;
              });
              await _save();
            },
          ),
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear all notifications?'),
                  content: const Text(
                    'This will permanently remove all notifications.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                setState(() => _notifications.clear());
                await _save();
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterChips(),
                // Scheduling controls for daily notifications
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _dailyScheduled
                                ? Colors.green
                                : Colors.grey.shade200,
                          ),
                          icon: Icon(
                            _dailyScheduled
                                ? Icons.check_circle
                                : Icons.schedule,
                            color: _dailyScheduled
                                ? Colors.white
                                : Colors.black54,
                          ),
                          label: Text(
                            _dailyScheduled
                                ? 'Daily Challenge: ON (8:00)'
                                : 'Enable Daily Challenge (8:00)',
                            style: TextStyle(
                              color: _dailyScheduled
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          onPressed: _toggleDailySchedule,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _ecoTipScheduled
                                ? Colors.green
                                : Colors.grey.shade200,
                          ),
                          icon: Icon(
                            _ecoTipScheduled
                                ? Icons.check_circle
                                : Icons.lightbulb,
                            color: _ecoTipScheduled
                                ? Colors.white
                                : Colors.black54,
                          ),
                          label: Text(
                            _ecoTipScheduled
                                ? 'Eco Tip: ON (12:00)'
                                : 'Enable Eco Tip (12:00)',
                            style: TextStyle(
                              color: _ecoTipScheduled
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          onPressed: _toggleEcoTipSchedule,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _visible.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.notifications_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No notifications',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () async {
                                  // Add a few demo notifications
                                  await _add(
                                    _makeSample(
                                      NotificationCategory.dailyChallenge,
                                    ),
                                  );
                                  await _add(
                                    _makeSample(NotificationCategory.ecoTip),
                                  );
                                  await _add(
                                    _makeSample(
                                      NotificationCategory.scanInsight,
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Generate demo notifications',
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _visible.length + 1,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              if (index == 0) return const SizedBox(height: 6);
                              final n = _visible[index - 1];
                              return Dismissible(
                                key: ValueKey(n.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.redAccent,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (_) => _remove(n.id),
                                child: ListTile(
                                  tileColor: n.read
                                      ? null
                                      : Colors.grey.shade50,
                                  leading: CircleAvatar(
                                    backgroundColor: n.category.color
                                        .withOpacity(0.12),
                                    child: Icon(
                                      n.category.icon,
                                      color: n.category.color,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          n.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatTime(n.time),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    n.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      if (v == 'mark')
                                        await _markRead(n.id, read: !n.read);
                                      if (v == 'delete') await _remove(n.id);
                                    },
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(
                                        value: 'mark',
                                        child: Text(
                                          n.read ? 'Mark Unread' : 'Mark Read',
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                  onTap: () => _showDetails(n),
                                ),
                              );
                            },
                          ),
                        ),
                ),
                // Quick-simulate bar for testing (adds one of each category)
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: NotificationCategory.values.map((c) {
                            return ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: c.color,
                              ),
                              onPressed: () => _simulate(c),
                              icon: Icon(c.icon, size: 16),
                              label: Text(c.displayName),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
