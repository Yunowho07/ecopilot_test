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
    final String imageUrl = product['imageUrl'] ?? '';
    final dynamic createdAt = product['createdAt'];
    final int ecoScore = product['eco_score'] ?? product['ecoScore'] ?? 0;

    // Format date/time
    String formattedDateTime = 'Recently';
    if (createdAt != null) {
      DateTime dt;
      if (createdAt is Timestamp) {
        dt = createdAt.toDate();
      } else if (createdAt is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(createdAt);
      } else {
        dt = DateTime.now();
      }
      formattedDateTime =
          '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }

    // Convert score to grade
    String getEcoGrade(int score) {
      if (score >= 80) return 'A';
      if (score >= 60) return 'B';
      if (score >= 40) return 'C';
      if (score >= 20) return 'D';
      if (score > 0) return 'E';
      return 'N/A';
    }

    // Get eco score color based on grade
    Color getEcoScoreColor(int score) {
      final ecoScoreColors = {
        'A': kResultCardGreen,
        'B': kDiscoverMoreGreen,
        'C': kPrimaryYellow,
        'D': kRankSustainabilityHero,
        'E': kWarningRed,
        'N/A': Colors.grey.shade600,
      };
      return ecoScoreColors[getEcoGrade(score)] ?? Colors.grey.shade600;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DisposalGuidanceScreen(productId: product['id']),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image with Hero animation
              Hero(
                tag: 'disposal_${product['id']}',
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        kPrimaryGreen.withOpacity(0.3),
                                        kPrimaryGreen.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.delete_sweep,
                                    color: kPrimaryGreen,
                                    size: 40,
                                  ),
                                ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  kPrimaryGreen.withOpacity(0.3),
                                  kPrimaryGreen.withOpacity(0.1),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.delete_sweep,
                              color: kPrimaryGreen,
                              size: 40,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Name
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: kPrimaryGreen.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                    // Material Info
                    Row(
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            material,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Date/Time
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDateTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Eco Score Badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: getEcoScoreColor(ecoScore),
                  boxShadow: [
                    BoxShadow(
                      color: getEcoScoreColor(ecoScore).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ecoScore.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'ECO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
