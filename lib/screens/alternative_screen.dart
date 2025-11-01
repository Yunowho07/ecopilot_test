// NOTE: These are required imports for the navigation logic provided.
// Since the full project structure is not provided, these are assumed imports.
import 'package:flutter/material.dart';
import 'package:ecopilot_test/widgets/app_drawer.dart';
import 'home_screen.dart'; // Assume this file exists
import 'scan_screen.dart'; // Assume this file exists
import 'dispose_screen.dart' as dispose_screen; // Assume this file exists
import 'profile_screen.dart' as profile_screen; // Assume this file exists

// Define global constants used in the provided navigation logic
const Color primaryGreen = Color(
  0xFF1DB954,
); // Assuming primaryGreen is the same as _kPrimaryGreenAlt

// The primary green color from the previous context
const Color _kPrimaryGreenAlt = Color(0xFF1DB954);

// Define colors for the ECO-SCORE segments based on standard traffic light colors
const Map<String, Color> _kEcoScoreColors = {
  'A+': Color(0xFF1DB954), // Dark Green
  'A': Color(0xFF4CAF50), // Green
  'B': Color(0xFF8BC34A), // Light Green
  'C': Color(0xFFFFC107), // Amber/Yellow
  'D': Color(0xFFFF9800), // Orange
  'E': Color(0xFFF44336), // Red
};

// --- Custom Data Model for an Alternative Product ---
class AlternativeProduct {
  final String name;
  final String ecoScore;
  final String materialType;
  final String benefit;
  final String whereToBuy;
  final String carbonSavings;
  final String imagePath; // Placeholder for image asset

  AlternativeProduct({
    required this.name,
    required this.ecoScore,
    required this.materialType,
    required this.benefit,
    required this.whereToBuy,
    required this.carbonSavings,
    required this.imagePath,
  });
}

// --- Sample Data (Replacing the generic ListView) ---
final List<AlternativeProduct> _sampleAlternatives = [
  AlternativeProduct(
    name: 'EcoBottle 500ml',
    ecoScore: 'A+',
    materialType: 'Stainless Steel',
    benefit: 'Reusable and BPA-free, reduces plastic waste',
    whereToBuy: 'Available on: EcoHaus, Amazon',
    carbonSavings: 'Reduces ~120kg CO₂ per year',
    imagePath: 'assets/images/ecobottle.png', // Placeholder
  ),
  AlternativeProduct(
    name: 'Bamboo Toothbrush (4-Pack)',
    ecoScore: 'A',
    materialType: 'Moso Bamboo',
    benefit: 'Compostable handle, sustainable fast-growing material',
    whereToBuy: 'Available at: Guardian, local eco-store',
    carbonSavings: 'Reduces 0.5kg plastic waste per year',
    imagePath: 'assets/images/bamboo_brush.png', // Placeholder
  ),
  AlternativeProduct(
    name: 'Recycled Glass Jar Candle',
    ecoScore: 'B',
    materialType: 'Recycled Glass & Soy Wax',
    benefit: 'Upcycled glass jar, clean-burning soy wax',
    whereToBuy: 'Available on: Etsy, HomeGoods',
    carbonSavings: 'Saves 0.2kg of virgin material use',
    imagePath: 'assets/images/candle.png', // Placeholder
  ),
];

// --- Custom Widget for the Eco-Score Badge ---
class EcoScoreBadge extends StatelessWidget {
  final String score;

  const EcoScoreBadge({Key? key, required this.score}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the color, defaulting to a gray if the score is not mapped
    final Color color = _kEcoScoreColors[score] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Eco-Score: $score',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

// --- Custom Widget for the Alternative Product Card ---
class AlternativeProductCard extends StatelessWidget {
  final AlternativeProduct product;

  const AlternativeProductCard({Key? key, required this.product})
    : super(key: key);

  // Helper method for the detail rows
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // [Image] Placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    // Using an icon as a placeholder for the product image
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 30,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Product Name and Eco-Score
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      EcoScoreBadge(score: product.ecoScore),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Detail Rows
            _buildDetailRow(
              Icons.layers,
              'Material Type',
              product.materialType,
            ),
            _buildDetailRow(
              Icons.sentiment_very_satisfied,
              'Benefit',
              product.benefit,
            ),
            _buildDetailRow(
              Icons.local_shipping,
              'Carbon Savings',
              product.carbonSavings,
            ),
            _buildDetailRow(
              Icons.shopping_cart,
              'Where to Buy',
              product.whereToBuy,
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.info_outline),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.grey[200], // Neutral background for details
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.link),
                    label: const Text('Buy Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _kPrimaryGreenAlt, // Green primary color for purchase
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Main Screen Widget (Stateful) ---
class AlternativeScreen extends StatefulWidget {
  const AlternativeScreen({Key? key}) : super(key: key);

  @override
  State<AlternativeScreen> createState() => _AlternativeScreenState();
}

class _AlternativeScreenState extends State<AlternativeScreen> {
  // Use a fixed index for this screen since it is a sub-route
  // 0: Home, 1: Alternative (Current), 2: Scan, 3: Dispose, 4: Profile
  final int _selectedIndex = 1;

  // NOTE: This list is necessary to prevent errors in the provided navigation logic.
  // In a real app, this data would likely be managed globally (e.g., via a state manager).
  final List<Map<String, String>> _recentActivity = [];

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      // Hardcode the index to 1 (Alternative) to visually highlight the current screen
      currentIndex: _selectedIndex,
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey,
      onTap: (index) async {
        // When the Home tab is tapped, open the Home screen.
        if (index == 0) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const HomeScreen()));
          return;
        }
        // When the Alternative tab is tapped, open the Alternative screen (or do nothing if already here).
        if (index == 1) {
          // Since we are already on the Alternative screen, we can simply pop to it
          // or do nothing. Pushing a new route of the same screen is redundant.
          return;
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

          return;
        }
        if (index == 3) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const dispose_screen.DisposalGuidanceScreen(),
            ),
          );
          return;
        }
        // When the Profile tab is tapped, open the Profile screen.
        if (index == 4) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const profile_screen.ProfileScreen(),
            ),
          );
          return;
        }

        // NOTE: The provided logic does not allow the index to be changed (setState)
        // because all navigations use push/return. Retaining the setState block just in case.
        // setState(() {
        //   _selectedIndex = index;
        // });
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
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        // Visible menu button to open drawer
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Alternative Products',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: _kPrimaryGreenAlt,
        elevation: 2,
      ),
      backgroundColor: Colors.grey[50], // Light background for better contrast
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section ---
            const Text(
              '🌱 Greener Alternatives Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Here are eco-friendly replacements for your scanned product.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // --- List of Alternative Product Cards ---
            ..._sampleAlternatives.map((product) {
              return AlternativeProductCard(product: product);
            }).toList(),

            const SizedBox(height: 20), // Padding at the bottom
          ],
        ),
      ),
      // --- Bottom Navigation Bar Integration ---
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}
