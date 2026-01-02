import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../utils/constants.dart';

// Conversion rate: 1000 eco points = RM 1.00
const double kEcoPointConversionRate = 1000.0;

class RedeemScreen extends StatefulWidget {
  const RedeemScreen({super.key});

  @override
  State<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends State<RedeemScreen> {
  int _userEcoPoints = 0;
  String _selectedCategory = 'All';
  bool _showOnlyAvailable = false;
  bool _isCheckingOffers = false;

  @override
  void initState() {
    super.initState();
    _loadUserEcoPoints();
    _checkAndLoadOffers();
  }

  // Check if offers exist, if not auto-load sample offers
  Future<void> _checkAndLoadOffers() async {
    try {
      setState(() {
        _isCheckingOffers = true;
      });

      debugPrint('🔍 Checking for existing offers...');
      final offersSnapshot = await FirebaseFirestore.instance
          .collection('redemption_offers')
          .limit(1)
          .get();

      // If no offers exist, automatically seed sample offers
      if (offersSnapshot.docs.isEmpty) {
        debugPrint('❌ No offers found, auto-loading sample offers...');
        await _seedSampleOffersWithoutDialog();
        debugPrint('✅ Sample offers loaded successfully');
      } else {
        debugPrint('✅ Found ${offersSnapshot.docs.length} existing offers');
      }
    } catch (e) {
      debugPrint('❌ Error checking offers: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load offers: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _checkAndLoadOffers,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingOffers = false;
        });
      }
    }
  }

  // Load user's total Eco Points
  Future<void> _loadUserEcoPoints() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (mounted) {
          setState(() {
            _userEcoPoints = data?['ecoPoints'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user eco points: $e');
    }
  }

  // Check if redemption offer is still valid
  bool _isOfferValid(Timestamp? expiryTimestamp) {
    if (expiryTimestamp == null) return true;
    final expiryDate = expiryTimestamp.toDate();
    return DateTime.now().isBefore(expiryDate);
  }

  // Check if user has enough points
  bool _hasEnoughPoints(int requiredPoints) {
    return _userEcoPoints >= requiredPoints;
  }

  // Format date for display
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Convert eco points to monetary value (RM)
  String _convertPointsToMoney(int points) {
    final value = points / kEcoPointConversionRate;
    return 'RM ${value.toStringAsFixed(2)}';
  }

  // Generate unique barcode/QR code for redemption
  String _generateRedemptionCode() {
    final now = DateTime.now();
    final random = Random();
    final randomNum = random.nextInt(999999).toString().padLeft(6, '0');
    final timestamp = now.millisecondsSinceEpoch.toString().substring(7);
    return 'ECO$timestamp$randomNum';
  }

  // Handle redemption process
  Future<void> _redeemOffer(
    String offerId,
    String offerTitle,
    int requiredPoints,
    String storeName,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Please sign in to redeem offers');
        return;
      }

      // Check if user has enough points
      if (!_hasEnoughPoints(requiredPoints)) {
        _showSnackBar('Insufficient Eco Points');
        return;
      }

      // Show confirmation dialog
      final confirmed = await _showConfirmationDialog(
        offerTitle,
        requiredPoints,
        storeName,
      );

      if (confirmed != true) return;

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Create redemption record without deducting points (pending verification)
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User document not found');
        }

        final currentPoints = userDoc.data()?['ecoPoints'] ?? 0;

        if (currentPoints < requiredPoints) {
          throw Exception('Insufficient points');
        }

        // Create redemption record with pending status
        // Points will be deducted only after store verification
        final now = DateTime.now();
        final expiryTime = now.add(const Duration(hours: 24)); // 24 hour expiry
        final redemptionCode = _generateRedemptionCode();

        final redemptionRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('redemptions')
            .doc();

        transaction.set(redemptionRef, {
          'offerId': offerId,
          'offerTitle': offerTitle,
          'storeName': storeName,
          'pointsRequired': requiredPoints,
          'monetaryValue': _convertPointsToMoney(requiredPoints),
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(expiryTime),
          'redemptionCode': redemptionCode, // QR/Barcode for store scanning
          'status':
              'pending', // pending, verified, completed, expired, cancelled
          'verificationMethod': 'barcode', // barcode or qr_code
        });
      });

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Reload user points
      await _loadUserEcoPoints();

      // Show success dialog with voucher
      if (!mounted) return;
      _showSuccessDialog(offerTitle, storeName);
    } catch (e) {
      debugPrint('Error redeeming offer: $e');
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      _showSnackBar('Failed to redeem offer: ${e.toString()}');
    }
  }

  // Show confirmation dialog before redemption
  Future<bool?> _showConfirmationDialog(
    String title,
    int points,
    String store,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.card_giftcard, color: kPrimaryGreen),
            SizedBox(width: 8),
            Text('Confirm Redemption'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to redeem:',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPrimaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPrimaryGreen.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'from $store',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.stars, size: 18, color: kPrimaryGreen),
                      const SizedBox(width: 4),
                      Text(
                        '$points Eco Points',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your remaining balance: ${_userEcoPoints - points} points',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // Show success dialog after redemption request
  void _showSuccessDialog(String title, String store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: kPrimaryGreen,
                size: 64,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Redemption Request Created! 🎉',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your redemption request for:',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'from $store',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 32),
                  const SizedBox(height: 12),
                  const Text(
                    'Next Steps:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Visit $store within 24 hours\n2. Show your QR code to staff\n3. Points deducted after verification\n4. Receive your reward!',
                    style: const TextStyle(fontSize: 13, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'QR code expires in 24 hours if not used',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyVouchersScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('View QR Code'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Seed sample offers without showing dialog (for auto-load)
  Future<void> _seedSampleOffersWithoutDialog() async {
    try {
      debugPrint('📦 Starting to seed sample offers...');
      await _addOffersToFirestore();
      debugPrint('✅ Sample offers seeded successfully');
      if (mounted) {
        _showSnackBar('✅ Sample offers loaded successfully!');
      }
    } catch (e) {
      debugPrint('❌ Error seeding offers: $e');
      if (mounted) {
        _showSnackBar('Failed to load offers: $e');
      }
    }
  }

  // Seed sample redemption offers to Firestore with dialog
  Future<void> _seedSampleOffers() async {
    try {
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: kPrimaryGreen),
                  SizedBox(height: 16),
                  Text('Loading sample offers...'),
                ],
              ),
            ),
          ),
        ),
      );

      await _addOffersToFirestore();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        _showSnackBar('✅ Sample offers added successfully!');
      }
    } catch (e) {
      debugPrint('Error seeding offers: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        _showSnackBar('Failed to load offers: $e');
      }
    }
  }

  // Add offers to Firestore
  Future<void> _addOffersToFirestore() async {
    final offers = [
      // 80-120 Points Tier - Small discounts, single items
      {
        'title': '₱50 OFF at 7 Eleven',
        'storeName': '7 Eleven',
        'description':
            'Get ₱50 discount on eco-friendly products at any 7 Eleven store',
        'requiredPoints': 80,
        'category': 'Food & Beverage',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
        'imageUrl': '',
      },
      {
        'title': 'Free Coffee at Gigi Coffee',
        'storeName': 'Gigi Coffee',
        'description':
            'Enjoy a free regular coffee of your choice at Gigi Coffee',
        'requiredPoints': 100,
        'category': 'Food & Beverage',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 45)),
        ),
        'imageUrl': '',
      },
      {
        'title': '₱80 Discount at 99 Speedmart',
        'storeName': '99 Speedmart',
        'description':
            'Save ₱80 on sustainable household products at 99 Speedmart',
        'requiredPoints': 110,
        'category': 'Home & Living',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 60)),
        ),
        'imageUrl': '',
      },
      {
        'title': 'Beverage Voucher at Chagee',
        'storeName': 'Chagee',
        'description':
            'Redeem for any medium-sized beverage at Chagee tea shop',
        'requiredPoints': 120,
        'category': 'Food & Beverage',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
        'imageUrl': '',
      },
      // 150-200 Points Tier - Medium rewards, free products
      {
        'title': 'Frozen Yogurt at llao llao',
        'storeName': 'llao llao',
        'description':
            'Get a free regular frozen yogurt with 2 toppings at llao llao',
        'requiredPoints': 150,
        'category': 'Food & Beverage',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 60)),
        ),
        'imageUrl': '',
      },
      {
        'title': 'Reusable Shopping Bag from KK Mart',
        'storeName': 'KK Mart',
        'description':
            'Claim a free eco-friendly reusable shopping bag at KK Mart',
        'requiredPoints': 160,
        'category': 'Home & Living',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 90)),
        ),
        'imageUrl': '',
      },
      {
        'title': '₱150 OFF at Zus Coffee',
        'storeName': 'Zus Coffee',
        'description': 'Enjoy ₱150 discount on any order at Zus Coffee outlets',
        'requiredPoints': 180,
        'category': 'Food & Beverage',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 45)),
        ),
        'imageUrl': '',
      },
      {
        'title': 'Combo Meal at Family Mart',
        'storeName': 'Family Mart',
        'description':
            'Redeem a sustainable meal combo at any Family Mart store',
        'requiredPoints': 200,
        'category': 'Food & Beverage',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 75)),
        ),
        'imageUrl': '',
      },
      // 220-300 Points Tier - Premium rewards, high-value items
      {
        'title': 'Free Organic Beauty Kit',
        'storeName': 'CU Mart',
        'description': 'Get a complete organic beauty care set from CU Mart',
        'requiredPoints': 220,
        'category': 'Beauty & Care',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 60)),
        ),
        'imageUrl': '',
      },
      {
        'title': '₱250 Voucher at Tealive',
        'storeName': 'Tealive',
        'description': 'Enjoy ₱250 worth of beverages at any Tealive location',
        'requiredPoints': 250,
        'category': 'Food & Beverage',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 90)),
        ),
        'imageUrl': '',
      },
      {
        'title': 'Sustainable Fashion Discount',
        'storeName': 'EcoFashion Hub',
        'description':
            '20% OFF on organic clothing and sustainable fashion items',
        'requiredPoints': 280,
        'category': 'Fashion',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 45)),
        ),
        'imageUrl': '',
      },
      {
        'title': 'Premium Coffee Experience',
        'storeName': 'Kopi Saigon',
        'description':
            '₱300 voucher for Vietnamese coffee and sustainable treats',
        'requiredPoints': 300,
        'category': 'Food & Beverage',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 75)),
        ),
        'imageUrl': '',
      },
    ];

    final batch = FirebaseFirestore.instance.batch();

    for (final offer in offers) {
      final docRef = FirebaseFirestore.instance
          .collection('redemption_offers')
          .doc();
      batch.set(docRef, offer);
    }

    await batch.commit();
    debugPrint('✅ ${offers.length} offers added to Firestore');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text(
          'Redeem Rewards',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimaryGreen, kPrimaryGreen.withOpacity(0.8)],
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyVouchersScreen()),
              );
            },
            tooltip: 'My Vouchers',
          ),
        ],
      ),
      body: Column(
        children: [
          // User Points Header - Modern Card Design
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kPrimaryGreen,
                  kPrimaryGreen.withOpacity(0.85),
                  const Color(0xFF1B5E20),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryGreen.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  left: -20,
                  bottom: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Balance',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Eco Points',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Icon(Icons.eco, color: Colors.white, size: 32),
                          const SizedBox(width: 12),
                          Text(
                            '$_userEcoPoints',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'POINTS',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '≈ ${_convertPointsToMoney(_userEcoPoints)} value',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filters Section - Modern Design
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 20,
                      color: kPrimaryGreen,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter Offers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('All'),
                      _buildCategoryChip('Food & Beverage'),
                      _buildCategoryChip('Fashion'),
                      _buildCategoryChip('Home & Living'),
                      _buildCategoryChip('Beauty & Care'),
                      _buildCategoryChip('Electronics'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _showOnlyAvailable,
                        onChanged: (value) {
                          setState(() {
                            _showOnlyAvailable = value ?? false;
                          });
                        },
                        activeColor: kPrimaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Show only affordable offers',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20,
                        color: kPrimaryGreen,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Redemption Offers List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('redemption_offers')
                  .orderBy('requiredPoints')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimaryGreen),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading offers',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  // Show loading if still checking for offers
                  if (_isCheckingOffers) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: kPrimaryGreen),
                          const SizedBox(height: 16),
                          Text(
                            'Loading offers...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_giftcard_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No redemption offers available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the button below to load sample offers',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _seedSampleOffers,
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          label: const Text('Load Sample Offers'),
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
                            elevation: 4,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter offers based on category and availability
                var filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  // Filter by category
                  if (_selectedCategory != 'All') {
                    final category = data['category'] ?? '';
                    if (category != _selectedCategory) return false;
                  }

                  // Filter by affordability
                  if (_showOnlyAvailable) {
                    final requiredPoints = data['requiredPoints'] ?? 0;
                    if (!_hasEnoughPoints(requiredPoints)) return false;
                  }

                  return true;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No offers match your filters',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildOfferCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [kPrimaryGreen, kPrimaryGreen.withOpacity(0.8)],
                  )
                : null,
            color: isSelected ? null : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? kPrimaryGreen : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: kPrimaryGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferCard(String offerId, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Untitled Offer';
    final storeName = data['storeName'] ?? 'Partner Store';
    final description = data['description'] ?? '';
    final requiredPoints = data['requiredPoints'] ?? 0;
    final imageUrl = data['imageUrl'] ?? '';
    final category = data['category'] ?? '';
    final expiryTimestamp = data['expiryDate'] as Timestamp?;

    final isValid = _isOfferValid(expiryTimestamp);
    final canAfford = _hasEnoughPoints(requiredPoints);
    final canRedeem = isValid && canAfford;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section - Modern Design
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey.shade300,
                              Colors.grey.shade200,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.card_giftcard_rounded,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay for better text visibility
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                  // Status Badge
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isValid
                            ? const Color(0xFF10B981)
                            : Colors.red.shade600,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isValid ? Icons.verified : Icons.access_time,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isValid ? 'ACTIVE' : 'EXPIRED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Affordability Badge
                  if (canAfford)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'CAN AFFORD',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kPrimaryGreen.withOpacity(0.7),
                    kPrimaryGreen.withOpacity(0.5),
                    kPrimaryGreen.withOpacity(0.3),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    bottom: -30,
                    child: Icon(
                      Icons.card_giftcard_rounded,
                      size: 150,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.card_giftcard_rounded,
                      size: 72,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Name Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.store, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        storeName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),

                // Category
                if (category.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Points Required with Monetary Value
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kPrimaryGreen.withOpacity(0.12),
                        kPrimaryGreen.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimaryGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.eco,
                                    size: 18,
                                    color: kPrimaryGreen,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$requiredPoints',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: kPrimaryGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Points',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Text(
                                  _convertPointsToMoney(requiredPoints),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!canAfford)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '+${requiredPoints - _userEcoPoints}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                  Text(
                                    'more needed',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Expiry Date
                if (expiryTimestamp != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: isValid ? Colors.grey.shade600 : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isValid
                            ? 'Valid until ${_formatDate(expiryTimestamp)}'
                            : 'Expired on ${_formatDate(expiryTimestamp)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isValid ? Colors.grey.shade600 : Colors.red,
                          fontWeight: isValid
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Redeem Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canRedeem
                        ? () => _redeemOffer(
                            offerId,
                            title,
                            requiredPoints,
                            storeName,
                          )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canRedeem ? kPrimaryGreen : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: canRedeem ? 4 : 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          canRedeem
                              ? Icons.redeem
                              : isValid
                              ? Icons.lock
                              : Icons.schedule,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          canRedeem
                              ? 'Redeem Now'
                              : isValid
                              ? 'Insufficient Points'
                              : 'Offer Expired',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
    );
  }
}

// My Redemptions Screen to view redemption QR codes
class MyVouchersScreen extends StatelessWidget {
  const MyVouchersScreen({super.key});

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatDateTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy - HH:mm').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'verified':
      case 'completed':
        return const Color(0xFF10B981);
      case 'expired':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'PENDING';
      case 'verified':
        return 'VERIFIED';
      case 'completed':
        return 'COMPLETED';
      case 'expired':
        return 'EXPIRED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text(
          'My Redemptions',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimaryGreen, kPrimaryGreen.withOpacity(0.8)],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: user == null
          ? const Center(child: Text('Please sign in to view your redemptions'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('redemptions')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimaryGreen),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No redemptions yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Redeem offers to get started!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final title = data['offerTitle'] ?? 'Reward';
                    final storeName = data['storeName'] ?? 'Store';
                    final pointsRequired = data['pointsRequired'] ?? 0;
                    final monetaryValue = data['monetaryValue'] ?? 'RM 0.00';
                    final redemptionCode = data['redemptionCode'] ?? 'N/A';
                    final status = data['status'] ?? 'pending';
                    final createdAt = data['createdAt'] as Timestamp?;
                    final expiresAt = data['expiresAt'] as Timestamp?;

                    final isExpired =
                        expiresAt != null &&
                        DateTime.now().isAfter(expiresAt.toDate());
                    final actualStatus = isExpired && status == 'pending'
                        ? 'expired'
                        : status;

                    return GestureDetector(
                      onTap: () {
                        if (actualStatus == 'pending') {
                          _showQRCodeDialog(
                            context,
                            redemptionCode,
                            title,
                            storeName,
                            monetaryValue,
                            expiresAt,
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(
                              actualStatus,
                            ).withOpacity(0.3),
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
                            // Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  actualStatus,
                                ).withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(18),
                                  topRight: Radius.circular(18),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(actualStatus),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      actualStatus == 'pending'
                                          ? Icons.qr_code_2_rounded
                                          : actualStatus == 'completed'
                                          ? Icons.check_circle_rounded
                                          : actualStatus == 'expired'
                                          ? Icons.access_time_rounded
                                          : Icons.card_giftcard_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          storeName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(actualStatus),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getStatusLabel(actualStatus),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Content
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  // Points Info
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoItem(
                                        Icons.eco,
                                        '$pointsRequired pts',
                                        'Points',
                                        kPrimaryGreen,
                                      ),
                                      _buildInfoItem(
                                        Icons.account_balance_wallet_outlined,
                                        monetaryValue,
                                        'Value',
                                        Colors.blue.shade700,
                                      ),
                                    ],
                                  ),
                                  if (createdAt != null) ...[
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Created: ${_formatDateTime(createdAt)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (expiresAt != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          isExpired
                                              ? Icons.error_outline
                                              : Icons.schedule,
                                          size: 16,
                                          color: isExpired
                                              ? Colors.red
                                              : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isExpired
                                              ? 'Expired: ${_formatDateTime(expiresAt)}'
                                              : 'Expires: ${_formatDateTime(expiresAt)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isExpired
                                                ? Colors.red
                                                : Colors.grey.shade600,
                                            fontWeight: isExpired
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (actualStatus == 'pending') ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.blue.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.qr_code_scanner,
                                            size: 18,
                                            color: Colors.blue.shade700,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Tap to view QR Code',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  void _showQRCodeDialog(
    BuildContext context,
    String code,
    String title,
    String store,
    String value,
    Timestamp? expiresAt,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // QR Code Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kPrimaryGreen, width: 3),
                ),
                child: Column(
                  children: [
                    // Simulated QR Code (in production, use qr_flutter package)
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_2_rounded,
                              size: 100,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'QR Code',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '(Install qr_flutter)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Redemption Code
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        code,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Product Info
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.store, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      store,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kPrimaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kPrimaryGreen.withOpacity(0.3)),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryGreen,
                  ),
                ),
              ),
              if (expiresAt != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Show this code to store staff before ${_formatDateTime(expiresAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
