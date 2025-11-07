import 'dart:typed_data';

import 'package:ecopilot_test/utils/cloudinary_config.dart';
import 'package:ecopilot_test/services/cloudinary_service.dart';
import 'package:ecopilot_test/utils/constants.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// Use MobileScanner for live barcode scanning preview
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:ecopilot_test/models/product_analysis_data.dart';
import 'package:ecopilot_test/auth/firebase_service.dart';
import 'package:ecopilot_test/screens/result_disposal_screen.dart';

// CloudinaryService and config are implemented in lib/services and lib/utils.

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

  // Mobile scanner controller for live barcode scanning
  final MobileScannerController _mobileScannerController =
      MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _scanningEnabled = false;
  bool _torchOn = false;
  // track whether a barcode result is being processed (read but not used elsewhere)

  @override
  void initState() {
    super.initState();
    // Initialize the live scanner automatically when screen opens
    _initScanner();
  }

  @override
  void dispose() {
    try {
      _mobileScannerController.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      setState(() {
        _busy = true;
        _analysis = null;
      });
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
      // If user picked an image from gallery, stop live scanning to save resources
      try {
        await _mobileScannerController.stop();
      } catch (_) {}
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

  // Initialize the mobile scanner (requests permission and enables scanning)
  Future<void> _initScanner() async {
    try {
      setState(() => _busy = true);

      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final result = await Permission.camera.request();
        // If still not granted, surface helpful UI. If permanently denied offer settings.
        if (!result.isGranted) {
          if (mounted) {
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Camera permission required'),
                content: const Text(
                  'Please allow camera access to scan products. You can enable it in app settings.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await openAppSettings();
                    },
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }

      // Try to start the MobileScanner controller so the preview begins.
      try {
        await _mobileScannerController.start();
      } catch (e) {
        debugPrint('MobileScanner start failed: $e');
      }

      // Mark scanning enabled so UI shows live preview.
      if (mounted) {
        setState(() {
          _scanningEnabled = true;
        });
      }
    } catch (e) {
      debugPrint('Scanner init failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Local simulator used when Gemini API key is not configured or fails.
  /// Returns a map in the same shape other barcode lookups produce so the
  /// rest of the flow can build a ProductAnalysisData from it.
  // NOTE: Removed the previous local simulator fallback. Image analysis
  // now requires a configured Gemini API key. If it's not present we
  // inform the user and do not attempt to fabricate results.

  Future<void> _toggleFlash() async {
    try {
      await _mobileScannerController.toggleTorch();
      setState(() => _torchOn = !_torchOn);
    } catch (e) {
      debugPrint('Flash toggle failed: $e');
    }
  }

  // Handle barcode lookups using OpenFoodFacts and OpenBeautyFacts
  Future<void> _handleBarcode(String code) async {
    if (code.isEmpty) return;
    // mark as processing (legacy flag removed)
    setState(() => _busy = true);

    // stop scanning to avoid duplicates
    try {
      await _mobileScannerController.stop();
    } catch (_) {}

    Map<String, dynamic>? product;
    String? imageUrl;
    String apiResultText = '';

    try {
      // Try OpenFoodFacts
      final foodUrl = Uri.parse(
        'https://world.openfoodfacts.org/api/v0/product/$code.json',
      );
      final r = await http.get(foodUrl).timeout(const Duration(seconds: 6));
      if (r.statusCode == 200) {
        final Map<String, dynamic> j = json.decode(r.body);
        if ((j['status'] ?? 0) == 1) {
          final p = j['product'] ?? {};
          final name =
              (p['product_name'] ?? p['product_name_en']) ?? 'Unknown product';
          imageUrl = p['image_front_url'] ?? p['image_url'];
          product = {
            'name': name,
            'category': p['categories'] ?? 'Food',
            'material': p['packaging'] ?? 'Unknown',
            'ecoScore': 'N/A',
            'disposalSteps': ['Check local recycling rules for packaging.'],
            'tips': ['Reduce single-use packaging when possible.'],
            'barcode': code,
          };
          apiResultText = r.body;
        }
      }

      // If not found, try OpenBeautyFacts
      if (product == null) {
        final beautyUrl = Uri.parse(
          'https://world.openbeautyfacts.org/api/v0/product/$code.json',
        );
        final r2 = await http
            .get(beautyUrl)
            .timeout(const Duration(seconds: 6));
        if (r2.statusCode == 200) {
          final Map<String, dynamic> j = json.decode(r2.body);
          if ((j['status'] ?? 0) == 1) {
            final p = j['product'] ?? {};
            final name =
                (p['product_name'] ?? p['product_name_en']) ??
                'Unknown product';
            imageUrl = p['image_front_url'] ?? p['image_url'];
            product = {
              'name': name,
              'category': p['categories'] ?? 'Cosmetic',
              'material': p['packaging'] ?? 'Unknown',
              'ecoScore': 'N/A',
              'disposalSteps': [
                'Follow local guidelines for cosmetics and hazardous waste.',
              ],
              'tips': ['Prefer solid bars to reduce packaging.'],
              'barcode': code,
            };
            apiResultText = r2.body;
          }
        }
      }
    } catch (e) {
      debugPrint('Barcode lookup failed: $e');
    }

    if (product != null) {
      // Build ProductAnalysisData and persist simple record
      final analysisData = ProductAnalysisData(
        imageFile: null,
        imageUrl: imageUrl,
        productName: product['name'] ?? 'Scanned product',
        category: product['category'] ?? 'N/A',
        ingredients: 'N/A',
        carbonFootprint: 'N/A',
        packagingType: product['material'] ?? 'Unknown',
        disposalMethod: (product['disposalSteps'] is List)
            ? (product['disposalSteps'] as List).join('\n')
            : (product['disposalSteps'] ?? 'N/A'),
        ecoScore: (product['ecoScore'] ?? 'N/A'),
      );

      try {
        await FirebaseService().saveUserScan(
          analysis: apiResultText.isNotEmpty
              ? apiResultText
              : json.encode(product),
          productName: analysisData.productName,
          ecoScore: analysisData.ecoScore,
          carbonFootprint: analysisData.carbonFootprint,
          imageUrl: imageUrl,
          category: analysisData.category,
          packagingType: analysisData.packagingType,
          disposalSteps: product['disposalSteps'] is List
              ? product['disposalSteps']
              : null,
          tips: product['tips'] is String
              ? product['tips']
              : (product['tips'] is List
                    ? (product['tips'] as List).join('\n')
                    : null),
          nearbyCenter: product['nearbyCenter'] ?? null,
          isDisposal: true,
        );
      } catch (e) {
        debugPrint('Failed to save barcode scan: $e');
      }

      // Also create a disposal_scans document so Disposals view shows this item
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
          'category': analysisData.category,
          'material': analysisData.packagingType,
          'ecoScore': analysisData.ecoScore,
          'imageUrl': imageUrl ?? analysisData.imageUrl ?? '',
          'disposalSteps': product['disposalSteps'] is List
              ? product['disposalSteps']
              : (product['disposalSteps'] is String
                    ? [product['disposalSteps']]
                    : []),
          'tips': product['tips'] is List
              ? product['tips']
              : (product['tips'] is String ? [product['tips']] : []),
          'nearbyCenter': product['nearbyCenter'] ?? null,
          'isDisposal': true,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Failed to save disposal_scans record for barcode: $e');
      }

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultDisposalScreen(analysisData: analysisData),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No product found for barcode $code')),
        );
      }
      // allow scanning again after short delay
      await Future.delayed(const Duration(seconds: 1));
      try {
        await _mobileScannerController.start();
      } catch (_) {}
      // processing finished
    }

    setState(() => _busy = false);
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
          model: 'models/gemini-2.5-pro',
          apiKey: _geminiApiKey,
        );

        const prompt = '''
You are an eco-disposal assistant AI. Analyze the uploaded or scanned product image and return ONLY a single JSON object (no additional text) that contains the following keys when available. Use 'N/A' or empty lists/false for missing values.

- product name: [Product Name]
- category: [Product Category, e.g., Food & Beverages (F&B), Personal Care, Household Products, Electronics, Clothing & Accessories, Health & Medicine, Baby & Kids, Pet Supplies, Automotive, Home & Furniture]
- ingredients: [List of ingredients, comma-separated, e.g., Water, Zinc Oxide, etc.]
- eco-friendliness rating: [A, B, C, D, E or etc.]
- carbon Footprint: [Estimated CO2e per unit, e.g., 0.36 kg CO2e per unit]
- packaging type: [Material and recyclability, e.g., Plastic Tube - Recyclable (Type 4 - LDPE)]
- disposal_steps (array of strings)
- nearby_center (string)
- tips (array of strings)

Example valid response (JSON only):
{
  "product_name": "Plastic Bottle - Sparkling Water",
  "category": "Food & Beverages (F&B)",
  "packaging_type": "PET Plastic",
  "ingredients": "Water, Carbon Dioxide",
  "eco_score": "C",
  "carbon_footprint": "0.15 kg CO2e",
  "disposal_steps": ["Rinse the bottle", "Remove cap", "Place in plastic recycling bin"],
  "nearby_center": "Green Recycling Center",
  "tips": ["Refill and reuse before recycling"],
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
          // keep analysis map for potential save/return
          _analysis = parsedMap;
        } else {
          // If the model returned free-form text, parse via the existing parser which
          // extracts fields from Gemini-style responses. This still comes from Gemini
          // (no local simulation) — we only parse the original AI text.
          analysisData = ProductAnalysisData.fromGeminiOutput(
            outputText,
            imageFile: tempFile,
          );
          _analysis = {
            'name': analysisData.productName,
            'category': analysisData.category,
            'material': analysisData.packagingType,
            'ecoScore': analysisData.ecoScore,
            'disposalSteps': analysisData.disposalMethod
                .split('\n')
                .where((s) => s.trim().isNotEmpty)
                .toList(),
            'tips': analysisData.tips,
            'nearbyCenter': analysisData.nearbyCenter,
            'containsMicroplastics': analysisData.containsMicroplastics,
            'palmOilDerivative': analysisData.palmOilDerivative,
            'crueltyFree': analysisData.crueltyFree,
          };
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
          packagingType: analysisData.packagingType,
          disposalSteps: analysisData.disposalMethod
              .split('\n')
              .where((s) => s.trim().isNotEmpty)
              .toList(),
          tips: analysisData.tips,
          nearbyCenter: analysisData.nearbyCenter,
          isDisposal: true,
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
          'category': analysisData.category,
          'material': analysisData.packagingType,
          'ecoScore': analysisData.ecoScore,
          'imageUrl': uploadedImageUrl ?? analysisData.imageUrl ?? '',
          'disposalSteps': analysisData.disposalMethod
              .split('\n')
              .where((s) => s.trim().isNotEmpty)
              .toList(),
          'tips': analysisData.tips,
          'nearbyCenter': analysisData.nearbyCenter,
          'isDisposal': true,
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
        'category': 'Unknown',
        'material': 'Unknown',
        'ecoScore': 'N/A',
        'imageUrl': uploadedImageUrl ?? '',
        'disposalSteps': <String>[],
        'tips': <String>[],
        'nearbyCenter': null,
        'isDisposal': true,
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

  Future<void> _saveAndReturn() async {
    if (_analysis == null) return;
    setState(() => _busy = true);

    final Map<String, dynamic> product = Map<String, dynamic>.from(_analysis!);
    final String productId = DateTime.now().millisecondsSinceEpoch.toString();
    product['productId'] = productId;

    // Upload image to Cloudinary (required for image storage)
    if (isCloudinaryConfigured) {
      try {
        final imageUrl = await CloudinaryService.uploadImageBytes(
          _bytes!,
          filename: '$productId.jpg',
          cloudName: kCloudinaryCloudName,
          uploadPreset: kCloudinaryUploadPreset,
        );
        if (imageUrl != null) product['imageUrl'] = imageUrl;
      } catch (e) {
        debugPrint('Cloudinary upload failed: $e');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cloudinary not configured. Set CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET in .env',
            ),
          ),
        );
      }
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
        backgroundColor: kPrimaryGreen,
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
                          : _scanningEnabled
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                // Live barcode scanner preview
                                MobileScanner(
                                  controller: _mobileScannerController,
                                  fit: BoxFit.cover,
                                  onDetect: (capture) {
                                    final List<Barcode> barcodes =
                                        capture.barcodes;
                                    if (barcodes.isNotEmpty) {
                                      final raw = barcodes.first.rawValue ?? '';
                                      // Delegate barcode handling to the lookup method
                                      if (!_busy) _handleBarcode(raw);
                                    }
                                  },
                                ),
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
                                // Capture button bottom center (opens native camera capture)
                                Positioned(
                                  bottom: 20,
                                  child: GestureDetector(
                                    onTap: _busy
                                        ? null
                                        : () => _pick(ImageSource.camera),
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
                                if (_scanningEnabled) {
                                  await _mobileScannerController.start();
                                } else {
                                  await _initScanner();
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
                        backgroundColor: kPrimaryGreen,
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
                'Analysis Result',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Product: ${_analysis!['name'] ?? _analysis!['product_name'] ?? 'N/A'}',
              ),
              Text(
                'Category: ${_analysis!['category'] ?? _analysis!['Category'] ?? 'N/A'}',
              ),
              Text(
                'Material: ${_analysis!['material'] ?? _analysis!['material'] ?? 'N/A'}',
              ),
              Text(
                'Eco Score: ${_analysis!['ecoScore'] ?? _analysis!['eco_score'] ?? 'N/A'}',
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                // Capture button (opens native camera capture) - replaces "Open Camera"
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text(
                      'Capture',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
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
                      backgroundColor: kPrimaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Removed "Save & View Details" per request. Keep space for layout balance.
                Expanded(child: Container()),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
