import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Assuming the existence of this file for kPrimaryGreen
// import 'package:ecopilot_test/utils/constants.dart'; 
import 'package:ecopilot_test/screens/disposal_guidance_screen.dart';

// Placeholder definitions for kPrimaryGreen if constants.dart is not available
const Color kPrimaryGreen = Color(0xFF4CAF50);

class RecentActivityScreen extends StatefulWidget {
  const RecentActivityScreen({super.key});

  @override
  State<RecentActivityScreen> createState() => _RecentActivityScreenState();
}

class _RecentActivityScreenState extends State<RecentActivityScreen> {
  List<Map<String, dynamic>> _recentActivity = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentActivity();
  }

  Future<void> _loadRecentActivity() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scans')
          .orderBy('createdAt', descending: true)
          .limit(20) // Increased limit for a proper list view
          .get();

      setState(() {
        _recentActivity = snapshot.docs
            .map(
              (doc) => {
                'id': doc.id,
                'name': doc['name'] ?? 'Scanned product',
                'category': doc['category'] ?? 'N/A', // Using new category field
                'material': doc['material'] ?? 'Unknown', // Using new material field
                'imageUrl': doc['imageUrl'] ?? 'https://placehold.co/100x120/A8D8B9/212121?text=Product',
              },
            )
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading recent activity: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildRecentProductTile(Map<String, dynamic> product) {
    final String name = product['name']!;
    final String category = product['category']!;
    final String material = product['material']!;
    final String imageUrl = product['imageUrl']!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          // Navigate to the Disposal Details Screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DisposalGuidanceScreen(productId: product['id']),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: kPrimaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.delete_sweep,
                color: kPrimaryGreen,
                size: 40,
              ),
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category: $category',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            Text(
              'Material: $material',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black38),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryGreen,
      appBar: AppBar(
        title: const Text(
          'Recent Activity',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        // The main content area with a rounded white background
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _recentActivity.isEmpty
                ? const Center(
                    child: Text(
                      'No recent scans yet. Go scan a product!',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 20, bottom: 20),
                    itemCount: _recentActivity.length,
                    itemBuilder: (context, index) {
                      return _buildRecentProductTile(_recentActivity[index]);
                    },
                  ),
      ),
    );
  }
}
