import 'dart:typed_data';

// Assuming the existence of these files
// import 'package:ecopilot_test/utils/cloudinary_config.dart';
// import 'package:ecopilot_test/services/cloudinary_service.dart';
// import 'package:ecopilot_test/utils/constants.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';

// Placeholder definitions for missing imports (Cloudinary and Constants)
const Color primaryGreen = Color(0xFF1DB954,);
const bool isCloudinaryConfigured = false;
const String cloudinaryCloudName = 'YOUR_CLOUD_NAME';
const String cloudinaryUploadPreset = 'YOUR_UPLOAD_PRESET';

// Placeholder for Cloudinary service since the actual implementation is not provided
class CloudinaryService {
  static Future<String?> uploadImageBytes(
    Uint8List bytes, {
    required String filename,
    required String cloudName,
    required String uploadPreset,
  }) async {
    // Simulation: in a real app, this would upload the image and return the URL
    await Future.delayed(const Duration(milliseconds: 500));
    // Return a placeholder URL if configured, otherwise null
    if (isCloudinaryConfigured && cloudName != 'YOUR_CLOUD_NAME') {
      return 'https://res.cloudinary.com/$cloudName/image/upload/v1/$filename';
    }
    return 'https://placehold.co/600x800/A8D8B9/212121?text=Product+Image';
  }
}

/// A lightweight scan screen that lets the user take a photo or pick from gallery,
/// runs a (stubbed) Gemini analysis to extract product info, uploads the image
/// to Cloudinary (if configured), stores the result in Firestore and returns
/// the product map to the caller via Navigator.pop(result).
class DisposalScanScreen extends StatefulWidget {
  const DisposalScanScreen({Key? key}) : super(key: key);

  @override
  State<DisposalScanScreen> createState() => _DisposalScanScreenState();
}

class _DisposalScanScreenState extends State<DisposalScanScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _picked;
  Uint8List? _bytes;
  bool _busy = false;
  Map<String, dynamic>? _analysis;
  bool _photoConfirmed = false;

  // Camera fields
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    // Initialize camera automatically when screen opens
    _initCamera();
  }

  @override
  void dispose() {
    _disposeCamera();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      setState(() {
        _busy = true;
        _analysis = null;
      });
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _picked = file;
        _bytes = bytes;
        _photoConfirmed = false;
        // If user picked an image from gallery, pause preview to save resources
        if (_isCameraInitialized) {
          try {
            _cameraController?.pausePreview();
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('Image pick failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
      }
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  // Camera helpers: initialize, dispose, capture and flash toggle
  Future<void> _initCamera() async {
    try {
      setState(() => _busy = true);
      _cameras = await availableCameras();
      final back = _cameras?.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      _cameraController = CameraController(
        back!,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(FlashMode.off);
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Camera init failed: $e');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to start camera')));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _disposeCamera() async {
    try {
      await _cameraController?.dispose();
    } catch (_) {}
    _cameraController = null;
    _isCameraInitialized = false;
  }

  Future<void> _captureFromCamera() async {
    if (!_isCameraInitialized || _cameraController == null) return;
    try {
      setState(() => _busy = true);
      final file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      setState(() {
        _picked = file;
        _bytes = bytes;
        _photoConfirmed = false;
      });
      try {
        await _cameraController?.pausePreview();
      } catch (_) {}
    } catch (e) {
      debugPrint('Capture failed: $e');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Capture failed')));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _toggleFlash() async {
    if (!_isCameraInitialized || _cameraController == null) return;
    try {
      setState(() => _torchOn = !_torchOn);
      await _cameraController!.setFlashMode(
        _torchOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      debugPrint('Flash toggle failed: $e');
    }
  }

  Future<Map<String, dynamic>> _analyzeImage(Uint8List bytes) async {
    // In a production app you'd call Google Gemini / google_generative_ai here.
    // This simulates the powerful analysis mentioned in the prompt.
    await Future.delayed(const Duration(seconds: 2));

    // Simulated Gemini 2.5 Pro analysis response
    final isYogurt = bytes.length % 2 == 0; // Simple random simulation

    final simulated = <String, dynamic>{
      'name': isYogurt ? 'Coconut Yogurt' : 'Shampoo 2',
      'category': isYogurt ? 'Food' : 'Cosmetic',
      'material': 'Plastic',
      'ecoScore': isYogurt ? 'C' : 'A',
      'disposalSteps': isYogurt
          ? [
              'Rinse the container thoroughly to remove all food residue.',
              'Place the plastic container in the designated mixed plastics bin.',
              'Check if the label is peelable and recycle it with paper if possible.',
            ]
          : [
              'Empty the bottle completely. Do not rinse into the drain.',
              'If the cap is a different plastic type, separate it.',
              'Place both the bottle and cap (if separated) in the plastics recycling bin.',
            ],
      'tips': isYogurt
          ? [
              'Try making your own yogurt to reduce plastic waste.',
              'Compost any residual fruit/yogurt mixture.',
            ]
          : [
              'Look for solid shampoo bars to eliminate plastic packaging entirely.',
              'Refill stations are great for bulk purchases.',
            ],
    };

    return simulated;
  }

  Future<void> _runAnalysis() async {
    if (_bytes == null) return;
    setState(() => _busy = true);
    try {
      final result = await _analyzeImage(_bytes!);
      setState(() {
        _analysis = result;
      });
    } catch (e) {
      debugPrint('Analysis error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Analysis failed')));
      }
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _saveAndReturn() async {
    if (_analysis == null) return;
    setState(() => _busy = true);

    final Map<String, dynamic> product = Map<String, dynamic>.from(_analysis!);
    final String productId = DateTime.now().millisecondsSinceEpoch.toString();
    product['productId'] = productId;

    // Upload image to Cloudinary if configured
    try {
      final imageUrl = await CloudinaryService.uploadImageBytes(
        _bytes!,
        filename: '$productId.jpg',
        cloudName: cloudinaryCloudName,
        uploadPreset: cloudinaryUploadPreset,
      );
      if (imageUrl != null) product['imageUrl'] = imageUrl;
    } catch (e) {
      debugPrint('Cloudinary upload failed: $e');
    }

    // Save to Firestore under current user's scans
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scans')
          .doc(productId);
      await docRef.set({
        'name': product['name'] ?? 'Scanned product',
        'category': product['category'] ?? 'General', // Saving category
        'material': product['material'] ?? 'Unknown', // Saving material
        'ecoScore': product['ecoScore'] ?? 'N/A',
        'imageUrl': product['imageUrl'] ?? '',
        'disposalSteps': product['disposalSteps'] ?? ['Rinse and recycle'],
        'tips': product['tips'] ?? ['Reduce waste'],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed saving scan: $e');
    }

    setState(() => _busy = false);

    // Return the product to the caller so it can be shown in Details
    if (mounted) Navigator.of(context).pop(product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Disposal Scan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: _picked != null
                          ? Image.memory(_bytes!, fit: BoxFit.contain)
                          : _isCameraInitialized && _cameraController != null
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                CameraPreview(_cameraController!),
                                // Top-right flash toggle
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Material(
                                    color: Colors.black45,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        _torchOn
                                            ? Icons.flash_on
                                            : Icons.flash_off,
                                        color: Colors.white,
                                      ),
                                      onPressed: _busy ? null : _toggleFlash,
                                    ),
                                  ),
                                ),
                                // Capture button bottom center
                                Positioned(
                                  bottom: 20,
                                  child: GestureDetector(
                                    onTap: _busy ? null : _captureFromCamera,
                                    child: Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.15),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Initializing camera or select from gallery',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),

            // Show Retake / Use Photo actions when a photo is picked/captured
            if (_picked != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              // Retake: clear picked image and resume camera
                              setState(() {
                                _picked = null;
                                _bytes = null;
                                _analysis = null;
                                _photoConfirmed = false;
                              });
                              try {
                                if (_isCameraInitialized) {
                                  await _cameraController?.resumePreview();
                                } else {
                                  await _initCamera();
                                }
                              } catch (_) {}
                            },
                      child: const Text(
                        'Retake',
                        style: TextStyle(color: Colors.black87),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy
                          ? null
                          : () {
                              setState(() {
                                _photoConfirmed = true;
                              });
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Photo selected. Tap Analyze to run analysis.',
                                    ),
                                  ),
                                );
                            },
                      child: const Text(
                        'Use Photo',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (_analysis != null) ...[
              const Divider(height: 24),
              const Text(
                'Analysis Result (Simulated)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text('Product: ${_analysis!['name'] ?? 'N/A'}'),
              Text('Category: ${_analysis!['category'] ?? 'N/A'}'),
              Text('Material: ${_analysis!['material'] ?? 'N/A'}'),
              Text('Eco Score: ${_analysis!['ecoScore'] ?? 'N/A'}'),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            // If camera already initialized, try resuming preview, otherwise init
                            if (_isCameraInitialized) {
                              try {
                                await _cameraController?.resumePreview();
                              } catch (_) {
                                await _initCamera();
                              }
                            } else {
                              await _initCamera();
                            }
                          },
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text(
                      'Open Camera',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text(
                      'Upload from Gallery',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (_bytes == null ||
                            _busy ||
                            _analysis != null ||
                            (_picked != null && !_photoConfirmed))
                        ? null
                        : _runAnalysis,
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Analyze with Gemini',
                            style: TextStyle(color: Colors.white),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_analysis == null || _busy)
                        ? null
                        : _saveAndReturn,
                    child: const Text(
                      'Save & View Details',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
