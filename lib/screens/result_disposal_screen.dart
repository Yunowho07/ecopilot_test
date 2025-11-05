import 'package:flutter/material.dart';
import 'package:ecopilot_test/models/product_analysis_data.dart';
import 'package:ecopilot_test/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultDisposalScreen extends StatelessWidget {
  final ProductAnalysisData analysisData;

  const ResultDisposalScreen({Key? key, required this.analysisData})
    : super(key: key);

  Color _scoreColor(String score) {
    switch (score.toUpperCase()) {
      case 'A':
        return Colors.green.shade700;
      case 'B':
        return Colors.lightGreen.shade700;
      case 'C':
        return Colors.orange.shade700;
      case 'D':
        return Colors.deepOrange.shade700;
      case 'E':
        return Colors.red.shade700;
      default:
        return kPrimaryGreen;
    }
  }

  Widget _buildImage(BuildContext context) {
    if (analysisData.imageUrl != null && analysisData.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          analysisData.imageUrl!,
          width: 110,
          height: 140,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }

    if (analysisData.imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          analysisData.imageFile!,
          width: 110,
          height: 140,
          fit: BoxFit.cover,
        ),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() => Container(
    width: 110,
    height: 140,
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(Icons.photo, size: 48, color: Colors.grey.shade400),
  );

  Future<void> _openMaps(String query) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    if (!await launchUrl(uri)) {
      // ignore: avoid_print
      print('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final disposalSteps = analysisData.disposalMethod
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Disposal Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Icon(Icons.recycling, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 18.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImage(context),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              analysisData.productName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Material',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              analysisData.packagingType,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _scoreColor(
                                    analysisData.ecoScore,
                                  ).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Eco Score',
                                      style: TextStyle(
                                        color: _scoreColor(
                                          analysisData.ecoScore,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      analysisData.ecoScore,
                                      style: TextStyle(
                                        color: _scoreColor(
                                          analysisData.ecoScore,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  'How to Dispose',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (disposalSteps.isEmpty)
                  Text('N/A', style: const TextStyle(color: Colors.black54))
                else ...[
                  for (int i = 0; i < disposalSteps.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Text(
                        '${i + 1}. ${disposalSteps[i]}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'View More Details',
                      style: TextStyle(
                        color: kPrimaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 18),
                const Text(
                  'Nearby Recycling Center',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.place,
                          color: kPrimaryGreen,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Green Recycling Center',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '0.5 km',
                              style: TextStyle(color: Colors.black54),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Open',
                              style: TextStyle(color: kPrimaryGreen),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openMaps('Green Recycling Center'),
                        icon: const Icon(Icons.navigation, color: Colors.white),
                        label: const Text(
                          'Navigate',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kPrimaryGreen.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: kPrimaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lightbulb,
                          color: kPrimaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Eco Tips',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              analysisData.ingredients.isNotEmpty
                                  ? analysisData.ingredients
                                  : analysisData.ecoScore,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
