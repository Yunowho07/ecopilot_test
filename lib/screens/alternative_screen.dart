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
import 'eco_assistant_screen.dart';
import 'product_wishlist_screen.dart';

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
  const EcoScoreBadge({super.key, required this.score});

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
    super.key,
    required this.product,
    this.onTap,
    this.onBuyNow,
    this.onAddToWishlist,
    this.onCompare,
    this.isInWishlist = false,
  });

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
                    // Product Image - Prominently displayed
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: product.imagePath.isNotEmpty
                            ? (product.imagePath.startsWith('http')
                                  ? Image.network(
                                      product.imagePath,
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Center(
                                          child: SizedBox(
                                            width: 35,
                                            height: 35,
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                              strokeWidth: 2.5,
                                              color: kPrimaryGreen,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (ctx, err, st) => Container(
                                        color: kPrimaryGreen.withOpacity(0.05),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.eco,
                                              size: 42,
                                              color: kPrimaryGreen.withOpacity(
                                                0.4,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Eco Product',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Image.asset(
                                      product.imagePath,
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, st) => Container(
                                        color: kPrimaryGreen.withOpacity(0.05),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.eco,
                                              size: 42,
                                              color: kPrimaryGreen.withOpacity(
                                                0.4,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Eco Product',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ))
                            : Container(
                                color: kPrimaryGreen.withOpacity(0.05),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      size: 42,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'No Image',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. PRODUCT NAME (PRIORITY #1 - Most Prominent)
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),

                          // 2. ECO SCORE (PRIORITY #2 - Prominent Badge)
                          Row(
                            children: [
                              EcoScoreBadge(score: product.ecoScore),
                              if (product.rating != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber.shade700,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  product.rating!.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
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

                          const SizedBox(height: 8),

                          // 3. PRICE (PRIORITY #3 - Clear and Visible)
                          if (product.price != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    size: 16,
                                    color: Colors.blue.shade700,
                                  ),
                                  Text(
                                    'RM ${product.price!.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Material Type (Secondary Info)
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 13,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  product.materialType,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
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

                // Carbon Savings (Environmental Impact)
                if (product.carbonSavings.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
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
                ],

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
  const AlternativeScreen({super.key, this.scannedProduct});
  @override
  State<AlternativeScreen> createState() => _AlternativeScreenState();
}

class _AlternativeScreenState extends State<AlternativeScreen> {
  final int _selectedIndex = 1;
  bool _loading = false;
  List<AlternativeProduct> _loadedAlternatives = [];
  Set<String> _wishlist = {}; // Product IDs in wishlist
  List<AlternativeProduct> _recentWishlisted =
      []; // Recently added wishlist items
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

  /// Extracts generic product type from full product name
  /// Example: "Colgate Total Whitening Toothpaste 150g Twin Pack" -> "Toothpaste"
  String _extractGenericProductType(String fullProductName) {
    if (fullProductName.isEmpty) return fullProductName;

    // Common patterns to remove (case-insensitive)
    final patternsToRemove = [
      // Sizes and quantities
      RegExp(
        r'\b\d+\s*(ml|l|g|kg|oz|lb|pack|pcs|pieces?)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(twin|triple|double|single|multi)\s*pack\b',
        caseSensitive: false,
      ),
      RegExp(r'\b\d+x\d+\b', caseSensitive: false), // 2x150ml
      RegExp(r"\b\d+'?\b", caseSensitive: false), // 5' or 5 (for sizes)
      // Colors and variants
      RegExp(
        r'\b(red|blue|green|yellow|black|white|pink|purple|orange|brown|grey|gray|silver|gold)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(light|dark|deep|bright|pale|neon)\s+(red|blue|green|yellow|black|white|pink|purple|orange|brown|grey|gray)\b',
        caseSensitive: false,
      ),

      // Model numbers and codes
      RegExp(r'\b[A-Z0-9]{2,}-?[A-Z0-9]{2,}\b'), // AB12, XYZ-123
      RegExp(r'\bmodel\s+[A-Z0-9]+\b', caseSensitive: false),
      RegExp(r'\bv\d+(\.\d+)?\b', caseSensitive: false), // v2.0, v3
      // Promotional terms
      RegExp(
        r'\b(new|latest|improved|advanced|premium|deluxe|special|limited|edition|pro|plus|max|ultra|super|mega|extra)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(sale|offer|deal|discount|promo|bundle)\b',
        caseSensitive: false,
      ),

      // Common brand indicators (will be handled separately)
      RegExp(
        r'\b(original|authentic|genuine|official)\b',
        caseSensitive: false,
      ),

      // Descriptive modifiers that are too specific
      RegExp(
        r'\b(organic|natural|eco|green|sustainable|biodegradable|recyclable)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(scented|unscented|fragrance-free|hypoallergenic)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(whitening|brightening|moisturizing|hydrating|nourishing)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(antibacterial|antiseptic|antifungal)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(long-lasting|quick-dry|fast-acting|instant)\b',
        caseSensitive: false,
      ),

      // Common connectors and fillers
      RegExp(r'\s+with\s+.*$', caseSensitive: false), // Everything after "with"
      RegExp(r'\s+for\s+.*$', caseSensitive: false), // Everything after "for"
    ];

    // Common brand names to remove (extend this list as needed)
    final commonBrands = [
      'Colgate',
      'Oral-B',
      'Sensodyne',
      'Pepsodent',
      'Darlie',
      'Dove',
      'Lux',
      'Lifebuoy',
      'Dettol',
      'Palmolive',
      'Pantene',
      'Head & Shoulders',
      'Rejoice',
      'Sunsilk',
      'Clear',
      'Coca-Cola',
      'Pepsi',
      'Nestle',
      'Milo',
      'Nescafe',
      'Maggi',
      'Knorr',
      'Ajinomoto',
      'Lady\'s Choice',
      'Kimball',
      'Samsung',
      'Apple',
      'Xiaomi',
      'Huawei',
      'Oppo',
      'Vivo',
      'Nike',
      'Adidas',
      'Puma',
      'Uniqlo',
      'H&M',
    ];

    String result = fullProductName;

    // Remove brand names (case-insensitive word boundary matching)
    for (final brand in commonBrands) {
      result = result.replaceAll(
        RegExp(r'\b' + RegExp.escape(brand) + r'\b', caseSensitive: false),
        '',
      );
    }

    // Apply all pattern removals
    for (final pattern in patternsToRemove) {
      result = result.replaceAll(pattern, '');
    }

    // Clean up extra whitespace and punctuation
    result = result
        .replaceAll(
          RegExp(r'[\s,\-\_\/\(\)\[\]\{\}]+'),
          ' ',
        ) // Normalize whitespace and punctuation
        .trim()
        .replaceAll(RegExp(r'\s+'), ' '); // Remove multiple spaces

    // If result is empty or too short, return the original
    if (result.isEmpty || result.length < 3) {
      // Fallback: try to extract the last meaningful word from original
      final words = fullProductName.split(RegExp(r'\s+'));
      for (int i = words.length - 1; i >= 0; i--) {
        final word = words[i].replaceAll(RegExp(r'[^a-zA-Z]'), '');
        if (word.length >= 3 && !RegExp(r'^\d+$').hasMatch(word)) {
          return word;
        }
      }
      return fullProductName; // Ultimate fallback
    }

    return result;
  }

  // Wishlist management methods
  Future<void> _loadWishlist() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Load all wishlist IDs
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .get();

      setState(() {
        _wishlist = doc.docs.map((d) => d.id).toSet();
      });

      // Load recent wishlisted items (up to 5 most recent)
      final recentDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      if (recentDocs.docs.isNotEmpty) {
        final recent = recentDocs.docs
            .map((d) => AlternativeProduct.fromFirestore(d))
            .toList();
        setState(() {
          _recentWishlisted = recent;
        });
      }
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
        setState(() {
          _recentWishlisted.removeWhere((item) => item.id == product.id);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removed from wishlist')));
      } else {
        await wishlistRef.set({
          ...product.toFirestore(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        setState(() => _wishlist.add(product.id));
        // Reload recent items
        _loadWishlist();
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

  // Build Recent Wishlist Section Widget
  Widget _buildRecentWishlistSection() {
    if (_recentWishlisted.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: kPrimaryGreen,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Your Recent Favorites',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_recentWishlisted.length} items',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _recentWishlisted.length,
                itemBuilder: (context, index) {
                  final product = _recentWishlisted[index];
                  return Container(
                    width: 170,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showAlternativeDetails(product),
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image with Overlay Badge
                            Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.grey.shade100,
                                        Colors.grey.shade50,
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                    child: product.imagePath.isNotEmpty
                                        ? (product.imagePath.startsWith('http')
                                              ? Image.network(
                                                  product.imagePath,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (ctx, err, st) => Center(
                                                        child: Icon(
                                                          Icons.eco,
                                                          size: 40,
                                                          color: kPrimaryGreen
                                                              .withOpacity(0.3),
                                                        ),
                                                      ),
                                                )
                                              : Image.asset(
                                                  product.imagePath,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (ctx, err, st) => Center(
                                                        child: Icon(
                                                          Icons.eco,
                                                          size: 40,
                                                          color: kPrimaryGreen
                                                              .withOpacity(0.3),
                                                        ),
                                                      ),
                                                ))
                                        : Center(
                                            child: Icon(
                                              Icons.eco,
                                              size: 40,
                                              color: kPrimaryGreen.withOpacity(
                                                0.3,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                // Eco Score Badge Overlay
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: EcoScoreBadge(score: product.ecoScore),
                                ),
                                // Favorite Icon
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.favorite,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Product Info
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    if (product.price != null)
                                      Row(
                                        children: [
                                          Text(
                                            'RM ${product.price!.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: kPrimaryGreen,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (product.rating != null)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  size: 12,
                                                  color: Colors.amber,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  product.rating!
                                                      .toStringAsFixed(1),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Modern Header with Gradient Background
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryGreen, kPrimaryGreen.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryGreen.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.compare_arrows,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Smart Comparison',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'See how your eco-choice stacks up',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Product Cards Side by Side with VS badge
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          children: [
                            // Current Product Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.shopping_bag_outlined,
                                          size: 48,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Current',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      scanned.productName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 60), // Space for VS badge
                            // Alternative Product Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      kPrimaryGreen.withOpacity(0.1),
                                      kPrimaryGreen.withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: kPrimaryGreen,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kPrimaryGreen.withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: alternative.imagePath.isNotEmpty
                                            ? (alternative.imagePath.startsWith(
                                                    'http',
                                                  )
                                                  ? Image.network(
                                                      alternative.imagePath,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            ctx,
                                                            err,
                                                            st,
                                                          ) => Icon(
                                                            Icons.eco,
                                                            size: 48,
                                                            color:
                                                                kPrimaryGreen,
                                                          ),
                                                    )
                                                  : Image.asset(
                                                      alternative.imagePath,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            ctx,
                                                            err,
                                                            st,
                                                          ) => Icon(
                                                            Icons.eco,
                                                            size: 48,
                                                            color:
                                                                kPrimaryGreen,
                                                          ),
                                                    ))
                                            : Center(
                                                child: Icon(
                                                  Icons.eco,
                                                  size: 48,
                                                  color: kPrimaryGreen,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kPrimaryGreen,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: kPrimaryGreen.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.stars,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Better Choice',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      alternative.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: kPrimaryGreen,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // VS Badge in the center
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.shade400,
                                Colors.purple.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Comparison Metrics Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kPrimaryGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.analytics_outlined,
                            color: kPrimaryGreen,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Detailed Metrics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Comparison Details with better design
                    _buildModernComparisonRow(
                      'Product Name',
                      scanned.productName,
                      alternative.name,
                      Icons.shopping_bag_outlined,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildModernComparisonRow(
                      'Eco Score',
                      scanned.ecoScore,
                      alternative.ecoScore,
                      Icons.eco,
                      kPrimaryGreen,
                      highlightBetter: true,
                    ),
                    const SizedBox(height: 12),
                    _buildModernComparisonRow(
                      'Packaging',
                      scanned.packagingType,
                      alternative.materialType,
                      Icons.inventory_2_outlined,
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildModernComparisonRow(
                      'Category',
                      scanned.category,
                      alternative.category,
                      Icons.category_outlined,
                      Colors.purple,
                    ),

                    // Price Comparison if available
                    if (alternative.price != null) ...[
                      const SizedBox(height: 12),
                      _buildModernComparisonRow(
                        'Price',
                        'N/A',
                        'RM ${alternative.price!.toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ],

                    // Environmental Impact Highlight
                    if (alternative.carbonSavings.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kPrimaryGreen.withOpacity(0.2),
                              kPrimaryGreen.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: kPrimaryGreen.withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimaryGreen.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.energy_savings_leaf,
                                color: kPrimaryGreen,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '🌍 Environmental Impact',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                alternative.carbonSavings,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: kPrimaryGreen,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: kPrimaryGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '✨ Your positive impact by switching',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action Buttons with improved design
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close, size: 20),
                            label: const Text('Close'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: Colors.grey.shade400,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _openBuyLink(alternative.buyLink);
                            },
                            icon: const Icon(Icons.shopping_cart, size: 20),
                            label: const Text(
                              'Choose Better Option',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 4,
                              shadowColor: kPrimaryGreen.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernComparisonRow(
    String label,
    String scannedValue,
    String altValue,
    IconData icon,
    Color accentColor, {
    bool highlightBetter = false,
  }) {
    bool altIsBetter = false;
    if (highlightBetter && label == 'Eco Score') {
      altIsBetter = _ecoRank(altValue) < _ecoRank(scannedValue);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label with icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: accentColor),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          // Values comparison
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Current value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          scannedValue.isEmpty || scannedValue == 'N/A'
                              ? '—'
                              : scannedValue,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 24,
                        color: altIsBetter
                            ? kPrimaryGreen
                            : Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
                // Alternative value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Alternative',
                            style: TextStyle(
                              fontSize: 11,
                              color: altIsBetter
                                  ? kPrimaryGreen
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (altIsBetter) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: kPrimaryGreen,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: altIsBetter
                              ? LinearGradient(
                                  colors: [
                                    kPrimaryGreen.withOpacity(0.15),
                                    kPrimaryGreen.withOpacity(0.05),
                                  ],
                                )
                              : null,
                          color: altIsBetter ? null : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: altIsBetter
                                ? kPrimaryGreen
                                : Colors.grey.shade200,
                            width: altIsBetter ? 2 : 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                altValue.isEmpty || altValue == 'N/A'
                                    ? '—'
                                    : altValue,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: altIsBetter
                                      ? kPrimaryGreen
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (altIsBetter)
                              Icon(
                                Icons.check_circle,
                                color: kPrimaryGreen,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
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

    // ✅ RANKING: Sort alternatives by priority criteria
    // Priority 1: Eco Score (A+ > A > B > C > D > E)
    // Priority 2: Product Relevance (shorter name = more generic/relevant)
    // Priority 3: Price (lower is better)
    alternatives.sort((a, b) {
      // 1. Compare eco scores (lower rank = better)
      final aEcoRank = _ecoRank(a.ecoScore);
      final bEcoRank = _ecoRank(b.ecoScore);
      if (aEcoRank != bEcoRank) {
        return aEcoRank.compareTo(bEcoRank);
      }

      // 2. Compare product name length (shorter = more relevant/generic)
      final aNameLength = a.name.length;
      final bNameLength = b.name.length;
      if (aNameLength != bNameLength) {
        return aNameLength.compareTo(bNameLength);
      }

      // 3. Compare prices (lower is better)
      // Products without price come last
      if (a.price == null && b.price != null) return 1;
      if (a.price != null && b.price == null) return -1;
      if (a.price != null && b.price != null) {
        return a.price!.compareTo(b.price!);
      }

      return 0; // Equal priority
    });

    // Debug: Show ranked alternatives
    if (alternatives.isNotEmpty) {
      debugPrint('📊 RANKED ALTERNATIVES (${alternatives.length} total):');
      for (int i = 0; i < alternatives.length && i < 10; i++) {
        final alt = alternatives[i];
        debugPrint(
          '   ${i + 1}. ${alt.name}\n'
          '      Eco: ${alt.ecoScore} (rank: ${_ecoRank(alt.ecoScore)})\n'
          '      Price: ${alt.price != null ? "RM ${alt.price!.toStringAsFixed(2)}" : "N/A"}\n'
          '      Name Length: ${alt.name.length}',
        );
      }
    }

    return alternatives;
  }

  List<AlternativeProduct> _computeFallbackAlternatives() {
    final scanned = widget.scannedProduct;

    // No static fallback - only show alternatives from real sources (Gemini/Firestore)
    if (scanned == null) {
      _dataSource = 'No Data Available';
      return [];
    }

    _dataSource = 'No Data Available';
    return [];
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
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: kPrimaryGreen.withOpacity(0.3),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimaryGreen.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: p.imagePath.isNotEmpty
                              ? (p.imagePath.startsWith('http')
                                    ? Image.network(
                                        p.imagePath,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Center(
                                            child: SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                    : null,
                                                strokeWidth: 3,
                                                color: kPrimaryGreen,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (ctx, err, st) =>
                                            Container(
                                              color: kPrimaryGreen.withOpacity(
                                                0.05,
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.eco,
                                                    size: 60,
                                                    color: kPrimaryGreen
                                                        .withOpacity(0.3),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Eco-Friendly\nProduct',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                      )
                                    : Image.asset(
                                        p.imagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, st) =>
                                            Container(
                                              color: kPrimaryGreen.withOpacity(
                                                0.05,
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.eco,
                                                    size: 60,
                                                    color: kPrimaryGreen
                                                        .withOpacity(0.3),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Eco-Friendly\nProduct',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                      ))
                              : Container(
                                  color: kPrimaryGreen.withOpacity(0.05),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 60,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No Image\nAvailable',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 1. PRODUCT NAME (PRIORITY #1 - Most Prominent)
                    Center(
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. ECO SCORE (PRIORITY #2 - Prominent Badge)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _kEcoScoreColors[p.ecoScore]?.withOpacity(0.15) ??
                              Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _kEcoScoreColors[p.ecoScore] ?? Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.eco,
                              color:
                                  _kEcoScoreColors[p.ecoScore] ?? Colors.grey,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Eco Score: ${p.ecoScore}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    _kEcoScoreColors[p.ecoScore] ?? Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. PRICE (PRIORITY #3 - Clear and Prominent)
                    if (p.price != null)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade50,
                                Colors.blue.shade100,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attach_money,
                                color: Colors.blue.shade700,
                                size: 26,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'RM ${p.price!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (p.price != null) const SizedBox(height: 24),

                    // Rating (if available)
                    if (p.rating != null)
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...List.generate(5, (index) {
                              return Icon(
                                index < p.rating!.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber.shade700,
                                size: 22,
                              );
                            }),
                            const SizedBox(width: 8),
                            Text(
                              p.rating!.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (p.rating != null) const SizedBox(height: 24),

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

                    // Brand (if available)
                    if (p.brand != null && p.brand!.isNotEmpty)
                      _buildDetailRow(
                        icon: Icons.business,
                        label: 'Brand',
                        value: p.brand!,
                        color: Colors.orange,
                      ),
                    if (p.brand != null && p.brand!.isNotEmpty)
                      const SizedBox(height: 16),

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

    // Extract generic product type from full product name
    final genericProductType = _extractGenericProductType(scanned.productName);

    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('🔄 PRODUCT NAME NORMALIZATION');
    debugPrint('   Original: ${scanned.productName}');
    debugPrint('   Generic Type: $genericProductType');
    debugPrint('   Category: ${scanned.category}');
    debugPrint('═══════════════════════════════════════════════════');

    setState(() => _loading = true);

    // Step 1: Try Firestore cache first (fastest)
    debugPrint('📍 Step 1: Checking Firestore cache...');
    bool firestoreSuccess = await _tryFirestoreAlternatives(scanned);
    if (firestoreSuccess) {
      debugPrint('✅ Success! Using cached Firestore alternatives');
      setState(() => _loading = false);
      return;
    }

    // Step 2: Try Gemini AI for intelligent alternatives
    debugPrint('📍 Step 2: Trying Gemini AI (no cache found)...');
    bool geminiSuccess = await _tryGeminiAlternatives(scanned);
    if (geminiSuccess) {
      debugPrint('✅ Success! Using Gemini AI alternatives (saved to cache)');
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

  Future<bool> _tryGeminiAlternatives(
    ProductAnalysisData scanned, {
    int retryCount = 0,
  }) async {
    const maxRetries = 2;

    try {
      debugPrint(
        '🤖 Trying Gemini AI for alternatives... (Attempt ${retryCount + 1}/${maxRetries + 1})',
      );
      debugPrint('   Product: ${scanned.productName}');
      debugPrint('   Category: ${scanned.category}');
      debugPrint('   Eco Score: ${scanned.ecoScore}');

      // Extract generic product type for better matching
      final genericProductType = _extractGenericProductType(
        scanned.productName,
      );

      // Build an enhanced prompt for Gemini 2.0 Flash (latest model)
      final prompt =
          '''
You are an expert eco-product recommender with access to current e-commerce data in Malaysia.

SCANNED PRODUCT ANALYSIS:
━━━━━━━━━━━━━━━━━━━━━━━━━━
Original Product: ${scanned.productName}
Generic Product Type: $genericProductType
Category: ${scanned.category}
Current Eco Score: ${scanned.ecoScore}
Packaging Type: ${scanned.packagingType}
Ingredients/Materials: ${scanned.ingredients}
━━━━━━━━━━━━━━━━━━━━━━━━━━

TASK: Find 5-8 REAL eco-friendly alternatives for "$genericProductType" available on Shopee or Lazada Malaysia that are:

✅ REQUIREMENTS (ALL MANDATORY):
1. Better eco score than "${scanned.ecoScore}" (must be A+, A, or B if current is C/D/E)
2. Same generic product type as "$genericProductType" (NOT the specific brand "${scanned.productName}")
3. Same category as "${scanned.category}"
4. Currently available for purchase in Malaysia (Shopee/Lazada)
5. REAL product names and brands (no generic examples)
6. More sustainable packaging or materials than scanned product
7. Specific Shopee/Lazada search URLs

🎯 PRIORITIZE:
- Plastic-free packaging
- Refillable/reusable containers
- Biodegradable materials
- Certified eco-labels (Leaping Bunny, FSC, etc.)
- Local/Malaysian sustainable brands

📋 OUTPUT FORMAT (JSON ARRAY ONLY - NO MARKDOWN, NO EXPLANATIONS):
[
  {
    "name": "Exact Product Name (Brand + Product)",
    "ecoScore": "A+",
    "category": "${scanned.category}",
    "material": "Specific packaging material (e.g., Recycled Glass, Bamboo Fiber)",
    "shortDescription": "Why this is more sustainable than the scanned product (1 sentence)",
    "buyUrl": "https://shopee.com.my/search?keyword=exact+product+name",
    "imageUrl": "https://example.com/product-image.jpg",
    "carbonSavings": "Estimated environmental benefit (e.g., Reduces 5kg CO₂/year)",
    "price": 35.50,
    "brand": "Brand Name",
    "rating": 4.5
  }
]

🖼️ IMAGE REQUIREMENTS (CRITICAL - MANDATORY FOR EVERY PRODUCT):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  EVERY alternative MUST include a valid, accessible product image URL
⚠️  Images are ESSENTIAL for user engagement and product recognition
⚠️  Do NOT skip images or provide placeholder URLs
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. PRIMARY SOURCES (Use these first):
   - Shopee Malaysia product images (direct links from search results)
   - Lazada Malaysia product images
   - Official brand website product photos

2. IMAGE REQUIREMENTS:
   ✓ HTTPS URLs preferred for security
   ✓ Direct image links (ending in .jpg, .png, .webp)
   ✓ High resolution (minimum 400x400 pixels)
   ✓ Clear product visibility (no watermarks/logos covering product)
   ✓ Actual product photo, not category icons or generic illustrations

3. FALLBACK SOURCES (if primary unavailable):
   - Unsplash (search: eco-friendly + product type)
   - Pexels (search: sustainable + product type)
   - Use actual product photos, never use placeholder.com or example.com

4. VALIDATION:
   - Test that URL is accessible before including
   - Ensure image shows the actual alternative product recommended
   - If unsure about image, search "[brand name] [product name] image" on Google Images

EXAMPLE VALID IMAGE URLS:
✓ https://cf.shopee.com.my/file/[product-image-id]
✓ https://laz-img-cdn.alicdn.com/[product-image-path]
✓ https://images.unsplash.com/photo-[id]?ixlib=eco+product

IMPORTANT: Focus on finding alternatives for the generic product type "$genericProductType", not the specific brand "${scanned.productName}". This ensures better category matching and more diverse eco-friendly options.

⚠️ CRITICAL RULES:
- Return ONLY the JSON array (no ```json``` markers, no extra text)
- All products MUST be real and purchasable in Malaysia
- Eco scores MUST be better than "${scanned.ecoScore}"
- Include 5-8 alternatives minimum
- Use real brand names (e.g., "Lush Shampoo Bar", "Bamboo Bae Toothbrush")
- Generate accurate Shopee search URLs

Generate the alternatives now:''';

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
      int itemIndex = 0;

      for (final item in decoded) {
        if (item is! Map) continue;

        final name = (item['name'] ?? '').toString();
        if (name.isEmpty) continue;

        debugPrint('   ✓ Adding alternative: $name (${item['ecoScore']})');

        // Generate unique ID using timestamp + index + name hash
        final uniqueId =
            '${DateTime.now().millisecondsSinceEpoch}_${itemIndex}_${name.hashCode.abs()}';
        itemIndex++;

        generated.add(
          AlternativeProduct(
            id: uniqueId,
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

        // Save to Firestore for future caching
        await _saveAlternativesToFirestore(scanned, generated);

        setState(() {
          _loadedAlternatives = generated;
          _dataSource = 'Gemini AI';
        });
        return true;
      } else {
        debugPrint('❌ No valid alternatives parsed from Gemini response');
      }
    } catch (e) {
      debugPrint('❌ Gemini generation failed (Attempt ${retryCount + 1}): $e');

      // Retry with exponential backoff if we haven't exceeded max retries
      if (retryCount < maxRetries) {
        final delaySeconds = (retryCount + 1) * 2; // 2s, 4s, 6s...
        debugPrint('⏳ Retrying in $delaySeconds seconds...');
        await Future.delayed(Duration(seconds: delaySeconds));
        return _tryGeminiAlternatives(scanned, retryCount: retryCount + 1);
      } else {
        debugPrint('❌ Max retries ($maxRetries) reached. Giving up on Gemini.');
      }
    }
    return false;
  }

  Future<bool> _tryFirestoreAlternatives(ProductAnalysisData scanned) async {
    try {
      debugPrint('🔍 Searching Firestore for cached alternatives...');

      // Extract generic product type for better cache matching
      final genericProductType = _extractGenericProductType(
        scanned.productName,
      );

      // Create product key for exact match lookup using generic type
      final productKey = genericProductType
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .trim();

      debugPrint('   Generic Product Type: $genericProductType');
      debugPrint('   Product Key: $productKey');

      QuerySnapshot querySnapshot;

      // First, try to find alternatives specifically cached for this generic product type
      debugPrint('   Trying generic product type cache: $productKey');
      querySnapshot = await FirebaseFirestore.instance
          .collection('alternative_products')
          .where('sourceProductKey', isEqualTo: productKey)
          .limit(10)
          .get();

      // If no product-specific cache, try category-based alternatives
      if (querySnapshot.docs.isEmpty &&
          scanned.category.isNotEmpty &&
          scanned.category != 'N/A') {
        debugPrint('   No product cache, trying category: ${scanned.category}');
        querySnapshot = await FirebaseFirestore.instance
            .collection('alternative_products')
            .where('category', isEqualTo: scanned.category)
            .orderBy('ecoScore')
            .limit(10)
            .get();
      }

      // Final fallback: get top-rated alternatives
      if (querySnapshot.docs.isEmpty) {
        debugPrint('   No category match, trying top-rated alternatives');
        querySnapshot = await FirebaseFirestore.instance
            .collection('alternative_products')
            .orderBy('rating', descending: true)
            .limit(10)
            .get();
      }

      if (querySnapshot.docs.isEmpty) {
        debugPrint('❌ No alternatives found in Firestore');
        return false;
      }

      debugPrint(
        '✅ Found ${querySnapshot.docs.length} alternatives in Firestore',
      );

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
          _dataSource =
              querySnapshot.docs.first.data().toString().contains(
                'sourceProductKey',
              )
              ? 'Firestore Cache (Product-Specific)'
              : 'Firestore Database';
        });
        return true;
      }
    } catch (e) {
      debugPrint('Firestore fetch failed: $e');
    }
    return false;
  }

  /// Save Gemini-generated alternatives to Firestore for caching
  Future<void> _saveAlternativesToFirestore(
    ProductAnalysisData scanned,
    List<AlternativeProduct> alternatives,
  ) async {
    try {
      debugPrint(
        '💾 Saving ${alternatives.length} alternatives to Firestore...',
      );

      // Extract generic product type for cache key
      final genericProductType = _extractGenericProductType(
        scanned.productName,
      );

      // Create a product-specific document ID based on generic product type
      final productKey = genericProductType
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .trim();

      debugPrint('   Caching with generic type: $genericProductType');
      debugPrint('   Product key: $productKey');

      final batch = FirebaseFirestore.instance.batch();

      for (final alt in alternatives) {
        final docRef = FirebaseFirestore.instance
            .collection('alternative_products')
            .doc(alt.id);

        batch.set(docRef, {
          ...alt.toFirestore(),
          'sourceProductName': scanned.productName,
          'sourceGenericType': genericProductType,
          'sourceProductKey': productKey,
          'sourceCategory': scanned.category,
          'sourceEcoScore': scanned.ecoScore,
          'generatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('✅ Successfully saved alternatives to Firestore');
    } catch (e) {
      debugPrint('❌ Failed to save alternatives to Firestore: $e');
      // Don't throw - this is just caching, not critical
    }
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
      int itemIndex = 0;
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

              // Generate unique ID for Cloudinary products
              final uniqueId =
                  'cloudinary_${DateTime.now().millisecondsSinceEpoch}_${itemIndex}_${name.hashCode.abs()}';
              itemIndex++;

              fetched.add(
                AlternativeProduct(
                  id: uniqueId,
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
        actions: [
          // Wishlist Button
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.white),
                onPressed: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => const ProductWishlistScreen(),
                        ),
                      )
                      .then((_) {
                        // Reload wishlist when returning from wishlist screen
                        _loadWishlist();
                      });
                },
                tooltip: 'My Wishlist',
              ),
              if (_wishlist.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        '${_wishlist.length > 9 ? '9+' : _wishlist.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
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

          // Recent Wishlist Section
          _buildRecentWishlistSection(),

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
                  mainAxisSize: MainAxisSize.min,
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
                        initialValue: _selectedBrand,
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
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                140,
              ), // Extra bottom padding for FAB + BottomNav
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
                        const SizedBox(
                          height: 20,
                        ), // Reduced since parent padding handles bottom spacing
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
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              kPrimaryGreen.withOpacity(0.1),
                              kPrimaryYellow.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.eco_outlined,
                          size: 64,
                          color: kPrimaryGreen,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No Alternatives Available',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Our AI is currently unable to find sustainable alternatives for this product.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Try scanning a different product or check back later as we continuously update our database.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Retry alternative generation
                            _generateAlternativesThenFallback();
                          },
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text(
                            'Retry Search',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.arrow_back, color: kPrimaryGreen),
                        label: Text(
                          'Back to Results',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: kPrimaryGreen,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: kPrimaryGreen, width: 2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const EcoAssistantScreen()));
        },
        backgroundColor: kPrimaryGreen,
        icon: Image.asset(
          'assets/chatbot.png',
          width: 40,
          height: 40,
          color: Colors.white,
        ),
        label: const Text(
          'Eco Assistant',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 6,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}
