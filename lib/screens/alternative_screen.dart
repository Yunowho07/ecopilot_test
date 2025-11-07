// Fresh, compact AlternativeScreen implementation that accepts the scanned product
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../services/generative_service.dart';
import '../models/product_analysis_data.dart';
import 'package:ecopilot_test/widgets/app_drawer.dart';
import 'package:ecopilot_test/widgets/bottom_navigation.dart';
import 'home_screen.dart';
import 'scan_screen.dart';
import 'disposal_guidance_screen.dart';
import 'profile_screen.dart';

const Color _kPrimaryGreenAlt = Color(0xFF1DB954);

const Map<String, Color> _kEcoScoreColors = {
  'A+': Color(0xFF1DB954),
  'A': Color(0xFF4CAF50),
  'B': Color(0xFF8BC34A),
  'C': Color(0xFFFFC107),
  'D': Color(0xFFFF9800),
  'E': Color(0xFFF44336),
};

class AlternativeProduct {
  final String name;
  final String ecoScore;
  final String materialType;
  final String benefit;
  final String whereToBuy;
  final String carbonSavings;
  final String imagePath;
  final String buyLink;
  final String shortDescription;

  AlternativeProduct({
    required this.name,
    required this.ecoScore,
    required this.materialType,
    required this.benefit,
    required this.whereToBuy,
    required this.carbonSavings,
    required this.imagePath,
    required this.buyLink,
    required this.shortDescription,
  });
}

final List<AlternativeProduct> _sampleAlternatives = [
  AlternativeProduct(
    name: 'EcoBottle 500ml',
    ecoScore: 'A+',
    materialType: 'Stainless Steel',
    benefit: 'Reusable and BPA-free, reduces plastic waste',
    whereToBuy: 'EcoHaus, Amazon',
    carbonSavings: 'Reduces ~120kg CO₂ per year',
    imagePath: 'assets/images/ecobottle.png',
    buyLink: 'https://example.com/ecobottle',
    shortDescription:
        'Durable stainless steel bottle with recyclable packaging.',
  ),
  AlternativeProduct(
    name: 'Bamboo Toothbrush (4-Pack)',
    ecoScore: 'A',
    materialType: 'Bamboo',
    benefit: 'Compostable handle',
    whereToBuy: 'Local eco-store, Amazon',
    carbonSavings: 'Reduces ~0.5kg plastic waste/year',
    imagePath: 'assets/images/bamboo_brush.png',
    buyLink: 'https://example.com/bamboo-toothbrush',
    shortDescription: 'Handles made from sustainably harvested bamboo.',
  ),
  AlternativeProduct(
    name: 'Recycled Glass Jar Candle',
    ecoScore: 'B',
    materialType: 'Recycled Glass & Soy Wax',
    benefit: 'Upcycled glass jar',
    whereToBuy: 'Etsy, HomeGoods',
    carbonSavings: 'Saves ~0.2kg virgin material',
    imagePath: 'assets/images/candle.png',
    buyLink: 'https://example.com/recycled-candle',
    shortDescription: 'Made from soy wax and packaged in recycled glass.',
  ),
];

class EcoScoreBadge extends StatelessWidget {
  final String score;
  const EcoScoreBadge({Key? key, required this.score}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = _kEcoScoreColors[score] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Eco: $score',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class AlternativeProductCard extends StatelessWidget {
  final AlternativeProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onBuyNow;

  const AlternativeProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.onBuyNow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.image,
                      size: 36,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            EcoScoreBadge(score: product.ecoScore),
                            const SizedBox(width: 8),
                            Text(
                              product.materialType,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                product.shortDescription,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onBuyNow,
                      icon: const Icon(Icons.link),
                      label: const Text('Buy Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryGreenAlt,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlternativeScreen extends StatefulWidget {
  final ProductAnalysisData? scannedProduct;
  const AlternativeScreen({Key? key, this.scannedProduct}) : super(key: key);
  @override
  State<AlternativeScreen> createState() => _AlternativeScreenState();
}

class _AlternativeScreenState extends State<AlternativeScreen> {
  final int _selectedIndex = 1;
  bool _loading = false;
  List<AlternativeProduct> _loadedAlternatives = [];

  int _ecoRank(String s) {
    final score = s.toUpperCase().trim();
    if (score.startsWith('A+')) return 0;
    if (score.startsWith('A')) return 1;
    if (score.startsWith('B')) return 2;
    if (score.startsWith('C')) return 3;
    if (score.startsWith('D')) return 4;
    if (score.startsWith('E')) return 5;
    return 99;
  }

  List<AlternativeProduct> _computeAlternatives() {
    final scanned = widget.scannedProduct;
    if (_loadedAlternatives.isNotEmpty) return _loadedAlternatives;
    if (scanned == null || scanned.ecoScore.isEmpty) return _sampleAlternatives;
    final int scannedRank = _ecoRank(scanned.ecoScore);
    final better = _sampleAlternatives
        .where((a) => _ecoRank(a.ecoScore) < scannedRank)
        .toList();
    if (better.isNotEmpty) return better;
    final sorted = List<AlternativeProduct>.from(_sampleAlternatives)
      ..sort((a, b) => _ecoRank(a.ecoScore).compareTo(_ecoRank(b.ecoScore)));
    return sorted.take(5).toList();
  }

  void _showAlternativeDetails(AlternativeProduct p) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(p.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Eco Score: ${p.ecoScore}'),
              const SizedBox(height: 8),
              Text(p.shortDescription),
              const SizedBox(height: 8),
              Text('Material: ${p.materialType}'),
              const SizedBox(height: 6),
              Text('Why: ${p.benefit}'),
              const SizedBox(height: 6),
              Text('Carbon: ${p.carbonSavings}'),
              const SizedBox(height: 12),
              SelectableText('Buy link: ${p.buyLink}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: p.buyLink));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Link copied')));
            },
            child: const Text('Copy Link'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _generateAlternativesThenFallback();
  }

  Future<void> _generateAlternativesThenFallback() async {
    final scanned = widget.scannedProduct;
    if (scanned == null) return;

    setState(() => _loading = true);

    try {
      // Build a structured prompt asking Gemini to return JSON array of alternatives
      final prompt =
          '''
You are an eco-product recommender. Given the following scanned product details, return a JSON array of up to 6 alternative products that are more sustainable.
Respond ONLY with a single JSON array. Each element must be an object with keys: name, ecoScore, category, material, shortDescription, buyUrl, imageUrl (optional), carbonSavings (optional).

Scanned product details:
Name: ${scanned.productName}
Category: ${scanned.category}
Packaging type: ${scanned.packagingType}
Ingredients: ${scanned.ingredients}
Eco score: ${scanned.ecoScore}

Return higher-rated items first (better ecoScore like A+ then A then B). If you cannot find alternatives, return an empty array [].
''';

      final text = await GenerativeService.generateResponse(prompt);
      if (text.isNotEmpty && !text.startsWith('__')) {
        // Try to extract JSON array from the response
        String jsonText = text.trim();
        // If the model included surrounding text, try to locate first '[' and last ']' to extract
        final first = jsonText.indexOf('[');
        final last = jsonText.lastIndexOf(']');
        if (first >= 0 && last > first) {
          jsonText = jsonText.substring(first, last + 1);
        }

        try {
          final decoded = jsonDecode(jsonText);
          if (decoded is List) {
            final List<AlternativeProduct> generated = [];
            for (final item in decoded) {
              if (item is Map) {
                final name = (item['name'] ?? item['title'] ?? '').toString();
                if (name.isEmpty) continue;
                final eco = (item['ecoScore'] ?? item['eco_score'] ?? 'N/A')
                    .toString();
                // category is available from the model but not currently used in the UI
                final material = (item['material'] ?? item['packaging'] ?? '')
                    .toString();
                final short =
                    (item['shortDescription'] ?? item['description'] ?? '')
                        .toString();
                final buy =
                    (item['buyUrl'] ?? item['buy_link'] ?? item['buy'] ?? '')
                        .toString();
                final image = (item['imageUrl'] ?? item['image'] ?? '')
                    .toString();
                final carbon = (item['carbonSavings'] ?? item['carbon'] ?? '')
                    .toString();
                generated.add(
                  AlternativeProduct(
                    name: name,
                    ecoScore: eco,
                    materialType: material,
                    benefit: '',
                    whereToBuy: '',
                    carbonSavings: carbon,
                    imagePath: image,
                    buyLink: buy,
                    shortDescription: short,
                  ),
                );
              }
            }
            if (generated.isNotEmpty) {
              _loadedAlternatives = generated;
              setState(() => _loading = false);
              return;
            }
          }
        } catch (e) {
          debugPrint('Failed to parse Gemini JSON: $e');
        }
      }
    } catch (e) {
      debugPrint('Gemini generation failed: $e');
    }

    // If generation failed or produced no results, fall back to Firestore loader
    await _loadAlternativesIfNeeded();
    setState(() => _loading = false);
  }

  Future<void> _loadAlternativesIfNeeded() async {
    final scanned = widget.scannedProduct;
    if (scanned == null) return; // nothing to fetch
    setState(() => _loading = true);

    final base = dotenv.env['CLOUDINARY_BASE_URL'] ?? '';
    final List<AlternativeProduct> fetched = [];

    if (base.isEmpty) {
      debugPrint('CLOUDINARY_BASE_URL not set; skipping cloud fetch.');
      setState(() => _loading = false);
      return;
    }

    // helper to slugify a key for URL
    String slug(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9]+"), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();

    final candidates = <String>[];
    if (scanned.category.isNotEmpty && scanned.category != 'N/A') {
      candidates.add('$base/${slug(scanned.category)}.json');
    }
    if (scanned.packagingType.isNotEmpty && scanned.packagingType != 'N/A') {
      candidates.add('$base/${slug(scanned.packagingType)}.json');
    }
    // a global fallback file
    candidates.add('$base/alternatives.json');

    for (final url in candidates) {
      try {
        final resp = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 6));
        if (resp.statusCode != 200) continue;
        final body = resp.body;
        final decoded = jsonDecode(body);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              final name = (item['name'] ?? item['title'] ?? '').toString();
              if (name.isEmpty) continue;
              final eco = (item['ecoScore'] ?? item['eco_score'] ?? 'N/A')
                  .toString();
              final material = (item['material'] ?? item['packaging'] ?? '')
                  .toString();
              final short =
                  (item['shortDescription'] ?? item['description'] ?? '')
                      .toString();
              final buy =
                  (item['buyUrl'] ?? item['buy_link'] ?? item['buy'] ?? '')
                      .toString();
              final image = (item['imageUrl'] ?? item['image'] ?? '')
                  .toString();
              final carbon = (item['carbonSavings'] ?? item['carbon'] ?? '')
                  .toString();
              fetched.add(
                AlternativeProduct(
                  name: name,
                  ecoScore: eco,
                  materialType: material,
                  benefit: '',
                  whereToBuy: '',
                  carbonSavings: carbon,
                  imagePath: image,
                  buyLink: buy,
                  shortDescription: short,
                ),
              );
            }
          }
        }
        if (fetched.isNotEmpty) break; // stop after first successful source
      } catch (e) {
        debugPrint('Cloudinary fetch failed for $url: $e');
        continue;
      }
    }

    // Filter by ecoScore where possible (prefer strictly better)
    if (fetched.isNotEmpty &&
        scanned.ecoScore.isNotEmpty &&
        scanned.ecoScore != 'N/A') {
      final sRank = _ecoRank(scanned.ecoScore);
      final better = fetched
          .where(
            (a) =>
                a.ecoScore.isNotEmpty &&
                a.ecoScore != 'N/A' &&
                _ecoRank(a.ecoScore) < sRank,
          )
          .toList();
      _loadedAlternatives = better.isNotEmpty ? better : fetched;
    } else {
      _loadedAlternatives = fetched;
    }

    setState(() => _loading = false);
  }

  Future<void> _openBuyLink(String url) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No buy link available')));
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      Clipboard.setData(ClipboardData(text: url));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid link copied to clipboard')),
      );
      return;
    }
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: copy link
        Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link copied to clipboard')),
        );
      }
    } catch (e) {
      Clipboard.setData(ClipboardData(text: url));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open link — copied to clipboard'),
        ),
      );
    }
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
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ScanScreen()));
          return;
        }
        if (index == 3) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DisposalGuidanceScreen()),
          );
          return;
        }
        if (index == 4) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          return;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final alternatives = _computeAlternatives();
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Better Alternatives'),
        backgroundColor: _kPrimaryGreenAlt,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🌱 Greener Alternatives Found',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Alternatives that are more sustainable than the scanned product.',
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Result'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryGreenAlt,
                ),
              ),
              const SizedBox(height: 12),
              if (_loading) const Center(child: CircularProgressIndicator()),
              if (!_loading)
                ...alternatives
                    .map(
                      (p) => AlternativeProductCard(
                        product: p,
                        onTap: () => _showAlternativeDetails(p),
                        onBuyNow: () => _openBuyLink(p.buyLink),
                      ),
                    )
                    .toList(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}
