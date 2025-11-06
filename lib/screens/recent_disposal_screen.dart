import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecopilot_test/utils/constants.dart';
import 'package:ecopilot_test/screens/disposal_guidance_screen.dart';

class RecentDisposalScreen extends StatefulWidget {
  const RecentDisposalScreen({super.key});

  @override
  State<RecentDisposalScreen> createState() => _RecentDisposalScreenState();
}

class _RecentDisposalScreenState extends State<RecentDisposalScreen> {
  // UI listens to Firestore snapshots; no local state required.
  // The previous manual loader is replaced by a real-time snapshot listener
  // inside the build method so the UI updates automatically after saving.

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
          'Recent Disposal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        // The main content area with a rounded white background
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x0F1DB954), Colors.white],
          ),
        ),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          // Listen to the user's per-user scans collection where isDisposal==true.
          // Many save paths (saveUserScan) write to `users/{uid}/scans`.
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid ?? 'anonymous')
              .collection('scans')
              .where('isDisposal', isEqualTo: true)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No recent scans yet. Go scan a product!',
                  style: TextStyle(color: Colors.black54),
                ),
              );
            }

            // Map documents to UI items and normalize fields saved under
            // different keys by various save flows. This handles records
            // written by `saveUserScan` (users/{uid}/scans) and similar writers.
            final rawItems = snapshot.data!.docs.map((doc) {
              final data = doc.data();
              final name =
                  data['product_name'] ?? data['name'] ?? 'Scanned product';
              final category = data['category'] ?? 'N/A';
              final material =
                  data['material'] ?? data['packaging'] ?? 'Unknown';
              final imageUrl =
                  (data['image_url'] ?? data['imageUrl'] ?? data['image'] ?? '')
                      ?.toString() ??
                  '';
              final createdAt =
                  data['createdAt'] ??
                  data['timestamp'] ??
                  data['scannedAt'] ??
                  null;
              return {
                'id': doc.id,
                'name': name,
                'category': category,
                'material': material,
                'imageUrl': imageUrl.isNotEmpty
                    ? imageUrl
                    : 'https://placehold.co/100x120/A8D8B9/212121?text=Product',
                'createdAt': createdAt,
              };
            }).toList();

            // Deduplicate entries client-side. Multiple save paths may write
            // separate documents representing the same scanned product. Use
            // a stable key (name + imageUrl) and keep the most recent item.
            int millisFrom(dynamic ts) {
              if (ts == null) return 0;
              if (ts is Timestamp) return ts.millisecondsSinceEpoch;
              if (ts is int) return ts;
              if (ts is String) return int.tryParse(ts) ?? 0;
              return 0;
            }

            final Map<String, Map<String, dynamic>> unique = {};
            for (final item in rawItems) {
              final key = '${item['name'] ?? ''}::${item['imageUrl'] ?? ''}';
              if (!unique.containsKey(key)) {
                unique[key] = Map<String, dynamic>.from(item);
              } else {
                // Keep the most recent by createdAt
                final existing = unique[key]!;
                if (millisFrom(item['createdAt']) >
                    millisFrom(existing['createdAt'])) {
                  unique[key] = Map<String, dynamic>.from(item);
                }
              }
            }

            final items = unique.values.toList();

            // Sort client-side by timestamp if present (descending)
            items.sort(
              (a, b) => millisFrom(
                b['createdAt'],
              ).compareTo(millisFrom(a['createdAt'])),
            );

            return ListView.builder(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildRecentProductTile(items[index]);
              },
            );
          },
        ),
      ),
    );
  }
}
