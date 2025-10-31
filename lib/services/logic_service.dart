// Removed unused import of flutter material here; this file contains mock logic only.

// --------------------------------------------------------------------------
// NOTE ON FIREBASE SETUP:
// In a real Flutter project, you would initialize Firebase here
// (e.g., in main.dart) and then use the official packages:
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// Since we are simulating the structure, we use mock logic.
// --------------------------------------------------------------------------

/// Mock User Class for simulation
class MockUser {
  final String uid;
  final String email;
  final String fullName;

  MockUser({required this.uid, required this.email, required this.fullName});
}

/// A service class to handle all Firebase interactions (Auth and Firestore).
class FirebaseService {
  // Singleton pattern for easy access
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Mock current user state
  MockUser? _currentUser;
  MockUser? get currentUser => _currentUser;

  // --- MOCK AUTH METHODS ---

  Future<MockUser?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    // In real Firebase:
    // 1. result = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
    // 2. await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).set({'fullName': fullName, ...});

    // Mock success
    _currentUser = MockUser(
      uid: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: fullName,
    );
    return _currentUser;
  }

  Future<MockUser?> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    // In real Firebase:
    // 1. result = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    // 2. Fetch user data (e.g., fullName) from Firestore

    // Mock success
    if (email == 'faris@ecopilot.com' && password == 'password123') {
      _currentUser = MockUser(
        uid: 'faris123',
        email: email,
        fullName: 'Faris Sufi',
      );
      return _currentUser;
    } else {
      throw Exception('Invalid email or password.');
    }
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In real Firebase: await FirebaseAuth.instance.signOut();
    _currentUser = null;
  }

  // --- MOCK FIRESTORE METHODS ---

  Future<Map<String, dynamic>> fetchActivities(String userId) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate database query

    // Mock data structures matching the HomeScreen UI
    return {
      'tip': "Bring your own bag to reduce plastic use",
      'challenge': "Use a reusable water bottle today",
      'recentActivity': [
        {'product': 'GreenBrush Eco', 'score': 'A', 'co2': '98g'},
        {'product': 'BambooClean 2.0', 'score': 'A+', 'co2': '123g'},
        {'product': 'EcoPaste Mint+', 'score': 'B+', 'co2': '50g'},
        {'product': 'RefillRoll Deodorant', 'score': 'A-', 'co2': '74g'},
      ],
    };

    // In real Firestore, this would be:
    // final doc = await FirebaseFirestore.instance.collection('user_data').doc(userId).get();
    // return doc.data() ?? {};
  }
}
