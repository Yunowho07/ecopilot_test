import 'package:ecopilot_test/screens/alternative_screen.dart';
import 'package:ecopilot_test/screens/home_screen.dart';
import 'package:ecopilot_test/screens/scan_screen.dart' as scan_screen;
import 'package:ecopilot_test/screens/profile_screen.dart' as profile_screen;
import 'package:flutter/material.dart';
import 'package:ecopilot_test/utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ecopilot_test/utils/cloudinary_config.dart';
import 'package:ecopilot_test/services/cloudinary_service.dart';
import 'dart:io' show File;
import 'dart:typed_data';

// Use the project's global primary color from utils/constants.dart

class DisposalGuidanceScreen extends StatefulWidget {
  // productId remains optional to allow calling this screen as the main hub (null)
  // or as the detail view (when productId is provided).
  final String? productId;
  const DisposalGuidanceScreen({Key? key, this.productId}) : super(key: key);

  @override
  State<DisposalGuidanceScreen> createState() => _DisposalGuidanceScreenState();
}

class _DisposalGuidanceScreenState extends State<DisposalGuidanceScreen> {
  // theme color (use the top-level constant)

  // --- State for the Detail View (Used if productId is NOT null) ---
  bool _loading = true;
  Map<String, dynamic>? _product;
  String? _error;
  static const Map<String, dynamic> _defaultData = {
    'name': 'General Recycling Guidance',
    'ecoScore': 'B',
    'imageUrl': null,
    'materials': ['Plastic (General)', 'Paper', 'Aluminum'],
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
  // -----------------------------------------------------------------

  // State used by the bottom navigation helper
  int _selectedIndex = 3;
  final List<Map<String, dynamic>> _recentActivity = [];

  // Simulated recent products for the main hub view (matching image)
  final List<Map<String, dynamic>> _simulatedRecentProducts = [
    {
      'id': 'prod1',
      'name': 'Green Tea Sunblock',
      'ecoScore': 'C',
      'co2': '36g CO2 saved',
    },
    {
      'id': 'prod2',
      'name': 'BambooClean 2.0',
      'ecoScore': 'A+',
      'co2': '123g CO2 saved',
    },
    {
      'id': 'prod3',
      'name': 'EcoPaste Mint+',
      'ecoScore': 'B+',
      'co2': '50g CO2 saved',
    },
    {
      'id': 'prod4',
      'name': 'RefillRoll Deodorant',
      'ecoScore': 'A-',
      'co2': '74g CO2 saved',
    },
    {
      'id': 'prod5',
      'name': 'GreenBrush Eco',
      'ecoScore': 'A',
      'co2': '98g CO2 saved',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Only attempt to load product data if we have an ID (i.e., we are in detail mode)
    if (widget.productId != null) {
      _loadProduct();
    } else {
      // If no ID, immediately show the main hub UI
      _loading = false;
    }
  }

  // --- PRODUCT LOADING LOGIC (Detail Mode) ---
  Future<void> _loadProduct() async {
    // This logic is only executed if widget.productId != null
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ⚠️ NOTE: This assumes a 'products' collection exists in Firestore
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();
      if (!doc.exists) {
        setState(() {
          _product = _defaultData;
          _error = 'Specific product guidance not found. Showing general tips.';
        });
      } else {
        setState(() {
          _product = doc.data();
        });
      }
    } catch (e) {
      setState(() {
        _product = _defaultData;
        _error = 'Failed to load product. Showing general tips.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // --- MAPS FUNCTIONALITY (Detail Mode) ---
  Future<void> _openMapsForRecycling() async {
    final query = Uri.encodeComponent('Recycling center near me');
    // Using a standard map search URL
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open maps. Please ensure you have a browser or map app installed.',
          ),
        ),
      );
    }
  }

  // Handle result returned by the Scan screen.
  // The Scan screen is expected to return a Map<String, dynamic> with product info.
  Future<void> _handleScanResult(dynamic result) async {
    if (result == null) return;

    // Normalize result into a product map
    Map<String, dynamic> product = {};
    if (result is Map<String, dynamic>) {
      product = Map<String, dynamic>.from(result);
    } else {
      // If it's another shape, try to stringify it minimally
      product = {'name': result.toString()};
    }

    // Ensure there's an ID we can use for storage/navigation
    final String productId =
        (product['productId'] ??
                product['id'] ??
                DateTime.now().millisecondsSinceEpoch.toString())
            .toString();
    product['productId'] = productId;

    // Persist the scanned product to Firestore under the user's scans collection
    await _saveScannedProduct(product);

    // Update local recent activity list for immediate UX feedback
    setState(() {
      _recentActivity.insert(0, {
        'id': productId,
        'name': product['name'] ?? 'Scanned product',
        'ecoScore': product['ecoScore'] ?? 'N/A',
        'co2': product['co2'] ?? '—',
      });
    });

    // Open the detail view for the newly scanned product
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DisposalGuidanceScreen(productId: productId),
        ),
      );
    }
  }

  // Save a scanned product to Firestore under the current user's scans subcollection.
  Future<void> _saveScannedProduct(Map<String, dynamic> product) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

      // If the product contains local image bytes or a local file path and
      // Cloudinary configuration is provided, attempt to upload.
      try {
        final cloudName = kCloudinaryCloudName;
        final preset = kCloudinaryUploadPreset;

        if ((cloudName.isNotEmpty && cloudName != '<YOUR_CLOUD_NAME>') &&
            (preset.isNotEmpty && preset != '<YOUR_UNSIGNED_UPLOAD_PRESET>')) {
          String? uploadedUrl;

          if (product['imageBytes'] != null &&
              product['imageBytes'] is Uint8List) {
            uploadedUrl = await CloudinaryService.uploadImageBytes(
              product['imageBytes'] as Uint8List,
              filename:
                  '${product['productId'] ?? DateTime.now().millisecondsSinceEpoch}.jpg',
              cloudName: cloudName,
              uploadPreset: preset,
            );
          } else if (product['localImagePath'] != null &&
              product['localImagePath'] is String) {
            try {
              final file = File(product['localImagePath'] as String);
              if (await file.exists()) {
                final bytes = await file.readAsBytes();
                uploadedUrl = await CloudinaryService.uploadImageBytes(
                  bytes,
                  filename:
                      '${product['productId'] ?? DateTime.now().millisecondsSinceEpoch}.jpg',
                  cloudName: cloudName,
                  uploadPreset: preset,
                );
              }
            } catch (_) {
              // ignore file read errors, we'll continue to save without image
            }
          }

          if (uploadedUrl != null) {
            product['imageUrl'] = uploadedUrl;
          }
        }
      } catch (_) {
        // Non-fatal: if upload fails, continue and store product without imageUrl
      }
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scans')
          .doc(product['productId'].toString());

      await docRef.set({
        'name': product['name'] ?? 'Scanned product',
        'ecoScore': product['ecoScore'] ?? 'N/A',
        'imageUrl': product['imageUrl'] ?? '',
        'materials': product['materials'] ?? [],
        'disposalSteps': product['disposalSteps'] ?? [],
        'tips': product['tips'] ?? [],
        'raw': product['raw'] ?? null,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save scan: $e')));
      }
    }
  }

  // --- UI Builders for Hub Elements ---

  Widget _buildScanCard() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Icon(
          Icons.camera_alt_outlined,
          color: kPrimaryGreen,
          size: 36,
        ),
        title: const Text(
          'Scan Product',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () async {
          // Navigate to the Scan screen to start a new analysis and await the result
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const scan_screen.ScanScreen()),
          );

          // If a scan result is returned, persist it and open the detail view
          if (result != null) {
            await _handleScanResult(result);
          }
        },
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(Icons.search, color: Colors.black54, size: 32),
        title: Text(
          'Search Product',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        subtitle: const Text('Sunblock Shampoo'), // Placeholder text
        onTap: () {
          // TODO: Implement search functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Search functionality coming soon!')),
          );
        },
      ),
    );
  }

  Widget _buildRecentProductTile(Map<String, dynamic> product) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: kPrimaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.recycling, color: kPrimaryGreen, size: 24),
      ),
      title: Text(product['name']!),
      subtitle: Text(
        'Eco Score : ${product['ecoScore']} | ${product['co2']}',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // Navigate to the detail view for this specific product ID
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DisposalGuidanceScreen(productId: product['id']),
          ),
        );
      },
    );
  }

  // --- MAIN HUB VIEW ---
  Widget _buildDisposalHub() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Scan a Product to',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.normal),
          ),
        ),
        const Center(
          child: Text(
            'Get Disposal Guidance',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),

        // 1. Scan Product Button
        _buildScanCard(),

        // 2. Search Product Card
        _buildSearchCard(),

        const SizedBox(height: 20),

        // 3. Recent Product List Header
        const Text(
          'Recent Product',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // Recent Products
        // NOTE: In a real app, this should be a StreamBuilder fetching data from Firebase
        ..._simulatedRecentProducts
            .map((p) => _buildRecentProductTile(p))
            .toList(),

        const SizedBox(height: 30),

        // 4. Analyzed Product Button (For general/fallback tips)
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              // Open the General Guidance view (uses a placeholder ID or null)
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DisposalGuidanceScreen(
                    productId: 'general_fallback',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: const Text(
              'ANALYZED PRODUCT',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- DETAIL GUIDANCE VIEW ---
  Widget _buildGuidanceDetail(BuildContext context) {
    const kGreen = Color(0xFF1db954);
    final productData = _product!;

    // This widget serves as the detail view, only rendered when productId is not null
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading:
                  productData['imageUrl'] != null &&
                      (productData['imageUrl'] as String).isNotEmpty
                  ? Image.network(
                      productData['imageUrl'] as String,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Icon(
                        Icons.recycling, // Default icon for disposal screen
                        size: 48,
                        color: kGreen,
                      ),
                    )
                  : SizedBox(
                      width: 72,
                      height: 72,
                      child: Icon(Icons.recycling, size: 48, color: kGreen),
                    ),
              title: Text(
                productData['name'] ?? 'Unknown product',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Eco Score: ${productData['ecoScore'] ?? 'N/A'}'),
              trailing: widget.productId != null && _error != null
                  ? const Icon(Icons.warning, color: Colors.orange)
                  : null,
            ),
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Material Section
          const Text(
            'Detected Materials',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.from(
              ((productData['materials'] ?? <dynamic>[]) as List).map(
                (m) => Chip(
                  label: Text(m.toString()),
                  backgroundColor: kGreen.withOpacity(0.1),
                  labelStyle: TextStyle(color: kGreen),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Guidance Section
          const Text(
            'How to Dispose',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Column(
            children: List<Widget>.from(
              ((productData['disposalSteps'] ?? <dynamic>[]) as List).map((
                step,
              ) {
                final s = step.toString().toLowerCase();
                IconData icon = Icons.recycling;
                Color color = kGreen;
                if (s.contains('compost')) {
                  icon = Icons.eco;
                  color = Colors.brown;
                } else if (s.contains('trash') || s.contains('landfill')) {
                  icon = Icons.delete_outline;
                  color = Colors.grey;
                } else if (s.contains('recycle') || s.contains('recycling')) {
                  icon = Icons.recycling;
                  color = kGreen;
                }

                return ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(step.toString()),
                );
              }),
            ),
          ),

          const SizedBox(height: 20),

          // Map Button
          ElevatedButton.icon(
            onPressed: _openMapsForRecycling,
            icon: const Icon(Icons.location_on),
            label: const Text('Find Nearest Recycling Center'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tips Section
          const Text(
            'Eco Tips',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.from(
              ((productData['tips'] ?? <dynamic>[]) as List).map(
                (t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t.toString())),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Done Button
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(), // Returns to the Hub screen
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // -------------------------------------------------------------

  // --- BOTTOM NAV BAR (RETAINED) ---
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      selectedItemColor: kPrimaryGreen,
      unselectedItemColor: Colors.grey,
      onTap: (index) async {
        if (index == 0) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else if (index == 1) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AlternativeScreen()));
        } else if (index == 2) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const scan_screen.ScanScreen()),
          );
        } else if (index == 3) {
          // If already on Dispose, navigate to the main Hub (productId: null)
          if (widget.productId != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const DisposalGuidanceScreen(productId: null),
              ),
            );
          }
          return;
        } else if (index == 4) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const profile_screen.ProfileScreen(),
            ),
          );
        }

        setState(() {
          _selectedIndex = index;
        });
      },
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Alternative',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Scan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.delete_sweep),
          label: 'Dispose',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // If loading or if a specific product ID was passed, show the detail view.
    // Otherwise, show the main hub view.
    final bool showDetail = widget.productId != null && !_loading;

    return Scaffold(
      appBar: AppBar(
        title: Text(showDetail ? 'Disposal Guidance' : 'Dispose'),
        backgroundColor: kPrimaryGreen,
        automaticallyImplyLeading:
            showDetail, // Only show back button in detail mode
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: showDetail
                  ? _buildGuidanceDetail(context)
                  : _buildDisposalHub(),
            ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}
