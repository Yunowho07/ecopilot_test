import 'package:flutter/material.dart';
import 'firebase_service.dart';

// Use a placeholder for kPrimaryGreen here, replace with your actual import
// final Color kPrimaryGreen = Color(0xFF1db954); // Spotify Green

/// Shows a themed Forgot Password dialog. Use this helper instead of
/// pushing a full-screen route when you want a lightweight modal UX.
Future<void> showForgotPasswordDialog(BuildContext context) {
  // Define the theme color based on the context's primary color or a constant.
  // We'll use the constant color defined in the prompt for theme consistency.
  final Color primaryGreen = const Color(0xFF1db954);

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => Theme(
      // Apply a local theme override to ensure green accents
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryGreen,
              secondary: primaryGreen,
            ),
        // Use the primary green for Elevated Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: _ForgotPasswordDialogContent(),
          ),
        ),
      ),
    ),
  );
}

class _ForgotPasswordDialogContent extends StatefulWidget {
  @override
  State<_ForgotPasswordDialogContent> createState() =>
      _ForgotPasswordDialogContentState();
}

class _ForgotPasswordDialogContentState
    extends State<_ForgotPasswordDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseService().sendPasswordReset(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Check your inbox.'),
          ),
        );
        Navigator.of(context).pop(); // close dialog
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset email: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the primary color defined in showForgotPasswordDialog's Theme
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Themed Header ---
        Row(
          children: [
            Icon(Icons.lock_reset, color: primaryColor, size: 28),
            const SizedBox(width: 10),
            Text(
              'Reset Password',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const Text(
          'Enter the email associated with your EcoPilot account. We will send a password reset link to your inbox.',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 20),

        // --- Themed Form Field ---
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || v.isEmpty || !v.contains('@')
                ? 'Enter a valid email'
                : null,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'user@example.com',
              // Green theme for prefix icon and focused border
              prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor, width: 2), // Highlighted border
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 25),

        // --- Action Buttons ---
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendReset,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white, // Ensures spinner is visible on green background
                      ),
                    )
                  : const Text('Send Reset Link'),
            ),
          ],
        ),
      ],
    );
  }
}