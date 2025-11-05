import 'dart:typed_data';

// Assuming the existence of these files
// import 'package:ecopilot_test/utils/cloudinary_config.dart';
// import 'package:ecopilot_test/services/cloudinary_service.dart';
// import 'package:ecopilot_test/utils/constants.dart';

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
import 'package:ecopilot_test/utils/constants.dart';
import 'package:ecopilot_test/screens/result_disposal_screen.dart';

// Placeholder definitions for Cloudinary configuration
const bool isCloudinaryConfigured = false;
const String cloudinaryCloudName = 'dwxpph0wt';
const String cloudinaryUploadPreset = 'unsigned_upload';

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
    if (isCloudinaryConfigured && cloudName != 'dwxpph0wt') {
      return 'https://res.cloudinary.com/$cloudName/image/upload/v1/$filename';
    }

    // Fall back to Firebase Storage via FirebaseService if Cloudinary not configured
    try {
      final url = await FirebaseService().uploadScannedImage(
        bytes: bytes,
        fileName: filename,
      );
      return url;
    } catch (e) {
      debugPrint('Firebase fallback upload failed: $e');
      return 'https://placehold.co/600x800/A8D8B9/212121?text=Product+Image';
    }
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

      setState(() {
        _scanningEnabled = true;
      });
    } catch (e) {
      debugPrint('Scanner init failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _toggleFlash() async {
    try {
      await _mobileScannerController.toggleTorch();
      setState(() => _torchOn = !_torchOn);
    } catch (e) {
      debugPrint('Flash toggle failed: $e');
    }
  }

  // Small local simulator kept for offline testing
  Future<Map<String, dynamic>> _simulateAnalyze(Uint8List bytes) async {
    await Future.delayed(const Duration(seconds: 1));
    final isYogurt = bytes.length % 2 == 0;
    return {
      'name': isYogurt ? 'Coconut Yogurt' : 'Shampoo 2',
      'category': isYogurt ? 'Food' : 'Cosmetic',
      'material': 'Plastic',
      'ecoScore': isYogurt ? 'C' : 'A',
      'disposalSteps': isYogurt
          ? [
              'Rinse the container thoroughly to remove all food residue.',
              'Place the plastic container in the designated mixed plastics bin.',
            ]
          : [
              'Empty the bottle completely.',
              'Separate the cap if different material.',
            ],
      'tips': isYogurt
          ? ['Compost any residual food.']
          : ['Consider refillable alternatives.'],
    };
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
        );
      } catch (e) {
        debugPrint('Failed to save barcode scan: $e');
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
        // No API key — use the local simulator and convert to ProductAnalysisData
        final result = await _simulateAnalyze(_bytes!);
        outputText = result.toString();
        final tempFile = (_picked != null && _picked!.path.isNotEmpty)
            ? File(_picked!.path)
            : null;
        analysisData = ProductAnalysisData(
          imageFile: tempFile,
          productName: result['name'] ?? 'N/A',
          category: result['category'] ?? 'N/A',
          ecoScore: result['ecoScore'] ?? 'N/A',
          packagingType: result['material'] ?? 'N/A',
          disposalMethod: (result['disposalSteps'] is List)
              ? (result['disposalSteps'] as List).join('\n')
              : 'N/A',
        );
      } else {
        // Use Gemini via google_generative_ai
        final model = GenerativeModel(
          model: 'models/gemini-2.5-pro',
          apiKey: _geminiApiKey,
        );

        const prompt = '''
You are an eco-disposal assistant AI. Analyze the uploaded or scanned product image and provide clear, structured information for a disposal guidance app. 
Follow this exact format. Use 'N/A' if any detail is not visible or available.

Product name?: [Exact product name as seen or recognized, e.g., Plastic Bottle]
Material?: [Primary material, e.g., PET Plastic, Glass, Aluminum, Paperboard]
Eco Score?: [Eco rating A–E, based on recyclability and environmental impact]
How to Dispose?:
1. [Step 1 for proper disposal, e.g., Rinse the bottle to remove residue]
2. [Step 2, e.g., Separate the cap and label]
3. [Step 3, e.g., Place in the plastic recycling bin]
Nearby Recycling Center?: [Example name, e.g., Green Recycling Center, or N/A if not applicable]
Eco Tips?: [One sustainability tip related to the product, e.g., Reuse bottles for storage before recycling]
''';

        final content = [
          Content.multi([TextPart(prompt), DataPart('image/jpeg', _bytes!)]),
        ];

        final response = await model.generateContent(content);
        outputText = response.text ?? 'No analysis result.';

        final tempFile = (_picked != null && _picked!.path.isNotEmpty)
            ? File(_picked!.path)
            : null;

        analysisData = ProductAnalysisData.fromGeminiOutput(
          outputText,
          imageFile: tempFile,
        );
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
        );
      } catch (e) {
        debugPrint('Failed to save scan metadata: $e');
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
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
                                      setState(() {
                                        _analysis = {
                                          'barcode': raw,
                                          'name': 'Scanned barcode',
                                          'category': 'N/A',
                                        };
                                      });
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Barcode: $raw'),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      }
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
                            // If scanner already enabled, try starting it, otherwise init
                            if (_scanningEnabled) {
                              try {
                                await _mobileScannerController.start();
                              } catch (_) {
                                await _initScanner();
                              }
                            } else {
                              await _initScanner();
                            }
                          },
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text(
                      'Open Camera',
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
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_analysis == null || _busy || _bytes == null)
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
