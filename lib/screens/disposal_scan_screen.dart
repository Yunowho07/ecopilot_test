import 'dart:typed_data';

import 'package:ecopilot_test/utils/cloudinary_config.dart';
import 'package:ecopilot_test/services/cloudinary_service.dart';
import 'package:ecopilot_test/utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
      });
    } catch (e) {
      debugPrint('Image pick failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<Map<String, dynamic>> _analyzeImage(Uint8List bytes) async {
    // In a production app you'd call Google Gemini / google_generative_ai here.
    // For now we return a simulated response based on simple heuristics.
    await Future.delayed(const Duration(seconds: 1));

    // Very small heuristic: choose a name & material randomly for demo
    final simulated = <String, dynamic>{
      'name': 'Sample Bottle',
      'material': 'PET Plastic',
      'ecoScore': 'A',
      'materials': ['PET Plastic', 'Label (Paper)'],
      'disposalSteps': [
        'Rinse the container to remove residue.',
        'Remove cap and label if required by local recycling.',
        'Place in plastic recycling bin.',
      ],
      'tips': [
        'Reuse containers before recycling.',
        'Crush bottles to save space in bins.',
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Analysis failed')));
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
      if (_bytes != null && isCloudinaryConfigured) {
        final uploaded = await CloudinaryService.uploadImageBytes(
          _bytes!,
          filename: '$productId.jpg',
          cloudName: kCloudinaryCloudName,
          uploadPreset: kCloudinaryUploadPreset,
        );
        if (uploaded != null) product['imageUrl'] = uploaded;
      }
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
        'ecoScore': product['ecoScore'] ?? 'N/A',
        'imageUrl': product['imageUrl'] ?? '',
        'materials': product['materials'] ?? [],
        'disposalSteps': product['disposalSteps'] ?? [],
        'tips': product['tips'] ?? [],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed saving scan: $e');
    }

    setState(() => _busy = false);

    // Return the product to the caller so it can be shown in Recent Activity
    if (mounted) Navigator.of(context).pop(product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product'),
        backgroundColor: kPrimaryGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: _picked == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No image selected',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      )
                    : Image.memory(_bytes!, fit: BoxFit.contain),
              ),
            ),

            if (_analysis != null) ...[
              const Divider(),
              Text(
                'Name: ${'${_analysis!['name'] ?? ''}'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Materials: ${((_analysis!['materials'] ?? []) as List).join(', ')}',
              ),
              const SizedBox(height: 8),
              Text('Eco Score: ${_analysis!['ecoScore'] ?? 'N/A'}'),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
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
                    onPressed: (_bytes == null || _busy) ? null : _runAnalysis,
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Analyze'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_analysis == null || _busy)
                        ? null
                        : _saveAndReturn,
                    child: const Text('Save & Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
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
