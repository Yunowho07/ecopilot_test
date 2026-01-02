import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Admin utility screen for managing redemption offers
/// This screen is for testing and admin purposes only
class RedemptionAdminScreen extends StatefulWidget {
  const RedemptionAdminScreen({super.key});

  @override
  State<RedemptionAdminScreen> createState() => _RedemptionAdminScreenState();
}

class _RedemptionAdminScreenState extends State<RedemptionAdminScreen> {
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _setupSampleOffers() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Setting up sample offers...';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final offersCollection = firestore.collection('redemption_offers');

      // Sample redemption offers
      final offers = [
        {
          'title': '\$10 Off Your Next Purchase',
          'storeName': 'Green Market',
          'description':
              'Get \$10 off on your next purchase of organic produce and sustainable products.',
          'category': 'Food & Beverage',
          'requiredPoints': 100,
          'imageUrl':
              'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800',
          'expiryDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 30)),
          ),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': '20% Off Eco-Friendly Clothing',
          'storeName': 'Sustainable Fashion Co.',
          'description':
              'Enjoy 20% discount on our collection of sustainable and ethically made clothing.',
          'category': 'Fashion',
          'requiredPoints': 150,
          'imageUrl':
              'https://images.unsplash.com/photo-1445205170230-053b83016050?w=800',
          'expiryDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 45)),
          ),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Free Reusable Water Bottle',
          'storeName': 'EcoStore',
          'description':
              'Claim your free premium stainless steel reusable water bottle.',
          'category': 'Home & Living',
          'requiredPoints': 200,
          'imageUrl':
              'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=800',
          'expiryDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 60)),
          ),
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Buy 1 Get 1 Free - Organic Coffee',
          'storeName': 'Bean & Green Café',
          'description':
              'Purchase one organic coffee and get another one absolutely free!',
          'category': 'Food & Beverage',
          'requiredPoints': 80,
          'imageUrl':
              'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800',
          'expiryDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 20)),
          ),
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      int successCount = 0;
      for (var offer in offers) {
        await offersCollection.add(offer);
        successCount++;
      }

      setState(() {
        _isLoading = false;
        _statusMessage = '✅ Successfully added $successCount offers!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error: $e';
      });
    }
  }

  Future<void> _addTestPoints() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Adding test points...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = '❌ No user signed in';
        });
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'ecoPoints': FieldValue.increment(500),
      }, SetOptions(merge: true));

      setState(() {
        _isLoading = false;
        _statusMessage = '✅ Added 500 test points to your account!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error: $e';
      });
    }
  }

  Future<void> _clearAllOffers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Warning'),
        content: const Text(
          'This will delete ALL redemption offers. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Deleting all offers...';
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('redemption_offers')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      setState(() {
        _isLoading = false;
        _statusMessage = '✅ Deleted ${snapshot.docs.length} offers';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redemption Admin'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🔧 Redemption System Setup',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Admin tools for testing and setup',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Setup Sample Offers Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _setupSampleOffers,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Setup Sample Offers'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            // Add Test Points Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _addTestPoints,
              icon: const Icon(Icons.stars),
              label: const Text('Add 500 Test Points'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            // Clear All Offers Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _clearAllOffers,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Clear All Offers'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 32),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(child: CircularProgressIndicator()),
              ),

            const Spacer(),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Quick Setup Guide',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '1. Setup Sample Offers - adds test redemption offers\n'
                    '2. Add Test Points - gives you points to test redemptions\n'
                    '3. Go to Redeem Screen and try redeeming an offer\n'
                    '4. Check My Vouchers to see your redemptions',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
