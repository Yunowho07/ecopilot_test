import 'package:ecopilot_test/screens/scan_screen.dart' hide ProfileScreen;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ecopilot_test/screens/disposal_scan_screen.dart';
// Avoid importing kPrimaryGreen twice: hide it from the recent_disposal import
import 'package:ecopilot_test/screens/recent_disposal_screen.dart';
import 'package:ecopilot_test/utils/constants.dart';
import 'package:ecopilot_test/widgets/app_drawer.dart';
import 'package:ecopilot_test/widgets/bottom_navigation.dart';
import 'package:ecopilot_test/screens/home_screen.dart';
import 'package:ecopilot_test/screens/alternative_screen.dart';
import 'package:ecopilot_test/screens/profile_screen.dart';

/// Clean Disposal Guidance screen (hub + details).
class DisposalGuidanceScreen extends StatefulWidget {
  final String? productId;
  const DisposalGuidanceScreen({Key? key, this.productId}) : super(key: key);

  @override
  State<DisposalGuidanceScreen> createState() => _DisposalGuidanceScreenState();
}

class _DisposalGuidanceScreenState extends State<DisposalGuidanceScreen> {
  bool _loading = true;
  Map<String, dynamic>? _product;
  int _selectedIndex = 3; // default to Dispose tab
  // Recent disposal list used when returning from ScanScreen (kept in memory for this view)
  final List<Map<String, dynamic>> _recentDisposal = [];

  static const Map<String, dynamic> _defaultData = {
    'name': 'General Recycling Guidance',
    'category': 'General Household Item',
    'material': 'Plastic / Mixed',
    'ecoScore': 'B',
    'imageUrl':
        'https://placehold.co/600x800/A8D8B9/212121?text=Placeholder+Image',
    'disposalSteps': [
      'Separate plastics, paper, and glass.',
      'Rinse containers thoroughly before recycling.',
      'Flatten cardboard boxes.',
      'Check local guidelines for battery disposal.',
    ],
    'tips': [
      'Always aim to reuse items before recycling.',
      'Composting food waste significantly reduces landfill volume.',
    ],
  };

  @override
  void initState() {
    super.initState();
    if (widget.productId != null && widget.productId != 'general_fallback') {
      _loadProduct();
    } else {
      _product = _defaultData;
      _loading = false;
    }
  }

  Future<void> _loadProduct() async {
    setState(() {
      _loading = true;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scans')
          .doc(widget.productId)
          .get();
      if (!doc.exists) {
        _product = _defaultData;
        // specific product guidance not found, continue with general tips
      } else {
        _product = doc.data();
        if (_product != null) {
          _product!['name'] = _product!['name'] ?? 'Scanned Item';
          _product!['category'] = _product!['category'] ?? 'General';
          _product!['material'] = _product!['material'] ?? 'Unknown';
        }
      }
    } catch (e) {
      _product = _defaultData;
      // failed to load product – show general tips
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMapsForRecycling([
    String query = 'recycling center near me',
  ]) async {
    final mapsUrl =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
    final url = Uri.parse(mapsUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open maps.')));
      }
    }
  }

  Future<void> _handleScanResult(dynamic result) async {
    if (result == null || result is! Map<String, dynamic>) return;
    final Map<String, dynamic> product = Map<String, dynamic>.from(result);
    final String productId =
        (product['productId'] ??
                product['id'] ??
                DateTime.now().millisecondsSinceEpoch.toString())
            .toString();
    product['productId'] = productId;
    await _saveScannedProduct(product);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DisposalGuidanceScreen(productId: productId),
        ),
      );
    }
  }

  Future<void> _saveScannedProduct(Map<String, dynamic> product) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scans')
          .doc(product['productId'].toString());
      await docRef.set({
        'name': product['name'] ?? 'Scanned product',
        'category': product['category'] ?? 'General',
        'ecoScore': product['ecoScore'] ?? 'N/A',
        'imageUrl': product['imageUrl'] ?? '',
        'material': product['material'] ?? 'Unknown',
        'disposalSteps': product['disposalSteps'] ?? ['Rinse and recycle'],
        'tips': product['tips'] ?? ['Reduce waste'],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save scan: $e');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save scan: $e')));
    }
  }

  Widget _styledHubCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? iconBgColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: iconBgColor ?? kPrimaryGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kPrimaryGreen, size: 30),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.black38,
        ),
      ),
    );
  }

  Widget _buildDisposalHub() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kPrimaryGreen.withOpacity(0.1), Colors.white],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _styledHubCard(
              icon: Icons.camera_alt_outlined,
              title: 'Scan Product',
              subtitle: 'Use your camera to identify product materials',
              onTap: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DisposalScanScreen()),
                );
                if (result != null) await _handleScanResult(result);
              },
            ),
            _styledHubCard(
              icon: Icons.qr_code_scanner,
              title: 'Find Product',
              subtitle: 'Search by barcode or product name',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Search functionality (Barcode/Name) coming soon!',
                  ),
                ),
              ),
            ),
            _styledHubCard(
              icon: Icons.history,
              title: 'Recent Disposal',
              subtitle: 'View your recently disposed products',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RecentDisposalScreen()),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 22, color: Colors.white),
                label: const Text(
                  'Scan New Product',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  elevation: 4,
                ),
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DisposalScanScreen(),
                    ),
                  );
                  if (result != null) await _handleScanResult(result);
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidanceDetail(BuildContext context) {
    final productData = _product!;
    final String name = productData['name'] ?? 'Unknown Item';
    final String category = productData['category'] ?? 'N/A';
    final String material = productData['material'] ?? 'N/A';
    final String ecoScore = productData['ecoScore'] ?? 'N/A';
    final List disposalSteps = productData['disposalSteps'] ?? [];
    final List tips = productData['tips'] ?? [];
    final String imageUrl = productData['imageUrl'] ?? '';

    Color getScoreColor(String score) {
      if (score.startsWith('A')) return Colors.green.shade600;
      if (score.startsWith('B')) return Colors.lightGreen.shade600;
      if (score.startsWith('C')) return Colors.amber.shade600;
      return Colors.grey;
    }

    Color getBgColor(String score) {
      if (score.startsWith('A')) return Colors.green.shade50;
      if (score.startsWith('B')) return Colors.lightGreen.shade50;
      if (score.startsWith('C')) return Colors.amber.shade50;
      return Colors.grey.shade50;
    }

    Widget _buildRecyclingCenterCard() {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Icon(Icons.map, color: kPrimaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Green Recycling Center',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text('0.5 km', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () =>
                    _openMapsForRecycling('Green Recycling Center'),
                child: const Text('Navigate'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(imageUrl, fit: BoxFit.cover),
                        )
                      : const Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: Colors.black26,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Chip(label: Text(category)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: getBgColor(ecoScore),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Eco: $ecoScore',
                              style: TextStyle(
                                color: getScoreColor(ecoScore),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Material: $material',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Disposal Steps',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...disposalSteps.map(
                    (s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s.toString())),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tips',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...tips.map(
                    (t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text('• ${t.toString()}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildRecyclingCenterCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return AppBottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) async {
        if (index == 0) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const HomeScreen()));
          return;
        }
        if (index == 1) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AlternativeScreen()));
          return;
        }
        if (index == 2) {
          final result = await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ScanScreen()));

          if (result != null && result is Map<String, dynamic>) {
            // Add to recent disposal list (basic shape for the home screen)
            setState(() {
              _recentDisposal.insert(0, {
                'product': result['product'] ?? 'Scanned product',
                'score':
                    result['raw'] != null &&
                        result['raw']['ecoscore_score'] != null
                    ? (result['raw']['ecoscore_score'].toString())
                    : 'N/A',
                'co2':
                    result['raw'] != null &&
                        result['raw']['carbon_footprint'] != null
                    ? result['raw']['carbon_footprint'].toString()
                    : '—',
              });
            });
          }

          return;
        }
        if (index == 3) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const DisposalGuidanceScreen()));
          return;
        }
        if (index == 4) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          return;
        }
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showDetail = widget.productId != null && !_loading;
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        centerTitle: true,
        // Show drawer on the hub, but show a back button on the details view
        leading: showDetail
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  // Return to the hub (clear productId)
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) =>
                          const DisposalGuidanceScreen(productId: null),
                    ),
                  );
                },
              )
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
        title: Text(
          showDetail ? 'Disposal Details' : 'Disposal Guidance',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : showDetail
          ? _buildGuidanceDetail(context)
          : _buildDisposalHub(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}
