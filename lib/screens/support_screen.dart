// lib/home/support_screen.dart

import 'package:ecopilot_test/screens/home_screen.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

const Color kPrimaryGreen = Color(0xFF1db954);

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        centerTitle: true,
        title: const Text('Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              ),
                            );
                          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need Help?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Our team is here to help you on your eco-journey!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            _buildSupportOption(
              icon: Icons.forum,
              title: 'Contact Us',
              subtitle: 'Send us a message or report a bug.',
              onTap: () {
                // TODO: Navigate to a contact form
              },
            ),
            _buildSupportOption(
              icon: Icons.question_answer,
              title: 'FAQ',
              subtitle: 'Find answers to common questions about scanning and scoring.',
              onTap: () {
                // TODO: Navigate to FAQ screen
              },
            ),
            _buildSupportOption(
              icon: Icons.thumb_up,
              title: 'Suggest a Feature',
              subtitle: 'Help us improve EcoPilot for the community.',
              onTap: () {
                // TODO: Navigate to feature request form
              },
            ),
            _buildSupportOption(
              icon: Icons.star,
              title: 'Rate EcoPilot',
              subtitle: 'Love the app? Leave us a review!',
              onTap: () {
                // TODO: Launch app store rating link
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: kPrimaryGreen, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}