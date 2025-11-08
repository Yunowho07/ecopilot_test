import 'package:flutter/material.dart';
import 'alternative_screen.dart' as alternative_screen;
import '../models/product_analysis_data.dart';
import 'package:ecopilot_test/utils/constants.dart';

class ResultScreen extends StatelessWidget {
  final ProductAnalysisData analysisData;

  const ResultScreen({Key? key, required this.analysisData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Modern Hero Header with Product Image
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            backgroundColor: kPrimaryGreen,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                // decoration: BoxDecoration(
                //   color: Colors.black.withOpacity(0.6),
                //   borderRadius: BorderRadius.circular(20),
                // ),
                // child: const Text(
                //   'Product Analysis',
                //   style: TextStyle(
                //     color: Colors.white,
                //     fontWeight: FontWeight.bold,
                //     fontSize: 16,
                //   ),
                // ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Product Image
                  if (analysisData.imageUrl != null &&
                      analysisData.imageUrl!.isNotEmpty)
                    Image.network(
                      analysisData.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) =>
                          analysisData.imageFile != null
                          ? Image.file(
                              analysisData.imageFile!,
                              fit: BoxFit.cover,
                            )
                          : _buildImagePlaceholder(),
                    )
                  else if (analysisData.imageFile != null)
                    Image.file(analysisData.imageFile!, fit: BoxFit.cover)
                  else
                    _buildImagePlaceholder(),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product Name & Eco Score Card
                  _buildProductHeaderCard(),
                  const SizedBox(height: 20),

                  // Product Details Card
                  _buildModernCard(
                    title: 'Product Details',
                    icon: Icons.info_outline,
                    iconColor: Colors.blue.shade600,
                    child: Column(
                      children: [
                        _buildModernInfoRow(
                          'Product Name',
                          analysisData.productName,
                          Icons.shopping_bag_outlined,
                          Colors.blue.shade600,
                        ),
                        const SizedBox(height: 12),
                        _buildModernInfoRow(
                          'Category',
                          analysisData.category,
                          Icons.category_outlined,
                          Colors.purple.shade600,
                        ),
                        const SizedBox(height: 12),
                        _buildModernInfoRow(
                          'Ingredients',
                          analysisData.ingredients,
                          Icons.science_outlined,
                          Colors.orange.shade600,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Eco Impact Card
                  _buildModernCard(
                    title: 'Environmental Impact',
                    icon: Icons.eco_outlined,
                    iconColor: kPrimaryGreen,
                    child: Column(
                      children: [
                        _buildImpactRow(
                          'Carbon Footprint',
                          analysisData.carbonFootprint,
                          Icons.cloud_outlined,
                          Colors.lightBlue.shade400,
                        ),
                        const SizedBox(height: 12),
                        _buildImpactRow(
                          'Packaging Type',
                          analysisData.packagingType,
                          Icons.recycling,
                          Colors.green.shade400,
                        ),
                        const SizedBox(height: 12),
                        _buildImpactRow(
                          'Disposal Method',
                          analysisData.disposalMethod,
                          Icons.delete_outline,
                          Colors.orange.shade400,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Environmental Warnings Card
                  _buildModernCard(
                    title: 'Sustainability Check',
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.teal.shade600,
                    child: Column(
                      children: [
                        _buildWarningCheckRow(
                          'Microplastics Free',
                          !analysisData.containsMicroplastics,
                        ),
                        const SizedBox(height: 10),
                        _buildWarningCheckRow(
                          'Palm Oil Free',
                          !analysisData.palmOilDerivative,
                        ),
                        const SizedBox(height: 10),
                        _buildWarningCheckRow(
                          'Cruelty-Free',
                          analysisData.crueltyFree,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Actions Card
                  _buildQuickActionsCard(context),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Image Placeholder Widget
  Widget _buildImagePlaceholder() {
    return Container(
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_outlined,
              size: 80,
              color: kPrimaryGreen.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No Product Image',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Product Header Card with Name and Eco Score
  Widget _buildProductHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryGreen, kPrimaryGreen.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysisData.productName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    analysisData.category,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Eco Score Badge
          _buildEcoScoreBadge(analysisData.ecoScore),
        ],
      ),
    );
  }

  // Eco Score Badge Widget
  Widget _buildEcoScoreBadge(String ecoScore) {
    Map<String, Color> ecoScoreColors = {
      'A': Colors.green.shade700,
      'B': Colors.lightGreen.shade700,
      'C': Colors.amber.shade700,
      'D': Colors.orange.shade700,
      'E': Colors.red.shade700,
      'N/A': Colors.grey.shade600,
    };

    String displayScore = ecoScore.toUpperCase().trim();
    if (displayScore.length > 1 && displayScore.contains('+')) {
      displayScore = displayScore.substring(0, 1);
    }
    String displayLetter = displayScore.isNotEmpty
        ? displayScore.substring(0, 1)
        : 'N';

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            displayLetter,
            style: TextStyle(
              color: ecoScoreColors[displayLetter] ?? Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 32,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ECO SCORE',
            style: TextStyle(
              color: ecoScoreColors[displayLetter] ?? Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Modern Card Widget
  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Card Content
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }

  // Modern Info Row Widget
  Widget _buildModernInfoRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Impact Row Widget
  Widget _buildImpactRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Warning Check Row Widget
  Widget _buildWarningCheckRow(String label, bool isGood) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isGood ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGood ? Colors.green.shade200 : Colors.red.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isGood ? Colors.green.shade100 : Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGood ? Icons.check : Icons.close,
              size: 18,
              color: isGood ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isGood ? Colors.green.shade900 : Colors.red.shade900,
              ),
            ),
          ),
          if (isGood)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'GOOD',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Quick Actions Card Widget
  Widget _buildQuickActionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kDiscoverMoreYellow, kDiscoverMoreYellow.withOpacity(0.9)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kDiscoverMoreYellow.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.explore_outlined,
                  color: kDiscoverMoreYellow,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Discover More',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Recipe Ideas',
                  icon: Icons.restaurant_menu,
                  color: kDiscoverMoreBlue,
                  onTap: () {
                    debugPrint('Navigating to Recipe Ideas');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Recipe Ideas feature coming soon! 🍳',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: kDiscoverMoreBlue,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'Alternatives',
                  icon: Icons.eco,
                  color: kPrimaryGreen,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => alternative_screen.AlternativeScreen(
                          scannedProduct: analysisData,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Action Button Widget
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
