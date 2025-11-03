// lib/screens/auth/auth_landing_screen.dart

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '/screens/onboarding_screen.dart'; // To navigate back to onboarding
import 'login.dart';
import 'signup.dart';
import 'forgot_password.dart';

class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryGreen, // Main theme background
      body: Stack(
        children: [
          // Back Button to Onboarding Screen (Top Left)
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () {
                // Navigate back to the main Onboarding Screen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const OnboardingScreen(),
                  ),
                );
              },
            ),
          ),

          // Menu Button (Top Right, similar to the FireFit design)
          Positioned(
            top: 40,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 30),
              onPressed: () {
                // Placeholder for potential future menu/skip
              },
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Logo and Text (The "FireFit" section)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white, // White background for the logo
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Image.asset(
                      kLogoWhiteAsset,
                      height: 80,
                      width: 80,
                    ), // Your EcoPilot logo
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'ECOPILOT',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Scan Smart, Buy Green, Live Clean',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const Spacer(flex: 2),

                  // 1. Sign Up Button (Red/Orange style)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            kPrimaryYellow, // Using Yellow for contrast/attention
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 2. Login Button (White style)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: const BorderSide(color: Colors.white, width: 2),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Forgot Password (Optional, similar to FireFit design)
                  TextButton(
                    onPressed: () {
                      showForgotPasswordDialog(context);
                    },
                    child: const Text(
                      'Forgot your password?',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
