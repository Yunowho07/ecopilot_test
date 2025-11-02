// lib/home/setting_screen.dart

import 'package:ecopilot_test/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import 'profile_screen.dart';
import 'package:ecopilot_test/screens/profile_screen.dart'
    as ps
    show ChangePasswordScreen;

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _darkMode = false;
  bool _locationServices = true;
  bool _dailyTips = true;
  String _language = 'English (US)';
  String _defaultCenter = 'Tanjung Malim Center';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _locationServices = prefs.getBool('location_services') ?? true;
      _dailyTips = prefs.getBool('daily_tips') ?? true;
      _language = prefs.getString('language') ?? 'English (US)';
      _defaultCenter =
          prefs.getString('default_center') ?? 'Tanjung Malim Center';
    });
  }

  Future<void> _setBoolPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _setStringPref(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
        child: Column(
          children: [
            _buildSettingsSection(
              title: 'Account',
              items: [
                _buildSettingsItem(
                  Icons.person,
                  'Edit Profile',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
                _buildSettingsItem(
                  Icons.lock,
                  'Change Password',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ps.ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            _buildSettingsSection(
              title: 'App Preferences',
              items: [
                _buildSettingsSwitch(
                  'Dark Mode',
                  Icons.dark_mode,
                  value: _darkMode,
                  onChanged: (v) async {
                    setState(() => _darkMode = v);
                    await _setBoolPref('dark_mode', v);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Dark mode preference saved. Restart app to apply.',
                        ),
                      ),
                    );
                  },
                ),
                _buildSettingsSwitch(
                  'Location Services',
                  Icons.location_on,
                  value: _locationServices,
                  onChanged: (v) async {
                    setState(() => _locationServices = v);
                    await _setBoolPref('location_services', v);
                  },
                  initialValue: true,
                ),
                _buildSettingsSwitch(
                  'Receive Daily Tips',
                  Icons.lightbulb_outline,
                  value: _dailyTips,
                  onChanged: (v) async {
                    setState(() => _dailyTips = v);
                    await _setBoolPref('daily_tips', v);
                  },
                  initialValue: true,
                ),
              ],
            ),
            _buildSettingsSection(
              title: 'Disposal & Scanning',
              items: [
                _buildSettingsItem(
                  Icons.map,
                  'Default Recycling Center',
                  subtitle: _defaultCenter,
                  onTap: _chooseDefaultCenter,
                ),
                _buildSettingsItem(
                  Icons.translate,
                  'Set Language',
                  subtitle: _language,
                  onTap: _chooseLanguage,
                ),
              ],
            ),
            _buildSettingsSection(
              title: 'Legal & Info',
              items: [
                _buildSettingsItem(
                  Icons.policy,
                  'Privacy Policy',
                  onTap: () => _openInfo('Privacy Policy', _privacyText),
                ),
                _buildSettingsItem(
                  Icons.description,
                  'Terms of Service',
                  onTap: () => _openInfo('Terms of Service', _termsText),
                ),
                _buildSettingsItem(
                  Icons.info,
                  'About EcoPilot',
                  subtitle: 'Version 1.0.0',
                  onTap: () => _openInfo('About EcoPilot', _aboutText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryGreen,
              ),
            ),
          ),
          ...items,
          const Divider(),
        ],
      ),
    );
  }

  // Settings Item with navigation/action
  Widget _buildSettingsItem(
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.grey))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  // Settings Item with a switch
  Widget _buildSettingsSwitch(
    String title,
    IconData icon, {
    bool value = false,
    bool initialValue = false,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: kPrimaryGreen,
      ),
    );
  }

  Future<void> _chooseLanguage() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Choose language'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop('English (US)'),
            child: const Text('English (US)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop('Bahasa Melayu'),
            child: const Text('Bahasa Melayu'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop('中文'),
            child: const Text('中文'),
          ),
        ],
      ),
    );

    if (selected != null) {
      if (!mounted) return;
      setState(() => _language = selected);
      await _setStringPref('language', selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Language saved. Restart app to apply.')),
      );
    }
  }

  Future<void> _chooseDefaultCenter() async {
    final centers = [
      'Tanjung Malim Center',
      'Kuala Lumpur Center',
      'Penang Center',
    ];
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Default Recycling Center'),
        children: centers
            .map(
              (c) => SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(c),
                child: Text(c),
              ),
            )
            .toList(),
      ),
    );

    if (selected != null) {
      if (!mounted) return;
      setState(() => _defaultCenter = selected);
      await _setStringPref('default_center', selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default recycling center saved.')),
      );
    }
  }

  void _openInfo(String title, String content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _InfoScreen(title: title, content: content),
      ),
    );
  }

  static const String _privacyText =
      'This is the privacy policy placeholder. Replace with real content.';
  static const String _termsText =
      'These are the terms of service placeholder. Replace with real content.';
  static const String _aboutText =
      'EcoPilot\nVersion 1.0.0\n\nEcoPilot helps you scan and choose greener products.';
}

class _InfoScreen extends StatelessWidget {
  final String title;
  final String content;
  const _InfoScreen({required this.title, required this.content, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: kPrimaryGreen),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(content, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
