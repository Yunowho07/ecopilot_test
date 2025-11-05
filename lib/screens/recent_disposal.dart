import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecopilot_test/utils/constants.dart';
import 'package:ecopilot_test/screens/disposal_guidance_screen.dart';

class RecentDisposalScreen extends StatefulWidget {
  const RecentDisposalScreen({super.key});

  @override
  State<RecentDisposalScreen> createState() => _RecentDisposalScreenState();
}

class _RecentDisposalScreenState extends State<RecentDisposalScreen> {
  List<Map<String, dynamic>> _recentDisposal = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentDisposal();
  }

  Future<void> _loadRecentDisposal() async {
    // Match the save behavior: scans are saved under 'anonymous' when not signed in.
    // Use the same default so recently-saved anonymous scans show up in this list.
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    try {
      // Read from the dedicated `disposal_scans` collection for the user.
      final coll = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('disposal_scans');

      final q = await coll
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      setState(() {
        _recentDisposal = q.docs.map((doc) {
          final data = doc.data();
          final name =
              data['product_name'] ?? data['name'] ?? 'Scanned product';
          final category = data['category'] ?? 'N/A';
          final material = data['material'] ?? 'Unknown';
          final imageUrl =
              data['imageUrl'] ??
              data['image'] ??
              'https://placehold.co/100x120/A8D8B9/212121?text=Product';

          return {
            'id': doc.id,
            'name': name,
            'category': category,
            'material': material,
            'imageUrl': imageUrl,
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading recent Disposal: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildRecentProductTile(Map<String, dynamic> product) {
    final String name = product['name'] ?? 'Scanned product';
    final String category = product['category'] ?? 'N/A';
    final String material = product['material'] ?? 'Unknown';
    final String imageUrl =
        product['imageUrl'] ??
        'https://placehold.co/100x120/A8D8B9/212121?text=Product';

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
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.delete_sweep, color: kPrimaryGreen, size: 40),
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
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.black38,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryGreen,
      appBar: AppBar(
        title: const Text(
          'Recent Disposal',
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
            : _recentDisposal.isEmpty
            ? const Center(
                child: Text(
                  'No recent scans yet. Go scan a product!',
                  style: TextStyle(color: Colors.black54),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                itemCount: _recentDisposal.length,
                itemBuilder: (context, index) {
                  return _buildRecentProductTile(_recentDisposal[index]);
                },
              ),
      ),
    );
  }
}
