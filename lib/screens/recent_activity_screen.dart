import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/utils/constants.dart';
import 'package:intl/intl.dart';

class RecentActivityScreen extends StatelessWidget {
  const RecentActivityScreen({Key? key}) : super(key: key);

  bool _readBool(dynamic v) {
    if (v is bool) return v;
    if (v is String)
      return v.toLowerCase() == 'true' || v.toLowerCase() == 'yes';
    if (v is num) return v != 0;
    return false;
  }

  String _readString(dynamic v) {
    if (v == null) return 'N/A';
    return v.toString();
  }

  // Build the product detail card widget
  Widget _buildProductDetailCard(Map<String, dynamic> data) {
    final name = (data['product_name'] ?? data['name'] ?? 'Unknown Product')
        .toString();
    final category = (data['category'] ?? 'N/A').toString();
    final ingredients =
        (data['ingredients'] ??
                data['ingredient_list'] ??
                data['ingredientList'] ??
                'N/A')
            .toString();
    final score = (data['eco_score'] ?? data['ecoScore'] ?? 'A')
        .toString()
        .toUpperCase();
    final co2 = (data['carbon_footprint'] ?? data['carbonFootprint'] ?? '—')
        .toString();
    final packaging =
        (data['packaging'] ??
                data['packaging_type'] ??
                data['packagingType'] ??
                'N/A')
            .toString();

    // Handle disposal
    String disposal = 'N/A';
    if (data['disposal_method'] != null) {
      disposal = data['disposal_method'].toString();
    } else if (data['disposalMethod'] != null) {
      disposal = data['disposalMethod'].toString();
    } else if (data['disposalSteps'] != null) {
      final ds = data['disposalSteps'];
      if (ds is List) {
        disposal = ds.join(' • ');
      } else {
        disposal = ds.toString();
      }
    }

    final containsMicroplastics = _readBool(
      data['containsMicroplastics'] ?? data['contains_microplastics'] ?? false,
    );
    final palmOilDerivative = _readBool(
      data['palmOilDerivative'] ?? data['palm_oil_derivative'] ?? false,
    );
    final crueltyFree = _readBool(
      data['crueltyFree'] ?? data['cruelty_free'] ?? false,
    );

    Color _getEcoScoreColor(String s) {
      final ecoScoreColors = {
        'A': kResultCardGreen,
        'B': kDiscoverMoreGreen,
        'C': kPrimaryYellow,
        'D': kRankSustainabilityHero,
        'E': kWarningRed,
      };
      return ecoScoreColors[s] ?? Colors.grey.shade600;
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient and eco score
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kPrimaryGreen, kPrimaryGreen.withOpacity(0.8)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Product Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Eco Score Badge
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        score,
                        style: TextStyle(
                          color: _getEcoScoreColor(score),
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ECO SCORE',
                        style: TextStyle(
                          color: _getEcoScoreColor(score),
                          fontWeight: FontWeight.w600,
                          fontSize: 8,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Product Image Section
          Builder(
            builder: (context) {
              String? imageUrl;
              final possibleKeys = [
                'image',
                'image_url',
                'imageUrl',
                'product_image',
                'thumbnail',
                'photo',
              ];
              for (final k in possibleKeys) {
                final v = data[k];
                if (v is String && v.isNotEmpty) {
                  imageUrl = v;
                  break;
                }
              }

              if (imageUrl != null && imageUrl.isNotEmpty) {
                return Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey.shade50,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => Container(
                            color: Colors.grey.shade100,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Image not available',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey.shade100,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: kPrimaryGreen,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kPrimaryGreen.withOpacity(0.1),
                      kPrimaryGreen.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.eco_outlined,
                        size: 56,
                        color: kPrimaryGreen.withOpacity(0.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No product image',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Content sections
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: kPrimaryGreen.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 16,
                        color: kPrimaryGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kPrimaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Ingredients Section
                _buildModernSection(
                  icon: Icons.science_outlined,
                  title: 'Ingredients',
                  content: ingredients,
                  iconColor: Colors.blue.shade600,
                ),
                const SizedBox(height: 16),

                // Eco Impact Section
                const Text(
                  'Eco Impact',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.cloud_outlined,
                  label: 'Carbon Footprint',
                  value: co2,
                  color: Colors.lightBlue.shade400,
                ),
                const SizedBox(height: 10),
                _buildInfoCard(
                  icon: Icons.eco_outlined,
                  label: 'Packaging',
                  value: packaging,
                  color: Colors.green.shade400,
                ),
                const SizedBox(height: 10),
                _buildInfoCard(
                  icon: Icons.restore_from_trash_outlined,
                  label: 'Disposal',
                  value: disposal,
                  color: Colors.orange.shade400,
                ),
                const SizedBox(height: 20),

                // Environmental Warnings
                const Text(
                  'Environmental Impact',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildWarningCard(
                  label: 'Microplastics Free',
                  isGood: !containsMicroplastics,
                ),
                const SizedBox(height: 8),
                _buildWarningCard(
                  label: 'Palm Oil Free',
                  isGood: !palmOilDerivative,
                ),
                const SizedBox(height: 8),
                _buildWarningCard(label: 'Cruelty-Free', isGood: crueltyFree),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection({
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard({required String label, required bool isGood}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isGood ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isGood ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isGood ? Colors.green.shade100 : Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGood ? Icons.check : Icons.close,
              size: 16,
              color: isGood ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isGood ? Colors.green.shade900 : Colors.red.shade900,
              ),
            ),
          ),
          if (isGood)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'GOOD',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Query the per-user scans saved by the scan flows (they write 'timestamp').
    final Stream<QuerySnapshot<Map<String, dynamic>>>? scansStream =
        user != null
        ? FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('scans')
              .orderBy('timestamp', descending: true)
              .withConverter<Map<String, dynamic>>(
                fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
                toFirestore: (m, _) => m,
              )
              .snapshots()
        : null;

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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x0F1DB954), Colors.white],
          ),
        ),
        child: scansStream == null
            ? const Center(child: Text('Please sign in to see your scans.'))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: scansStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading scans: ${snapshot.error}'),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No scans yet.'));
                  }

                  final docs = snapshot.data!.docs;
                  // Client-side filter to exclude disposal-specific scans
                  final filtered = docs.where((doc) {
                    final m = doc.data();
                    final v = m['isDisposal'];
                    return v == null ? true : (v == false);
                  }).toList();
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final data = doc.data();

                      // --- Data Reading for List Tile ---
                      // These variables use robust fallbacks and are displayed in the list tile
                      final product = _readString(
                        data['name'] ??
                            data['product_name'] ??
                            data['productName'] ??
                            'Scanned product',
                      );

                      final score = _readString(
                        data['eco_score'] ?? data['ecoScore'] ?? 'N/A',
                      );

                      final co2 = _readString(
                        data['carbon_footprint'] ??
                            data['carbonFootprint'] ??
                            '—',
                      );

                      final imageUrl = _readString(
                        data['image_url'] ??
                            data['imageUrl'] ??
                            data['image'] ??
                            '',
                      );

                      final category = _readString(
                        data['category'] ??
                            data['product_category'] ??
                            data['productCategory'] ??
                            'N/A',
                      );

                      final ingredients = _readString(
                        data['ingredients'] ??
                            data['ingredient_list'] ??
                            data['ingredientList'] ??
                            'N/A',
                      );

                      String packaging = _readString(
                        data['packaging'] ??
                            data['packaging_type'] ??
                            data['packagingType'] ??
                            'N/A',
                      );

                      String disposalMethod = 'N/A';
                      if (data['disposal_method'] != null) {
                        disposalMethod = _readString(data['disposal_method']);
                      } else if (data['disposalMethod'] != null) {
                        disposalMethod = _readString(data['disposalMethod']);
                      } else if (data['disposalSteps'] != null) {
                        final ds = data['disposalSteps'];
                        if (ds is List)
                          disposalMethod = ds.join(' • ');
                        else
                          disposalMethod = _readString(ds);
                      }

                      DateTime? created;
                      final createdRaw =
                          data['createdAt'] ??
                          data['created_at'] ??
                          data['timestamp'];
                      if (createdRaw is Timestamp)
                        created = createdRaw.toDate();
                      else if (createdRaw is int)
                        created = DateTime.fromMillisecondsSinceEpoch(
                          createdRaw,
                        );
                      else if (createdRaw is String) {
                        try {
                          created = DateTime.parse(createdRaw);
                        } catch (_) {}
                      }

                      String formattedDate = created != null
                          ? DateFormat.yMMMd().add_jm().format(created)
                          : '';
                      // --- End Data Reading for List Tile ---

                      Color scoreColor(String s) {
                        if (s.isEmpty) return Colors.grey;
                        final c = s.trim().toUpperCase();
                        if (c.startsWith('A')) return Colors.green.shade600;
                        if (c.startsWith('B')) return Colors.lightGreen;
                        if (c.startsWith('C')) return Colors.orange;
                        if (c.startsWith('D')) return Colors.deepOrange;
                        if (c.startsWith('E')) return Colors.redAccent;
                        return Colors.grey;
                      }

                      // Card UI - Redesigned for cleaner, smarter layout
                      return Card(
                        elevation: 3,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            // Show product details in a modal bottom sheet instead of navigating to ResultScreen
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => DraggableScrollableSheet(
                                initialChildSize: 0.9,
                                minChildSize: 0.5,
                                maxChildSize: 0.95,
                                builder: (_, controller) => Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(25),
                                      topRight: Radius.circular(25),
                                    ),
                                  ),
                                  child: ListView(
                                    controller: controller,
                                    children: [
                                      // Drag handle
                                      Center(
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      _buildProductDetailCard(data),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 120,
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Product Image - Larger and more prominent
                                Hero(
                                  tag: 'product_${doc.id}',
                                  child: Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => Container(
                                                color: Colors.grey.shade100,
                                                child: Icon(
                                                  Icons
                                                      .image_not_supported_outlined,
                                                  size: 32,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    kPrimaryGreen.withOpacity(
                                                      0.1,
                                                    ),
                                                    kPrimaryGreen.withOpacity(
                                                      0.05,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.eco_outlined,
                                                color: kPrimaryGreen,
                                                size: 40,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Content area - Product info and metadata
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Product name
                                      Text(
                                        product,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      // Category badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: kPrimaryGreen.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: kPrimaryGreen.withOpacity(
                                              0.3,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: kPrimaryGreen.withOpacity(
                                              0.9,
                                            ),
                                            letterSpacing: 0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Date/Time
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 13,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              formattedDate,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
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
                                const SizedBox(width: 12),
                                // Eco Score Badge - Prominent on the right
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: scoreColor(score),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: scoreColor(
                                              score,
                                            ).withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            score,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                              height: 1,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'ECO',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 9,
                                              letterSpacing: 0.5,
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
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
