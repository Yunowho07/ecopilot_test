import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper script to populate Firestore with sample redemption offers
/// Run this from your main.dart or a separate utility file to seed the database
class RedemptionOffersSetup {
  static Future<void> setupSampleOffers() async {
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
      {
        'title': '\$25 Gift Card',
        'storeName': 'Whole Earth Store',
        'description':
            'Redeem a \$25 gift card to use on any eco-friendly products in our store.',
        'category': 'Home & Living',
        'requiredPoints': 250,
        'imageUrl':
            'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=800',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 90)),
        ),
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Free Natural Skincare Set',
        'storeName': 'Pure Beauty',
        'description':
            'Get a complete natural skincare set made with organic ingredients.',
        'category': 'Beauty & Care',
        'requiredPoints': 180,
        'imageUrl':
            'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=800',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 40)),
        ),
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': '15% Off Solar Chargers',
        'storeName': 'TechGreen',
        'description':
            'Save 15% on our range of solar-powered phone chargers and power banks.',
        'category': 'Electronics',
        'requiredPoints': 120,
        'imageUrl':
            'https://images.unsplash.com/photo-1593941707882-a5bba14938c7?w=800',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 35)),
        ),
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Bamboo Cutlery Set - Free',
        'storeName': 'Zero Waste Shop',
        'description':
            'Claim your free bamboo cutlery set perfect for on-the-go meals.',
        'category': 'Home & Living',
        'requiredPoints': 90,
        'imageUrl':
            'https://images.unsplash.com/photo-1606302287717-4498bbcfaa7b?w=800',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 50)),
        ),
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': '\$50 Organic Meal Kit',
        'storeName': 'Farm Fresh Delivery',
        'description':
            'Redeem a \$50 organic meal kit with locally sourced ingredients.',
        'category': 'Food & Beverage',
        'requiredPoints': 300,
        'imageUrl':
            'https://images.unsplash.com/photo-1506617564039-2f3b650b7010?w=800',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 25)),
        ),
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Eco-Friendly Yoga Mat',
        'storeName': 'Mindful Living',
        'description':
            'Get a premium yoga mat made from sustainable cork and natural rubber.',
        'category': 'Home & Living',
        'requiredPoints': 220,
        'imageUrl':
            'https://images.unsplash.com/photo-1601925260368-ae2f83cf8b7f?w=800',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 55)),
        ),
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Free Bike Tune-Up Service',
        'storeName': 'Pedal Power Bikes',
        'description':
            'Get a complete bike tune-up service to keep your eco-friendly transport in top shape.',
        'category': 'Home & Living',
        'requiredPoints': 130,
        'imageUrl':
            'https://images.unsplash.com/photo-1532298229144-0ec0c57515c7?w=800',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 70)),
        ),
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': '30% Off Compost Bin',
        'storeName': 'Garden Eco',
        'description':
            'Save 30% on kitchen compost bins to reduce your food waste.',
        'category': 'Home & Living',
        'requiredPoints': 110,
        'imageUrl':
            'https://images.unsplash.com/photo-1585908579728-7950ad9791ff?w=800',
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 45)),
        ),
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    // Add all offers to Firestore
    for (var offer in offers) {
      try {
        await offersCollection.add(offer);
        print('✅ Added offer: ${offer['title']}');
      } catch (e) {
        print('❌ Error adding offer ${offer['title']}: $e');
      }
    }

    print('\n🎉 Successfully added ${offers.length} redemption offers!');
  }

  /// Clear all existing redemption offers (use with caution)
  static Future<void> clearAllOffers() async {
    final firestore = FirebaseFirestore.instance;
    final offersCollection = firestore.collection('redemption_offers');

    final snapshot = await offersCollection.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    print('🗑️ Cleared all redemption offers');
  }

  /// Update expiry dates for existing offers (extend by days)
  static Future<void> extendOfferExpiry(int extendByDays) async {
    final firestore = FirebaseFirestore.instance;
    final offersCollection = firestore.collection('redemption_offers');

    final snapshot = await offersCollection.get();
    for (var doc in snapshot.docs) {
      final currentExpiry = (doc.data()['expiryDate'] as Timestamp).toDate();
      final newExpiry = currentExpiry.add(Duration(days: extendByDays));

      await doc.reference.update({'expiryDate': Timestamp.fromDate(newExpiry)});

      print('✅ Extended expiry for: ${doc.data()['title']}');
    }

    print(
      '\n🎉 Extended expiry for ${snapshot.docs.length} offers by $extendByDays days!',
    );
  }
}
