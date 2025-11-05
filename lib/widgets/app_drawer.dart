import 'package:ecopilot_test/screens/disposal_guidance_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecopilot_test/auth/firebase_service.dart';
import 'package:ecopilot_test/auth/landing.dart';
import 'package:ecopilot_test/screens/profile_screen.dart' as profile_screen;
import 'package:ecopilot_test/screens/alternative_screen.dart'as alternative_screen;
import 'package:ecopilot_test/screens/disposal_guidance_screen.dart' as dispose_screen;
// Note: Home & Scan screens are not directly referenced here anymore
import 'package:ecopilot_test/screens/notification_screen.dart';
import 'package:ecopilot_test/screens/setting_screen.dart';
import 'package:ecopilot_test/screens/support_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      // Use FirebaseService to ensure provider sessions are cleared as well
      await FirebaseService().signOut();

      // After sign out, navigate to the Auth landing screen and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthLandingScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String userName = user?.displayName ?? (user?.email ?? 'User');
    // Define the primary brand color for the dialog accent
    final Color primaryGreen = const Color(0xFF1DB954);

    return Drawer(
      width: 320,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with avatar and name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.userChanges(),
                    builder: (context, snapshot) {
                      final currentUser =
                          snapshot.data ?? FirebaseAuth.instance.currentUser;
                      final photoUrl = currentUser?.photoURL;
                      return Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFC300),
                            width: 6,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          backgroundImage: photoUrl != null
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 36,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Become a Supporter button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Become a Supporter',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                  // TODO: Implement supporter functionality
                },
                icon: const Icon(Icons.favorite, color: Colors.white),
                label: const Text(
                  'Become a Supporter',
                  style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white,),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(
                    context,
                    icon: Icons.home,
                    label: 'Home',
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.person,
                    label: 'Profile',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const profile_screen.ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.shopping_cart,
                    label: 'Alternative',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const alternative_screen.AlternativeScreen(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.delete_sweep,
                    label: 'Dispose',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const DisposalGuidanceScreen(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.notifications_none,
                    label: 'Notification',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.settings,
                    label: 'Setting',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingScreen(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    context,
                    icon: Icons.support_agent,
                    label: 'Support',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SupportScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Logout button styled red
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          // --- START: Themed Logout Dialog ---
                          final shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              // 🟢 Themed Title
                              title: Row(
                                children: [
                                  Icon(Icons.logout, color: primaryGreen),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Confirm Logout',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              content: const Text(
                                'Are you sure you want to log out of EcoPilot?',
                                style: TextStyle(color: Colors.black87),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                                // 🔴 Themed Logout Button (Red for security, but follows button style)
                                ElevatedButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600, 
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Log Out',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                          // --- END: Themed Logout Dialog ---

                          if (shouldLogout == true) {
                            await _handleSignOut(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),

            // Bottom green share bar
            Container(
              color: primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Icon(Icons.group, color: primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Share Ecopilot with your friends',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.grey.shade700),
      ),
      title: Text(label, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
    );
  }
}