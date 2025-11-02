import 'package:flutter/material.dart';
import 'alternative_screen.dart' as alternative_screen;
import '../models/product_analysis_data.dart';
import 'package:ecopilot_test/utils/constants.dart';

class ResultScreen extends StatelessWidget {
  final ProductAnalysisData analysisData;

  const ResultScreen({Key? key, required this.analysisData}) : super(key: key);

  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    Color? iconColor,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: iconColor ?? Colors.white70),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(color: valueColor ?? Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningRow(String label, bool isChecked) {
    final bool isGood = label.toLowerCase().contains('cruelty')
        ? isChecked
        : !isChecked;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: isGood ? kPrimaryGreen : kWarningRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEcoScoreDisplay(String ecoScore) {
    Map<String, Color> ecoScoreColors = {
      'A': kResultCardGreen,
      'B': kDiscoverMoreGreen, // lighter green from theme
      'C': kPrimaryYellow,
      'D': kRankSustainabilityHero,
      'E': kWarningRed,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ecoScoreColors[displayLetter] ?? Colors.grey.shade600,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'ECO-SCORE $ecoScore'.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDiscoverMoreButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
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
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.grey.shade900,
                ),
                height: 200,
                child:
                    analysisData.imageUrl != null &&
                        analysisData.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          analysisData.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) =>
                              analysisData.imageFile != null
                              ? Image.file(
                                  analysisData.imageFile!,
                                  fit: BoxFit.cover,
                                )
                              : const Center(
                                  child: Text(
                                    "Image Not Available",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                        ),
                      )
                    : analysisData.imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          analysisData.imageFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Text(
                          "Image Not Available",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: kPrimaryGreen, width: 3),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Details',
                      style: TextStyle(
                        color: kPrimaryGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: Colors.white30, height: 16),
                    _buildInfoRow('Name', analysisData.productName),
                    _buildInfoRow('Category', analysisData.category),
                    _buildInfoRow('Ingredients', analysisData.ingredients),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: kPrimaryGreen, width: 3),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eco Impact',
                      style: TextStyle(
                        color: kPrimaryGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: Colors.white30, height: 16),
                    _buildInfoRow(
                      'Carbon Footprint',
                      analysisData.carbonFootprint,
                      icon: Icons.cloud,
                      iconColor: Colors.lightBlue.shade300,
                    ),
                    _buildInfoRow(
                      'Packaging',
                      analysisData.packagingType,
                      icon: Icons.eco,
                      iconColor: Colors.lightGreen.shade300,
                    ),
                    _buildInfoRow(
                      'Suggested Disposal',
                      analysisData.disposalMethod,
                      icon: Icons.restore_from_trash,
                      iconColor: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: kPrimaryGreen, width: 3),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Environmental Warnings',
                      style: TextStyle(
                        color: kPrimaryGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: Colors.white30, height: 16),
                    _buildWarningRow(
                      'Contains microplastics?',
                      analysisData.containsMicroplastics,
                    ),
                    _buildWarningRow(
                      'Palm oil derivative?',
                      analysisData.palmOilDerivative,
                    ),
                    _buildWarningRow('Cruelty-Free?', analysisData.crueltyFree),
                    const SizedBox(height: 10),
                    _buildEcoScoreDisplay(analysisData.ecoScore),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: kDiscoverMoreYellow, width: 3),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discover More',
                      style: TextStyle(
                        color: kDiscoverMoreYellow,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildDiscoverMoreButton(
                          label: 'Recipe Ideas',
                          icon: Icons.restaurant_menu,
                          color: kDiscoverMoreBlue,
                          onTap: () {
                            debugPrint('Navigating to Recipe Ideas');
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildDiscoverMoreButton(
                          label: 'Better Alternative',
                          icon: Icons.eco,
                          color: kPrimaryGreen,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const alternative_screen.AlternativeScreen(),
                              ),
                            );
                          },
                        ),
                      ],
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
}
