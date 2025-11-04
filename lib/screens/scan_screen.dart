import 'dart:io';
// NOTE: ⚠️ UNCOMMENT THESE IMPORTS AFTER ADDING THE 'camera' PACKAGE TO PUBSPEC.YAML
import 'package:camera/camera.dart';
import 'package:ecopilot_test/screens/disposal_guidance_screen.dart';
import 'package:ecopilot_test/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecopilot_test/auth/firebase_service.dart';
import 'profile_screen.dart' as profile_screen;
import 'alternative_screen.dart' as alternative_screen;
import 'disposal_guidance_screen.dart' as disposal_guidance_screen;
import 'package:ecopilot_test/widgets/app_drawer.dart';
import '/utils/constants.dart';
import 'package:ecopilot_test/models/product_analysis_data.dart';
import 'package:ecopilot_test/screens/result_screen.dart';

// Colors are defined in lib/utils/constants.dart

// ProductAnalysisData moved to lib/models/product_analysis_data.dart
const Color kPrimaryGreen = Color(0xFF1db954);
// --- III. Helper Widgets (ResultScreen, ProfileScreen) ---
// (ResultScreen and ProfileScreen remain unchanged for brevity, but are included in the final file)

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
  // bool _isFrontCamera = false; // State for camera toggle (controls the icon)

  // NOTE: This variable is now unused, as the flip button is replaced by Capture.
  // We keep the state logic for conceptual camera control.

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
    _cameraController?.dispose();
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

  // NOTE: This handles the bottom FAB tap
  Future<void> _scanBarcodeAndAnalyze() async {
    debugPrint("Triggering Barcode/Camera Scan (FAB Tapped)...");

    // Launch a full-screen camera scanner that returns the first barcode scanned
    final scannedCode = await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    if (scannedCode == null || scannedCode.isEmpty) return;

    // Lookup the barcode in Open Beauty Facts first
    final data = await _lookupBarcode(scannedCode);
    if (data != null) {
      _navigateToResultScreen(data);
      return;
    }

    // If not found, notify the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product not found in Open Beauty Facts')),
    );
  }

  // Lookup product by barcode from Open Beauty Facts
  Future<ProductAnalysisData?> _lookupBarcode(String barcode) async {
    try {
      final uri = Uri.parse(
        'https://world.openbeautyfacts.org/api/v0/product/$barcode.json',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;

      final Map<String, dynamic> json = resp.body.isNotEmpty
          ? (await Future.value(jsonDecode(resp.body)) as Map<String, dynamic>)
          : {};
      if (json['status'] != 1) return null; // Not found

      final prod = json['product'] as Map<String, dynamic>;

      String name =
          (prod['product_name'] as String?) ??
          (prod['brands'] as String?) ??
          'Unknown Product';
      String ingredients = (prod['ingredients_text'] as String?) ?? 'N/A';
      String packaging =
          (prod['packaging'] as String?) ??
          (prod['packaging_tags'] != null
              ? (prod['packaging_tags'] as List).join(', ')
              : 'N/A');
      String eco =
          (prod['ecoscore_grade'] as String?) ??
          (prod['environment_impact_grade'] as String?) ??
          'N/A';

      final ingredientsLower = ingredients.toLowerCase();
      final containsMicroplastics = RegExp(
        r'polyethylene|polypropylene|polymethyl|polystyrene|microplastic',
      ).hasMatch(ingredientsLower);
      final palmOilDerivative =
          ingredientsLower.contains('palm') ||
          ingredientsLower.contains('palmitate') ||
          ingredientsLower.contains('palmitic');

      bool crueltyFree = false;
      if (prod['labels_tags'] is List) {
        final labels = (prod['labels_tags'] as List)
            .map((e) => e.toString().toLowerCase())
            .toList();
        crueltyFree = labels.any(
          (l) =>
              l.contains('cruelty') ||
              l.contains('not-tested-on-animals') ||
              l.contains('no-animal-testing'),
        );
      }

      final analysis = ProductAnalysisData(
        imageFile: null,
        imageUrl:
            (prod['image_front_url'] as String?) ??
            (prod['image_url'] as String?),
        productName: name,
        category: (prod['categories'] as String?) ?? 'N/A',
        ingredients: ingredients,
        carbonFootprint: 'N/A',
        packagingType: packaging,
        disposalMethod: 'N/A',
        containsMicroplastics: containsMicroplastics,
        palmOilDerivative: palmOilDerivative,
        crueltyFree: crueltyFree,
        ecoScore: eco,
      );

      return analysis;
    } catch (e) {
      debugPrint('Barcode lookup error: $e');
      return null;
    }
  }

  // NOTE: This handles the top-right button tap (now Capture)
  Future<void> _capturePicture() async {
    debugPrint("Triggering Picture Capture (Top Right Button Tapped)...");

    // ⚠️ UNCOMMENT and replace with actual capture logic:

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final XFile file = await _cameraController!.takePicture();
        final imageFile = File(file.path);
        await _analyzeProduct(imageFile);
      } catch (e) {
        debugPrint("Error taking picture: $e");
      }
    } else {
      // Fallback to gallery/camera picker
    }
    // For simulation, we fall back to the picker immediately:
  }

  // ... (analyze, navigate, save, showActionSheet methods remain unchanged) ...
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
Eco-friendliness rating: [A, B, C, D, E or etc.]
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

  // void _showImageSourceActionSheet(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
  //     ),
  //     builder: (BuildContext context) {
  //       return Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: <Widget>[
  //           const Padding(
  //             padding: EdgeInsets.all(16.0),
  //             child: Text(
  //               'Select Image Source',
  //               style: TextStyle(
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.bold,
  //                 color: kPrimaryGreen,
  //               ),
  //             ),
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.photo_library, color: kPrimaryGreen),
  //             title: const Text(
  //               'Photo Gallery',
  //               style: TextStyle(fontSize: 16),
  //             ),
  //             onTap: () {
  //               Navigator.pop(context);
  //               _pickImage(ImageSource.gallery);
  //             },
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.camera_alt, color: kPrimaryGreen),
  //             title: const Text('Use Camera', style: TextStyle(fontSize: 16)),
  //             onTap: () {
  //               Navigator.pop(context);
  //               _pickImage(ImageSource.camera);
  //             },
  //           ),
  //           const SizedBox(height: 20),
  //         ],
  //       );
  //     },
  //   );
  // }

  // --- UI Builder Widgets ---

  // Small circle button for camera controls
  Widget _buildCameraButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
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
      return const Expanded(
        child: Center(child: CircularProgressIndicator(color: kPrimaryGreen)),
      );
    }

    // FIX: Removed Expanded and set height to cover the screen minus the bottom overlay
    return Flexible(
      // Use MediaQuery to calculate the height above the bottom section.
      // NOTE: This height calculation is conceptual and might need fine-tuning
      // depending on the size of _buildScannerOverlay().
      child: Container(
        color: Colors.black, // Simulating a live camera feed's dark background
        child: Stack(
          children: [
            // ⚠️ UNCOMMENT the line below to show the live preview
            CameraPreview(_cameraController!),

            // Scanner Frame/Corner Indicators (White borders for scanning area)
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height:
                    MediaQuery.of(context).size.width *
                    0.8 *
                    0.7, // Rectangular scan area
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white10, width: 2),
                ),
                child: CustomPaint(
                  painter: _CornerPainter(
                    color: Colors.white,
                    cornerLength: 40,
                    cornerThickness: 4,
                  ),
                  child: Center(
                    child: _isLoading
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: kPrimaryGreen,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Analyzing product...",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                ),
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

            // Top Control Bar (Flash and Capture/Gallery)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top-Left: Flashlight Toggle
                    _buildCameraButton(
                      icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      onTap: () {
                        // ⚠️ UNCOMMENT the check for camera initialization
                        if (_cameraController != null &&
                            _cameraController!.value.isInitialized) {
                          setState(() {
                            _isFlashOn = !_isFlashOn;
                            // Actual flash control command:
                            _cameraController!.setFlashMode(
                              _isFlashOn ? FlashMode.torch : FlashMode.off,
                            );
                            debugPrint('Flashlight toggled to: $_isFlashOn');
                          });
                        }
                      },
                    ),
                    // // Top-Center: Upload from Gallery
                    // _buildCameraButton(
                    //   icon: Icons.image,
                    //   onTap: () {
                    //     debugPrint('Opening photo gallery...');
                    //     _pickImage(ImageSource.gallery);
                    //   },
                    // ),
                    // Top-Right: Capture Button (Replaced Flip)
                    _buildCameraButton(
                      icon: Icons.camera_alt, // Capture Icon
                      onTap: _capturePicture,
                    ),
                    // Top-Center: Upload from Gallery
                    _buildCameraButton(
                      icon: Icons.image,
                      onTap: () {
                        debugPrint('Opening photo gallery...');
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Center Capture Button (Scan Barcode) - Stays as the FAB
            // Align(
            //   alignment: Alignment.bottomCenter,
            //   child: Padding(
            //     padding: const EdgeInsets.only(bottom: 20.0),
            //     child: FloatingActionButton(
            //       onPressed: _scanBarcodeAndAnalyze, // Barcode scan/Image Action Sheet
            //       backgroundColor: kPrimaryGreen,
            //       child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
            //     ),
            //   ),
            // ),
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
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo and App Name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/ecopilot_logo.png',
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
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
                'Pilot',
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
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 20,
              ),
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
              // ⬅️ CRUCIAL CHANGE HERE
              builder: (_) => const DisposalGuidanceScreen(productId: null), 
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
      // Remove AppBar so camera view can go full height
      body: Column(
        children: [
          // 1. Camera View Area (Covers everything above the bottom overlay)
          _buildCameraView(),

          // 2. Scanner Overlay (Dark section with search and logo)
          _buildScannerOverlay(),

          // 3. Bottom Navigation Bar (Handled outside of Column structure by Scaffold)
        ],
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

  _CornerPainter({
    required this.color,
    required this.cornerLength,
    required this.cornerThickness,
  });

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
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // Bottom-Left Corner
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height - cornerLength),
      Offset(0, size.height),
      paint,
    );

    // Bottom-Right Corner
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerLength),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Full screen barcode scanner page using mobile_scanner. Returns the scanned
// barcode string via Navigator.pop(context, code).
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({Key? key}) : super(key: key);

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              try {
                await _controller.toggleTorch();
                setState(() {
                  _torchOn = !_torchOn;
                });
              } catch (_) {}
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_scanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final String? raw = barcodes.first.rawValue;
              if (raw == null || raw.isEmpty) return;
              _scanned = true;
              // Stop the camera before popping to avoid camera errors on some devices
              _controller.stop();
              Navigator.of(context).pop(raw);
            },
          ),

          // Center guide box
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.4,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
