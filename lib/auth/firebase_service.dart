import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Firestore
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// A comprehensive Firebase service class handling:
/// 1. Firebase Authentication (Email/Password, Google, Facebook, Apple).
/// 2. Firebase Storage (Profile Photo Upload).
/// 3. Cloud Firestore (User Profiles, Scanned Products, Challenges, Notifications).
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Added Firestore

  /// Returns the currently signed in [User], or null if not signed in.
  User? get currentUser => _auth.currentUser;

  /// Returns the current user's UID, or an empty string if not signed in.
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // ===============================================
  // 🔰 AUTHENTICATION (From Version 1) 🔰
  // ===============================================

  // Top-level helper used by compute() to perform image resizing and JPEG encoding
  // in a background isolate. Keep this function top-level so compute() can call it.
  Uint8List _encodeResizeJpeg(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;

      // Resize to a smaller width to prioritize speed and lower upload size.
      final resized = img.copyResize(decoded, width: 400);

      // Encode with lower quality to further reduce payload size for faster uploads.
      final encoded = img.encodeJpg(resized, quality: 50);
      return Uint8List.fromList(encoded);
    } catch (e) {
      // If decoding/encoding fails, return the original bytes so upload can still proceed.
      return bytes;
    }
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<User?> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // If a display name was provided, update the user profile.
    if (fullName != null && credential.user != null) {
      await credential.user!.updateDisplayName(fullName);
      // Refresh the user to make sure displayName is available immediately.
      await credential.user!.reload();
      // Ensure the Firestore profile is created immediately after a successful sign-up
      await createUserProfile(fullName, email, credential.user!.photoURL ?? '');
      return _auth.currentUser;
    }

    // Ensure the Firestore profile is created for basic sign-up
    if (credential.user != null) {
      await createUserProfile(
        credential.user!.displayName ?? 'New User',
        email,
        credential.user!.photoURL ?? '',
      );
    }
    return credential.user;
  }

  Future<void> signOut() async {
    try {
      // Try to sign out from provider SDKs where applicable to fully clear tokens
      try {
        final google = GoogleSignIn();
        await google.signOut();
      } catch (_) {}

      try {
        await FacebookAuth.instance.logOut();
      } catch (_) {}

      await _auth.signOut();
    } catch (e) {
      debugPrint('signOut failed: $e');
      rethrow;
    }
  }

  /// Update the current user's password. This will fail if the user's
  /// credentials are too old and re-authentication is required.
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    await user.updatePassword(newPassword);
    await user.reload();
  }

  /// Send a password reset email to the provided [email].
  ///
  /// Throws a [FirebaseAuthException] on failure.
  Future<void> sendPasswordReset({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // --- Social Sign-In Methods ---

  /// Sign in using Google. Supports web (popup) and mobile flows.
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        if (userCredential.user != null) {
          await _handleSocialSignInProfile(userCredential.user!);
        }
        return userCredential.user;
      } else {
        final googleSignIn = GoogleSignIn();
        final account = await googleSignIn.signIn();
        if (account == null) return null; // User canceled

        final auth = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        if (userCredential.user != null) {
          await _handleSocialSignInProfile(userCredential.user!);
        }
        return userCredential.user;
      }
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      rethrow;
    }
  }

  /// Sign in with Facebook.
  Future<User?> signInWithFacebook() async {
    try {
      if (kIsWeb) {
        final fbProvider = OAuthProvider('facebook.com');
        final userCredential = await _auth.signInWithPopup(fbProvider);
        if (userCredential.user != null) {
          await _handleSocialSignInProfile(userCredential.user!);
        }
        return userCredential.user;
      } else {
        final LoginResult result = await FacebookAuth.instance.login();
        if (result.status == LoginStatus.success &&
            result.accessToken != null) {
          final dynamic at = result.accessToken;
          final accessToken = at?.token ?? at?.accessToken ?? at?.value;
          final credential = FacebookAuthProvider.credential(
            accessToken as String,
          );
          final userCredential = await _auth.signInWithCredential(credential);
          if (userCredential.user != null) {
            await _handleSocialSignInProfile(userCredential.user!);
          }
          return userCredential.user;
        } else if (result.status == LoginStatus.cancelled) {
          return null;
        } else {
          throw Exception(result.message ?? 'Facebook sign-in failed');
        }
      }
    } catch (e) {
      debugPrint('Facebook sign-in failed: $e');
      rethrow;
    }
  }

  /// Sign in with Apple.
  Future<User?> signInWithApple() async {
    try {
      if (kIsWeb) {
        final appleProvider = OAuthProvider('apple.com');
        final userCredential = await _auth.signInWithPopup(appleProvider);
        if (userCredential.user != null) {
          await _handleSocialSignInProfile(userCredential.user!);
        }
        return userCredential.user;
      } else {
        final rawNonce = _generateNonce();
        final hashedNonce = _sha256ofString(rawNonce);

        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: hashedNonce,
        );

        final oauthCredential = OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
        );

        final userCredential = await _auth.signInWithCredential(
          oauthCredential,
        );
        if (userCredential.user != null) {
          await _handleSocialSignInProfile(userCredential.user!);
        }
        return userCredential.user;
      }
    } catch (e) {
      debugPrint('Apple sign-in failed: $e');
      rethrow;
    }
  }

  // Helper function to create Firestore profile after a successful social sign-in
  Future<void> _handleSocialSignInProfile(User user) async {
    await createUserProfile(
      user.displayName ?? 'New User',
      user.email ??
          '', // Email can be null for anonymous sign-in, though not for these providers
      user.photoURL ?? '',
    );
  }

  // Helpers for Apple sign-in nonce generation (from Version 1)
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(charset[(random + i) % charset.length]);
    }
    return buffer.toString();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ===============================================
  // ✏️ USER PROFILE UPDATES (From Version 1 - Auth part) ✏️
  // ===============================================

  /// Update the current user's display name in Firebase Auth and Firestore.
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    await user.updateDisplayName(name);
    await user.reload();
    await updateUserProfile(name: name); // Update in Firestore
  }

  /// Update the current user's photo URL in Firebase Auth and Firestore.
  Future<void> updatePhotoUrl(String photoUrl) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    await user.updatePhotoURL(photoUrl);
    await user.reload();
    await updateUserProfile(photoUrl: photoUrl); // Update in Firestore
  }

  // ===============================================
  // ☁️ FIREBASE STORAGE (From Version 1) ☁️
  // ===============================================

  /// Upload a local file to Firebase Storage and return the download URL.
  Future<String> uploadProfilePhoto({
    File? file,
    Uint8List? bytes,
    String? fileName,
    void Function(int transferred, int total)? onProgress,
    int maxAttempts = 3,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      final uid = user.uid;
      final name =
          fileName ?? 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Prepare bytes (prefer provided bytes so callers can reuse them)
      Uint8List uploadBytes;
      if (bytes != null) {
        uploadBytes = bytes;
      } else if (file != null) {
        uploadBytes = await file.readAsBytes();
      } else {
        throw Exception('No image data provided for upload');
      }

      // Adaptive sizing: if already small, skip resizing. Threshold 80KB.
      try {
        if (uploadBytes.length > 80 * 1024) {
          uploadBytes = await compute(_encodeResizeJpeg, uploadBytes);
        }
      } catch (e) {
        debugPrint('Image processing failed, using original bytes. Error: $e');
      }

      // Upload to Cloudinary (unsigned preset) using HTTP multipart upload.
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
      final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
      if (cloudName.isEmpty || uploadPreset.isEmpty) {
        throw Exception(
          'Cloudinary configuration missing. Set CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET in .env',
        );
      }

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      int attempt = 0;
      int backoffMs = 500;
      while (true) {
        attempt++;
        try {
          final request = http.MultipartRequest('POST', uri);
          request.fields['upload_preset'] = uploadPreset;
          request.fields['folder'] = 'profile_photos/$uid';
          request.files.add(
            http.MultipartFile.fromBytes('file', uploadBytes, filename: name),
          );

          final streamed = await request.send();
          if (onProgress != null)
            onProgress(uploadBytes.length, uploadBytes.length);

          final respStr = await streamed.stream.bytesToString();
          if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
            throw Exception(
              'Cloudinary upload failed: ${streamed.statusCode} ${respStr}',
            );
          }
          final Map<String, dynamic> decoded = jsonDecode(respStr);
          final url = decoded['secure_url'] as String?;
          if (url == null || url.isEmpty)
            throw Exception('Cloudinary response missing secure_url');

          await updatePhotoUrl(url);
          return url;
        } catch (e) {
          debugPrint('Cloudinary upload attempt $attempt failed: $e');
          if (attempt >= maxAttempts) rethrow;
          await Future<void>.delayed(Duration(milliseconds: backoffMs));
          backoffMs *= 2;
        }
      }
    } catch (e) {
      debugPrint('Upload failed: $e');
      rethrow;
    }
  }

  /// Upload a scanned image (product scan) to Cloudinary and return the secure URL.
  Future<String> uploadScannedImage({
    File? file,
    Uint8List? bytes,
    String? fileName,
    void Function(int transferred, int total)? onProgress,
    int maxAttempts = 3,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');
      final uid = user.uid;

      final name =
          fileName ?? 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';

      Uint8List uploadBytes;
      if (bytes != null) {
        uploadBytes = bytes;
      } else if (file != null) {
        uploadBytes = await file.readAsBytes();
      } else {
        throw Exception('No image data provided for upload');
      }

      try {
        if (uploadBytes.length > 80 * 1024) {
          uploadBytes = await compute(_encodeResizeJpeg, uploadBytes);
        }
      } catch (e) {
        debugPrint('Image processing failed, using original bytes. Error: $e');
      }

      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
      final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
      if (cloudName.isEmpty || uploadPreset.isEmpty) {
        throw Exception(
          'Cloudinary configuration missing. Set CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET in .env',
        );
      }

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      int attempt = 0;
      int backoffMs = 500;
      while (true) {
        attempt++;
        try {
          final request = http.MultipartRequest('POST', uri);
          request.fields['upload_preset'] = uploadPreset;
          request.fields['folder'] = 'scanned_images/$uid';
          request.files.add(
            http.MultipartFile.fromBytes('file', uploadBytes, filename: name),
          );

          final streamed = await request.send();
          if (onProgress != null)
            onProgress(uploadBytes.length, uploadBytes.length);

          final respStr = await streamed.stream.bytesToString();
          if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
            throw Exception(
              'Cloudinary upload failed: ${streamed.statusCode} ${respStr}',
            );
          }
          final Map<String, dynamic> decoded = jsonDecode(respStr);
          final url = decoded['secure_url'] as String?;
          if (url == null || url.isEmpty)
            throw Exception('Cloudinary response missing secure_url');
          return url;
        } catch (e) {
          debugPrint(
            'Cloudinary scanned image upload attempt $attempt failed: $e',
          );
          if (attempt >= maxAttempts) rethrow;
          await Future<void>.delayed(Duration(milliseconds: backoffMs));
          backoffMs *= 2;
        }
      }
    } catch (e) {
      debugPrint('uploadScannedImage failed: $e');
      rethrow;
    }
  }

  // ===============================================
  // 📖 FIRESTORE - USER DATA (From Version 2) 📖
  // ===============================================

  Future<void> createUserProfile(
    String name,
    String email,
    String photoUrl,
  ) async {
    final uid = _auth.currentUser!.uid;

    final userRef = _firestore.collection('users').doc(uid);
    final existingUser = await userRef.get();

    // Only create profile if it doesn't exist yet
    if (!existingUser.exists) {
      await userRef.set({
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'ecoScore': 0,
        'title': 'Eco Beginner',
        'streakDays': 0,
        'createdAt': Timestamp.now(),
      });
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile() async {
    final uid = _auth.currentUser!.uid;
    return _firestore.collection('users').doc(uid).get();
  }

  /// Return a small summary for the user used by UI (streak, ecoScore, etc.).
  /// If the document doesn't exist, returns defaults.
  Future<Map<String, dynamic>> getUserSummary(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      final streak = data['streak'] ?? data['streakDays'] ?? 0;
      final ecoScore = data['ecoScore'] ?? data['ecoPoints'] ?? 0;
      return {'streak': streak, 'ecoScore': ecoScore, 'profile': data};
    } catch (e) {
      debugPrint('getUserSummary failed: $e');
      return {'streak': 0, 'ecoScore': 0, 'profile': {}};
    }
  }

  Future<void> updateUserProfile({String? name, String? photoUrl}) async {
    final uid = _auth.currentUser!.uid;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }

  Future<void> updateEcoScore(int points) async {
    final uid = _auth.currentUser!.uid;
    final userRef = _firestore.collection('users').doc(uid);
    final userDoc = await userRef.get();

    if (userDoc.exists) {
      final currentScore = userDoc.data()?['ecoScore'] ?? 0;
      await userRef.update({'ecoScore': currentScore + points});
    }
  }

  // ===============================================
  // 📦 FIRESTORE - SCANNED PRODUCTS (From Version 2) 📦
  // ===============================================

  Future<void> saveScannedProduct({
    required String productName,
    required String ecoScore,
    required String imageUrl,
    required String packaging,
    required String disposalMethod,
    double? carbonFootprint,
    String? barcode,
  }) async {
    final uid = _auth.currentUser!.uid;

    // Save under users/{uid}/scans for per-user history (centralized location).
    final scansRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('scans');
    await scansRef.add({
      'analysis':
          '', // legacy callers may not pass raw analysis; keep empty by default
      'product_name': productName,
      'eco_score': ecoScore,
      'barcode': barcode ?? '',
      'carbon_footprint': carbonFootprint ?? 0.0,
      'packaging': packaging,
      'disposal_method': disposalMethod,
      'image_url': imageUrl,
      'timestamp': Timestamp.now(),
      'date': DateTime.now().toIso8601String(),
    });

    // Also keep the legacy global collection for compatibility (optional).
    await _firestore.collection('scanned_products').add({
      'userId': uid,
      'productName': productName,
      'ecoScore': ecoScore,
      'barcode': barcode ?? '',
      'carbonFootprint': carbonFootprint ?? 0.0,
      'packaging': packaging,
      'disposalMethod': disposalMethod,
      'imageUrl': imageUrl,
      'scannedAt': Timestamp.now(),
    });
  }

  /// Save a user scan with analysis text and optional image URL to per-user scans.
  Future<void> saveUserScan({
    required String analysis,
    required String productName,
    required String ecoScore,
    required String carbonFootprint,
    String? imageUrl,
    String? category,
    String? packagingType,
    List<dynamic>? disposalSteps,
    String? tips,
    String? nearbyCenter,
    bool isDisposal = false,
  }) async {
    // Allow saving scans even when no FirebaseAuth user is signed in by
    // falling back to the 'anonymous' UID. Callers (UI) already sometimes
    // write to users/anonymous directly, so make the helper consistent.
    final uid = _auth.currentUser?.uid ?? 'anonymous';
    final scansRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('scans');
    await scansRef.add({
      'analysis': analysis,
      'product_name': productName,
      'eco_score': ecoScore,
      'carbon_footprint': carbonFootprint,
      'image_url': imageUrl ?? null,
      'category': category ?? null,
      'packaging': packagingType ?? null,
      'disposalSteps': disposalSteps ?? null,
      'tips': tips ?? null,
      'nearbyCenter': nearbyCenter ?? null,
      'isDisposal': isDisposal,
      'timestamp': FieldValue.serverTimestamp(),
      'date': DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now()),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserRecentScans() {
    final uid = _auth.currentUser!.uid;
    return _firestore
        .collection('scanned_products')
        .where('userId', isEqualTo: uid)
        .orderBy('scannedAt', descending: true)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getScannedProductsOnce() async {
    final uid = _auth.currentUser!.uid;
    final snapshot = await _firestore
        .collection('scanned_products')
        .where('userId', isEqualTo: uid)
        .orderBy('scannedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // ===============================================
  // 🌱 FIRESTORE - ALTERNATIVES (From Version 2) 🌱
  // ===============================================

  Future<List<Map<String, dynamic>>> getAlternatives(String forProduct) async {
    final snapshot = await _firestore
        .collection('alternatives')
        .where('forProduct', isEqualTo: forProduct)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> addAlternative({
    required String forProduct,
    required String alternativeName,
    required String ecoScore,
    required String reason,
    required String productUrl,
  }) async {
    await _firestore.collection('alternatives').add({
      'forProduct': forProduct,
      'alternativeName': alternativeName,
      'ecoScore': ecoScore,
      'reason': reason,
      'productUrl': productUrl,
      'createdAt': Timestamp.now(),
    });
  }

  // ===============================================
  // 🏆 FIRESTORE - DAILY CHALLENGES (From Version 2) 🏆
  // ===============================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getDailyChallenges() {
    return _firestore
        .collection('challenges')
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<void> addChallenge({
    required String title,
    required String description,
    required int points,
    required String date,
  }) async {
    await _firestore.collection('challenges').add({
      'title': title,
      'description': description,
      'points': points,
      'date': date,
      'createdAt': Timestamp.now(),
    });
  }

  /// Mark a daily challenge as completed for the current user.
  ///
  /// This will create/update a document under `user_challenges/{uid}-{yyyy-MM-dd}`
  /// recording which challenges were completed and increment the user's eco score.
  Future<void> completeChallenge(int challengeIndex, int points) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');

    final uid = user.uid;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docRef = _firestore.collection('user_challenges').doc('$uid-$today');
    final userRef = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((tx) async {
      final docSnap = await tx.get(docRef);
      List<dynamic> completed = [];
      int currentPoints = 0;

      if (docSnap.exists) {
        final data = docSnap.data()!;
        completed = List.from(data['completed'] ?? []);
        currentPoints = data['pointsEarned'] ?? 0;
      } else {
        // Default to two challenge slots if not present — callers may have different counts.
        completed = [false, false];
      }

      // Expand list if needed
      while (completed.length <= challengeIndex) completed.add(false);

      // Already completed -> nothing to do
      if (completed[challengeIndex] == true) return;

      completed[challengeIndex] = true;

      // Update the user_challenges doc (merge to avoid clobbering)
      tx.set(docRef, {
        'completed': completed,
        'pointsEarned': currentPoints + points,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      // Update user's eco score
      final userSnap = await tx.get(userRef);
      final existingEco = userSnap.exists
          ? (userSnap.data()?['ecoScore'] ?? 0) as int
          : 0;
      tx.update(userRef, {'ecoScore': existingEco + points});
    });
  }

  // ===============================================
  // 🔔 FIRESTORE - NOTIFICATIONS (From Version 2) 🔔
  // ===============================================

  Future<void> sendUserNotification(String message) async {
    final uid = _auth.currentUser!.uid;

    await _firestore.collection('notifications').add({
      'userId': uid,
      'message': message,
      'timestamp': Timestamp.now(),
      'isRead': false,
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserNotifications() {
    final uid = _auth.currentUser!.uid;
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }
}
