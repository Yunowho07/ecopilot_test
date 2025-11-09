// Enhanced AlternativeScreen with Gemini AI, Firestore, and external API integration
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../services/generative_service.dart';
import '../models/product_analysis_data.dart';
import 'package:ecopilot_test/widgets/app_drawer.dart';
import 'package:ecopilot_test/widgets/bottom_navigation.dart';
import 'package:ecopilot_test/utils/constants.dart';
import 'home_screen.dart';
import 'scan_screen.dart';
import 'disposal_guidance_screen.dart';
import 'profile_screen.dart';

const Map<String, Color> _kEcoScoreColors = {
  'A+': Color(0xFF1DB954),
  'A': kResultCardGreen,
  'B': kDiscoverMoreGreen,
  'C': kPrimaryYellow,
  'D': kRankSustainabilityHero,
  'E': kWarningRed,
};

class AlternativeProduct {
  final String id; // Unique ID for Firestore
  final String name;
  final String ecoScore;
  final String materialType;
  final String benefit;
  final String whereToBuy;
  final String carbonSavings;
  final String imagePath;
  final String buyLink;
  final String shortDescription;
  final String category; // Product category
  final double? price; // Optional price for filtering
  final String? brand; // Optional brand for filtering
  final double? rating; // Optional rating (1-5)
  final String?
  externalSource; // Source: 'gemini', 'firestore', 'openfoodfacts', etc.

  AlternativeProduct({
    String? id,
    required this.name,
    required this.ecoScore,
    required this.materialType,
    required this.benefit,
    required this.whereToBuy,
    required this.carbonSavings,
    required this.imagePath,
    required this.buyLink,
    required this.shortDescription,
    this.category = '',
    this.price,
    this.brand,
    this.rating,
    this.externalSource,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ecoScore': ecoScore,
      'materialType': materialType,
      'benefit': benefit,
      'whereToBuy': whereToBuy,
      'carbonSavings': carbonSavings,
      'imagePath': imagePath,
      'buyLink': buyLink,
      'shortDescription': shortDescription,
      'category': category,
      'price': price,
      'brand': brand,
      'rating': rating,
      'externalSource': externalSource,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Create from Firestore document
  factory AlternativeProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AlternativeProduct(
      id: doc.id,
      name: data['name'] ?? '',
      ecoScore: data['ecoScore'] ?? 'N/A',
      materialType: data['materialType'] ?? '',
      benefit: data['benefit'] ?? '',
      whereToBuy: data['whereToBuy'] ?? '',
      carbonSavings: data['carbonSavings'] ?? '',
      imagePath: data['imagePath'] ?? '',
      buyLink: data['buyLink'] ?? '',
      shortDescription: data['shortDescription'] ?? '',
      category: data['category'] ?? '',
      price: data['price']?.toDouble(),
      brand: data['brand'],
      rating: data['rating']?.toDouble(),
      externalSource: data['externalSource'],
    );
  }
}

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
  final VoidCallback? onAddToWishlist;
  final VoidCallback? onCompare;
  final bool isInWishlist;

  const AlternativeProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.onBuyNow,
    this.onAddToWishlist,
    this.onCompare,
    this.isInWishlist = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: product.imagePath.isNotEmpty
                            ? (product.imagePath.startsWith('http')
                                  ? Image.network(
                                      product.imagePath,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, st) => Icon(
                                        Icons.eco,
                                        size: 40,
                                        color: kPrimaryGreen.withOpacity(0.3),
                                      ),
                                    )
                                  : Image.asset(
                                      product.imagePath,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, st) => Icon(
                                        Icons.eco,
                                        size: 40,
                                        color: kPrimaryGreen.withOpacity(0.3),
                                      ),
                                    ))
                            : Center(
                                child: Icon(
                                  Icons.eco,
                                  size: 40,
                                  color: kPrimaryGreen.withOpacity(0.3),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Name
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Eco Score Badge and Wishlist
                          Row(
                            children: [
                              EcoScoreBadge(score: product.ecoScore),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  isInWishlist
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isInWishlist
                                      ? Colors.red
                                      : Colors.grey,
                                  size: 22,
                                ),
                                onPressed: onAddToWishlist,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Material Type
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  product.materialType,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          // Rating if available
                          if (product.rating != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  product.rating!.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Description
                Text(
                  product.shortDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Price and Carbon Savings Row
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      // Price
                      if (product.price != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'RM ${product.price!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Carbon Savings
                      if (product.carbonSavings.isNotEmpty)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.eco, size: 14, color: kPrimaryGreen),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    product.carbonSavings,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: kPrimaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                // Action Buttons
                Row(
                  children: [
                    if (onCompare != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onCompare,
                          icon: const Icon(Icons.compare_arrows, size: 18),
                          label: const Text('Compare'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.purple,
                            side: const BorderSide(color: Colors.purple),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    if (onCompare != null) const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryGreen,
                          side: BorderSide(color: kPrimaryGreen),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onBuyNow,
                        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                        label: const Text('Buy Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
  Set<String> _wishlist = {}; // Product IDs in wishlist
  String _dataSource = ''; // Track which data source was used

  // Filter states
  double? _maxPrice;
  String? _selectedBrand;
  double? _minRating;
  List<String> _availableBrands = [];

  bool _showFilters = false;

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

  // Wishlist management methods
  Future<void> _loadWishlist() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .get();

      setState(() {
        _wishlist = doc.docs.map((d) => d.id).toSet();
      });
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
    }
  }

  Future<void> _toggleWishlist(AlternativeProduct product) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to use wishlist')),
        );
        return;
      }

      final wishlistRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(product.id);

      if (_wishlist.contains(product.id)) {
        await wishlistRef.delete();
        setState(() => _wishlist.remove(product.id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removed from wishlist')));
      } else {
        await wishlistRef.set(product.toFirestore());
        setState(() => _wishlist.add(product.id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Added to wishlist 💚')));
      }
    } catch (e) {
      debugPrint('Error toggling wishlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update wishlist')),
      );
    }
  }

  // Filter methods
  List<AlternativeProduct> _applyFilters(List<AlternativeProduct> products) {
    var filtered = products;

    // Filter by max price
    if (_maxPrice != null) {
      filtered = filtered.where((p) {
        if (p.price == null) return true; // Include products without price
        return p.price! <= _maxPrice!;
      }).toList();
    }

    // Filter by brand
    if (_selectedBrand != null && _selectedBrand!.isNotEmpty) {
      filtered = filtered.where((p) {
        if (p.brand == null) return false;
        return p.brand == _selectedBrand;
      }).toList();
    }

    // Filter by minimum rating
    if (_minRating != null) {
      filtered = filtered.where((p) {
        if (p.rating == null) return true; // Include unrated products
        return p.rating! >= _minRating!;
      }).toList();
    }

    return filtered;
  }

  void _updateAvailableBrands(List<AlternativeProduct> products) {
    final brands = products
        .where((p) => p.brand != null && p.brand!.isNotEmpty)
        .map((p) => p.brand!)
        .toSet()
        .toList();
    brands.sort();
    setState(() {
      _availableBrands = brands;
    });
  }

  void _resetFilters() {
    setState(() {
      _maxPrice = null;
      _selectedBrand = null;
      _minRating = null;
    });
  }

  // Compare with scanned product
  void _showComparison(AlternativeProduct alternative) {
    final scanned = widget.scannedProduct;
    if (scanned == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No scanned product to compare')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.compare_arrows, color: kPrimaryGreen, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Product Comparison',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Comparison Table
                    _buildComparisonRow(
                      'Product Name',
                      scanned.productName,
                      alternative.name,
                    ),
                    const Divider(),
                    _buildComparisonRow(
                      'Eco Score',
                      scanned.ecoScore,
                      alternative.ecoScore,
                    ),
                    const Divider(),
                    _buildComparisonRow(
                      'Packaging',
                      scanned.packagingType,
                      alternative.materialType,
                    ),
                    const Divider(),
                    _buildComparisonRow(
                      'Category',
                      scanned.category,
                      alternative.category,
                    ),

                    // Carbon Impact Difference
                    if (alternative.carbonSavings.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kPrimaryGreen.withOpacity(0.1),
                              kPrimaryGreen.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: kPrimaryGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.eco, color: kPrimaryGreen, size: 40),
                            const SizedBox(height: 12),
                            const Text(
                              'Environmental Impact',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              alternative.carbonSavings,
                              style: TextStyle(
                                fontSize: 14,
                                color: kPrimaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'By choosing this alternative',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openBuyLink(alternative.buyLink);
                        },
                        icon: const Icon(Icons.shopping_bag),
                        label: const Text('Choose This Alternative'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    String scannedValue,
    String altValue,
  ) {
    // Determine which is better for eco score
    bool altIsBetter = false;
    if (label == 'Eco Score') {
      altIsBetter = _ecoRank(altValue) < _ecoRank(scannedValue);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scannedValue.isEmpty || scannedValue == 'N/A'
                      ? '-'
                      : scannedValue,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                const Text(
                  '(Current)',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.arrow_forward, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        altValue.isEmpty || altValue == 'N/A' ? '-' : altValue,
                        style: TextStyle(
                          fontSize: 14,
                          color: altIsBetter ? kPrimaryGreen : Colors.black87,
                          fontWeight: altIsBetter
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (altIsBetter)
                      Icon(Icons.check_circle, color: kPrimaryGreen, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '(Alternative)',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<AlternativeProduct> _computeAlternatives() {
    var alternatives = _loadedAlternatives.isNotEmpty
        ? _loadedAlternatives
        : (_computeFallbackAlternatives());

    // Apply filters
    alternatives = _applyFilters(alternatives);

    // Update available brands for filter
    _updateAvailableBrands(alternatives);

    return alternatives;
  }

  List<AlternativeProduct> _computeFallbackAlternatives() {
    final scanned = widget.scannedProduct;

    // If no scanned product, return empty
    if (scanned == null) {
      _dataSource = 'No Data Available';
      return [];
    }

    // Generate context-aware alternatives based on scanned product
    _dataSource = 'AI-Generated (Fallback)';
    return _generateContextualAlternatives(scanned);
  }

  List<AlternativeProduct> _generateContextualAlternatives(
    ProductAnalysisData scanned,
  ) {
    // Get better eco score suggestions
    final currentRank = _ecoRank(scanned.ecoScore);
    final betterScores = [
      'A+',
      'A',
      'B',
    ].where((score) => _ecoRank(score) < currentRank).toList();

    if (betterScores.isEmpty) {
      betterScores.add('A+'); // Always suggest A+ as best option
    }

    final category = scanned.category.toLowerCase();
    final alternatives = <AlternativeProduct>[];

    // Generate category-specific alternatives
    if (category.contains('beverage') ||
        category.contains('drink') ||
        category.contains('water') ||
        category.contains('bottle')) {
      alternatives.addAll([
        AlternativeProduct(
          name: 'Stainless Steel Reusable Bottle',
          ecoScore: betterScores.first,
          materialType: 'Stainless Steel',
          benefit: 'Durable and reusable',
          whereToBuy: 'Shopee, Lazada',
          carbonSavings: 'Saves ~120kg CO₂/year',
          imagePath: '',
          buyLink:
              'https://shopee.com.my/search?keyword=stainless+steel+bottle',
          shortDescription:
              'Reusable stainless steel bottle, BPA-free and dishwasher safe',
          category: scanned.category,
          price: 45.00,
          brand: 'EcoLife',
          rating: 4.7,
          externalSource: 'contextual',
        ),
        AlternativeProduct(
          name: 'Glass Water Bottle with Silicone Sleeve',
          ecoScore: betterScores.length > 1
              ? betterScores[1]
              : betterScores.first,
          materialType: 'Borosilicate Glass',
          benefit: '100% recyclable glass',
          whereToBuy: 'Shopee, Lazada',
          carbonSavings: 'Prevents ~100kg plastic waste/year',
          imagePath: '',
          buyLink: 'https://shopee.com.my/search?keyword=glass+water+bottle',
          shortDescription:
              '100% recyclable glass with protective silicone sleeve',
          category: scanned.category,
          price: 38.00,
          brand: 'GreenBottle',
          rating: 4.6,
          externalSource: 'contextual',
        ),
        AlternativeProduct(
          name: 'Bamboo Fiber Bottle',
          ecoScore: betterScores.length > 2
              ? betterScores[2]
              : betterScores.first,
          materialType: 'Bamboo Fiber Composite',
          benefit: 'Biodegradable material',
          whereToBuy: 'Shopee, Lazada',
          carbonSavings: 'Reduces plastic by ~90kg/year',
          imagePath: '',
          buyLink: 'https://shopee.com.my/search?keyword=bamboo+bottle',
          shortDescription:
              'Made from sustainable bamboo fiber, fully biodegradable',
          category: scanned.category,
          price: 35.00,
          brand: 'BambooLife',
          rating: 4.5,
          externalSource: 'contextual',
        ),
      ]);
    } else if (category.contains('personal care') ||
        category.contains('shampoo') ||
        category.contains('soap') ||
        category.contains('cosmetic')) {
      alternatives.addAll([
        AlternativeProduct(
          name: 'Solid Shampoo Bar',
          ecoScore: betterScores.first,
          materialType: 'Plastic-Free Packaging',
          benefit: 'Zero plastic waste',
          whereToBuy: 'Shopee, Lazada',
          carbonSavings: 'Eliminates 2-3 plastic bottles/year',
          imagePath: '',
          buyLink: 'https://shopee.com.my/search?keyword=solid+shampoo+bar',
          shortDescription: 'Concentrated shampoo bar in compostable packaging',
          category: scanned.category,
          price: 28.00,
          brand: 'EcoHair',
          rating: 4.8,
          externalSource: 'contextual',
        ),
        AlternativeProduct(
          name: 'Refillable Shampoo Bottle Set',
          ecoScore: betterScores.length > 1
              ? betterScores[1]
              : betterScores.first,
          materialType: 'Recycled Plastic + Refill Station',
          benefit: 'Reusable container system',
          whereToBuy: 'Shopee, Lazada',
          carbonSavings: 'Reduces plastic by 80%/year',
          imagePath: '',
          buyLink: 'https://shopee.com.my/search?keyword=refillable+shampoo',
          shortDescription: 'Durable bottle with refill stations at eco-shops',
          category: scanned.category,
          price: 42.00,
          brand: 'GreenWash',
          rating: 4.6,
          externalSource: 'contextual',
        ),
        AlternativeProduct(
          name: 'Organic Shampoo in Aluminum Bottle',
          ecoScore: betterScores.length > 2
              ? betterScores[2]
              : betterScores.first,
          materialType: 'Recycled Aluminum',
          benefit: 'Infinitely recyclable',
          whereToBuy: 'Shopee, Lazada',
          carbonSavings: 'Saves ~50kg CO₂/year',
          imagePath: '',
          buyLink: 'https://shopee.com.my/search?keyword=aluminum+shampoo',
          shortDescription:
              'Natural ingredients in recyclable aluminum packaging',
          category: scanned.category,
          price: 38.00,
          brand: 'PureNature',
          rating: 4.7,
          externalSource: 'contextual',
        ),
      ]);
    } else if (category.contains('food') ||
        category.contains('snack') ||
        category.contains('packaging')) {
      alternatives.addAll([
        AlternativeProduct(
          name: 'Bulk Store Alternative (Bring Own Container)',
          ecoScore: betterScores.first,
          materialType: 'No Packaging',
          benefit: 'Zero waste shopping',
          whereToBuy: 'Bulk Stores, Zero Waste Shops',
          carbonSavings: 'Eliminates all packaging waste',
          imagePath: '',
          buyLink: 'https://shopee.com.my/search?keyword=zero+waste+store',
          shortDescription:
              'Buy the same product from bulk stores with your own container',
          category: scanned.category,
          price: 0.00,
          brand: 'Local Bulk Stores',
          rating: 4.9,
          externalSource: 'contextual',
        ),
        AlternativeProduct(
          name: 'Paper/Cardboard Packaged Alternative',
          ecoScore: betterScores.length > 1
              ? betterScores[1]
              : betterScores.first,
          materialType: 'Recycled Paper/Cardboard',
          benefit: 'Compostable packaging',
          whereToBuy: 'Shopee, Lazada, Eco Shops',
          carbonSavings: 'Reduces plastic by 100%',
          imagePath: '',
          buyLink: 'https://shopee.com.my/search?keyword=eco+packaging+food',
          shortDescription:
              'Same product type in biodegradable paper packaging',
          category: scanned.category,
          price: 25.00,
          brand: 'EcoPack',
          rating: 4.6,
          externalSource: 'contextual',
        ),
        AlternativeProduct(
          name: 'Glass Jar Packaged Product',
          ecoScore: betterScores.length > 2
              ? betterScores[2]
              : betterScores.first,
          materialType: 'Reusable Glass',
          benefit: 'Reusable container',
          whereToBuy: 'Shopee, Lazada',
          carbonSavings: 'Jar can be reused for years',
          imagePath: '',
          buyLink: 'https://shopee.com.my/search?keyword=glass+jar+food',
          shortDescription: 'Product in reusable glass jar packaging',
          category: scanned.category,
          price: 32.00,
          brand: 'GlassGood',
          rating: 4.5,
          externalSource: 'contextual',
        ),
      ]);
    } else {
      // Generic eco-friendly alternatives for any category
      alternatives.addAll([
        AlternativeProduct(
          name: 'Eco-Friendly Alternative (Recycled Materials)',
          ecoScore: betterScores.first,
          materialType: 'Recycled Materials',
          benefit: 'Made from recycled content',
          whereToBuy: 'Shopee, Lazada, Eco Shops',
          carbonSavings: 'Reduces new material production',
          imagePath: '',
          buyLink:
              'https://shopee.com.my/search?keyword=eco+friendly+${Uri.encodeComponent(scanned.category)}',
          shortDescription:
              'Similar product made with recycled or sustainable materials',
          category: scanned.category,
          price: 30.00,
          brand: 'EcoChoice',
          rating: 4.6,
          externalSource: 'contextual',
        ),
        AlternativeProduct(
          name: 'Sustainable ${scanned.category} Option',
          ecoScore: betterScores.length > 1
              ? betterScores[1]
              : betterScores.first,
          materialType: 'Biodegradable/Compostable',
          benefit: 'Environmentally friendly disposal',
          whereToBuy: 'Shopee, Lazada',
          carbonSavings: 'Decomposes naturally',
          imagePath: '',
          buyLink:
              'https://shopee.com.my/search?keyword=sustainable+${Uri.encodeComponent(scanned.category)}',
          shortDescription:
              'Sustainable alternative with minimal environmental impact',
          category: scanned.category,
          price: 35.00,
          brand: 'GreenLiving',
          rating: 4.7,
          externalSource: 'contextual',
        ),
        AlternativeProduct(
          name: 'Reusable/Refillable Version',
          ecoScore: betterScores.length > 2
              ? betterScores[2]
              : betterScores.first,
          materialType: 'Durable Reusable',
          benefit: 'Long-lasting, reduces waste',
          whereToBuy: 'Shopee, Lazada',
          carbonSavings: 'Prevents repeated purchases',
          imagePath: '',
          buyLink:
              'https://shopee.com.my/search?keyword=reusable+${Uri.encodeComponent(scanned.category)}',
          shortDescription: 'Reusable version that eliminates single-use waste',
          category: scanned.category,
          price: 40.00,
          brand: 'ReUse',
          rating: 4.5,
          externalSource: 'contextual',
        ),
      ]);
    }

    // Filter to only show alternatives with better eco scores
    final filteredAlternatives = alternatives
        .where((alt) => _ecoRank(alt.ecoScore) < currentRank)
        .toList();

    return filteredAlternatives.isNotEmpty
        ? filteredAlternatives
        : alternatives;
  }

  void _showAlternativeDetails(AlternativeProduct p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: p.imagePath.isNotEmpty
                              ? (p.imagePath.startsWith('http')
                                    ? Image.network(
                                        p.imagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, st) => Icon(
                                          Icons.eco,
                                          size: 60,
                                          color: kPrimaryGreen.withOpacity(0.3),
                                        ),
                                      )
                                    : Image.asset(
                                        p.imagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, st) => Icon(
                                          Icons.eco,
                                          size: 60,
                                          color: kPrimaryGreen.withOpacity(0.3),
                                        ),
                                      ))
                              : Icon(
                                  Icons.eco,
                                  size: 60,
                                  color: kPrimaryGreen.withOpacity(0.3),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Product Name
                    Center(
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Eco Score Badge (Centered)
                    Center(child: EcoScoreBadge(score: p.ecoScore)),
                    const SizedBox(height: 24),

                    // Material Section
                    _buildDetailRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Material',
                      value: p.materialType,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildDetailRow(
                      icon: Icons.description_outlined,
                      label: 'Description',
                      value: p.shortDescription,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 16),

                    // Carbon Savings
                    if (p.carbonSavings.isNotEmpty)
                      _buildDetailRow(
                        icon: Icons.eco,
                        label: 'Environmental Impact',
                        value: p.carbonSavings,
                        color: kPrimaryGreen,
                      ),
                    if (p.carbonSavings.isNotEmpty) const SizedBox(height: 16),

                    // Buy Link Section
                    if (p.buyLink.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.link,
                                  size: 18,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Purchase Link',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              p.buyLink,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: p.buyLink));
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Link copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy Link'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryGreen,
                          side: BorderSide(color: kPrimaryGreen),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _openBuyLink(p.buyLink);
                        },
                        icon: const Icon(Icons.shopping_bag, size: 18),
                        label: const Text('Buy Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    if (value.isEmpty || value == 'N/A') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
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
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadWishlist(); // Load user's wishlist
    _generateAlternativesThenFallback();
  }

  Future<void> _generateAlternativesThenFallback() async {
    final scanned = widget.scannedProduct;
    if (scanned == null) {
      debugPrint('⚠️ No scanned product provided');
      return;
    }

    debugPrint(
      '🔄 Starting alternative generation for: ${scanned.productName}',
    );
    setState(() => _loading = true);

    // Step 1: Try Gemini AI for intelligent alternatives
    debugPrint('📍 Step 1: Trying Gemini AI...');
    bool geminiSuccess = await _tryGeminiAlternatives(scanned);
    if (geminiSuccess) {
      debugPrint('✅ Success! Using Gemini AI alternatives');
      setState(() => _loading = false);
      return;
    }

    // Step 2: Try Firestore database
    debugPrint('📍 Step 2: Trying Firestore database...');
    bool firestoreSuccess = await _tryFirestoreAlternatives(scanned);
    if (firestoreSuccess) {
      debugPrint('✅ Success! Using Firestore alternatives');
      setState(() => _loading = false);
      return;
    }

    // Step 3: Try Cloudinary JSON files
    debugPrint('📍 Step 3: Trying Cloudinary JSON...');
    await _loadAlternativesIfNeeded();

    if (_loadedAlternatives.isNotEmpty) {
      debugPrint('✅ Success! Using Cloudinary alternatives');
    } else {
      debugPrint('❌ All sources failed, no alternatives available');
      _dataSource = 'No Data Available';
    }

    setState(() => _loading = false);
  }

  Future<bool> _tryGeminiAlternatives(ProductAnalysisData scanned) async {
    try {
      debugPrint('🤖 Trying Gemini AI for alternatives...');
      debugPrint('   Product: ${scanned.productName}');
      debugPrint('   Category: ${scanned.category}');
      debugPrint('   Eco Score: ${scanned.ecoScore}');

      // Build an enhanced prompt for Gemini 2.5 Pro
      final prompt =
          '''
You are an expert eco-product recommender with access to sustainable product databases.

Analyze this product and suggest better eco-friendly alternatives:

Scanned Product:
- Name: ${scanned.productName}
- Category: ${scanned.category}
- Packaging: ${scanned.packagingType}
- Ingredients/Materials: ${scanned.ingredients}
- Current Eco Score: ${scanned.ecoScore}

Generate at least 3 sustainable alternatives (preferably 5-8) that are:
1. More eco-friendly (better eco score than ${scanned.ecoScore})
2. Available on Shopee or Lazada Malaysia
3. Specific real products with accurate information

Return ONLY a valid JSON array with this exact structure:
[
  {
    "name": "Product Name",
    "ecoScore": "A+",
    "category": "Product Category",
    "material": "Material/Packaging Type",
    "shortDescription": "Brief sustainability description",
    "buyUrl": "Full Shopee or Lazada URL",
    "imageUrl": "Product image URL (optional)",
    "carbonSavings": "Environmental impact (e.g., Saves 2kg CO₂/year)",
    "price": 35.50,
    "brand": "Brand Name",
    "rating": 4.7
  }
]

Focus on plastic-free alternatives, refillable options, or products with minimal packaging.
''';

      debugPrint('📤 Sending request to Gemini...');
      final text = await GenerativeService.generateResponse(prompt);

      if (text.isEmpty) {
        debugPrint('❌ Gemini returned empty response');
        return false;
      }

      if (text.startsWith('__')) {
        debugPrint('❌ Gemini API error: $text');
        return false;
      }

      debugPrint('✅ Gemini response received (${text.length} chars)');
      debugPrint(
        '📝 Response preview: ${text.substring(0, text.length > 200 ? 200 : text.length)}...',
      );

      debugPrint('✅ Gemini response received (${text.length} chars)');
      debugPrint(
        '📝 Response preview: ${text.substring(0, text.length > 200 ? 200 : text.length)}...',
      );

      // Extract JSON array
      String jsonText = text.trim();
      final first = jsonText.indexOf('[');
      final last = jsonText.lastIndexOf(']');
      if (first >= 0 && last > first) {
        jsonText = jsonText.substring(first, last + 1);
      }

      debugPrint('🔍 Parsing JSON...');
      final decoded = jsonDecode(jsonText);

      if (decoded is! List || decoded.isEmpty) {
        debugPrint('❌ Invalid JSON format or empty array');
        return false;
      }

      debugPrint('✅ JSON parsed successfully, found ${decoded.length} items');
      final List<AlternativeProduct> generated = [];

      for (final item in decoded) {
        if (item is! Map) continue;

        final name = (item['name'] ?? '').toString();
        if (name.isEmpty) continue;

        debugPrint('   ✓ Adding alternative: $name (${item['ecoScore']})');
        generated.add(
          AlternativeProduct(
            name: name,
            ecoScore: (item['ecoScore'] ?? item['eco_score'] ?? 'A').toString(),
            materialType: (item['material'] ?? item['packaging'] ?? '')
                .toString(),
            category: (item['category'] ?? scanned.category).toString(),
            benefit: '',
            whereToBuy: '',
            carbonSavings: (item['carbonSavings'] ?? item['carbon'] ?? '')
                .toString(),
            imagePath: (item['imageUrl'] ?? item['image'] ?? '').toString(),
            buyLink: (item['buyUrl'] ?? item['buy_link'] ?? item['buy'] ?? '')
                .toString(),
            shortDescription:
                (item['shortDescription'] ?? item['description'] ?? '')
                    .toString(),
            price: _parsePrice(item['price']),
            brand: (item['brand'] ?? '').toString().isEmpty
                ? null
                : (item['brand'] ?? '').toString(),
            rating: _parseRating(item['rating']),
            externalSource: 'gemini',
          ),
        );
      }

      if (generated.isNotEmpty) {
        debugPrint(
          '✅ Successfully generated ${generated.length} alternatives from Gemini',
        );
        setState(() {
          _loadedAlternatives = generated;
          _dataSource = 'Gemini AI';
        });
        return true;
      } else {
        debugPrint('❌ No valid alternatives parsed from Gemini response');
      }
    } catch (e) {
      debugPrint('❌ Gemini generation failed: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
    }
    return false;
  }

  Future<bool> _tryFirestoreAlternatives(ProductAnalysisData scanned) async {
    try {
      // Query Firestore for alternatives based on category
      QuerySnapshot querySnapshot;

      if (scanned.category.isNotEmpty && scanned.category != 'N/A') {
        querySnapshot = await FirebaseFirestore.instance
            .collection('alternative_products')
            .where('category', isEqualTo: scanned.category)
            .orderBy('ecoScore')
            .limit(10)
            .get();
      } else {
        // Fallback: get top-rated alternatives
        querySnapshot = await FirebaseFirestore.instance
            .collection('alternative_products')
            .orderBy('rating', descending: true)
            .limit(10)
            .get();
      }

      if (querySnapshot.docs.isEmpty) return false;

      final List<AlternativeProduct> fetched = [];
      for (final doc in querySnapshot.docs) {
        try {
          fetched.add(AlternativeProduct.fromFirestore(doc));
        } catch (e) {
          debugPrint('Error parsing Firestore document: $e');
        }
      }

      if (fetched.isNotEmpty) {
        // Filter to show only better eco scores
        final scannedRank = _ecoRank(scanned.ecoScore);
        final better = fetched
            .where((a) => _ecoRank(a.ecoScore) < scannedRank)
            .toList();

        setState(() {
          _loadedAlternatives = better.isNotEmpty ? better : fetched;
          _dataSource = 'Firestore Database';
        });
        return true;
      }
    } catch (e) {
      debugPrint('Firestore fetch failed: $e');
    }
    return false;
  }

  double? _parsePrice(dynamic price) {
    if (price == null) return null;
    if (price is num) return price.toDouble();
    if (price is String) {
      final cleaned = price.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  double? _parseRating(dynamic rating) {
    if (rating == null) return null;
    if (rating is num) {
      final val = rating.toDouble();
      return val.clamp(0.0, 5.0);
    }
    if (rating is String) {
      final val = double.tryParse(rating);
      return val?.clamp(0.0, 5.0);
    }
    return null;
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
      setState(() {
        _loadedAlternatives = better.isNotEmpty ? better : fetched;
        _dataSource = 'Cloudinary';
      });
    } else {
      setState(() {
        _loadedAlternatives = fetched;
        _dataSource = 'Cloudinary';
      });
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
    final scannedProduct = widget.scannedProduct;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'Better Alternatives',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Hero Header Section
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: kPrimaryGreen,
                // gradient: LinearGradient(
                //   begin: Alignment.topLeft,
                //   end: Alignment.bottomRight,
                //   colors: [kPrimaryGreen, kPrimaryGreen.withOpacity(0.8)],
                // ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Greener Choices',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              scannedProduct != null
                                  ? 'For ${scannedProduct.productName}'
                                  : 'Sustainable alternatives',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.95),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tips_and_updates,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Choose greener options to reduce waste 🌿',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter Button Row
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              !_loading && alternatives.isNotEmpty
                                  ? '${alternatives.length} alternatives found'
                                  : 'Finding alternatives...',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // Show data source
                            if (_dataSource.isNotEmpty && !_loading)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      _dataSource.contains('Gemini')
                                          ? Icons.auto_awesome
                                          : _dataSource.contains('Firestore')
                                          ? Icons.cloud_done
                                          : _dataSource.contains('Cloudinary')
                                          ? Icons.cloud_download
                                          : _dataSource.contains('AI-Generated')
                                          ? Icons.lightbulb_outline
                                          : Icons.info_outline,
                                      size: 12,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Source: $_dataSource',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.7),
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                setState(() => _showFilters = !_showFilters),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Filters',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (_maxPrice != null ||
                                      _selectedBrand != null ||
                                      _minRating != null)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '!',
                                        style: TextStyle(
                                          color: kPrimaryGreen,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Filter Panel
          if (_showFilters && !_loading)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune, color: kPrimaryGreen),
                        const SizedBox(width: 8),
                        const Text(
                          'Filter Alternatives',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _resetFilters,
                          child: Text(
                            'Reset',
                            style: TextStyle(color: kPrimaryGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Max Price Filter
                    Text(
                      'Maximum Price (RM)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _maxPrice ?? 100.0,
                      min: 10.0,
                      max: 200.0,
                      divisions: 19,
                      activeColor: kPrimaryGreen,
                      label: 'RM ${(_maxPrice ?? 100.0).toStringAsFixed(0)}',
                      onChanged: (value) => setState(() => _maxPrice = value),
                    ),
                    const SizedBox(height: 16),

                    // Brand Filter
                    if (_availableBrands.isNotEmpty) ...[
                      Text(
                        'Brand',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedBrand,
                        decoration: InputDecoration(
                          hintText: 'All Brands',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Brands'),
                          ),
                          ..._availableBrands.map(
                            (brand) => DropdownMenuItem(
                              value: brand,
                              child: Text(brand),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedBrand = value),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Minimum Rating Filter
                    Text(
                      'Minimum Rating',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (double rating in [0.0, 3.0, 3.5, 4.0, 4.5])
                          ChoiceChip(
                            label: Text(rating == 0.0 ? 'Any' : '$rating ⭐'),
                            selected:
                                _minRating == (rating == 0.0 ? null : rating),
                            selectedColor: kPrimaryGreen,
                            labelStyle: TextStyle(
                              color:
                                  _minRating == (rating == 0.0 ? null : rating)
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _minRating = rating == 0.0 ? null : rating;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Loading Indicator
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(kPrimaryGreen),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Finding sustainable alternatives...',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),

          // Alternatives List
          if (!_loading)
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index >= alternatives.length) {
                    // Bottom spacing and back button
                    return Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                kPrimaryGreen.withOpacity(0.1),
                                kPrimaryGreen.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: kPrimaryGreen.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 48,
                                color: kPrimaryGreen,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Making Sustainable Choices',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Every eco-friendly product you choose helps reduce environmental impact',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Back to Result',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    );
                  }

                  return AlternativeProductCard(
                    product: alternatives[index],
                    isInWishlist: _wishlist.contains(alternatives[index].id),
                    onTap: () => _showAlternativeDetails(alternatives[index]),
                    onBuyNow: () => _openBuyLink(alternatives[index].buyLink),
                    onAddToWishlist: () => _toggleWishlist(alternatives[index]),
                    onCompare: widget.scannedProduct != null
                        ? () => _showComparison(alternatives[index])
                        : null,
                  );
                }, childCount: alternatives.length + 1),
              ),
            ),

          // Empty State
          if (!_loading && alternatives.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No Alternatives Found',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We couldn\'t find sustainable alternatives for this product yet.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}
