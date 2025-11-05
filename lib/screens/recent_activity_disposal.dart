import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecopilot_test/utils/constants.dart';
import 'package:ecopilot_test/screens/disposal_guidance_screen.dart';

class RecentActivityScreen extends StatefulWidget {
  const RecentActivityScreen({super.key});

  @override
  State<RecentActivityScreen> createState() => _RecentActivityScreenState();
}

class _RecentActivityScreenState extends State<RecentActivityScreen> {
  List<Map<String, dynamic>> _recentActivity = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentActivity();
  }

  Future<void> _loadRecentActivity() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // Query only scans that include disposal information to separate
      // disposal activity from general scan activity. We attempt to
      // filter by a few possible disposal-related fields. Firestore
      // supports 'isNotEqualTo' filters; here we check for a non-null
      // value for 'disposal_method' OR 'disposalSteps' by running two
      // queries and merging results to be safe across existing documents.
      final coll = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scans');

      final q1 = await coll
          .where('disposal_method', isNotEqualTo: null)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final q2 = await coll
          .where('disposalSteps', isNotEqualTo: null)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      // Merge docs (by id) preserving order by createdAt roughly
      final map = <String, QueryDocumentSnapshot>{};
      for (final d in q1.docs) map[d.id] = d;
      for (final d in q2.docs) map[d.id] = d;
      final merged = map.values.toList()
        ..sort((a, b) {
          final aData = a.data() as Map<String, dynamic>?;
          final bData = b.data() as Map<String, dynamic>?;
          final aTs = aData?['createdAt'];
          final bTs = bData?['createdAt'];
          DateTime? ad;
          DateTime? bd;
          if (aTs is Timestamp) ad = aTs.toDate();
          if (bTs is Timestamp) bd = bTs.toDate();
          if (ad != null && bd != null) return bd.compareTo(ad);
          return 0;
        });

      // Limit merged results
      final limited = merged.take(20).toList();

      // Build a safe list of maps for UI consumption
      setState(() {
        _recentActivity = limited.map((doc) {
          final data = (doc.data() ?? {}) as Map<String, dynamic>;
          final name =
              data['name'] ?? data['product_name'] ?? 'Scanned product';
          final category = data['category'] ?? 'N/A';
          final material = data['material'] ?? 'Unknown';
          final imageUrl =
              data['imageUrl'] ??
              data['image'] ??
              'https://placehold.co/100x120/A8D8B9/212121?text=Product';

          return {
            'id': doc.id,
            'name': name,
            'category': category,
            'material': material,
            'imageUrl': imageUrl,
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading recent activity: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildRecentProductTile(Map<String, dynamic> product) {
    final String name = product['name'] ?? 'Scanned product';
    final String category = product['category'] ?? 'N/A';
    final String material = product['material'] ?? 'Unknown';
    final String imageUrl =
        product['imageUrl'] ??
        'https://placehold.co/100x120/A8D8B9/212121?text=Product';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          // Navigate to the Disposal Details Screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DisposalGuidanceScreen(productId: product['id']),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: kPrimaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.delete_sweep, color: kPrimaryGreen, size: 40),
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category: $category',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            Text(
              'Material: $material',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.black38,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryGreen,
      appBar: AppBar(
        title: const Text(
          'Recent Activity',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        // The main content area with a rounded white background
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _recentActivity.isEmpty
            ? const Center(
                child: Text(
                  'No recent scans yet. Go scan a product!',
                  style: TextStyle(color: Colors.black54),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                itemCount: _recentActivity.length,
                itemBuilder: (context, index) {
                  return _buildRecentProductTile(_recentActivity[index]);
                },
              ),
      ),
    );
  }
}
