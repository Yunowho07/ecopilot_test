import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecopilot_test/utils/constants.dart';
import 'package:ecopilot_test/utils/cloudinary_config.dart';
import 'package:ecopilot_test/services/cloudinary_service.dart';
import 'package:ecopilot_test/models/product_analysis_data.dart';
import 'package:ecopilot_test/auth/firebase_service.dart';
import 'package:ecopilot_test/screens/result_disposal_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({Key? key}) : super(key: key);

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  bool _torchOn = false;
  String? _scannedBarcode;

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  Future<void> _initScanner() async {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    try {
      await _controller!.toggleTorch();
      setState(() {
        _torchOn = !_torchOn;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _handleBarcode(String barcode) async {
    if (_isProcessing || barcode.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _scannedBarcode = barcode;
    });

    try {
      // Try Open Food Facts first
      Map<String, dynamic>? productData = await _fetchFromOpenFoodFacts(
        barcode,
      );

      // If not found, try Open Beauty Facts
      if (productData == null || productData.isEmpty) {
        productData = await _fetchFromOpenBeautyFacts(barcode);
      }

      if (productData != null && productData.isNotEmpty) {
        // Product found, now analyze with Gemini
        await _analyzeWithGemini(productData, barcode);
      } else {
        // Product not found in databases
        if (mounted) {
          _showProductNotFoundDialog(barcode);
        }
      }
    } catch (e) {
      debugPrint('Error processing barcode: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchFromOpenFoodFacts(String barcode) async {
    try {
      final url =
          'https://world.openfoodfacts.org/api/v2/product/$barcode.json';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          return {
            'name': product['product_name'] ?? 'Unknown Product',
            'brand': product['brands'] ?? '',
            'category': product['categories'] ?? 'Food & Beverages',
            'ingredients': product['ingredients_text'] ?? '',
            'packaging':
                product['packaging'] ?? product['packaging_text'] ?? '',
            'image_url':
                product['image_url'] ?? product['image_front_url'] ?? '',
            'barcode': barcode,
            'source': 'Open Food Facts',
          };
        }
      }
    } catch (e) {
      debugPrint('Error fetching from Open Food Facts: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchFromOpenBeautyFacts(
    String barcode,
  ) async {
    try {
      final url =
          'https://world.openbeautyfacts.org/api/v2/product/$barcode.json';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          return {
            'name': product['product_name'] ?? 'Unknown Product',
            'brand': product['brands'] ?? '',
            'category': product['categories'] ?? 'Personal Care',
            'ingredients': product['ingredients_text'] ?? '',
            'packaging':
                product['packaging'] ?? product['packaging_text'] ?? '',
            'image_url':
                product['image_url'] ?? product['image_front_url'] ?? '',
            'barcode': barcode,
            'source': 'Open Beauty Facts',
          };
        }
      }
    } catch (e) {
      debugPrint('Error fetching from Open Beauty Facts: $e');
    }
    return null;
  }

  Future<void> _analyzeWithGemini(
    Map<String, dynamic> productData,
    String barcode,
  ) async {
    final geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    if (geminiApiKey.isEmpty) {
      // No Gemini API, create basic analysis from product data
      await _saveAndNavigate(productData, null);
      return;
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: geminiApiKey,
      );

      final prompt =
          '''
Analyze this product for eco-friendly disposal guidance:

Product Name: ${productData['name']}
Brand: ${productData['brand']}
Category: ${productData['category']}
Ingredients: ${productData['ingredients']}
Packaging: ${productData['packaging']}
Barcode: $barcode

Provide a detailed disposal analysis in JSON format with these fields:
{
  "product_name": "Full product name",
  "category": "Category (Food & Beverages, Personal Care, etc.)",
  "packaging_type": "Detailed packaging materials",
  "ingredients": "List of ingredients",
  "eco_score": "A-E rating based on recyclability and environmental impact",
  "carbon_footprint": "Estimated CO2e",
  "disposal_steps": ["Step 1", "Step 2", "Step 3"],
  "nearby_center": "Type of recycling center needed",
  "tips": ["Eco tip 1", "Eco tip 2"],
  "contains_microplastics": true/false,
  "palm_oil_derivative": true/false,
  "cruelty_free": true/false (if applicable)
}

Return ONLY the JSON object, no additional text.
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final outputText = response.text ?? '';

      // Parse JSON response
      Map<String, dynamic>? analysisData;
      try {
        final decoded = json.decode(outputText);
        if (decoded is Map<String, dynamic>) {
          analysisData = decoded;
        }
      } catch (_) {
        // Try to extract JSON from text
        final jsonStart = outputText.indexOf('{');
        final jsonEnd = outputText.lastIndexOf('}');
        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final jsonStr = outputText.substring(jsonStart, jsonEnd + 1);
          try {
            final decoded = json.decode(jsonStr);
            if (decoded is Map<String, dynamic>) {
              analysisData = decoded;
            }
          } catch (_) {}
        }
      }

      if (analysisData != null) {
        // Merge product data with Gemini analysis
        final mergedData = {
          ...productData,
          ...analysisData,
          'image_url': productData['image_url'],
        };
        await _saveAndNavigate(mergedData, outputText);
      } else {
        // Fallback: use product data without AI analysis
        await _saveAndNavigate(productData, outputText);
      }
    } catch (e) {
      debugPrint('Gemini analysis error: $e');
      // Fallback to basic product data
      await _saveAndNavigate(productData, null);
    }
  }

  Future<void> _saveAndNavigate(
    Map<String, dynamic> data,
    String? aiOutput,
  ) async {
    try {
      // Upload image to Cloudinary if available
      String? cloudinaryImageUrl;
      final sourceImageUrl = data['image_url'] ?? '';

      if (sourceImageUrl.isNotEmpty && isCloudinaryConfigured) {
        try {
          // Download image from Open Food Facts/Open Beauty Facts
          final imageResponse = await http.get(Uri.parse(sourceImageUrl));

          if (imageResponse.statusCode == 200) {
            final imageBytes = imageResponse.bodyBytes;
            final barcode =
                data['barcode'] ??
                DateTime.now().millisecondsSinceEpoch.toString();

            // Upload to Cloudinary
            cloudinaryImageUrl = await CloudinaryService.uploadImageBytes(
              imageBytes,
              filename: 'barcode_$barcode.jpg',
              cloudName: kCloudinaryCloudName,
              uploadPreset: kCloudinaryUploadPreset,
            );

            debugPrint('Image uploaded to Cloudinary: $cloudinaryImageUrl');
          }
        } catch (e) {
          debugPrint('Error uploading to Cloudinary: $e');
          // Fallback to original image URL
          cloudinaryImageUrl = sourceImageUrl;
        }
      } else if (sourceImageUrl.isNotEmpty) {
        // Cloudinary not configured, use original URL
        cloudinaryImageUrl = sourceImageUrl;
      }

      // Create ProductAnalysisData from the merged data
      final analysisData = ProductAnalysisData(
        productName: data['product_name'] ?? data['name'] ?? 'Unknown Product',
        category: data['category'] ?? 'General',
        ingredients: data['ingredients'] ?? '',
        ecoScore: data['eco_score'] ?? data['ecoScore'] ?? 'N/A',
        carbonFootprint:
            data['carbon_footprint'] ?? data['carbonFootprint'] ?? 'N/A',
        packagingType: data['packaging_type'] ?? data['packaging'] ?? 'Unknown',
        disposalMethod: (data['disposal_steps'] is List)
            ? (data['disposal_steps'] as List).join('\n')
            : (data['disposal_steps'] ?? ''),
        tips: (data['tips'] is List)
            ? (data['tips'] as List).join('\n')
            : (data['tips'] ?? ''),
        nearbyCenter: data['nearby_center'] ?? data['nearbyCenter'] ?? '',
        imageUrl: cloudinaryImageUrl ?? '', // Use Cloudinary URL
        containsMicroplastics:
            data['contains_microplastics'] ??
            data['containsMicroplastics'] ??
            false,
        palmOilDerivative:
            data['palm_oil_derivative'] ?? data['palmOilDerivative'] ?? false,
        crueltyFree: data['cruelty_free'] ?? data['crueltyFree'] ?? false,
      );

      // Save to Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final productId =
          data['barcode'] ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Save to disposal_scans collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('disposal_scans')
          .doc(productId)
          .set({
            'product_name': analysisData.productName,
            'productName': analysisData.productName,
            'name': analysisData.productName,
            'category': analysisData.category,
            'product_category': analysisData.category,
            'material': analysisData.packagingType,
            'packagingType': analysisData.packagingType,
            'ecoScore': analysisData.ecoScore,
            'eco_score': analysisData.ecoScore,
            'imageUrl': analysisData.imageUrl, // Cloudinary URL
            'image_url': analysisData.imageUrl, // Cloudinary URL
            'disposalSteps': analysisData.disposalMethod
                .split('\n')
                .where((s) => s.trim().isNotEmpty)
                .toList(),
            'disposalMethod': analysisData.disposalMethod,
            'tips': analysisData.tips.isNotEmpty
                ? analysisData.tips.split('\n')
                : [],
            'tips_text': analysisData.tips,
            'nearbyCenter': analysisData.nearbyCenter,
            'nearby_center': analysisData.nearbyCenter,
            'isDisposal': true,
            'containsMicroplastics': analysisData.containsMicroplastics,
            'contains_microplastics': analysisData.containsMicroplastics,
            'palmOilDerivative': analysisData.palmOilDerivative,
            'palm_oil_derivative': analysisData.palmOilDerivative,
            'crueltyFree': analysisData.crueltyFree,
            'cruelty_free': analysisData.crueltyFree,
            'barcode': data['barcode'],
            'source': data['source'] ?? 'Barcode Scanner',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Also save to scans collection
      await FirebaseService().saveUserScan(
        analysis: aiOutput ?? 'Scanned from ${data['source'] ?? 'barcode'}',
        productName: analysisData.productName,
        ecoScore: analysisData.ecoScore,
        carbonFootprint: analysisData.carbonFootprint,
        imageUrl: analysisData.imageUrl, // Cloudinary URL
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

      if (mounted) {
        // Navigate to result screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultDisposalScreen(analysisData: analysisData),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving product: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving product: $e')));
      }
    }
  }

  void _showProductNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Not Found'),
        content: Text(
          'The product with barcode "$barcode" was not found in Open Food Facts or Open Beauty Facts databases.\n\nPlease try scanning a different product or use the camera to capture a product photo instead.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _scannedBarcode = null;
              });
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'Scan Barcode',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Camera Scanner
          if (_controller != null)
            MobileScanner(
              controller: _controller!,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && !_isProcessing) {
                  final barcode = barcodes.first;
                  if (barcode.rawValue != null) {
                    _handleBarcode(barcode.rawValue!);
                  }
                }
              },
            ),

          // Scanning overlay
          if (!_isProcessing)
            Center(
              child: Container(
                width: 300,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: kPrimaryGreen, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    // Corner accents
                    ...List.generate(4, (index) {
                      return Positioned(
                        top: index < 2 ? 0 : null,
                        bottom: index >= 2 ? 0 : null,
                        left: index % 2 == 0 ? 0 : null,
                        right: index % 2 == 1 ? 0 : null,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kPrimaryGreen,
                            borderRadius: BorderRadius.only(
                              topLeft: index == 0
                                  ? const Radius.circular(17)
                                  : Radius.zero,
                              topRight: index == 1
                                  ? const Radius.circular(17)
                                  : Radius.zero,
                              bottomLeft: index == 2
                                  ? const Radius.circular(17)
                                  : Radius.zero,
                              bottomRight: index == 3
                                  ? const Radius.circular(17)
                                  : Radius.zero,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          // Instruction text
          if (!_isProcessing)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Position barcode within the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Flash toggle button
          if (!_isProcessing)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _torchOn ? Icons.flash_on : Icons.flash_off,
                    color: _torchOn ? kPrimaryYellow : Colors.white,
                  ),
                  onPressed: _toggleFlash,
                ),
              ),
            ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(kPrimaryGreen),
                      strokeWidth: 4,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Processing Barcode',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_scannedBarcode != null)
                            Text(
                              _scannedBarcode!,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            'Searching databases...',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
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
}
