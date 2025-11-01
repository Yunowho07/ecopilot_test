import 'dart:io';
import 'package:ecopilot_test/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
// removed unused cloud_firestore and intl imports (centralized in FirebaseService)
import 'package:ecopilot_test/auth/firebase_service.dart';
import 'profile_screen.dart' as profile_screen;
import 'alternative_screen.dart' as alternative_screen;
import 'dispose_screen.dart' as dispose_screen;
import 'package:ecopilot_test/widgets/app_drawer.dart';
import '/utils/constants.dart';

// --- II. Data Model and Parsing Logic ---

class ProductAnalysisData {
  final File? imageFile;
  final String? imageUrl;
  final String productName;
  final String category;
  final String ingredients;
  final String carbonFootprint;
  final String packagingType;
  final String disposalMethod;
  final bool containsMicroplastics;
  final bool palmOilDerivative;
  final bool crueltyFree;
  final String ecoScore;

  ProductAnalysisData({
    this.imageFile,
    this.imageUrl,
    required this.productName,
    this.category = 'N/A',
    this.ingredients = 'N/A',
    this.carbonFootprint = 'N/A',
    this.packagingType = 'N/A',
    this.disposalMethod = 'N/A',
    this.containsMicroplastics = false,
    this.palmOilDerivative = false,
    this.crueltyFree = false,
    this.ecoScore = 'N/A',
  });

  ProductAnalysisData copyWith({
    File? imageFile,
    String? imageUrl,
    String? productName,
    String? category,
    String? ingredients,
    String? carbonFootprint,
    String? packagingType,
    String? disposalMethod,
    bool? containsMicroplastics,
    bool? palmOilDerivative,
    bool? crueltyFree,
    String? ecoScore,
  }) {
    return ProductAnalysisData(
      imageFile: imageFile ?? this.imageFile,
      imageUrl: imageUrl ?? this.imageUrl,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      ingredients: ingredients ?? this.ingredients,
      carbonFootprint: carbonFootprint ?? this.carbonFootprint,
      packagingType: packagingType ?? this.packagingType,
      disposalMethod: disposalMethod ?? this.disposalMethod,
      containsMicroplastics:
          containsMicroplastics ?? this.containsMicroplastics,
      palmOilDerivative: palmOilDerivative ?? this.palmOilDerivative,
      crueltyFree: crueltyFree ?? this.crueltyFree,
      ecoScore: ecoScore ?? this.ecoScore,
    );
  }

  factory ProductAnalysisData.fromGeminiOutput(
    String geminiOutput, {
    File? imageFile,
  }) {
    String productName = _extractValue(
      geminiOutput,
      r'Product name:\s*(.*?)\n',
    );
    String category = _extractValue(geminiOutput, r'Category:\s*(.*?)\n');
    String ingredients = _extractValue(geminiOutput, r'Ingredients:\s*(.*?)\n');
    String carbonFootprint = _extractValue(
      geminiOutput,
      r'Carbon Footprint:\s*(.*?)\n',
    );
    String packagingType = _extractValue(
      geminiOutput,
      r'Packaging type:\s*(.*?)\n',
    );
    String disposalMethod = _extractValue(
      geminiOutput,
      r'Disposal method:\s*(.*?)\n',
    );
    String ecoScore = _extractValue(
      geminiOutput,
      r'Eco-friendliness rating:\s*(.*?)\n',
    );

    bool microplastics = _extractValue(
      geminiOutput,
      r'Contains microplastics\? \s*(.*?)\n',
    ).toLowerCase().contains('yes');
    bool palmOil = _extractValue(
      geminiOutput,
      r'Palm oil derivative\? \s*(.*?)\n',
    ).toLowerCase().contains('yes');
    bool crueltyFree = _extractValue(
      geminiOutput,
      r'Cruelty-Free\? \s*(.*?)\n',
    ).toLowerCase().contains('yes');

    // Basic inferral if category is missing
    if (category == 'N/A' && productName.toLowerCase().contains('cream')) {
      category = 'Personal Care (Sunscreen)';
    }

    // Clean up redundant/duplicated data that sometimes appears in Gemini output
    String cleanIngredients = _sanitizeField(
      ingredients,
      removeIfContains: [
        productName,
        'Product name',
        'Category',
        'Eco-friendliness',
        'Carbon Footprint',
      ],
    );

    // Also clean packaging/disposal fields similarly
    packagingType = _sanitizeField(packagingType);
    disposalMethod = _sanitizeField(disposalMethod);

    return ProductAnalysisData(
      imageFile: imageFile,
      productName: productName,
      category: category,
      ingredients: cleanIngredients,
      carbonFootprint: carbonFootprint,
      packagingType: packagingType,
      disposalMethod: disposalMethod,
      containsMicroplastics: microplastics,
      palmOilDerivative: palmOil,
      crueltyFree: crueltyFree,
      ecoScore: ecoScore,
    );
  }

  // Remove obvious repeated labels or full-line duplicates originating from
  // the raw Gemini output. If removeIfContains is provided, any line that
  // includes any of those substrings will be dropped from the result.
  static String _sanitizeField(String raw, {List<String>? removeIfContains}) {
    if (raw.trim().isEmpty) return 'N/A';
    final lines = raw
        .split(RegExp(r"\r?\n"))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final seen = <String>{};
    final out = <String>[];
    for (var line in lines) {
      var skip = false;
      if (removeIfContains != null) {
        for (var sub in removeIfContains) {
          if (sub.isEmpty) continue;
          if (line.toLowerCase().contains(sub.toLowerCase())) {
            skip = true;
            break;
          }
        }
      }
      if (skip) continue;

      // If the line is already seen (exact duplicate), skip it.
      if (seen.contains(line)) continue;

      // Avoid adding a line that is just a repeat of a short token like 'N/A'
      if (line.toUpperCase() == 'N/A') continue;

      seen.add(line);
      out.add(line);
    }

    if (out.isEmpty) return 'N/A';
    return out.join('\n');
  }

  static String _extractValue(String text, String regexPattern) {
    final RegExp regExp = RegExp(regexPattern, dotAll: true);
    final Match? match = regExp.firstMatch(text);
    // Clean up the extracted value, removing trailing parenthesis/notes
    String? rawValue = match?.group(1)?.trim();
    if (rawValue != null) {
      // Clean up common Gemini output formats like "Value (Note)"
      final noteIndex = rawValue.indexOf('(');
      if (noteIndex > 0) {
        rawValue = rawValue.substring(0, noteIndex).trim();
      }
    }
    return rawValue ?? 'N/A';
  }
}

// --- III. Helper Widgets (Bottom Nav, Placeholder) ---

// Placeholder for ProfileScreen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile Screen - Implement me!')),
    );
  }
}

// --- IV. Result Screen Implementation (Design Match) ---

class ResultScreen extends StatelessWidget {
  final ProductAnalysisData analysisData;
  final int _selectedIndex = 2;

  const ResultScreen({Key? key, required this.analysisData}) : super(key: key);

  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    Color? iconColor,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: iconColor ?? Colors.white70),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(color: valueColor ?? Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningRow(String label, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: isChecked ? kPrimaryGreen : kWarningRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isChecked ? Colors.white : kWarningRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEcoScoreDisplay(String ecoScore) {
    Map<String, Color> ecoScoreColors = {
      'A': Colors.green.shade700,
      'B': Colors.lightGreen.shade700,
      'C': Colors.yellow.shade800,
      'D': Colors.orange.shade800,
      'E': Colors.red.shade800,
      'N/A': Colors.grey.shade600,
    };
    String displayScore = ecoScore.toUpperCase().trim();
    if (displayScore.length > 1 && displayScore.contains('+')) {
      displayScore = displayScore.substring(0, 1);
    }
    String displayLetter = displayScore.substring(0, 1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ecoScoreColors[displayLetter] ?? Colors.grey.shade600,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        // Show the actual ecoScore from data model, but use only the letter for color
        'ECO-SCORE $ecoScore'.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required Color borderColor,
    required Color titleColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black, // Background color is black as in the design
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white30, height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDiscoverMoreButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: kPrimaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black, // Background matches the image design
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Image (Simulated like a header)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color:
                      Colors.grey.shade900, // Background when image is missing
                ),
                height: 200,
                child:
                    analysisData.imageUrl != null &&
                        analysisData.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          analysisData.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) =>
                              analysisData.imageFile != null
                              ? Image.file(
                                  analysisData.imageFile!,
                                  fit: BoxFit.cover,
                                )
                              : const Center(
                                  child: Text(
                                    "Image Not Available",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                        ),
                      )
                    : analysisData.imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          analysisData.imageFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Text(
                          "Image Not Available",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              // 1. Product Details Card (Green Text/Border)
              _buildSectionCard(
                borderColor: kPrimaryGreen,
                titleColor: kPrimaryGreen,
                title: 'Product Details',
                children: [
                  _buildInfoRow('Name', analysisData.productName),
                  _buildInfoRow('Category', analysisData.category),
                  _buildInfoRow('Ingredients', analysisData.ingredients),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Eco Impact Card (Green Text/Border)
              _buildSectionCard(
                borderColor: kPrimaryGreen,
                titleColor: kPrimaryGreen,
                title: 'Eco Impact',
                children: [
                  _buildInfoRow(
                    'Carbon Footprint',
                    analysisData.carbonFootprint,
                    icon: Icons.cloud,
                    iconColor: Colors.lightBlue.shade300,
                  ),
                  _buildInfoRow(
                    'Packaging',
                    analysisData.packagingType,
                    icon: Icons.eco,
                    iconColor: Colors.lightGreen.shade300,
                  ),
                  _buildInfoRow(
                    'Suggested Disposal',
                    analysisData.disposalMethod,
                    icon: Icons.restore_from_trash,
                    iconColor: Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Environmental Warnings Card (Green Text/Border)
              _buildSectionCard(
                borderColor: kPrimaryGreen,
                titleColor: kPrimaryGreen,
                title:
                    'Environmental Warnings', // keep bold via the card's Text style; to center the title, update _buildSectionCard's Text to use textAlign: TextAlign.center
                children: [
                  _buildWarningRow(
                    'Contains microplastics?',
                    analysisData.containsMicroplastics,
                  ),
                  _buildWarningRow(
                    'Palm oil derivative?',
                    analysisData.palmOilDerivative,
                  ),
                  _buildWarningRow('Cruelty-Free?', analysisData.crueltyFree),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildEcoScoreDisplay(analysisData.ecoScore),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Discover More Section (Yellow Border)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: kDiscoverMoreYellow, width: 2),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discover More',
                      style: TextStyle(
                        color: kDiscoverMoreYellow,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDiscoverMoreButton(
                            label: 'Disposal Guidance',
                            icon: Icons.delete_sweep,
                            color: kDiscoverMoreBlue,
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDiscoverMoreButton(
                            label: 'Better Alternative',
                            icon: Icons.shopping_cart,
                            color: kDiscoverMoreGreen,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const alternative_screen.AlternativeScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- V. Scan Screen (The main entry widget) ---

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isLoading = false;
  late final String _geminiApiKey;
  final ImagePicker _picker = ImagePicker();
  int _selectedIndex = 2; // Default to 'Scan' tab

  @override
  void initState() {
    super.initState();
    _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      await _analyzeProduct(imageFile);
    }
  }

  Future<void> _scanBarcodeAndAnalyze() async {
    // **TODO: Implement Barcode Scanning logic here**
    /*
    Example using 'flutter_barcode_scanner'
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', 'Cancel', true, ScanMode.BARCODE);

    if (barcodeScanRes != '-1' && barcodeScanRes.isNotEmpty) {
      // Barcode scanned successfully, try OpenFoodFacts
      // final productInfo = await _fetchOpenFoodFacts(barcodeScanRes);
      // if (productInfo != null) {
      //   final analysisData = ProductAnalysisData.fromOpenFoodFacts(productInfo);
      //   _navigateToResultScreen(analysisData);
      //   return;
      // }
    }
    */

    // Fallback to image upload/camera
    _showImageSourceActionSheet(context);
  }

  Future<void> _analyzeImage(File imageFile) async {
    setState(() {
      _isLoading = true;
    });

    ProductAnalysisData analysisData;
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

      // **CRUCIAL: Prompt updated to enforce parsable output format**
      const prompt = """
You are an eco-expert AI. Analyze the uploaded product image and describe clearly, exactly in this format. Provide 'N/A' if information is not visible or applicable.
Product name: [Product Name]
Category: [Product Category, e.g., Personal Care (Sunscreen)]
Ingredients: [List of ingredients, comma-separated, e.g., Water, Zinc Oxide, etc.]
Eco-friendliness rating: [A, B, C, D, E or A+, B+, etc.]
Carbon Footprint: [Estimated CO2e per unit, e.g., 0.36 kg CO2e per unit]
Packaging type: [Material and recyclability, e.g., Plastic Tube - Recyclable (Type 4 - LDPE)]
Disposal method: [Suggested disposal, e.g., Rinse and recycle locally]
Contains microplastics? [Yes/No]
Palm oil derivative? [Yes/No (No trace/Contains)]
Cruelty-Free? [Yes/No (Certified by Leaping Bunny)]
      """;

      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      final response = await model.generateContent(content);
      final outputText = response.text ?? "No analysis result.";

      analysisData = ProductAnalysisData.fromGeminiOutput(
        outputText,
        imageFile: imageFile,
      );

      final uploadedImageUrl = await _saveScanToFirebase(
        imageFile,
        outputText,
        analysisData,
      );

      // If we have an uploaded URL from Cloudinary, attach it to the analysis data
      final analysisToShow = uploadedImageUrl != null
          ? analysisData.copyWith(imageUrl: uploadedImageUrl)
          : analysisData;

      _navigateToResultScreen(analysisToShow);
    } catch (e) {
      analysisData = ProductAnalysisData(
        productName: 'Analysis Error',
        ingredients: 'Failed to analyze product: $e',
        ecoScore: 'E',
      );
      _navigateToResultScreen(analysisData);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _analyzeProduct(File imageFile) async {
    await _analyzeImage(imageFile);
  }

  void _navigateToResultScreen(ProductAnalysisData analysisData) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(analysisData: analysisData),
      ),
    );
  }

  Future<String?> _saveScanToFirebase(
    File imageFile,
    String analysisText,
    ProductAnalysisData analysisData,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      // Upload image to Cloudinary via FirebaseService helper
      String? imageUrl;
      try {
        imageUrl = await FirebaseService().uploadScannedImage(
          file: imageFile,
          fileName: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          onProgress: (transferred, total) {
            debugPrint('Scan upload progress: $transferred / $total');
          },
        );
      } catch (e) {
        debugPrint('Failed to upload scanned image to Cloudinary: $e');
        imageUrl = null;
      }

      // Persist using centralized FirebaseService so all per-user scan logic
      // (and any legacy writes) are handled in one place.
      try {
        await FirebaseService().saveUserScan(
          analysis: analysisText,
          productName: analysisData.productName,
          ecoScore: analysisData.ecoScore,
          carbonFootprint: analysisData.carbonFootprint,
          imageUrl: imageUrl,
        );
        debugPrint("✅ Scan saved to Firestore via FirebaseService.");
      } catch (e) {
        debugPrint("❌ Failed to save scan via FirebaseService: $e");
      }

      // Return the uploaded image URL (if any) so caller can show it immediately
      return imageUrl;
    } catch (e) {
      debugPrint("❌ Error saving to Firestore: $e");
      return null;
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryGreen,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: kPrimaryGreen),
              title: const Text(
                'Photo Gallery',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: kPrimaryGreen),
              title: const Text('Use Camera', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        // Use a Builder for the leading icon so we can call Scaffold.of(context)
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Scan Product',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: kPrimaryGreen,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLoading)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: kPrimaryGreen),
                      SizedBox(height: 16),
                      Text(
                        "Analyzing product...",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: _scanBarcodeAndAnalyze,
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 24,
                      ),
                      label: const Text(
                        'Scan Barcode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimaryGreen,
                        side: const BorderSide(color: kPrimaryGreen, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => _showImageSourceActionSheet(context),
                      icon: const Icon(Icons.camera_alt, size: 24),
                      label: const Text(
                        'Upload or Take Product Photo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              const Text(
                "Tap 'Scan Barcode' for quick data from OpenFoodFacts, or 'Upload or Take Photo' for comprehensive analysis via Gemini.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      // Hardcode the index to 1 (Alternative) to visually highlight the current screen
      currentIndex: _selectedIndex,
      selectedItemColor: kPrimaryGreen,
      unselectedItemColor: Colors.grey,
      onTap: (index) async {
        // When the Home tab is tapped, open the Home screen.
        if (index == 0) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const HomeScreen()));
          return;
        }
        // When the Alternative tab is tapped, open the Alternative screen (or do nothing if already here).
        if (index == 1) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const alternative_screen.AlternativeScreen(),
            ),
          );
          return;
        }
        // When Scan tab is tapped, open the ScanScreen and wait for result
        if (index == 2) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ScanScreen()));
          return;
        }
        if (index == 3) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const dispose_screen.DisposalGuidanceScreen(),
            ),
          );
          return;
        }
        // When the Profile tab is tapped, open the Profile screen.
        if (index == 4) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const profile_screen.ProfileScreen(),
            ),
          );
          return;
        }

        // NOTE: The provided logic does not allow the index to be changed (setState)
        // because all navigations use push/return. Retaining the setState block just in case.
        // setState(() {
        //   _selectedIndex = index;
        // });
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
