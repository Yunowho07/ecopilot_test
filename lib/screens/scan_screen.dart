import 'dart:io';
// NOTE: ⚠️ UNCOMMENT THESE IMPORTS AFTER ADDING THE 'camera' PACKAGE TO PUBSPEC.YAML
import 'package:camera/camera.dart'; 
import 'package:path_provider/path_provider.dart'; 
import 'package:ecopilot_test/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecopilot_test/auth/firebase_service.dart';
import 'profile_screen.dart' as profile_screen;
import 'alternative_screen.dart' as alternative_screen;
import 'dispose_screen.dart' as dispose_screen;
import 'package:ecopilot_test/widgets/app_drawer.dart';
import '/utils/constants.dart';

// Assuming you have defined these colors in utils/constants.dart
const Color kPrimaryGreen = Color(0xFF4CAF50);
const Color kWarningRed = Color(0xFFF44336);
const Color kDiscoverMoreYellow = Color(0xFFFFC107);
const Color kDiscoverMoreBlue = Color(0xFF2196F3);

// --- II. Data Model and Parsing Logic ---
// (No changes in this section)
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

// --- III. Helper Widgets (ResultScreen, ProfileScreen) ---

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
    final bool isGood = label.toLowerCase().contains('cruelty') ? isChecked : !isChecked;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: isGood ? kPrimaryGreen : kWarningRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
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
    String displayLetter = displayScore.isNotEmpty ? displayScore.substring(0, 1) : 'N';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ecoScoreColors[displayLetter] ?? Colors.grey.shade600,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'ECO-SCORE $ecoScore'.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDiscoverMoreButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Container(
          height: 80, // Fixed height for a button-like appearance
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
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
        backgroundColor: Colors.black, // Dark app bar
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black, // Black background for the body
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: kPrimaryGreen, width: 3),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product Details', style: TextStyle(color: kPrimaryGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(color: Colors.white30, height: 16),
                    _buildInfoRow('Name', analysisData.productName),
                    _buildInfoRow('Category', analysisData.category),
                    _buildInfoRow('Ingredients', analysisData.ingredients),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Eco Impact Card (Green Text/Border)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: kPrimaryGreen, width: 3),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Eco Impact', style: TextStyle(color: kPrimaryGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(color: Colors.white30, height: 16),
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
              ),
              const SizedBox(height: 16),

              // 3. Environmental Warnings Card (Green Text/Border)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: kPrimaryGreen, width: 3),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Environmental Warnings', style: TextStyle(color: kPrimaryGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(color: Colors.white30, height: 16),
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
                    // ECO-SCORE DISPLAY
                    _buildEcoScoreDisplay(analysisData.ecoScore),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Discover More Section (Yellow Border)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: kDiscoverMoreYellow, width: 3),
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
                        _buildDiscoverMoreButton(
                          label: 'Recipe Ideas', // Changed label to match image
                          icon: Icons.restaurant_menu, // Using relevant icon
                          color: kDiscoverMoreBlue,
                          onTap: () {
                            // TODO: Implement navigation to Recipe Ideas screen
                            debugPrint('Navigating to Recipe Ideas');
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildDiscoverMoreButton(
                          label: 'Better Alternative',
                          icon: Icons.eco, // Changed icon to be more relevant
                          color: kPrimaryGreen, // Using primary green for alt
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const alternative_screen.AlternativeScreen(),
                              ),
                            );
                          },
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
  // ⚠️ UNCOMMENT THESE VARIABLES FOR CAMERA PACKAGE INTEGRATION
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  List<CameraDescription> _cameras = [];

  bool _isLoading = false;
  late final String _geminiApiKey;
  final ImagePicker _picker = ImagePicker();
  int _selectedIndex = 2; // Default to 'Scan' tab
  bool _isFlashOn = false; // State for flashlight (controls the icon)
  bool _isFrontCamera = false; // State for camera toggle (controls the icon)

  // A. State Variables & Initialization
  @override
  void initState() {
    super.initState();
    _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    // Start camera initialization
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // ⚠️ UNCOMMENT and use these methods for actual camera setup.
    
    try {
      // 1. Fetch available cameras
      _cameras = await availableCameras();
      
      // 2. Initialize the controller with the rear camera
      _cameraController = CameraController(
        _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        ),
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      // 3. Initialize the controller instance
      await _cameraController!.initialize();

      // 4. Update state to reflect readiness and set initial flash state
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraController!.setFlashMode(FlashMode.off); 
        });
      }
    } on CameraException catch (e) {
      debugPrint("Camera initialization error: $e");
      // Handle error gracefully in UI, e.g., show an error message
    }
    
    debugPrint("Camera initialization logic executed (using simulation).");
    if (mounted) {
      // Simulate initialization completion for UI to render properly
      setState(() {
        // _isCameraInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    // ⚠️ UNCOMMENT for camera package integration
    // _cameraController?.dispose(); 
    super.dispose();
  }


  // --- Image/Analysis Logic ---
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      await _analyzeProduct(imageFile);
    }
  }

  Future<void> _scanBarcodeAndAnalyze() async {
    debugPrint("Triggering Barcode/Camera Scan...");
    // If using the camera package, this would be where you call:
    // final XFile = await _cameraController.takePicture();
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


  // --- UI Builder Widgets ---

  // Small circle button for camera controls
  Widget _buildCameraButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54, width: 1.5),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  // B. Live Preview (_buildCameraView)
  Widget _buildCameraView() {
    // ⚠️ UNCOMMENT this block for actual camera initialization check
    
    if (_cameraController == null || !_isCameraInitialized) {
      // Show a loading indicator or a placeholder until the camera is ready
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: kPrimaryGreen),
        ),
      );
    }
    
    
    return Expanded(
      child: Container(
        color: Colors.black, // Simulating a live camera feed's dark background
        child: Stack(
          children: [
            // ⚠️ UNCOMMENT the line below to show the live preview
            // CameraPreview(_cameraController!), 

            // Scanner Frame/Corner Indicators (White borders for scanning area)
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.width * 0.8 * 0.7, // Rectangular scan area
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white10, width: 2),
                ),
                child: CustomPaint(
                  painter: _CornerPainter(color: Colors.white, cornerLength: 40, cornerThickness: 4),
                  child: Center(
                    child: _isLoading
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: kPrimaryGreen),
                              const SizedBox(height: 16),
                              Text(
                                "Analyzing product...",
                                style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
                              ),
                            ],
                          )
                        : Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white.withOpacity(0.5),
                            size: 80,
                          ),
                  ),
                ),
              ),
            ),

            // Top Control Bar (Flash and Flip Camera)
            Positioned(
              top: 30,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Flashlight Toggle - C. Enabling Flash
                    _buildCameraButton(
                      icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      onTap: () {
                        // ⚠️ UNCOMMENT the check for camera initialization
                        // if (_cameraController != null && _cameraController!.value.isInitialized) {
                          setState(() {
                            _isFlashOn = !_isFlashOn;
                            // Actual flash control command:
                            // _cameraController!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
                            debugPrint('Flashlight toggled to: $_isFlashOn');
                          });
                        // }
                      },
                    ),
                    // Upload from Gallery
                    _buildCameraButton(
                      icon: Icons.image,
                      onTap: () {
                        debugPrint('Opening photo gallery...');
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    // Flip Camera - C. Enabling Flip
                    _buildCameraButton(
                      icon: Icons.flip_camera_ios,
                      onTap: () {
                        // ⚠️ UNCOMMENT the check for camera initialization
                        // if (_cameraController != null && _cameraController!.value.isInitialized && _cameras.length > 1) {
                          setState(() {
                            _isFrontCamera = !_isFrontCamera;
                            // Actual camera flip command:
                            // final newCamera = _isFrontCamera ? _cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front) : _cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
                            // _cameraController!.setDescription(newCamera);
                            debugPrint('Camera flipped to: ${_isFrontCamera ? 'Front' : 'Rear'}');
                          });
                        // }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Center Capture Button (Scan Barcode)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: FloatingActionButton(
                  onPressed: _scanBarcodeAndAnalyze, // Barcode scan/Image Action Sheet
                  backgroundColor: kPrimaryGreen,
                  child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // The main dark bottom section containing the logo, search, and help text
  Widget _buildScannerOverlay() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E), // Dark grey/black for the bottom overlay
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo and App Name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco, color: kPrimaryGreen, size: 30),
              const SizedBox(width: 8),
              const Text(
                'Eco',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                ),
              ),
              Text(
                'PILOT',
                style: TextStyle(
                  color: kPrimaryGreen,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Instruction Text
          const Text(
            'Scan a barcode or search for a product',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // Search Bar
          TextField(
            onSubmitted: (query) {
              // TODO: Implement manual product search logic
              debugPrint("Search for product: $query");
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search for a product',
              hintStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.black, // Darker background for the search bar
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: kPrimaryGreen),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: kPrimaryGreen),
                onPressed: _scanBarcodeAndAnalyze,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // 'Help us translate' section (Simulating the secondary card)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.help_outline, color: kPrimaryGreen, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Help us improve our data!',
                        style: TextStyle(
                          color: kPrimaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Translate the app, submit missing products, or verify ingredients.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // --- Bottom Navigation Bar ---
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      selectedItemColor: kPrimaryGreen,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.black,
      onTap: (index) async {
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
          return; // Already on ScanScreen
        }
        if (index == 3) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const dispose_screen.DisposalGuidanceScreen(),
            ),
          );
          return;
        }
        if (index == 4) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const profile_screen.ProfileScreen(),
            ),
          );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      // No AppBar to allow the CameraView to be full height
      body: SafeArea(
        child: Column(
          children: [
            // 1. Camera View Area
            _buildCameraView(),

            // 2. Scanner Overlay (Dark section with search and logo)
            _buildScannerOverlay(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}

// Helper painter to draw the corner guides for the scanner
class _CornerPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double cornerThickness;

  _CornerPainter({required this.color, required this.cornerLength, required this.cornerThickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = cornerThickness
      ..style = PaintingStyle.stroke;

    // Top-Left Corner
    canvas.drawLine(Offset(0, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, cornerLength), paint);

    // Top-Right Corner
    canvas.drawLine(Offset(size.width - cornerLength, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-Left Corner
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height - cornerLength), Offset(0, size.height), paint);

    // Bottom-Right Corner
    canvas.drawLine(Offset(size.width - cornerLength, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerLength), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}