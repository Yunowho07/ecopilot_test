import 'dart:typed_data';

import 'package:ecopilot_test/utils/cloudinary_config.dart';
import 'package:ecopilot_test/services/cloudinary_service.dart';
import 'package:ecopilot_test/utils/constants.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:ecopilot_test/models/product_analysis_data.dart';
import 'package:ecopilot_test/auth/firebase_service.dart';
import 'package:ecopilot_test/screens/result_disposal_screen.dart';

/// A lightweight scan screen that lets the user take a photo or pick from gallery,
/// runs Gemini analysis to extract product info, uploads the image
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
  bool _photoConfirmed = false;

  // Camera related
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _showCamera = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _initializeCameras();
    // Automatically start camera when screen opens
    _startCameraAutomatically();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  /// Initialize available cameras
  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
    }
  }

  /// Automatically start camera on screen load
  Future<void> _startCameraAutomatically() async {
    // Wait a bit for the widget to build
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      await _startCamera();
    }
  }

  /// Start camera preview
  Future<void> _startCamera() async {
    if (_cameras == null || _cameras!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cameras available on this device')),
        );
      }
      return;
    }

    // Request camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
      }
      return;
    }

    try {
      // Use the first available camera (usually back camera)
      final camera = _cameras!.first;

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _showCamera = true;
        });
      }
    } catch (e) {
      debugPrint('Error starting camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start camera: $e')));
      }
    }
  }

  /// Stop camera preview
  Future<void> _stopCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
      setState(() {
        _isCameraInitialized = false;
        _showCamera = false;
      });
    }
  }

  /// Capture photo from camera
  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() => _busy = true);

      final XFile imageFile = await _cameraController!.takePicture();
      final bytes = await imageFile.readAsBytes();

      // Stop camera after capturing
      await _stopCamera();

      setState(() {
        _picked = imageFile;
        _bytes = bytes;
        _photoConfirmed = false;
        _busy = false;
      });
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      setState(() => _busy = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to capture photo: $e')));
      }
    }
  }

  /// Toggle between front and back cameras
  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No other camera available')),
        );
      }
      return;
    }

    try {
      setState(() => _busy = true);

      // Find the next camera (toggle between front and back)
      final currentLensDirection = _cameraController?.description.lensDirection;
      CameraDescription? newCamera;

      for (var camera in _cameras!) {
        if (camera.lensDirection != currentLensDirection) {
          newCamera = camera;
          break;
        }
      }

      if (newCamera == null) {
        // Fallback to the other camera
        newCamera = _cameras!.firstWhere(
          (camera) => camera != _cameraController?.description,
          orElse: () => _cameras!.first,
        );
      }

      // Dispose current controller
      await _cameraController?.dispose();

      // Initialize new camera
      _cameraController = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _busy = false;
        });
      }
    } catch (e) {
      debugPrint('Error switching camera: $e');
      setState(() => _busy = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to switch camera: $e')));
      }
    }
  }

  /// Toggle flash mode
  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;

    try {
      if (_flashMode == FlashMode.off) {
        _flashMode = FlashMode.torch;
      } else {
        _flashMode = FlashMode.off;
      }

      await _cameraController!.setFlashMode(_flashMode);
      setState(() {});
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _pick(ImageSource source) async {
    try {
      setState(() {
        _busy = true;
      });

      // Stop camera if it's running
      if (_showCamera) {
        await _stopCamera();
      }

      // Request gallery permission when picking from gallery
      if (source == ImageSource.gallery) {
        PermissionStatus galleryStatus;
        try {
          galleryStatus = await Permission.photos.request();
        } catch (_) {
          galleryStatus = await Permission.storage.request();
        }
        if (!galleryStatus.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gallery permission is required to pick images.'),
              ),
            );
          }
          return;
        }
      }

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

  /// Run Gemini analysis (if configured) and navigate to the Result screen.
  /// Falls back to the local simulator when no API key is found or an error occurs.
  Future<void> _runAnalysis() async {
    if (_bytes == null) return;
    setState(() => _busy = true);
    try {
      final _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

      String outputText;
      ProductAnalysisData analysisData;

      if (_geminiApiKey.isEmpty) {
        // No API key — inform the user and stop. We no longer use a
        // simulated offline analyzer to avoid fabricating results.
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Analysis not available'),
              content: const Text(
                'Image analysis requires a configured Gemini API key.\n'
                'Please add GEMINI_API_KEY to your .env file to enable AI analysis,\n'
                'or scan a barcode which will perform a lookup via OpenFoodFacts / OpenBeautyFacts.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        // Ensure we clear the busy indicator before returning
        setState(() => _busy = false);
        return;
      } else {
        // Use Gemini via google_generative_ai
        final model = GenerativeModel(
          model:'models/gemini-2.5-pro', // Stable production model with excellent vision for disposal analysis
          apiKey: _geminiApiKey,
        );

        const prompt = '''
You are an eco-disposal assistant AI. Analyze the uploaded or scanned product image and return ONLY a single JSON object (no additional text) with these EXACT field names. Use 'N/A' or empty arrays/false for missing values.

Required JSON fields:
- "product_name": Product name as a string
- "category": Product category (e.g., "Food & Beverages (F&B)", "Personal Care", "Household Products", "Electronics", "Clothing & Accessories", "Health & Medicine", "Baby & Kids", "Pet Supplies", "Automotive", "Home & Furniture")
- "ingredients": Ingredients as a comma-separated string (e.g., "Water, Zinc Oxide, etc.")
- "eco_score": Eco-friendliness rating as a SINGLE LETTER - must be exactly one of: "A", "B", "C", "D", or "E" (A is best, E is worst)
- "carbon_footprint": Estimated CO2e per unit as string (e.g., "0.36 kg CO2e per unit")
- "packaging_type": Material and recyclability as string (e.g., "Plastic Tube - Recyclable (Type 4 - LDPE)")
- "disposal_steps": Array of disposal step strings
- "nearby_center": Nearby recycling center name as string (or "N/A")
- "tips": Array of eco-friendly tip strings

IMPORTANT: The "eco_score" MUST be a single letter grade (A, B, C, D, or E). Do not use other formats.

Example valid response (JSON only, no markdown, no backticks):
{
  "product_name": "Plastic Bottle - Sparkling Water",
  "category": "Food & Beverages (F&B)",
  "packaging_type": "PET Plastic",
  "ingredients": "Water, Carbon Dioxide",
  "eco_score": "C",
  "carbon_footprint": "0.15 kg CO2e",
  "disposal_steps": ["Rinse the bottle thoroughly", "Remove and recycle the cap separately", "Place in plastic recycling bin (PET #1)"],
  "nearby_center": "Green Recycling Center",
  "tips": ["Refill and reuse before recycling", "Check local recycling guidelines"]
}
''';

        final content = [
          Content.multi([TextPart(prompt), DataPart('image/jpeg', _bytes!)]),
        ];

        final response = await model.generateContent(content);
        outputText = response.text ?? 'No analysis result.';

        final tempFile = (_picked != null && _picked!.path.isNotEmpty)
            ? File(_picked!.path)
            : null;

        // Attempt to parse structured JSON output from Gemini first.
        ProductAnalysisData? parsedFromJson;
        Map<String, dynamic>? parsedMap;
        try {
          final decoded = json.decode(outputText);
          if (decoded is Map<String, dynamic>) {
            parsedMap = decoded;
          }
        } catch (_) {
          // If the model returned text with an embedded JSON block, try to extract it
          final jsonStart = outputText.indexOf('{');
          final jsonEnd = outputText.lastIndexOf('}');
          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final possible = outputText.substring(jsonStart, jsonEnd + 1);
            try {
              final dec = json.decode(possible);
              if (dec is Map<String, dynamic>) parsedMap = dec;
            } catch (_) {}
          }
        }

        if (parsedMap != null) {
          // Build typed model from structured map
          parsedFromJson = ProductAnalysisData.fromMap(
            parsedMap,
            imageFile: tempFile,
          );
          analysisData = parsedFromJson;
        } else {
          // If the model returned free-form text, parse via the existing parser which
          // extracts fields from Gemini-style responses. This still comes from Gemini
          // (no local simulation) — we only parse the original AI text.
          analysisData = ProductAnalysisData.fromGeminiOutput(
            outputText,
            imageFile: tempFile,
          );
        }
      }

      // Upload image and persist to Firestore using FirebaseService
      String? uploadedImageUrl;
      try {
        uploadedImageUrl = await FirebaseService().uploadScannedImage(
          bytes: _bytes,
          fileName: '${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } catch (e) {
        debugPrint('Failed to upload scanned image: $e');
        uploadedImageUrl = null;
      }

      try {
        await FirebaseService().saveUserScan(
          analysis: outputText,
          productName: analysisData.productName,
          ecoScore: analysisData.ecoScore,
          carbonFootprint: analysisData.carbonFootprint,
          imageUrl: uploadedImageUrl,
          category: analysisData.category,
          ingredients: analysisData.ingredients,
          packagingType: analysisData.packagingType,
          disposalSteps: analysisData.disposalMethod
              .split('\n')
              .where((s) => s.trim().isNotEmpty)
              .toList(),
          tips: analysisData.tips,
          nearbyCenter: analysisData.nearbyCenter,
          isDisposal: true,
          containsMicroplastics: analysisData.containsMicroplastics,
          palmOilDerivative: analysisData.palmOilDerivative,
          crueltyFree: analysisData.crueltyFree,
        );
      } catch (e) {
        debugPrint('Failed to save scan metadata: $e');
      }

      // Also persist a dedicated disposal-scans record so the Disposal
      // Guidance Recent Activity view can show only disposal-related items.
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
        final String productId = DateTime.now().millisecondsSinceEpoch
            .toString();
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('disposal_scans')
            .doc(productId);

        await docRef.set({
          'product_name': analysisData.productName,
          'productName': analysisData.productName,
          'name': analysisData.productName,
          'category': analysisData.category,
          'product_category': analysisData.category,
          'material': analysisData.packagingType,
          'packagingType': analysisData.packagingType,
          'ecoScore': analysisData.ecoScore,
          'eco_score': analysisData.ecoScore,
          'imageUrl': uploadedImageUrl ?? analysisData.imageUrl ?? '',
          'image_url': uploadedImageUrl ?? analysisData.imageUrl ?? '',
          'disposalSteps': analysisData.disposalMethod
              .split('\n')
              .where((s) => s.trim().isNotEmpty)
              .toList(),
          'disposalMethod': analysisData.disposalMethod,
          'tips': analysisData.tips.isNotEmpty
              ? analysisData.tips.split('\n')
              : [],
          'tips_text': analysisData.tips.isNotEmpty ? analysisData.tips : null,
          'nearbyCenter': analysisData.nearbyCenter,
          'nearby_center': analysisData.nearbyCenter,
          'isDisposal': true,
          'containsMicroplastics': analysisData.containsMicroplastics,
          'contains_microplastics': analysisData.containsMicroplastics,
          'palmOilDerivative': analysisData.palmOilDerivative,
          'palm_oil_derivative': analysisData.palmOilDerivative,
          'crueltyFree': analysisData.crueltyFree,
          'cruelty_free': analysisData.crueltyFree,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Failed to save disposal_scans record: $e');
      }

      final analysisToShow = uploadedImageUrl != null
          ? analysisData.copyWith(imageUrl: uploadedImageUrl)
          : analysisData;

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultDisposalScreen(analysisData: analysisToShow),
          ),
        );
      }
    } catch (e) {
      debugPrint('Analysis error: $e');
      if (mounted) {
        final err = e.toString();
        final isServiceUnavailable =
            err.contains('503') ||
            err.toUpperCase().contains('UNAVAILABLE') ||
            err.toLowerCase().contains('overloaded');

        if (isServiceUnavailable) {
          // Offer retry or save without analysis
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Analysis temporarily unavailable'),
              content: const Text(
                'The AI analysis service is currently overloaded. You can retry now, or save the photo without analysis (image will still be uploaded).',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    // Retry
                    _runAnalysis();
                  },
                  child: const Text('Retry'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _saveImageOnly();
                  },
                  child: const Text('Save without analysis'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
        }
      }
    } finally {
      setState(() => _busy = false);
    }
  }

  /// Upload image and save a minimal disposal record when analysis fails.
  Future<void> _saveImageOnly() async {
    if (_bytes == null) return;
    setState(() => _busy = true);
    try {
      String? uploadedImageUrl;
      if (isCloudinaryConfigured) {
        try {
          final productId = DateTime.now().millisecondsSinceEpoch.toString();
          uploadedImageUrl = await CloudinaryService.uploadImageBytes(
            _bytes!,
            filename: '$productId.jpg',
            cloudName: kCloudinaryCloudName,
            uploadPreset: kCloudinaryUploadPreset,
          );
        } catch (e) {
          debugPrint('Cloudinary upload failed: $e');
          uploadedImageUrl = null;
        }
      }

      // Persist a minimal record to Firestore under disposal_scans and scans
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final productId = DateTime.now().millisecondsSinceEpoch.toString();

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('disposal_scans')
          .doc(productId);

      await docRef.set({
        'product_name': (_picked != null && _picked!.name.isNotEmpty)
            ? _picked!.name
            : 'Scanned product',
        'productName': (_picked != null && _picked!.name.isNotEmpty)
            ? _picked!.name
            : 'Scanned product',
        'name': (_picked != null && _picked!.name.isNotEmpty)
            ? _picked!.name
            : 'Scanned product',
        'category': 'Unknown',
        'product_category': 'Unknown',
        'material': 'Unknown',
        'packagingType': 'Unknown',
        'ecoScore': 'N/A',
        'eco_score': 'N/A',
        'imageUrl': uploadedImageUrl ?? '',
        'image_url': uploadedImageUrl ?? '',
        'disposalSteps': <String>[],
        'disposalMethod': '',
        'tips': <String>[],
        'tips_text': '',
        'nearbyCenter': null,
        'nearby_center': null,
        'isDisposal': true,
        'containsMicroplastics': false,
        'contains_microplastics': false,
        'palmOilDerivative': false,
        'palm_oil_derivative': false,
        'crueltyFree': false,
        'cruelty_free': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also save to per-user scans collection for history
      try {
        final scansRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('scans')
            .doc(productId);
        await scansRef.set({
          'analysis': 'Saved without analysis',
          'product_name': (_picked != null && _picked!.name.isNotEmpty)
              ? _picked!.name
              : 'Scanned product',
          'eco_score': 'N/A',
          'carbon_footprint': 'N/A',
          'image_url': uploadedImageUrl ?? '',
          'category': 'Unknown',
          'packaging': 'Unknown',
          'disposalSteps': <String>[],
          'tips': <String>[],
          'nearbyCenter': null,
          'isDisposal': true,
          'containsMicroplastics': false,
          'palmOilDerivative': false,
          'crueltyFree': false,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Failed to also save to scans collection: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved image without analysis')),
        );
        Navigator.of(context).pop({
          'productId': productId,
          'imageUrl': uploadedImageUrl ?? '',
          'product_name': (_picked != null && _picked!.name.isNotEmpty)
              ? _picked!.name
              : 'Scanned product',
        });
      }
    } catch (e) {
      debugPrint('Save image only failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save image: $e')));
      }
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Scan Product for Disposal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: kPrimaryGreen,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Camera Preview / Image Display Area
          Expanded(
            child: Stack(
              children: [
                // Main content area
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child:
                        _showCamera &&
                            _isCameraInitialized &&
                            _cameraController != null
                        ? Stack(
                            children: [
                              // Live camera preview
                              Center(child: CameraPreview(_cameraController!)),
                              // Flash toggle button
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      _flashMode == FlashMode.off
                                          ? Icons.flash_off
                                          : Icons.flash_on,
                                      color: _flashMode == FlashMode.off
                                          ? Colors.white
                                          : kPrimaryYellow,
                                    ),
                                    onPressed: _toggleFlash,
                                  ),
                                ),
                              ),
                              // Close camera button
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    onPressed: _stopCamera,
                                  ),
                                ),
                              ),
                              // Capture button at bottom
                              Positioned(
                                bottom: 20,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: kPrimaryGreen.withOpacity(0.5),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.white,
                                      shape: const CircleBorder(),
                                      child: InkWell(
                                        onTap: _busy ? null : _capturePhoto,
                                        customBorder: const CircleBorder(),
                                        child: Container(
                                          width: 70,
                                          height: 70,
                                          padding: const EdgeInsets.all(4),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: kPrimaryGreen,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 3,
                                              ),
                                            ),
                                            child: _busy
                                                ? const Padding(
                                                    padding: EdgeInsets.all(12),
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 3,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.camera_alt,
                                                    color: Colors.white,
                                                    size: 28,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Camera guide
                              Center(
                                child: Container(
                                  width: 280,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: kPrimaryGreen.withOpacity(0.7),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _picked != null
                        ? Stack(
                            children: [
                              // Display picked image
                              Center(
                                child: Image.memory(
                                  _bytes!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              // Confirmation overlay
                              if (!_photoConfirmed)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.8),
                                        ],
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        // Retake button
                                        _buildActionButton(
                                          icon: Icons.refresh,
                                          label: 'Retake',
                                          onPressed: _busy
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _picked = null;
                                                    _bytes = null;
                                                    _photoConfirmed = false;
                                                  });
                                                },
                                          backgroundColor: Colors.white
                                              .withOpacity(0.2),
                                        ),
                                        // Use Photo button
                                        _buildActionButton(
                                          icon: Icons.check_circle,
                                          label: 'Use Photo',
                                          onPressed: _busy
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _photoConfirmed = true;
                                                  });
                                                },
                                          backgroundColor: kPrimaryGreen,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: 80,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Take or select a product photo',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'AI will analyze the product for disposal guidance',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                // Busy indicator overlay
                if (_busy)
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                kPrimaryGreen,
                              ),
                              strokeWidth: 4,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Analyzing...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Control Panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick actions row
                  Row(
                    children: [
                      Expanded(
                        child: _buildControlButton(
                          icon: Icons.cameraswitch,
                          label: 'Switch Camera',
                          onPressed: (_busy || !_showCamera)
                              ? null
                              : _switchCamera,
                          backgroundColor: kPrimaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildControlButton(
                          icon: Icons.photo_library,
                          label: 'Gallery',
                          onPressed: _busy
                              ? null
                              : () => _pick(ImageSource.gallery),
                          backgroundColor: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),

                  if (_photoConfirmed) ...[
                    const SizedBox(height: 16),
                    // Analyze button when photo is confirmed
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _runAnalysis,
                        icon: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                              ),
                        label: Text(
                          _busy ? 'Analyzing...' : 'Analyze with AI',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],

                  // Info text
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kPrimaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kPrimaryGreen.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: kPrimaryGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _showCamera
                                ? 'Position product within the frame and tap the capture button'
                                : 'Camera will start automatically or select from gallery',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build action buttons
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color backgroundColor,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build control buttons
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color backgroundColor,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 22),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
