# 🔧 Settings Screen Dark Mode Fix Guide

## Problem

The `setting_screen.dart` file has syntax errors after attempting to add dark mode support. This guide provides a step-by-step fix.

## Solution

### Option 1: Manual Fix (Recommended)

Replace the dark mode switch section in `setting_screen.dart`:

**Location:** Around line 710 in the `_buildSettingsSection` for "App Preferences"

**Find this code:**
```dart
_buildSettingsSwitch(
  'Dark Mode',
  Icons.dark_mode_outlined,
  value: _darkMode,
  color: Colors.indigo,
  onChanged: (v) async {
    setState(() => _darkMode = v);
    await _setBoolPref('dark_mode', v);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dark mode preference saved. Restart app to apply.'),
      ),
    );
  },
),
```

**Replace with:**
```dart
_buildSettingsSwitch(
  'Dark Mode',
  Icons.dark_mode_outlined,
  value: _darkMode,
  color: Colors.indigo,
  onChanged: (v) async {
    setState(() => _darkMode = v);
    
    // Update theme provider for instant theme switch
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.setThemeMode(
      v ? ThemeMode.dark : ThemeMode.light,
    );
    
    // Also save to shared preferences for backward compatibility
    await _setBoolPref('dark_mode', v);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          v ? '🌙 Dark mode enabled' : '☀️ Light mode enabled',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: kPrimaryGreen,
      ),
    );
  },
),
```

### Step-by-Step Manual Fix:

1. **Add imports at the top of `setting_screen.dart`:**

```dart
import 'package:provider/provider.dart';
import '../../utils/theme_provider.dart';
```

2. **Add `didChangeDependencies` method to sync with theme provider:**

Add this after `initState()` in `_SettingScreenState`:

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // Sync dark mode state with theme provider
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  if (_darkMode != themeProvider.isDarkMode) {
    setState(() {
      _darkMode = themeProvider.isDarkMode;
    });
  }
}
```

3. **Update the dark mode switch** as shown above

4. **Test the implementation:**
   - Run the app
   - Go to Settings
   - Toggle Dark Mode
   - UI should change instantly without restart

---

### Option 2: Theme-Aware UI Updates (Optional Enhancement)

To make the Settings screen UI adapt to dark mode, update helper methods:

**Update `_buildSettingsSection`:**

```dart
Widget _buildSettingsSection({
  required String title,
  required IconData icon,
  required List<Widget> items,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ... existing code ...
      Container(
        decoration: BoxDecoration(
          color: theme.cardColor, // ← Theme-aware
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: items),
      ),
    ],
  );
}
```

**Update `build` method AppBar:**

```dart
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  
  return Scaffold(
    backgroundColor: theme.scaffoldBackgroundColor, // ← Theme-aware
    body: CustomScrollView(
      slivers: [
        SliverAppBar(
          // ... existing code ...
          backgroundColor: isDark ? theme.cardColor : kPrimaryGreen,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
            // ... rest of code
          ),
        ),
      ],
    ),
  );
}
```

---

## Quick Test

After making changes:

```bash
# Run the app
flutter run

# Or hot reload if already running
# Press 'r' in terminal or click hot reload button
```

**Expected behavior:**
1. Toggle dark mode in settings
2. Entire app UI changes instantly
3. No restart required
4. Preference saved (survives app restart)

---

## Verification Checklist

- [ ] Provider package added to pubspec.yaml
- [ ] Import statements added to setting_screen.dart
- [ ] didChangeDependencies method added
- [ ] Dark mode switch updated with ThemeProvider
- [ ] No compilation errors
- [ ] Dark mode toggles instantly
- [ ] Preference persists after app restart

---

## Rollback (If Needed)

If you encounter issues, you can revert the dark mode changes:

1. Remove provider imports
2. Remove didChangeDependencies override
3. Restore original dark mode switch handler
4. Run `flutter pub get`

---

**Status:** 🟡 Manual fix required  
**Estimated Time:** 10-15 minutes  
**Difficulty:** Easy
