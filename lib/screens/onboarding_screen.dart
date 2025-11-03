// lib/screens/onboarding/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'dart:math';
import '../../utils/constants.dart';
import 'package:ecopilot_test/utils/color_extensions.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(viewportFraction: 1);
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Scan Any Product',
      'image': 'assets/onboarding_eco_product.png',
      'price': r'Instantly scan products to see their Eco-Score and environmental impact',
    },
    {
      'title': 'Discover Eco Friendly',
      'image': 'assets/onboarding_eco_product_2.png',
      'price': r'Find greener alternatives to make smarter, sustainable choices',
    },
    {
      'title': 'Track & Improve',
      'image': 'assets/onboarding_eco_product_3.png',
      'price': r'Track your progress and grow your positive impact every day',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Bottom green semicircle
            Positioned(
              bottom: -screenSize.height * 0.12,
              left: 0,
              right: 0,
              child: Container(
                height: screenSize.height * 0.65,
                decoration: BoxDecoration(
                  color: kPrimaryGreen,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(screenSize.width * 0.6),
                    topRight: Radius.circular(screenSize.width * 0.6),
                  ),
                ),
              ),
            ),

            // Top content + PageView
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),

                    // Header: name and simple icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'EcoPilot',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryGreen,
                              ),
                            ),
                            // const SizedBox(width: 8),
                            // const Icon(
                            //   Icons.eco,
                            //   size: 22,
                            //   color: Colors.green,
                            // ),
                          ],
                        ),
                        // small cart-like icon to mirror the wireframe spacing
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white, // Border color
                              width: 3, // Border thickness
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0), // Space between image and border
                            child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15), // Adjust the curve value
                                  child: Image.asset('assets/ecopilot_logo_white.png',
                                  width: 150,   // Set your preferred size
                                  height: 150,
                                  fit: BoxFit.cover,
                                  ),
                                )
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Headline (left)
                    Center(
                      child: Text(
                        _pages[_currentPage]['title'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Top small feature icons row (floating above the semicircle)
                    SizedBox(
                      height: 86,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        // children: [
                        //   _smallFeatureCircle('Hot Coffee', Icons.local_cafe),
                        //   _smallFeatureCircle('Drinks',Icons.emoji_food_beverage,),
                        //   _smallFeatureCircle('Hot Teas', Icons.local_drink),
                        //   _smallFeatureCircle('Bakery', Icons.cake),
                        // ],
                      ),
                    ),

                    // Centered PageView with big circular product overlapping the green semicircle
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        onPageChanged: (idx) =>
                            setState(() => _currentPage = idx),
                        itemBuilder: (context, index) {
                          final page = _pages[index];
                          // limit image size to avoid overflow on short screens
                          final double imageDim = min(
                            screenSize.width * 0.56,
                            screenSize.height * 0.42,
                          );

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // circular product image
                              Center(
                                child: Container(
                                  width: imageDim,
                                  height: imageDim,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorWithOpacity(
                                          Colors.black,
                                          0.12,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        page['image'] ?? '',
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Center(
                                                  child: Icon(
                                                    Icons.local_drink,
                                                    size: max(
                                                      40,
                                                      imageDim * 0.25,
                                                    ),
                                                    color: colorWithOpacity(
                                                      kPrimaryGreen,
                                                      0.9,
                                                    ),
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Product title and price (centered, white text on green area feel)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      page['subtitle'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      page['price'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    // Text(
                                    //   page['price'] ?? '',
                                    //   style: const TextStyle(
                                    //     fontSize: 18,
                                    //     color: Colors.white,
                                    //     fontWeight: FontWeight.bold,
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Slider dots and a primary CTA button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _pages.length,
                              (i) => _buildDot(i == _currentPage),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate to auth landing
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/auth');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryYellow,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: const Text(
                                'Get Started',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
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
      ),
    );
  }

  // small circular features above semicircle
  Widget _smallFeatureCircle(String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorWithOpacity(Colors.black, 0.08),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(icon, color: kPrimaryGreen, size: 28),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
      ],
    );
  }

  Widget _buildDot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: active ? 14 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? kPrimaryYellow : Colors.white54,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
