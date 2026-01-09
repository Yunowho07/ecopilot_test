// lib/screens/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:ui';

import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Color primaryGreen = kPrimaryGreen;

  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _3dRotationController;
  late AnimationController _perspectiveController;

  // Main Animation Values
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _taglineFadeAnimation;
  late Animation<double> _glowAnimation;

  // 3D Animation Values
  late Animation<double> _3dRotationXAnimation;
  late Animation<double> _3dRotationYAnimation;
  late Animation<double> _3dRotationZAnimation;
  late Animation<double> _perspectiveAnimation;
  late Animation<double> _depthAnimation;

  // Pulse Animation
  late Animation<double> _pulseAnimation;

  // Particle Animation
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startRoutingTimer();
  }

  void _initializeAnimations() {
    // Main controller for logo entrance
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Pulse controller for breathing effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Particle controller for floating particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // 3D rotation controller
    _3dRotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Perspective controller for depth effect
    _perspectiveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Logo scale with bounce
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // 3D Rotation animations
    _3dRotationXAnimation = Tween<double>(begin: pi * 2, end: 0.0).animate(
      CurvedAnimation(
        parent: _3dRotationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _3dRotationYAnimation = Tween<double>(begin: pi * 1.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _3dRotationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _3dRotationZAnimation = Tween<double>(begin: pi * 0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _3dRotationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Perspective animation for depth
    _perspectiveAnimation = Tween<double>(begin: 0.001, end: 0.003).animate(
      CurvedAnimation(parent: _perspectiveController, curve: Curves.easeInOut),
    );

    // Depth effect animation
    _depthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    // Text fade in
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 0.85, curve: Curves.easeIn),
      ),
    );

    // Text slide up
    _textSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 0.85, curve: Curves.easeOut),
      ),
    );

    // Tagline fade
    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );

    // Glow effect
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeInOut),
      ),
    );

    // Pulse animation (breathing effect)
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Particle float animation
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    // Start animations
    _mainController.forward();
    _3dRotationController.forward();
    _perspectiveController.forward();

    // Start pulse after main animation
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });

    // Start particles
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _particleController.repeat();
      }
    });
  }

  void _startRoutingTimer() {
    Timer(const Duration(seconds: 3), _checkAuthAndRoute);
  }

  Future<void> _checkAuthAndRoute() async {
    final prefs = await SharedPreferences.getInstance();
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
    _mainController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _3dRotationController.dispose();
    _perspectiveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryGreen,
              primaryGreen.withOpacity(0.8),
              const Color(0xFF1db954),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            _buildFloatingParticles(),

            // 3D Background layers for depth
            _build3DBackgroundLayers(),

            // Main content
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _mainController,
                  _pulseController,
                  _particleController,
                  _3dRotationController,
                  _perspectiveController,
                ]),
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 3D Logo container
                      _build3DLogo(),

                      const SizedBox(height: 40),

                      // App name with 3D text effect
                      _build3DText(),

                      const SizedBox(height: 60),

                      // Loading indicator with 3D effect
                      _build3DLoadingIndicator(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3D Logo with perspective transformation
  Widget _build3DLogo() {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, _perspectiveAnimation.value)
        ..rotateX(_3dRotationXAnimation.value)
        ..rotateY(_3dRotationYAnimation.value)
        ..rotateZ(_3dRotationZAnimation.value),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Multiple shadow layers for 3D depth
          for (int i = 5; i > 0; i--)
            Transform.translate(
              offset: Offset(
                i * 3.0 * _depthAnimation.value,
                i * 3.0 * _depthAnimation.value,
              ),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(
                    0.05 * i * _depthAnimation.value,
                  ),
                ),
              ),
            ),

          // Outer glow with 3D effect
          if (_glowAnimation.value > 0)
            Container(
              width: 220 * _glowAnimation.value,
              height: 220 * _glowAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.4 * _glowAnimation.value),
                    blurRadius: 80,
                    spreadRadius: 30,
                  ),
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.3 * _glowAnimation.value),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),

          // Pulsing background circle with glass effect
          Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),

          // Logo with enhanced 3D scale effect
          Transform.scale(
            scale: _logoScaleAnimation.value,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.white.withOpacity(0.95)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 15),
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(22),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(65),
                child: Image.asset(
                  'assets/ecopilot_logo_white.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Highlight reflection for glass effect
          Positioned(
            top: 20 * _logoScaleAnimation.value,
            left: 20 * _logoScaleAnimation.value,
            child: Container(
              width: 60 * _logoScaleAnimation.value,
              height: 60 * _logoScaleAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.6),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3D Text effect with perspective
  Widget _build3DText() {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002)
        ..rotateX(_3dRotationXAnimation.value * 0.3),
      alignment: Alignment.center,
      child: Transform.translate(
        offset: Offset(0, _textSlideAnimation.value),
        child: Opacity(
          opacity: _textFadeAnimation.value,
          child: Column(
            children: [
              // 3D layered text
              Stack(
                children: [
                  // Shadow layers for depth
                  for (int i = 8; i > 0; i--)
                    Transform.translate(
                      offset: Offset(i * 0.5, i * 0.5),
                      child: Text(
                        'EcoPilot',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.05 * i),
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                  // Main text with gradient
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.white.withOpacity(0.9)],
                    ).createShader(bounds),
                    child: const Text(
                      'EcoPilot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Tagline with 3D card effect
              Opacity(
                opacity: _taglineFadeAnimation.value,
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(_3dRotationXAnimation.value * 0.2),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Your Smart Eco Companion',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3D Loading indicator
  Widget _build3DLoadingIndicator() {
    return Opacity(
      opacity: _taglineFadeAnimation.value,
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateX(_3dRotationXAnimation.value * 0.15),
        alignment: Alignment.center,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3.5,
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
        ),
      ),
    );
  }

  // 3D Background layers for parallax depth
  Widget _build3DBackgroundLayers() {
    return AnimatedBuilder(
      animation: _perspectiveController,
      child: Stack(
        children: [
          // Layer 1 - Farthest
          Positioned.fill(
            child: Transform.scale(
              scale: 1.1,
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(
                  painter: _CirclePatternPainter(
                    offset: _particleAnimation.value * 50,
                  ),
                ),
              ),
            ),
          ),
          // Layer 2 - Middle
          Positioned.fill(
            child: Transform.scale(
              scale: 1.05,
              child: Opacity(
                opacity: 0.15,
                child: CustomPaint(
                  painter: _CirclePatternPainter(
                    offset: _particleAnimation.value * 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      builder: (context, child) {
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, _perspectiveAnimation.value * 0.5)
            ..rotateX(_3dRotationXAnimation.value * 0.05),
          alignment: Alignment.center,
          child: child,
        );
      },
    );
  }

  // Floating particles in the background
  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return Stack(
          children: List.generate(15, (index) {
            final random = Random(index);
            final startX =
                random.nextDouble() * MediaQuery.of(context).size.width;
            final startY =
                random.nextDouble() * MediaQuery.of(context).size.height;
            final size = 4.0 + random.nextDouble() * 8;

            // Sine wave motion for organic movement
            final offsetX = sin(_particleAnimation.value * 2 * pi + index) * 30;
            final offsetY =
                -_particleAnimation.value *
                MediaQuery.of(context).size.height *
                0.3;

            return Positioned(
              left: startX + offsetX,
              top: startY + offsetY,
              child: Opacity(
                opacity:
                    0.3 +
                    (sin(_particleAnimation.value * 2 * pi + index) * 0.3),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// Custom painter for 3D background pattern
class _CirclePatternPainter extends CustomPainter {
  final double offset;

  _CirclePatternPainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final spacing = 100.0;

    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        final adjustedX = x + (offset % spacing);
        final adjustedY = y + (offset % spacing);

        canvas.drawCircle(
          Offset(adjustedX, adjustedY),
          20 + (offset % 20),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CirclePatternPainter oldDelegate) {
    return oldDelegate.offset != offset;
  }
}
