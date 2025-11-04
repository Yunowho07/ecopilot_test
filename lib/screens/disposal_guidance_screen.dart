import 'package:ecopilot_test/screens/alternative_screen.dart';
import 'package:ecopilot_test/screens/home_screen.dart';
import 'package:ecopilot_test/screens/scan_screen.dart' as scan_screen;
import 'package:ecopilot_test/screens/disposal_scan_screen.dart';
import 'package:ecopilot_test/screens/profile_screen.dart' as profile_screen;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
// Assuming the existence of this file for kPrimaryGreen
import 'package:ecopilot_test/utils/constants.dart'; 
import 'package:ecopilot_test/widgets/app_drawer.dart';
import 'package:ecopilot_test/screens/recent_activity_screen.dart';

// Assuming kPrimaryGreen is defined in constants.dart
const Color kPrimaryGreen = Color(0xFF4CAF50); // Default placeholder

class DisposalGuidanceScreen extends StatefulWidget {
  final String? productId;

  const DisposalGuidanceScreen({Key? key, this.productId}) : super(key: key);

  @override
  State<DisposalGuidanceScreen> createState() => _DisposalGuidanceScreenState();
}

class _DisposalGuidanceScreenState extends State<DisposalGuidanceScreen> {
  bool _loading = true;
  Map<String, dynamic>? _product;
  String? _error;
  static const Map<String, dynamic> _defaultData = {
    'name': 'General Recycling Guidance',
    'category': 'General Household Item', // Added category
    'material': 'Plastic (PET) / Aluminum',
    'ecoScore': 'B',
    'imageUrl':
        'https://placehold.co/600x800/A8D8B9/212121?text=Placeholder+Image', // Placeholder URL for demo image
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

  int _selectedIndex = 3;
  // Recent activity list is now managed by the new RecentActivityScreen

  @override
  void initState() {
    super.initState();
    // Load product only if an ID is passed (i.e., we are on the Details view)
    if (widget.productId != null && widget.productId != 'general_fallback') {
      _loadProduct();
    } else {
      _product = _defaultData;
      _loading = false;
    }
  }

  // NOTE: _loadRecentActivity is no longer needed here as it's moved to RecentActivityScreen.
  // We keep _saveScannedProduct as it is crucial for handling the result from DisposalScanScreen.

  Future<void> _loadProduct() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load from the user's scan history to get full product details
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scans')
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
          // Ensure null checks for essential fields
          if (_product != null) {
            _product!['name'] = _product!['name'] ?? 'Scanned Item';
            _product!['category'] = _product!['category'] ?? 'General';
            _product!['material'] = _product!['material'] ?? 'Unknown';
          }
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

  Future<void> _openMapsForRecycling() async {
    const mapsUrl =
        'https://www.google.com/maps/search/?api=1&query=recycling+center+near+me';
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

    // --- Generate a unique ID if not provided by the scanning system ---
    final String productId =
        (product['productId'] ??
                product['id'] ??
                DateTime.now().millisecondsSinceEpoch.toString())
            .toString();
    product['productId'] = productId;

    // Simulate saving the product data returned from the ScanScreen/Gemini
    await _saveScannedProduct(product);

    // Open the detail view for the newly scanned product
    if (mounted) {
      Navigator.of(context).pushReplacement( // Use pushReplacement to avoid stacking
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
        'category': product['category'] ?? 'General', // Added category
        'ecoScore': product['ecoScore'] ?? 'N/A',
        'imageUrl': product['imageUrl'] ?? '',
        'material': product['material'] ?? 'Unknown',
        'disposalSteps': product['disposalSteps'] ?? ['Rinse and recycle'],
        'tips': product['tips'] ?? ['Reduce waste'],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save scan: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save scan: $e')));
      }
    }
  }

  // --- UI Builders for Hub Elements ---

  Widget _styledHubCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? iconBgColor,
  }) {
    // Styling adjusted to match the clean, rounded look of the reference image
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

  // --- MAIN HUB VIEW ---
  Widget _buildDisposalHub() {
    return Container(
      // Background gradient effect to match the reference image
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

            // Action Cards
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
              icon: Icons.qr_code_scanner, // Changed to a more barcode-like icon
              title: 'Find Product',
              subtitle: 'Search by barcode or product name',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Search functionality (Barcode/Name) coming soon!'),
                  ),
                );
              },
            ),

            _styledHubCard(
              icon: Icons.history,
              title: 'Recent Activity',
              subtitle: 'View your recently scanned products',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RecentActivityScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Large CTA - Scan New Product (Uncommented and styled)
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

  // --- DETAIL GUIDANCE VIEW (Updated to match image) ---
  Widget _buildGuidanceDetail(BuildContext context) {
    final kGreen = kPrimaryGreen;
    final productData = _product!;

    final String name = productData['name'] ?? 'Unknown Item';
    final String category = productData['category'] ?? 'N/A'; // Using new field
    final String material = productData['material'] ?? 'N/A';
    final String ecoScore = productData['ecoScore'] ?? 'N/A';
    final List disposalSteps = productData['disposalSteps'] ?? [];
    final List tips = productData['tips'] ?? [];
    final String imageUrl = productData['imageUrl'] ?? '';

    // --- Helper to style the Eco Score badge ---
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

    // --- Placeholder for Nearby Center ---
    Widget _buildRecyclingCenterCard() {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              //  - Placeholder map image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(Icons.map, color: kGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Green Recycling Center',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const Text(
                      '0.5 km',
                      style: TextStyle(color: Colors.black54),
                    ),
                    Text(
                      'Open',
                      style: TextStyle(
                        color: kGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openMapsForRecycling,
                icon: const Icon(Icons.navigation, size: 18, color: Colors.white),
                label: const Text('Navigate', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
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
          // Top Product Card Section (Matches Image)
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
                // Product Image
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
                          child: Image.network(
                            imageUrl, 
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.delete_sweep, 
                              size: 40, 
                              color: Colors.grey.shade400,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.delete_sweep,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Category: $category',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Material',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      Text(
                        material,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      // Eco Score Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: getBgColor(ecoScore),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: getScoreColor(ecoScore),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Eco Score $ecoScore',
                          style: TextStyle(
                            color: getScoreColor(ecoScore),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // --- How to Dispose Section ---
          const Text(
            'How to Dispose',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: disposalSteps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value.toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ',
                      style: const TextStyle(
                        fontSize: 16, 
                        height: 1.5, 
                        fontWeight: FontWeight.bold, 
                        color: kPrimaryGreen
                      ),
                    ),
                    Expanded(
                      child: Text(
                        step,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Showing full disposal details...')),
              );
            },
            child: Text(
              'View More Details',
              style: TextStyle(
                color: kPrimaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- Nearby Recycling Center Section ---
          const Text(
            'Nearby Recycling Center',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildRecyclingCenterCard(),

          const SizedBox(height: 24),

          // --- Eco Tips Section ---
          const Text(
            'Eco Tips',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...tips
              .map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 24,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.toString(),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),

          const SizedBox(height: 40),

          // Done Button (Returns to Hub)
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
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
        // ... (Navigation logic is retained as is)
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
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart),label: 'Alternative',),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner),label: 'Scan',),
        BottomNavigationBarItem(icon: Icon(Icons.delete_sweep),label: 'Dispose',),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we are showing the detailed product guidance or the main hub
    final bool showDetail = widget.productId != null && !_loading;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        // Ensure the title bar uses the primary green color for the Hub view
        backgroundColor: showDetail ? kPrimaryGreen : kPrimaryGreen,
        foregroundColor: showDetail ? Colors.white : Colors.white,
        elevation: showDetail ? 4 : 0,
        centerTitle: true,
        title: Text(
          showDetail ? 'Disposal Details' : 'Disposal Guidance',
          style: TextStyle(
            color: showDetail ? Colors.white : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: showDetail,
        // Menu button on the Hub, back button on Details
        leading: showDetail
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        actions: [
          // IconButton(
          //   icon: Icon(
          //     Icons.recycling,
          //     color: showDetail ? kPrimaryGreen : Colors.white,
          //     size: 28,
          //   ),
          //   onPressed: () {},
          // ),
        ],
      ),
      // Body color is white/transparent for the gradient effect
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : showDetail
              ? _buildGuidanceDetail(context)
              : _buildDisposalHub(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}
