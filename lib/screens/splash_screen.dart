// lib/screens/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math'; // For rotation

import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryGreen = kPrimaryGreen;

  late AnimationController _controller;

  // Animation Values
  late Animation<double>
  _scanAnimation; // Controls scan line position (0.0 to 1.0)
  late Animation<double>
  _dataFlowAnimation; // Controls data particle flow (0.0 to 1.0)
  late Animation<double>
  _logoScaleAnimation; // Controls logo final scale and snap
  late Animation<double>
  _houseRotationAnimation; // Controls rotation of the house/leaf snap

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _startRoutingTimer();
  }

  void _initializeAnimation() {
    // Total duration for the smart animation: 2.5 seconds
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // 1. Scan Line (Happens in first 30%)
    _scanAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // 2. Data Flow (Happens in middle 30%)
    _dataFlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeInOut),
      ),
    );

    // 3. Logo Snap and Scale (Happens in final 40%)
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );

    // 4. House Rotation (Snappy rotation during snap-in)
    _houseRotationAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.8, curve: Curves.fastOutSlowIn),
      ),
    );

    // Start the animation
    _controller.forward();
  }

  // --- Routing Logic (Remains the same) ---
  void _startRoutingTimer() {
    // Wait for 3 seconds total before checking auth and routing
    Timer(const Duration(seconds: 3), _checkAuthAndRoute);
  }

  Future<void> _checkAuthAndRoute() async {
    final prefs = await SharedPreferences.getInstance();
    // Use the name of your new OnboardingScreen
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;
    final user = FirebaseAuth.instance.currentUser;

    String routeName;

    if (isFirstTime) {
      routeName = '/onboarding';
    } else if (user != null) {
      routeName = '/home';
    } else {
      routeName = '/auth';
    }

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(routeName);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- UI Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryGreen,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double scanValue = _scanAnimation.value;
            final double dataValue = _dataFlowAnimation.value;
            // Some curves (eg. Curves.elasticOut) can overshoot > 1.0 — clamp values
            final double scaleValue = (_logoScaleAnimation.value).clamp(
              0.0,
              1.0,
            );
            final double dataValueClamped = (_dataFlowAnimation.value).clamp(
              0.0,
              1.0,
            );
            final double rotationValue = _houseRotationAnimation.value;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Logo Animation Container
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // --- Generic Product / Container (Input) ---
                      Opacity(
                        opacity: 1.0 - dataValue, // Fades out as data flows
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 40,
                              color: primaryGreen,
                            ),
                          ),
                        ),
                      ),

                      // --- Scanning Line Effect ---
                      Opacity(
                        opacity:
                            1.0 - dataValue, // Fades out after scan finishes
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            80 * scanValue,
                          ), // Moves up and down the box
                          child: Container(
                            width: 120,
                            height: 2,
                            color:
                                kPrimaryYellow, // Bright yellow scanning line
                          ),
                        ),
                      ),

                      // --- Data Particles (Coalescing into Leaf) ---
                      if (dataValueClamped > 0.0)
                        ...List.generate(5, (index) {
                          // Particles move from center outwards, then gather at the top-left
                          double particleOffset =
                              40.0 * (1.0 - dataValueClamped) * sin(index + 1);
                          final double particleSize = max(
                            2.0,
                            4 * (1.0 - dataValueClamped) + 2,
                          );

                          return Positioned(
                            left: 75 + particleOffset,
                            top: 75 + particleOffset * 0.5,
                            child: Opacity(
                              opacity:
                                  dataValueClamped, // Fades in during flow (clamped)
                              child: Transform.translate(
                                offset: Offset(
                                  -75 * dataValueClamped,
                                  -75 * dataValueClamped,
                                ), // Moves towards the final logo point
                                child: Icon(
                                  Icons.circle,
                                  size: particleSize,
                                  color: primaryGreen,
                                ),
                              ),
                            ),
                          );
                        }),

                      // --- Final EcoPilot Logo (House and Leaf) ---
                      Transform.scale(
                        scale: _logoScaleAnimation
                            .value, // Keep scale overshoot visually
                        child: Transform.rotate(
                          angle: rotationValue, // Rotates before snapping
                          child: Opacity(
                            opacity:
                                scaleValue, // use clamped value for opacity (0..1)
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // House (Green)
                                Icon(Icons.home, size: 70, color: Colors.white),
                                // Leaf (Yellow/White - Snaps onto the house)
                                Icon(
                                  Icons.spa,
                                  size: 50,
                                  color: kPrimaryYellow,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. App Name Fade-in
                Opacity(
                  opacity: scaleValue, // Fades in with the final logo
                  child: const Text(
                    'ECOPILOT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
