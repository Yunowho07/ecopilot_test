import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Backfill script to populate weekly_points from existing monthly_points data
/// Run this once to migrate existing data to the new weekly tracking system
Future<void> backfillWeeklyPoints() async {
  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();

  // Calculate current week key
  final weekNumber =
      ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).floor() + 1;
  final weekKey = '${now.year}-${weekNumber.toString().padLeft(2, '0')}';
  final monthKey = DateFormat('yyyy-MM').format(now);

  print('🔄 Starting backfill for week $weekKey (month $monthKey)...');

  try {
    // Get all users
    final usersSnapshot = await firestore.collection('users').get();
    print('👥 Found ${usersSnapshot.docs.length} users');

    int usersUpdated = 0;

    for (final userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;
      final userName = userDoc.data()['name'] ?? 'Unknown';

      // Get current month's points
      final monthlyDoc = await firestore
          .collection('users')
          .doc(userId)
          .collection('monthly_points')
          .doc(monthKey)
          .get();

      if (!monthlyDoc.exists) {
        print('  ⏭️  Skipping $userName (no monthly data)');
        continue;
      }

      final monthlyPoints = monthlyDoc.data()?['points'] ?? 0;

      if (monthlyPoints == 0) {
        print('  ⏭️  Skipping $userName (0 points this month)');
        continue;
      }

      // Check if weekly points already exist
      final weeklyDoc = await firestore
          .collection('users')
          .doc(userId)
          .collection('weekly_points')
          .doc(weekKey)
          .get();

      if (weeklyDoc.exists) {
        final existingPoints = weeklyDoc.data()?['points'] ?? 0;
        print('  ✓ $userName already has $existingPoints weekly points');
        continue;
      }

      // Copy monthly points to weekly (as an estimate for current week)
      // Note: This assumes all monthly points were earned this week
      // In reality, this is just a migration - future points will be accurate
      await firestore
          .collection('users')
          .doc(userId)
          .collection('weekly_points')
          .doc(weekKey)
          .set({
            'points': monthlyPoints,
            'week': weekKey,
            'year': now.year,
            'weekNumber': weekNumber,
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'backfilled': true, // Mark as backfilled for tracking
          });

      usersUpdated++;
      print('  ✅ Backfilled $userName: $monthlyPoints points');
    }

    print('\n✅ Backfill complete! Updated $usersUpdated users');
  } catch (e) {
    print('❌ Error during backfill: $e');
  }
}
