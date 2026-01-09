// Migration Script: Initialize availablePoints for existing users
// Run this once to migrate existing users from single ecoPoints to dual system

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> migrateUserPointsToAvailablePoints() async {
  final firestore = FirebaseFirestore.instance;

  print('🔄 Starting migration: Initializing availablePoints for all users...');

  try {
    // Get all users
    final usersSnapshot = await firestore.collection('users').get();

    print('📊 Found ${usersSnapshot.docs.length} users to migrate');

    int migrated = 0;
    int skipped = 0;

    final batch = firestore.batch();
    int batchCount = 0;

    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final ecoPoints = data['ecoPoints'] ?? 0;
      final availablePoints = data['availablePoints'];

      // Only migrate if availablePoints doesn't exist yet
      if (availablePoints == null) {
        // Set availablePoints equal to current ecoPoints
        // This assumes no redemptions have happened yet
        batch.update(doc.reference, {'availablePoints': ecoPoints});

        migrated++;
        batchCount++;

        // Firestore batch limit is 500 operations
        if (batchCount >= 500) {
          await batch.commit();
          print('💾 Committed batch of $batchCount users');
          batchCount = 0;
        }
      } else {
        skipped++;
      }
    }

    // Commit remaining batch
    if (batchCount > 0) {
      await batch.commit();
      print('💾 Committed final batch of $batchCount users');
    }

    print('✅ Migration complete!');
    print('   - Migrated: $migrated users');
    print('   - Skipped (already had availablePoints): $skipped users');
    print('');
    print('📝 Summary:');
    print(
      '   - ecoPoints: Total earned points (never decreases) - shown on leaderboard',
    );
    print(
      '   - availablePoints: Spendable points (decreases on redemption) - used in redeem screen',
    );
  } catch (e) {
    print('❌ Migration failed: $e');
    rethrow;
  }
}

// Call this function once to perform the migration
// You can add this to a debug menu or admin panel
void main() async {
  // Initialize Firebase first
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();

  await migrateUserPointsToAvailablePoints();
}
