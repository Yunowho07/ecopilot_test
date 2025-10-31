import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'alternative_screen.dart';

// Style constants for easy tuning
const Color _kPrimaryGreen = Color(0xFF1DB954);
const Color _kAccentYellow = Color(0xFFFFC300);
const double _kCardRadius = 16.0;
const double _kResultBorderWidth = 3.0;
const double _kContentPadding = 14.0;

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _imageFile;
  bool _isLoading = false;
  String _result = '';
  late final String _geminiApiKey;

  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _lastSavedResult;

  @override
  void initState() {
    super.initState();
    _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _result = '';
      });

      await _analyzeImage(_imageFile!);
    }
  }

  Future<void> _takePhoto() async {
    // Request camera permission by trying to pick an image from camera
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _result = '';
        });
        await _analyzeImage(_imageFile!);
      }
    } catch (e) {
      setState(() {
        _result = 'Failed to open camera: $e';
      });
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      if (_geminiApiKey.isEmpty) {
        throw Exception(
          "Gemini API key not found. Please check your .env file.",
        );
      }

      final model = GenerativeModel(
        model: 'models/gemini-2.5-pro',
        apiKey: _geminiApiKey,
      );

      final imageBytes = await imageFile.readAsBytes();

      const prompt = """
You are an eco-expert AI. Analyze the uploaded product image and describe clearly:
1. Product name (if visible)
2. Material or packaging type
3. Eco-friendliness rating (A+ to E)
4. Environmental impact summary
5. Suggested greener alternatives
6. Recommended disposal method
      """;

      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      final response = await model.generateContent(content);
      final outputText = response.text ?? "No analysis result.";

      setState(() {
        _result = outputText;
      });

      final imageUrl = await _saveScanToFirebase(imageFile, outputText);

      // Build a structured result to return to HomeScreen if user chooses
      _lastSavedResult = {
        'product': _extractProductName(outputText) ?? 'Scanned product',
        'raw': {
          'analysis': outputText,
          'image_url': imageUrl ?? '',
          'date': DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now()),
        },
      };
    } catch (e) {
      setState(() {
        _result = "⚠️ Error analyzing image:\n$e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _saveScanToFirebase(
    File imageFile,
    String analysisText,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('scanned_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(imageFile);
      final imageUrl = await storageRef.getDownloadURL();

      // Save scan result to Firestore
      final scansRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scans');

      final docRef = await scansRef.add({
        'analysis': analysisText,
        'image_url': imageUrl,
        'timestamp': DateTime.now(),
        'date': DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now()),
      });

      debugPrint("✅ Scan saved to Firestore successfully. id=${docRef.id}");
      return imageUrl;
    } catch (e) {
      debugPrint("❌ Error saving to Firestore: $e");
      return null;
    }
  }

  String? _extractProductName(String analysis) {
    // crude heuristic: first line up to newline or first sentence
    if (analysis.trim().isEmpty) return null;
    final lines = analysis.trim().split('\n');
    if (lines.isNotEmpty && lines.first.trim().isNotEmpty) {
      final first = lines.first.trim();
      // if it looks like a label 'Product name: xyz', try to parse
      final m = RegExp(
        r'Product name[:\s-]{0,3}(.*)',
        caseSensitive: false,
      ).firstMatch(first);
      if (m != null) return m.group(1)?.trim();
      return first.split('.').first.trim();
    }
    return null;
  }

  Widget _buildResultCard() {
    if (_result.isEmpty) return const SizedBox();

    // Styled result screen matching provided design: black panel with green border
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(_kContentPadding),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(_kCardRadius + 2),
              border: Border.all(
                color: _kPrimaryGreen,
                width: _kResultBorderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _extractProductName(_result) ?? 'Product Details',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_lastSavedResult != null &&
                        _lastSavedResult!['raw'] != null)
                      SizedBox(
                        width: 56,
                        height: 56,
                        child:
                            _lastSavedResult!['raw']['image_url'] != null &&
                                _lastSavedResult!['raw']['image_url'] != ''
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _lastSavedResult!['raw']['image_url'],
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Category: ${_lastSavedResult?['raw']?['category'] ?? 'Personal Care (Sunscreen)'},',
                  style: const TextStyle(color: Colors.white70, height: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingredients: ${_lastSavedResult?['raw']?['ingredients'] ?? 'Ingredients not available'}',
                  style: const TextStyle(color: Colors.white70, height: 1.3),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Eco Impact :',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '• Carbon Footprint : ${_lastSavedResult?['raw']?['co2'] ?? '0.36 kg CO2e per unit'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  '• Packaging : ${_lastSavedResult?['raw']?['packaging'] ?? 'Plastic Tube - Recyclable'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Environmental Warnings:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '• Contains microplastics? ${_lastSavedResult?['raw']?['microplastics'] ?? 'No'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                // Eco-score badge row
                Row(
                  children: [
                    const Text(
                      'ECO-SCORE',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _lastSavedResult?['raw']?['eco_score']?.toString() ??
                            'C',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Discover more section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_kCardRadius),
              border: Border.all(
                color: _kAccentYellow,
                width: _kResultBorderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Recipe Ideas')),
                      );
                    },
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Recipe Ideas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AlternativeScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.nature),
                    label: const Text('Better Alternative'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      if (_lastSavedResult != null) {
                        Navigator.of(context).pop(_lastSavedResult);
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No scan to save')),
                      );
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.bookmark_add),
                  label: const Text('Add to Recent'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: _kPrimaryGreen, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageFile == null) {
      return const Text(
        "No image selected.\nTap below to upload or scan a product image.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.black54),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(_imageFile!, height: 250, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Scan Product',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: _kPrimaryGreen,
        elevation: 2,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(_kContentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: Center(
                  child: _isLoading
                      ? CircularProgressIndicator(color: _kPrimaryGreen)
                      : _buildImagePreview(),
                ),
              ),
              _buildResultCard(),
              const SizedBox(height: 16),
              // Camera / Capture controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _isLoading ? null : _pickImage,
                    icon: const Icon(Icons.photo_library, size: 28),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isLoading ? null : _takePhoto,
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _kPrimaryGreen, width: 4),
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.camera_alt,
                          size: 34,
                          color: _kPrimaryGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      // Placeholder for flash / info
                    },
                    icon: const Icon(Icons.info_outline, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
