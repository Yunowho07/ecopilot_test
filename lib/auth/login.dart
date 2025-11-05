import 'package:ecopilot_test/auth/landing.dart';
import 'package:ecopilot_test/auth/signup.dart';
import 'package:ecopilot_test/utils/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'firebase_service.dart';
import '../screens/home_screen.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final kPrimaryGreen = const Color(0xFF1db954);
  final kDarkGreen = const Color(0xFF205D1C);

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = await FirebaseService().signInWithGoogle();
      if (user != null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google sign-in cancelled')),
          );
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Google sign-in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = await FirebaseService().signInWithFacebook();
      if (user != null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Facebook sign-in cancelled')),
          );
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Facebook sign-in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Facebook sign-in failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = await FirebaseService().signInWithApple();
      if (user != null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Apple sign-in cancelled')),
          );
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Apple sign-in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple sign-in failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = await FirebaseService().signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (user != null) {
          // Navigate to the home screen after successful sign in
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }
      } on Exception catch (e) {
        // Surface FirebaseAuthException or other exceptions with details
        String message = 'Login failed';
        try {
          // FirebaseAuthException has a message property
          // We avoid importing firebase_auth here to keep UI file simple,
          // so attempt to read `message` via map-like access if available.
          message = (e as dynamic).message ?? e.toString();
        } catch (_) {
          message = e.toString();
        }

        // Log to console for debugging
        // (Check your terminal or browser console when running on web)
        // ignore: avoid_print
        print('Login error: $e');

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Login Failed: $message')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kPrimaryGreen.withOpacity(0.1), Colors.white],
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30.0,
                  vertical: 20.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LOGIN',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Enter your login details to access your account',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 30),

                      // Email Field
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v!.isEmpty || !v.contains('@')
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        isPassword: true,
                        validator: (v) =>
                            v!.isEmpty ? 'Please enter your password' : null,
                      ),
                      const SizedBox(height: 10),

                      // Remember Me and Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    _rememberMe = newValue!;
                                  });
                                },
                                activeColor: kPrimaryGreen,
                              ),
                              const Text(
                                'Remember',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              showForgotPasswordDialog(context);
                            },
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: kPrimaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Sign In Button
                      _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: kPrimaryGreen,
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _handleSignIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                ),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                      const SizedBox(height: 20),

                      // Social Login Separator
                      Center(
                        child: Text(
                          'or login with',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Social Login Buttons
                      _buildSocialButton(
                        'SIGN IN WITH GOOGLE',
                        'assets/google.png',
                        kPrimaryGreen,
                        onPressed: _handleGoogleSignIn,
                      ),
                      const SizedBox(height: 15),
                      _buildSocialButton(
                        'SIGN IN WITH FACEBOOK',
                        'assets/facebook.png',
                        kPrimaryGreen,
                        onPressed: _handleFacebookSignIn,
                      ),
                      const SizedBox(height: 15),
                      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS))
                        // Use the native Apple sign-in button on supported Apple platforms
                        SignInWithAppleButton(
                          onPressed: _handleAppleSignIn,
                          style: SignInWithAppleButtonStyle.white,
                        )
                      else
                        // Fallback button for other platforms (shows Apple asset)
                        _buildSocialButton(
                          'SIGN IN WITH APPLE',
                          'assets/apple.png',
                          kPrimaryGreen,
                          onPressed: _handleAppleSignIn,
                        ),
                      const SizedBox(height: 30),

                      // Terms and Services
                      const Center(
                        child: Text(
                          'By clicking Sign In you agree with our\nServices and Terms',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.25,
      width: size.width,
      decoration: BoxDecoration(color: kPrimaryGreen),
      child: Stack(
        children: [
          // Background circles (for aesthetic matching the image)
          Positioned(
            top: -size.width * 0.1,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.5,
              height: size.width * 0.5,
              decoration: BoxDecoration(
                color: colorWithOpacity(kDarkGreen, 0.8),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Positioned(
          //   bottom: size.height * 0.0,
          //   right: size.width * 0.50,
          //   child: Container(
          //     width: size.width * 0.2,
          //     height: size.width * 0.2,
          //     decoration: BoxDecoration(
          //       color: colorWithOpacity(
          //         const Color(0xFF9CCC65),
          //         0.8,
          //       ), // Lighter Green Accent
          //       shape: BoxShape.circle,
          //     ),
          //   ),
          // ),

          // Back Button (Top Left) - Placeholder as Login is usually the first screen
          Positioned(
            top: 35,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () {
                // Navigate back to the main Onboarding Screen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const AuthLandingScreen(),
                  ),
                );
              },
            ),
          ),

          // Sign Up Button (Top Right)
          Positioned(
            top: 35,
            right: 10,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const SignUpScreen()),
              ),
              child: const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: isPassword ? 'Enter your password' : 'example@gmail.com',
            prefixIcon: Icon(
              isPassword ? Icons.lock_outline : Icons.email_outlined,
              color: Colors.grey[700],
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    String text,
    String assetPath,
    Color borderColor, {
    VoidCallback? onPressed,
  }) {
    // Note: Since we cannot include external assets (images), this uses Icons as a placeholder.
    // In your project, replace the Icon with an Image.asset('path/to/icon.png').
    return OutlinedButton(
      onPressed:
          onPressed ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$text not implemented yet!')),
            );
          },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Use project asset icon if available, otherwise fall back to a generic avatar icon
          Image.asset(
            assetPath,
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.account_circle, size: 24),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
