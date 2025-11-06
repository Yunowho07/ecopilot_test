import 'package:flutter/material.dart';
import 'package:ecopilot_test/models/product_analysis_data.dart';
import 'package:ecopilot_test/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ecopilot_test/auth/firebase_service.dart';
import 'package:ecopilot_test/screens/disposal_guidance_screen.dart';
import 'package:flutter/widgets.dart';

class ResultDisposalScreen extends StatelessWidget {
  final ProductAnalysisData analysisData;
  const ResultDisposalScreen({Key? key, required this.analysisData})
    : super(key: key);

  // Helper to map disposal steps (newline-separated) into a list for DB
  List<String> _disposalStepsAsList() {
    if (analysisData.disposalMethod.trim().isEmpty ||
        analysisData.disposalMethod == 'N/A')
      return [];
    return analysisData.disposalMethod
        .split(RegExp(r"\r?\n"))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

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
                          children: [
                            Text(
                              analysisData.nearbyCenter != 'N/A' &&
                                      analysisData.nearbyCenter.isNotEmpty
                                  ? analysisData.nearbyCenter
                                  : 'Nearest recycling center',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              analysisData.nearbyCenter != 'N/A' &&
                                      analysisData.nearbyCenter.isNotEmpty
                                  ? 'Show on map'
                                  : 'Search for nearby centers',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              analysisData.nearbyCenter != 'N/A' &&
                                      analysisData.nearbyCenter.isNotEmpty
                                  ? 'Open'
                                  : '—',
                              style: const TextStyle(color: kPrimaryGreen),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openMaps(
                          analysisData.nearbyCenter != 'N/A' &&
                                  analysisData.nearbyCenter.isNotEmpty
                              ? analysisData.nearbyCenter
                              : '${analysisData.productName} recycling center',
                        ),
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
                              analysisData.tips.isNotEmpty &&
                                      analysisData.tips != 'N/A'
                                  ? analysisData.tips
                                  : 'No specific tips available. Consider reducing single-use packaging and rinsing containers before recycling.',
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
      // Bottom Done button: saves the disposal scan and navigates back to Disposal Guidance
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _DoneButton(
          analysisData: analysisData,
          disposalStepsList: _disposalStepsAsList(),
        ),
      ),
    );
  }
}

class _DoneButton extends StatefulWidget {
  final ProductAnalysisData analysisData;
  final List<String> disposalStepsList;

  const _DoneButton({
    Key? key,
    required this.analysisData,
    required this.disposalStepsList,
  }) : super(key: key);

  @override
  State<_DoneButton> createState() => _DoneButtonState();
}

class _DoneButtonState extends State<_DoneButton> {
  bool _isSaving = false;

  Future<void> _onDonePressed() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // Build a short analysis summary to persist (reuse disposalMethod + tips)
      final analysisText = widget.analysisData.disposalMethod.isNotEmpty
          ? widget.analysisData.disposalMethod
          : widget.analysisData.tips;

      await FirebaseService().saveUserScan(
        analysis: analysisText ?? 'Disposal scan',
        productName: widget.analysisData.productName,
        ecoScore: widget.analysisData.ecoScore,
        carbonFootprint: widget.analysisData.carbonFootprint,
        imageUrl: widget.analysisData.imageUrl,
        category: widget.analysisData.category,
        packagingType: widget.analysisData.packagingType,
        disposalSteps: widget.disposalStepsList.isNotEmpty
            ? widget.disposalStepsList
            : null,
        tips: widget.analysisData.tips,
        nearbyCenter: widget.analysisData.nearbyCenter,
        isDisposal: true,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved to Recent Disposal')));

      // Navigate back to Disposal Guidance screen smoothly
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DisposalGuidanceScreen()),
      );
    } catch (e) {
      debugPrint('Failed to save disposal scan: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _onDonePressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Done',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
