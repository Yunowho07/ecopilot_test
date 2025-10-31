import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart' as fb_storage;
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';

/// Simple Firebase authentication helper used by the login/signup screens.
///
/// This keeps the UI files decoupled from direct FirebaseAuth calls and
/// provides a small abstraction for signIn/signUp/signOut.
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the currently signed in [User], or null if not signed in.
  User? get currentUser => _auth.currentUser;

  /// Example fetcher for activity data. In a real app this would query
  /// Firestore or another backend. Returning a simple mock payload so
  /// the UI can render without adding Firestore as a dependency here.
  Future<Map<String, dynamic>> fetchActivities(String uid) async {
    // Simulate a small delay like a network/database call
    await Future<void>.delayed(const Duration(milliseconds: 200));

    return {
      'tip': 'Bring a reusable bag for shopping.',
      'challenge': 'Avoid single-use plastics today.',
      'recentActivity': [
        {'product': 'Reusable Bottle', 'score': '95', 'co2': '0.2kg'},
        {'product': 'Compost Bin', 'score': '88', 'co2': '0.1kg'},
      ],
    };
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
      return _auth.currentUser;
    }

    return credential.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Update the current user's display name.
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    await user.updateDisplayName(name);
    await user.reload();
  }

  /// Update the current user's photo URL.
  Future<void> updatePhotoUrl(String photoUrl) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    await user.updatePhotoURL(photoUrl);
    await user.reload();
  }

  /// Upload a local file to Firebase Storage and return the download URL.
  /// On web, [file] will be null and [bytes] should be provided.
  /// Upload profile photo with progress and automatic retries.
  ///
  /// Parameters:
  /// - [file]: local File (mobile). If [bytes] is provided, it will be used
  ///   instead (preferred so callers can retry without re-reading disk).
  /// - [bytes]: raw image bytes to upload.
  /// - [fileName]: optional filename to use in storage path.
  /// - [onProgress]: optional callback (transferred, total) called with snapshot updates.
  /// - [maxAttempts]: number of attempts (default 3) for automatic retries.
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
      // Store in a profile_photos folder within a subfolder of the user's UID
      final ref = fb_storage.FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child(uid)
          .child(name);

      // no-op placeholder removed; we directly forward snapshot events to caller

      // Prepare bytes (prefer provided bytes so callers can reuse them)
      Uint8List uploadBytes;
      if (bytes != null) {
        uploadBytes = bytes;
      } else if (file != null) {
        uploadBytes = await file.readAsBytes();
      } else {
        throw Exception('No image data provided for upload');
      }

      // Adaptive sizing: if already small, skip resizing. Threshold 200KB.
      try {
        if (uploadBytes.length > 200 * 1024) {
          final decoded = img.decodeImage(uploadBytes);
          if (decoded != null) {
            final resized = img.copyResize(decoded, width: 800);
            int quality = 70;
            var encoded = img.encodeJpg(resized, quality: quality);

            if (encoded.length > 400 * 1024) {
              quality = 60;
              encoded = img.encodeJpg(resized, quality: quality);
            }

            uploadBytes = Uint8List.fromList(encoded);
          }
        }
      } catch (_) {
        debugPrint('Image processing failed, using original bytes.');
      }

      // Attempt upload with retries and exponential backoff
      int attempt = 0;
      int backoffMs = 500;
      while (true) {
        attempt++;
        try {
          final task = ref.putData(
            uploadBytes,
            fb_storage.SettableMetadata(
              contentType: 'image/jpeg',
              cacheControl: 'public,max-age=3600',
            ),
          );

          // Listen to progress and forward to callback
          final sub = task.snapshotEvents.listen((snapshot) {
            try {
              final transferred = snapshot.bytesTransferred;
              final total = snapshot.totalBytes;
              if (onProgress != null) onProgress(transferred, total);
            } catch (_) {}
          });

          final snapshot = await task;
          await sub.cancel();

          final url = await snapshot.ref.getDownloadURL();
          // Update user's photoURL in Auth
          await updatePhotoUrl(url);
          return url;
        } catch (e) {
          debugPrint('Upload attempt $attempt failed: $e');
          if (attempt >= maxAttempts) rethrow;
          // exponential backoff before retrying
          await Future<void>.delayed(Duration(milliseconds: backoffMs));
          backoffMs *= 2;
        }
      }
    } catch (e) {
      debugPrint('Upload failed: $e');
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

  /// Sign in using Google. Supports web (popup) and mobile flows.
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
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
        return userCredential.user;
      }
    } catch (e) {
      debugPrint('Apple sign-in failed: $e');
      rethrow;
    }
  }

  // Helpers for Apple sign-in nonce generation (from Firebase docs)
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
}
