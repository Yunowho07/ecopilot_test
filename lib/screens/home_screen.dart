import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/firebase_service.dart';
import '/auth/landing.dart';
import 'profile_screen.dart' as profile_screen;
import 'alternative_screen.dart' as alternative_screen;
import 'dispose_screen.dart' as dispose_screen;
import '/screens/scan_screen.dart';
import 'notification_screen.dart';
import 'setting_screen.dart';
import 'support_screen.dart';
import 'package:ecopilot_test/utils/color_extensions.dart';
import 'package:ecopilot_test/utils/constants.dart';
import 'package:ecopilot_test/widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _userName = 'User';
  String _tip = 'Loading tip...';
  String _challenge = 'Loading challenge...';
  List<Map<String, String>> _recentActivity = [];
  int _selectedIndex = 0; // For Bottom Navigation Bar

  // Use theme colors from constants
  final primaryGreen = const Color(0xFF4CAF50);
  final yellowAccent = const Color(0xFFFFEB3B);

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Recent activity will be loaded via a Firestore stream in the widget tree
  }

  // Fetch user data from the service
  void _loadUserData() {
    final user = _firebaseService.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? 'User';
      });
    }
  }

  Future<void> _handleSignOut() async {
    // Open the Notification screen instead of signing out
    if (mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AuthLandingScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Section
            Text(
              'Hello !',
              style: TextStyle(fontSize: 24, color: Colors.grey.shade700),
            ),
            Text(
              _userName,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              'Lets get started',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 25),

            // Today's Tips
            _buildTipsCard(),
            const SizedBox(height: 15),

            // Daily Eco Challenge
            _buildChallengeCard(),
            const SizedBox(height: 30),

            // Recent Activity
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            // Recent activity now comes from Firestore (users/{uid}/scans)
            Builder(
              builder: (context) {
                final user = FirebaseAuth.instance.currentUser;
                final Stream<QuerySnapshot<Map<String, dynamic>>>? scansStream =
                    user != null
                    ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('scans')
                          .orderBy('timestamp', descending: true)
                          .limit(10)
                          .withConverter<Map<String, dynamic>>(
                            fromFirestore: (snap, _) =>
                                snap.data() ?? <String, dynamic>{},
                            toFirestore: (m, _) => m,
                          )
                          .snapshots()
                    : null;

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: scansStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text(
                        'No recent activity yet. Scan a product to get started.',
                      );
                    }
                    final docs = snapshot.data!.docs;
                    return Column(
                      children: docs.map((doc) {
                        return _buildActivityTile(doc);
                      }).toList(),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 30),

            // Weekly Eco Score
            const Text(
              'Your Weekly Eco Score',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildScoreIndicator(),
            const SizedBox(height: 5),
            Row(
              children: [
                const Text(
                  "You're doing great keep doing! ",
                  style: TextStyle(color: Colors.grey),
                ),
                const Icon(Icons.eco, color: Colors.green, size: 18),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Menu Icon (Hamburger)
          GestureDetector(
            onTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            child: const Icon(Icons.menu, size: 30),
          ),
          // Notification Icon — navigate to NotificationScreen on tap
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: primaryGreen,
              child: const Icon(Icons.notifications_none, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Removed duplicate build method that caused name collision with the main build implementation.
  // If you need an alternatives screen, use the existing AlternativeScreen widget (imported as alternative_screen)
  // or extract this UI into a separate widget/class.

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colorWithOpacity(kPrimaryYellow, 0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.black, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's tips :",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(_tip, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: primaryGreen, size: 28),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Eco Challenge',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    _challenge,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Challenge marked complete!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Complete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder for the icon and text used for the boolean checks (✔ / ❌)
Widget _buildBooleanRow(String label, bool value) {
  final icon = value ? Icons.check_circle : Icons.cancel;
  final color = value ? Colors.green.shade600 : Colors.red.shade600;
  final text = value ? 'Yes' : 'No';

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $text',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    ),
  );
}

// Custom widget to display the product details, mimicking the image
Widget _buildProductDetailCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data();
  final name = (data['product_name'] ?? 'Unknown Product').toString();
  final category = (data['category'] ?? 'N/A').toString();
  final ingredients = (data['ingredients'] ?? 'N/A').toString();
  final score = (data['eco_score'] ?? 'A').toString().toUpperCase(); // Assuming A-E score
  final co2 = (data['carbon_footprint'] ?? '—').toString();
  final packaging = (data['packaging'] ?? 'N/A').toString();
  final disposal = (data['disposal_method'] ?? 'Rinse and recycle locally').toString();
  // Using the safe boolean read logic from your onTap function
  bool _readBool(dynamic v) {
    if (v is bool) return v;
    if (v is String)
      return v.toLowerCase() == 'true' || v.toLowerCase() == 'yes';
    if (v is num) return v != 0;
    return false;
  }
  final containsMicroplastics = _readBool(data['contains_microplastics']);
  final palmOilDerivative = _readBool(data['palm_oil_derivative']);
  final crueltyFree = _readBool(data['cruelty_free']);

  // Function to determine the color for the Eco-Score background
  Color _getEcoScoreColor(String s) {
    switch (s) {
      case 'A': return Colors.green.shade700;
      case 'B': return Colors.lightGreen.shade700;
      case 'C': return Colors.amber.shade700;
      case 'D': return Colors.orange.shade700;
      case 'E': return Colors.red.shade700;
      default: return Colors.grey.shade700;
    }
  }
  
  // Custom styled Text for detail sections
  Widget _detailText(String label, String value, {bool boldValue = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 14),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: TextStyle(fontWeight: boldValue ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  // --- Main Card Widget ---
  return Container(
    margin: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.8), // Dark background for the card area
      borderRadius: BorderRadius.circular(15.0),
      border: Border.all(color: Colors.green, width: 3.0),
    ),
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Product Details Section ---
        Text('Product Details', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const Divider(color: Colors.white54),
        _detailText('Name', name, boldValue: true),
        _detailText('Category', category),
        _detailText('Ingredients', ingredients),
        
        const SizedBox(height: 12),

        // --- Eco Impact Section ---
        Text('Eco Impact', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const Divider(color: Colors.white54),
        _detailText('Carbon Footprint', 'Estimated $co2 CO₂e per unit (Low impact for a skincare product)'),
        _detailText('Packaging', '$packaging (Type 4 - LDPE) ♻️'),
        _detailText('Suggested Disposal', disposal),

        const SizedBox(height: 12),

        // --- Environmental Warnings Section ---
        Text('Environmental Warnings:', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const Divider(color: Colors.white54),
        
        _buildBooleanRow('Contains microplastics?', !containsMicroplastics), // Inverting logic for display: X if contains, ✔ if not.
        _buildBooleanRow('Palm oil derivative?', !palmOilDerivative), // X if derivative, ✔ if not.
        _buildBooleanRow('Cruelty-Free', crueltyFree), // ✔ if cruelty-free, X if not.

        const SizedBox(height: 16),

        // --- ECO-SCORE Section (Simplified) ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ECO-SCORE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getEcoScoreColor(score),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                score,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
            //             // For a complete match, you'd add the A-E colored bar widget here.
          ],
        ),
      ],
    ),
  );
}

  Widget _buildActivityTile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final product =
        (data['product_name'] ?? data['product'] ?? 'Unknown product')
            .toString();
    final score = (data['eco_score'] ?? data['ecoscore'] ?? data['score'] ?? 'N/A')
        .toString()
        .toUpperCase();
    final ts = data['timestamp'];
    DateTime? dt;
    if (ts is Timestamp) {
      dt = ts.toDate();
    } else if (ts is DateTime) {
      dt = ts;
    }

    String _twoDigits(int n) => n.toString().padLeft(2, '0');
    String _formatDateTime(DateTime d) {
      final month = d.month;
      final day = d.day;
      final year = d.year;
      final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final minute = _twoDigits(d.minute);
      final ampm = d.hour >= 12 ? 'PM' : 'AM';
      return '$month/$day/$year ${_twoDigits(hour12)}:$minute $ampm';
    }

    final timeText = dt != null ? _formatDateTime(dt) : '';

    // Try common image keys
    String? imageUrl;
    final possibleKeys = ['image', 'image_url', 'product_image', 'thumbnail', 'photo', 'img'];
    for (final k in possibleKeys) {
      final v = data[k];
      if (v is String && v.isNotEmpty) {
        imageUrl = v;
        break;
      }
    }

    Color _getEcoScoreColor(String s) {
      switch (s) {
        case 'A':
          return Colors.green.shade700;
        case 'B':
          return Colors.lightGreen.shade700;
        case 'C':
          return Colors.amber.shade700;
        case 'D':
          return Colors.orange.shade700;
        case 'E':
          return Colors.red.shade700;
        default:
          return Colors.grey.shade700;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 56,
            height: 56,
            color: Colors.grey.shade200,
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 32,
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  )
                : const Icon(Icons.image, color: Colors.grey, size: 32),
          ),
        ),
        title: Text(product),
        subtitle: Text([
          if ((data['category'] ?? '').toString().isNotEmpty)
            data['category'].toString(),
          if (timeText.isNotEmpty) timeText, // includes exact time now
        ].join(' • ')),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _getEcoScoreColor(score),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(score,
              style:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.9,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (_, controller) => SingleChildScrollView(
                controller: controller,
                child: _buildProductDetailCard(doc),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreIndicator() {
    // Simple linear progress indicator to represent the score bar
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: 0.8, // 80% progress
            minHeight: 15,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey,
      onTap: (index) async {
        // When the Profile tab is tapped, open the Profile screen.
        if (index == 0) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const HomeScreen()));
          return; // don't change selected index when opening profile as a separate route
        }
        // When the Alternative tab is tapped, open the Alternative screen.
        if (index == 1) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const alternative_screen.AlternativeScreen(),
            ),
          );
          return; // don't change selected index when opening alternative as a separate route
        }
        // When Scan tab is tapped, open the ScanScreen and wait for result
        if (index == 2) {
          final result = await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ScanScreen()));

          if (result != null && result is Map<String, dynamic>) {
            // Add to recent activity list (basic shape for the home screen)
            setState(() {
              _recentActivity.insert(0, {
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

          return; // don't change selected index when opening scan as a separate route
        }
        if (index == 3) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const dispose_screen.DisposalGuidanceScreen(),
            ),
          );
          return; // don't change selected index when opening dispose as a separate route
        }
        // When the Profile tab is tapped, open the Profile screen.
        if (index == 4) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const profile_screen.ProfileScreen(),
            ),
          );
          return; // don't change selected index when opening profile as a separate route
        }

        setState(() {
          _selectedIndex = index;
        });
        // TODO: Implement navigation logic for the other tabs
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
}
