import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecopilot_test/screens/result_screen.dart';
import 'package:ecopilot_test/models/product_analysis_data.dart';
import '/utils/constants.dart';
import 'package:intl/intl.dart';

class RecentActivityScreen extends StatelessWidget {
  const RecentActivityScreen({Key? key}) : super(key: key);

  bool _readBool(dynamic v) {
    if (v is bool) return v;
    if (v is String)
      return v.toLowerCase() == 'true' || v.toLowerCase() == 'yes';
    if (v is num) return v != 0;
    return false;
  }

  String _readString(dynamic v) {
    if (v == null) return 'N/A';
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Query the per-user scans saved by the scan flows (they write 'timestamp').
    final Stream<QuerySnapshot<Map<String, dynamic>>>? scansStream =
        user != null
        ? FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('scans')
              .orderBy('timestamp', descending: true)
              .withConverter<Map<String, dynamic>>(
                fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
                toFirestore: (m, _) => m,
              )
              .snapshots()
        : null;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Scan History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: kPrimaryGreen,
      ),
      body: Container(
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
        child: scansStream == null
            ? const Center(child: Text('Please sign in to see your scans.'))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: scansStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading scans: ${snapshot.error}'),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No scans yet.'));
                  }

                  final docs = snapshot.data!.docs;
                  // Client-side filter to exclude disposal-specific scans
                  final filtered = docs.where((doc) {
                    final m = doc.data();
                    final v = m['isDisposal'];
                    return v == null ? true : (v == false);
                  }).toList();
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final data = doc.data();

                      final product = _readString(
                        data['name'] ??
                            data['product_name'] ??
                            data['productName'] ??
                            'Scanned product',
                      );

                      final score = _readString(
                        data['eco_score'] ?? data['ecoScore'] ?? 'N/A',
                      );

                      final co2 = _readString(
                        data['carbon_footprint'] ??
                            data['carbonFootprint'] ??
                            '—',
                      );

                      final imageUrl = _readString(
                        data['image_url'] ??
                            data['imageUrl'] ??
                            data['image'] ??
                            '',
                      );

                      final category = _readString(
                        data['category'] ??
                            data['product_category'] ??
                            data['productCategory'] ??
                            'N/A',
                      );

                      final ingredients = _readString(
                        data['ingredients'] ??
                            data['ingredient_list'] ??
                            data['ingredientList'] ??
                            'N/A',
                      );

                      String packaging = _readString(
                        data['packaging'] ??
                            data['packaging_type'] ??
                            data['packagingType'] ??
                            'N/A',
                      );

                      String disposalMethod = 'N/A';
                      if (data['disposal_method'] != null) {
                        disposalMethod = _readString(data['disposal_method']);
                      } else if (data['disposalMethod'] != null) {
                        disposalMethod = _readString(data['disposalMethod']);
                      } else if (data['disposalSteps'] != null) {
                        final ds = data['disposalSteps'];
                        if (ds is List)
                          disposalMethod = ds.join(' • ');
                        else
                          disposalMethod = _readString(ds);
                      }

                      DateTime? created;
                      final createdRaw =
                          data['createdAt'] ??
                          data['created_at'] ??
                          data['timestamp'];
                      if (createdRaw is Timestamp)
                        created = createdRaw.toDate();
                      else if (createdRaw is int)
                        created = DateTime.fromMillisecondsSinceEpoch(
                          createdRaw,
                        );
                      else if (createdRaw is String) {
                        try {
                          created = DateTime.parse(createdRaw);
                        } catch (_) {}
                      }

                      String formattedDate = created != null
                          ? DateFormat.yMMMd().add_jm().format(created)
                          : '';

                      Color scoreColor(String s) {
                        if (s.isEmpty) return Colors.grey;
                        final c = s.trim().toUpperCase();
                        if (c.startsWith('A')) return Colors.green.shade600;
                        if (c.startsWith('B')) return Colors.lightGreen;
                        if (c.startsWith('C')) return Colors.orange;
                        if (c.startsWith('D')) return Colors.deepOrange;
                        if (c.startsWith('E')) return Colors.redAccent;
                        return Colors.grey;
                      }

                      // Card UI
                      return Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            final analysisData = ProductAnalysisData(
                              imageFile: null,
                              imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
                              productName: product,
                              category: category,
                              ingredients: ingredients,
                              carbonFootprint: _readString(
                                data['carbon_footprint'] ??
                                    data['carbonFootprint'] ??
                                    'N/A',
                              ),
                              packagingType: packaging,
                              disposalMethod: disposalMethod,
                              containsMicroplastics: _readBool(
                                data['contains_microplastics'] ??
                                    data['containsMicroplastics'],
                              ),
                              palmOilDerivative: _readBool(
                                data['palm_oil_derivative'] ??
                                    data['palmOilDerivative'],
                              ),
                              crueltyFree: _readBool(
                                data['cruelty_free'] ?? data['crueltyFree'],
                              ),
                              ecoScore: _readString(
                                data['eco_score'] ?? data['ecoScore'] ?? score,
                              ),
                            );

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ResultScreen(analysisData: analysisData),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.image_not_supported,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.recycling,
                                            color: Colors.grey,
                                            size: 36,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 14),
                                // Text area
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              category,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green.shade800,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            '•',
                                            style: TextStyle(
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Eco: $score',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'CO₂: $co2',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Right column: score badge and date
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: scoreColor(score),
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: Text(
                                        score,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
