import 'package:ecopilot_test/screens/disposal_guidance_screen.dart';
import 'package:flutter/material.dart';
import '/auth/firebase_service.dart';
import 'package:ecopilot_test/utils/rank_utils.dart';
import '/utils/constants.dart'
    as constants; // Assumed location for kPrimaryGreen/kPrimaryYellow
import 'package:ecopilot_test/widgets/app_drawer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'alternative_screen.dart' as alternative_screen;
import 'home_screen.dart'; // Assume this file exists
import 'scan_screen.dart'; // Assume this file exists
import 'disposal_guidance_screen.dart'
    as disposal_guidance_screen; // Assume this file exists

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _service = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final _emailController = TextEditingController();
  // String _rank = 'Rookie'; // Placeholder for user rank
  bool _isSaving = false;
  int _ecoPoints = 0;
  Color _rankColor = constants.kRankGreenExplorer;

  // State variables for photo upload preview and error handling
  bool _isUploading = false;
  Uint8List? _pickedImageBytes;
  String? _pickedFileName;
  String? _uploadError;
  double? _uploadProgress;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current Firebase user data
    final user = _service.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _photoUrlController.text = user.photoURL ?? '';
      _emailController.text = user.email ?? '';
      // Load rank for the user
      _loadUserRank();
    }
  }

  Future<void> _loadUserRank() async {
    try {
      final user = _service.currentUser;
      if (user == null) return;
      final summary = await _service.getUserSummary(user.uid);
      final points = (summary['ecoScore'] ?? summary['ecoPoints'] ?? 0) as int;
      final rankInfo = rankForPoints(points);
      if (!mounted) return;
      setState(() {
        _ecoPoints = points;
        // _rank = rankInfo.title;
        _rankColor = rankInfo.color;
      });
    } catch (e) {
      debugPrint('Error loading user rank: $e');
    }
  }
  // Rank logic moved to lib/utils/rank_utils.dart

  @override
  void dispose() {
    _nameController.dispose();
    _photoUrlController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // --- Photo Picking and Upload Logic ---

  Future<void> _pickImage() async {
    // Request permission on platforms that need it
    if (!kIsWeb) {
      // Request both common permissions to cover Android and iOS cases.
      // On iOS Permission.photos is used; on Android apps may need READ_EXTERNAL_STORAGE
      // or READ_MEDIA_IMAGES (Android 13+). Request both and continue if either is granted.
      final statuses = await [Permission.photos, Permission.storage].request();

      final photosGranted = statuses[Permission.photos]?.isGranted ?? false;
      final storageGranted = statuses[Permission.storage]?.isGranted ?? false;
      final photosPermDenied =
          statuses[Permission.photos]?.isPermanentlyDenied ?? false;
      final storagePermDenied =
          statuses[Permission.storage]?.isPermanentlyDenied ?? false;

      if (!photosGranted && !storageGranted) {
        if (photosPermDenied || storagePermDenied) {
          // If permission is permanently denied, prompt user to open app settings
          if (!mounted) return;
          final open = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Permission required'),
              content: const Text(
                'Photo access is permanently denied. Please open app settings to enable photo permissions.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
          if (open == true) {
            await openAppSettings();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permission denied to access photos'),
              ),
            );
          }
        }
        return;
      }
    }

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    // Read bytes for immediate local preview
    Uint8List bytes;
    if (kIsWeb) {
      bytes = await picked.readAsBytes();
    } else {
      bytes = await File(picked.path).readAsBytes();
    }

    setState(() {
      _isUploading = true;
      _pickedImageBytes = bytes;
      _pickedFileName = picked.name;
      _uploadError = null;
    });

    try {
      String url = await _service.uploadProfilePhoto(
        bytes: bytes,
        fileName: picked.name,
        onProgress: (transferred, total) {
          if (!mounted) return;
          setState(() {
            _uploadProgress = (total > 0) ? transferred / total : null;
          });
        },
      );

      _photoUrlController.text = url;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Photo uploaded')));
        // Clear local preview so the final network image loads
        setState(() {
          _pickedImageBytes = null;
          _uploadProgress = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError = e.toString(); // Show retry button
          _uploadProgress = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _retryUpload() async {
    if (_pickedImageBytes == null) return;
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });
    try {
      // Re-upload using the cached bytes and filename, show progress
      final url = await _service.uploadProfilePhoto(
        bytes: _pickedImageBytes,
        fileName: _pickedFileName,
        onProgress: (transferred, total) {
          if (!mounted) return;
          setState(() {
            _uploadProgress = (total > 0) ? transferred / total : null;
          });
        },
      );
      _photoUrlController.text = url;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Photo uploaded')));
        setState(() {
          _pickedImageBytes = null;
          _uploadError = null;
          _uploadProgress = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError = e.toString();
          _uploadProgress = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Retry failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- Profile Saving Logic ---

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final newName = _nameController.text.trim();
      final newPhoto = _photoUrlController.text.trim();

      if (newName.isNotEmpty) await _service.updateDisplayName(newName);
      // This will update the photo URL in Firebase Auth
      if (newPhoto.isNotEmpty) await _service.updatePhotoUrl(newPhoto);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openChangePassword() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    final user = _service.currentUser;
    // Prioritize the newly uploaded URL, otherwise use existing network photo
    final photo = _photoUrlController.text.isNotEmpty
        ? _photoUrlController.text
        : user?.photoURL;

    // Constant for space reserved by the sticky button
    final double bottomPadding = 100.0;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: constants.kPrimaryGreen,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        // leading: IconButton(
        //   onPressed: () => Navigator.of(context).pop(),
        //   icon: const Icon(Icons.arrow_back, color: Colors.white),
        // ),
      ),

      body: Column(
        children: [
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                // The main content area with a rounded white background
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar overlapping header with upload overlay and retry card
                      Transform.translate(
                        offset: const Offset(0, -5),
                        child: Center(
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer ring and shadow
                                  Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: constants.kPrimaryYellow,
                                        width: 8,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color.fromRGBO(0, 0, 0, 0.12),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Inner avatar
                                  ClipOval(
                                    child: SizedBox(
                                      width: 124,
                                      height: 124,
                                      child: CircleAvatar(
                                        radius: 62,
                                        backgroundColor: Colors.grey.shade200,
                                        backgroundImage:
                                            _pickedImageBytes != null
                                            ? MemoryImage(_pickedImageBytes!)
                                            : (photo != null &&
                                                  photo.isNotEmpty)
                                            ? CachedNetworkImageProvider(photo)
                                            : null,
                                        child:
                                            (_pickedImageBytes == null &&
                                                (photo == null ||
                                                    photo.isEmpty))
                                            ? const Icon(
                                                Icons.person,
                                                size: 56,
                                                color: Colors.grey,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),

                                  // Upload progress overlay
                                  if (_isUploading && _uploadProgress != null)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black26,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 56,
                                                height: 56,
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    CircularProgressIndicator(
                                                      value: _uploadProgress,
                                                      strokeWidth: 4,
                                                      color: constants
                                                          .kPrimaryGreen,
                                                    ),
                                                    Text(
                                                      '${((_uploadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Edit button / indicator
                                  Positioned(
                                    right: 12,
                                    bottom: 12,
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: _isUploading
                                          ? SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                color: constants.kPrimaryGreen,
                                              ),
                                            )
                                          : (_uploadError != null)
                                          ? GestureDetector(
                                              onTap: _retryUpload,
                                              child: _buildEditButton(
                                                Icons.refresh,
                                                Colors.redAccent,
                                              ),
                                            )
                                          : _buildEditButton(
                                              Icons.edit,
                                              constants.kPrimaryGreen,
                                            ),
                                    ),
                                  ),
                                ],
                              ),

                              // If the last upload failed, show a small retry card
                              if (_uploadError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Center(
                                    child: Card(
                                      color: Colors.red.shade50,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              color: Colors.redAccent,
                                            ),
                                            const SizedBox(width: 8),
                                            const Expanded(
                                              child: Text(
                                                'Upload failed. You can retry or cancel.',
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: _retryUpload,
                                              child: const Text('Retry'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                // Cancel: clear preview and error
                                                setState(() {
                                                  _pickedImageBytes = null;
                                                  _uploadError = null;
                                                  _uploadProgress = null;
                                                });
                                              },
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Name card (Input)
                      _buildInfoCard(
                        icon: Icons.person,
                        label: 'Name',
                        contentWidget: TextFormField(
                          controller: _nameController,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter a name'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Rank (Placeholder)
                      _buildInfoCard(
                        icon: Icons.emoji_events,
                        label: 'Rank',
                        contentWidget: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star, color: _rankColor, size: 18),
                                const SizedBox(width: 8),
                                // Text(
                                //   _rank,
                                //   style: TextStyle(
                                //     fontWeight: FontWeight.bold,
                                //     fontSize: 16,
                                //     color: _rankColor,
                                //   ),
                                // ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_ecoPoints eco points',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email (Read-only)
                      _buildInfoCard(
                        icon: Icons.mail_outline,
                        label: 'Email',
                        contentWidget: Text(
                          _emailController.text,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password (Change Button)
                      _buildInfoCard(
                        icon: Icons.lock_outline,
                        label: 'Password',
                        contentWidget: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '***********',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: _openChangePassword,
                              child: const Text(
                                'Change',
                                style: TextStyle(
                                  color: constants.kPrimaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailingWidget: const SizedBox(),
                      ),

                      // Spacer to ensure scroll view pushes content above the sticky button
                      SizedBox(height: bottomPadding),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Sticky Save button
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: 24 + MediaQuery.of(context).padding.bottom,
              top: 12,
            ),
            child: _isUploading || _isSaving
                ? Center(
                    child: CircularProgressIndicator(
                      color: constants.kPrimaryGreen,
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: constants.kPrimaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  // Helper widget to build the data cards, matching Image 11.png
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required Widget contentWidget,
    Widget? trailingWidget,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: constants.kPrimaryGreen, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                contentWidget,
              ],
            ),
          ),
          if (trailingWidget != null) trailingWidget,
        ],
      ),
    );
  }

  // Helper for the profile picture edit button style
  Widget _buildEditButton(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    const int currentIndex = 4; // Profile tab

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: constants.kPrimaryGreen,
      unselectedItemColor: Colors.grey,
      onTap: (index) async {
        // Simple navigation that doesn't rely on state located outside this widget
        if (index == 0) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const HomeScreen()));
          return;
        }
        if (index == 1) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const alternative_screen.AlternativeScreen(),
            ),
          );
          return;
        }
        if (index == 2) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ScanScreen()));
          return;
        }
        if (index == 3) {
          Navigator.of(context).push(
            MaterialPageRoute(
              // ⬅️ CRUCIAL CHANGE HERE
              builder: (_) => const DisposalGuidanceScreen(productId: null),
            ),
          );
          return;
        }
        if (index == 4) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          return;
        }
      },
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Alternative',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Scan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.delete_sweep),
          label: 'Dispose',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}

// Change Password Screen (Matching Image 12.png)
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  final FirebaseService _service = FirebaseService();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _service.updatePassword(_passwordController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change password: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: constants.kPrimaryGreen,
        centerTitle: true,
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Type your new password',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),

                    // New Password Field
                    _buildPasswordInputField(
                      controller: _passwordController,
                      label: 'New password',
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Minimum 6 characters'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Retype Password Field
                    _buildPasswordInputField(
                      controller: _confirmController,
                      label: 'Retype password',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Please confirm' : null,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Change Password Button (sticky)
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: 24 + MediaQuery.of(context).padding.bottom,
              top: 16,
            ),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: constants.kPrimaryGreen,
                    ),
                  )
                : SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: constants.kPrimaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Change Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Helper function for password input fields (matching the card style)
  Widget _buildPasswordInputField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, color: constants.kPrimaryGreen, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextFormField(
                  controller: controller,
                  obscureText: true,
                  validator: validator,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  decoration: const InputDecoration(
                    hintText: '*********', // Placeholder to match visual
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
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
