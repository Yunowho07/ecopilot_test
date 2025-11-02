import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/screens/scan_screen.dart' show ResultScreen, ProductAnalysisData;
import '/utils/constants.dart';

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
        title: const Text('All Scans'),
        backgroundColor: kPrimaryGreen,
      ),
      body: scansStream == null
          ? const Center(child: Text('Please sign in to see your scans.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: scansStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No scans yet.'));
                }

                final docs = snapshot.data!.docs;
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final product = _readString(
                      data['product_name'] ??
                          data['analysis'] ??
                          'Scanned product',
                    );
                    final score = _readString(data['eco_score'] ?? 'N/A');
                    final co2 = _readString(data['carbon_footprint'] ?? '—');
                    final imageUrl = _readString(data['image_url'] ?? '');

                    return ListTile(
                      onTap: () {
                        final analysisData = ProductAnalysisData(
                          imageFile: null,
                          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
                          productName: product,
                          category: _readString(
                            data['category'] ??
                                data['product_category'] ??
                                'N/A',
                          ),
                          ingredients: _readString(
                            data['ingredients'] ?? data['analysis'] ?? 'N/A',
                          ),
                          carbonFootprint: _readString(
                            data['carbon_footprint'] ??
                                data['carbonFootprint'] ??
                                'N/A',
                          ),
                          packagingType: _readString(
                            data['packaging'] ??
                                data['packaging_type'] ??
                                'N/A',
                          ),
                          disposalMethod: _readString(
                            data['disposal_method'] ??
                                data['disposalMethod'] ??
                                'N/A',
                          ),
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
                      leading: imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                imageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) =>
                                    const Icon(Icons.image_not_supported),
                              ),
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.recycling,
                                color: Colors.grey,
                              ),
                            ),
                      title: Text(
                        product,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Eco Score: $score • $co2'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    );
                  },
                );
              },
            ),
    );
  }
}
