// lib/models/database_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Database Models following the EcoPilot Database Schema
/// Based on the official database diagram

// ========================================
// USERS TABLE
// ========================================
class UserModel {
  final String userId;
  final String name;
  final String email;
  final String? profileImageUrl;
  final int ecoPoints;
  final String rank;
  final int streakCount;
  final int totalChallengesCompleted;
  final DateTime dateJoined;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.ecoPoints = 0,
    this.rank = 'Green Beginner',
    this.streakCount = 0,
    this.totalChallengesCompleted = 0,
    required this.dateJoined,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'ecoPoints': ecoPoints,
      'rank': rank,
      'streakCount': streakCount,
      'totalChallengesCompleted': totalChallengesCompleted,
      'dateJoined': Timestamp.fromDate(dateJoined),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      ecoPoints: data['ecoPoints'] ?? 0,
      rank: data['rank'] ?? 'Green Beginner',
      streakCount: data['streakCount'] ?? 0,
      totalChallengesCompleted: data['totalChallengesCompleted'] ?? 0,
      dateJoined:
          (data['dateJoined'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ========================================
// SCANNED PRODUCTS TABLE
// ========================================
class ScannedProductModel {
  final String productId;
  final String userId;
  final String productName;
  final String category;
  final String ingredients;
  final String ecoScore;
  final double carbonFootprint;
  final String packagingType;
  final String disposalMethod;
  final bool containsMicroplastics;
  final bool palmOilDerivative;
  final bool crueltyFree;
  final String? imageUrl;
  final String scanType; // 'manual', 'barcode', 'image'
  final DateTime timestamp;

  ScannedProductModel({
    required this.productId,
    required this.userId,
    required this.productName,
    this.category = '',
    this.ingredients = '',
    this.ecoScore = 'N/A',
    this.carbonFootprint = 0.0,
    this.packagingType = '',
    this.disposalMethod = '',
    this.containsMicroplastics = false,
    this.palmOilDerivative = false,
    this.crueltyFree = false,
    this.imageUrl,
    this.scanType = 'manual',
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'userId': userId,
      'productName': productName,
      'category': category,
      'ingredients': ingredients,
      'ecoScore': ecoScore,
      'carbonFootprint': carbonFootprint,
      'packagingType': packagingType,
      'disposalMethod': disposalMethod,
      'containsMicroplastics': containsMicroplastics,
      'palmOilDerivative': palmOilDerivative,
      'crueltyFree': crueltyFree,
      'imageUrl': imageUrl,
      'scanType': scanType,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ScannedProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScannedProductModel(
      productId: doc.id,
      userId: data['userId'] ?? '',
      productName: data['productName'] ?? data['product_name'] ?? '',
      category: data['category'] ?? '',
      ingredients: data['ingredients'] ?? '',
      ecoScore: data['ecoScore'] ?? data['eco_score'] ?? 'N/A',
      carbonFootprint:
          (data['carbonFootprint'] ?? data['carbon_footprint'] ?? 0.0)
              .toDouble(),
      packagingType: data['packagingType'] ?? data['packaging'] ?? '',
      disposalMethod: data['disposalMethod'] ?? data['disposal_method'] ?? '',
      containsMicroplastics:
          data['containsMicroplastics'] ??
          data['contains_microplastics'] ??
          false,
      palmOilDerivative:
          data['palmOilDerivative'] ?? data['palm_oil_derivative'] ?? false,
      crueltyFree: data['crueltyFree'] ?? data['cruelty_free'] ?? false,
      imageUrl: data['imageUrl'] ?? data['image_url'],
      scanType: data['scanType'] ?? 'manual',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ========================================
// DISPOSAL PRODUCTS TABLE
// ========================================
class DisposalProductModel {
  final String disposalId;
  final String userId;
  final String productName;
  final String material;
  final String ecoScore;
  final String howToDispose;
  final List<String> ecoTips;
  final String? nearbyRecyclingCenter;
  final String? imageUrl;
  final DateTime timestamp;

  DisposalProductModel({
    required this.disposalId,
    required this.userId,
    required this.productName,
    required this.material,
    this.ecoScore = 'N/A',
    required this.howToDispose,
    this.ecoTips = const [],
    this.nearbyRecyclingCenter,
    this.imageUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'disposalId': disposalId,
      'userId': userId,
      'productName': productName,
      'material': material,
      'ecoScore': ecoScore,
      'howToDispose': howToDispose,
      'ecoTips': ecoTips,
      'nearbyRecyclingCenter': nearbyRecyclingCenter,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory DisposalProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DisposalProductModel(
      disposalId: doc.id,
      userId: data['userId'] ?? '',
      productName: data['productName'] ?? '',
      material: data['material'] ?? '',
      ecoScore: data['ecoScore'] ?? 'N/A',
      howToDispose: data['howToDispose'] ?? '',
      ecoTips: List<String>.from(data['ecoTips'] ?? []),
      nearbyRecyclingCenter: data['nearbyRecyclingCenter'],
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ========================================
// ALTERNATIVE PRODUCTS TABLE
// ========================================
class AlternativeProductModel {
  final String alternativeId;
  final String baseProductId;
  final String name;
  final String ecoScore;
  final String description;
  final String? imageUrl;
  final String? buyUrl;
  final String category;
  final DateTime timestamp;

  AlternativeProductModel({
    required this.alternativeId,
    required this.baseProductId,
    required this.name,
    required this.ecoScore,
    this.description = '',
    this.imageUrl,
    this.buyUrl,
    this.category = '',
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'alternativeId': alternativeId,
      'baseProductId': baseProductId,
      'name': name,
      'ecoScore': ecoScore,
      'description': description,
      'imageUrl': imageUrl,
      'buyUrl': buyUrl,
      'category': category,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory AlternativeProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AlternativeProductModel(
      alternativeId: doc.id,
      baseProductId: data['baseProductId'] ?? '',
      name: data['name'] ?? '',
      ecoScore: data['ecoScore'] ?? 'N/A',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      buyUrl: data['buyUrl'],
      category: data['category'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ========================================
// ECO CHALLENGES TABLE
// ========================================
class EcoChallengeModel {
  final String challengeId;
  final String title;
  final String description;
  final int pointsReward;
  final DateTime dateAvailable;
  final bool isActive;

  EcoChallengeModel({
    required this.challengeId,
    required this.title,
    required this.description,
    required this.pointsReward,
    required this.dateAvailable,
    this.isActive = true,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'challengeId': challengeId,
      'title': title,
      'description': description,
      'pointsReward': pointsReward,
      'dateAvailable': Timestamp.fromDate(dateAvailable),
      'isActive': isActive,
    };
  }

  factory EcoChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EcoChallengeModel(
      challengeId: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      pointsReward: data['pointsReward'] ?? data['points'] ?? 0,
      dateAvailable:
          (data['dateAvailable'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }
}

// ========================================
// USER CHALLENGES TABLE (Progress Tracking)
// ========================================
class UserChallengeModel {
  final String userId;
  final String challengeId;
  final bool isCompleted;
  final DateTime? completedDate;
  final int pointsEarned;
  final DateTime date;

  UserChallengeModel({
    required this.userId,
    required this.challengeId,
    this.isCompleted = false,
    this.completedDate,
    this.pointsEarned = 0,
    required this.date,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'challengeId': challengeId,
      'isCompleted': isCompleted,
      'completedDate': completedDate != null
          ? Timestamp.fromDate(completedDate!)
          : null,
      'pointsEarned': pointsEarned,
      'date': Timestamp.fromDate(date),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserChallengeModel(
      userId: data['userId'] ?? '',
      challengeId: data['challengeId'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      completedDate: (data['completedDate'] as Timestamp?)?.toDate(),
      pointsEarned: data['pointsEarned'] ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ========================================
// ECO POINT HISTORY TABLE
// ========================================
class EcoPointHistoryModel {
  final String userId;
  final String source; // 'scan', 'challenge', 'streak', 'bonus', etc.
  final int pointsEarned;
  final DateTime dateEarned;
  final String? description; // Optional description of the point award

  EcoPointHistoryModel({
    required this.userId,
    required this.source,
    required this.pointsEarned,
    required this.dateEarned,
    this.description,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'source': source,
      'pointsEarned': pointsEarned,
      'dateEarned': Timestamp.fromDate(dateEarned),
      'description': description,
    };
  }

  factory EcoPointHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EcoPointHistoryModel(
      userId: data['userId'] ?? '',
      source: data['source'] ?? data['reason'] ?? '',
      pointsEarned: data['pointsEarned'] ?? data['points'] ?? 0,
      dateEarned:
          (data['dateEarned'] ?? data['timestamp'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      description: data['description'],
    );
  }
}

// ========================================
// DATABASE HELPER CLASS
// ========================================
class FirestoreCollections {
  // Collection names as constants
  static const String users = 'users';
  static const String scannedProducts = 'scanned_products';
  static const String disposalProducts = 'disposal_products';
  static const String alternativeProducts = 'alternative_products';
  static const String ecoChallenges = 'eco_challenges';
  static const String userChallenges = 'user_challenges';
  static const String ecoPointHistory = 'eco_point_history';

  // Subcollections
  static const String pointHistory = 'point_history';
  static const String monthlyPoints = 'monthly_points';
  static const String scans = 'scans';
  static const String disposalScans = 'disposal_scans';
}
