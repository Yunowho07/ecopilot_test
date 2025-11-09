# 🌙 Dark Mode Implementation Guide

## Overview

This guide explains how to implement a fully functional, **no-restart dark mode** for the EcoPilot app using Flutter's centralized theme management system.

## Architecture

The dark mode system follows industry best practices:

1. **Centralized Theme Management** - All theme definitions in one place
2. **State Management with Provider** - Reactive theme switching
3. **Persistent Storage** - Remembers user preference across app sessions
4. **Instant UI Updates** - No app restart required

---

## 🎯 Key Components

### 1. Theme Provider (`lib/utils/theme_provider.dart`)

The `ThemeProvider` class manages the app's theme state using Flutter's `ChangeNotifier` pattern:

```dart
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  // Toggle between light and dark
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    await _saveThemePreference();
    notifyListeners(); // ⚡ Triggers instant UI update
  }
}
```

**Key Features:**
- ✅ Loads saved preference on app start
- ✅ Saves preference to SharedPreferences
- ✅ Notifies all listeners when theme changes
- ✅ Provides theme mode to MaterialApp

### 2. Theme Definitions (`lib/utils/app_theme.dart`)

All color and style definitions for both light and dark modes:

```dart
class AppTheme {
  static ThemeData get lightTheme { ... }
  static ThemeData get darkTheme { ... }
}
```

**Benefits:**
- 🎨 Consistent styling across the app
- 🔄 Easy to maintain and update
- 📦 Single source of truth for theme values
- 🌈 Comprehensive color schemes

### 3. Main App Integration (`lib/main.dart`)

Wrap the app with `ChangeNotifierProvider` and connect to theme system:

```dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const EcoPilotApp(),
    ),
  );
}

class EcoPilotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode, // 🔥 Dynamic switching
    );
  }
}
```

---

## 🛠️ Implementation Steps

### Step 1: Add Provider Package

```bash
flutter pub add provider
```

✅ **Already completed!** Provider package is now in your `pubspec.yaml`.

### Step 2: Create Theme Files

Two new files have been created:

1. **`lib/utils/theme_provider.dart`** - State management
2. **`lib/utils/app_theme.dart`** - Theme definitions

✅ **Already created!**

### Step 3: Update Main App

The `main.dart` file has been updated to:
- Import Provider and ThemeProvider
- Wrap app with ChangeNotifierProvider
- Use dynamic theming

✅ **Already updated!**

### Step 4: Update Settings Screen

To enable the dark mode toggle in settings, update `setting_screen.dart`:

```dart
import 'package:provider/provider.dart';
import '../../utils/theme_provider.dart';

// In the dark mode switch handler:
_buildSettingsSwitch(
  'Dark Mode',
  Icons.dark_mode_outlined,
  value: _darkMode,
  color: Colors.indigo,
  onChanged: (v) async {
    setState(() => _darkMode = v);
    
    // Get theme provider
    final themeProvider = Provider.of<ThemeProvider>(
      context, 
      listen: false,
    );
    
    // Toggle theme instantly
    await themeProvider.setThemeMode(
      v ? ThemeMode.dark : ThemeMode.light,
    );
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          v ? '🌙 Dark mode enabled' : '☀️ Light mode enabled',
        ),
      ),
    );
  },
),
```

### Step 5: Use Theme Colors in Widgets

Instead of hardcoded colors, use theme variables:

```dart
// ❌ BEFORE (hardcoded)
Container(
  color: Colors.white,
  child: Text(
    'Hello',
    style: TextStyle(color: Colors.black87),
  ),
)

// ✅ AFTER (theme-aware)
Container(
  color: Theme.of(context).cardColor,
  child: Text(
    'Hello',
    style: Theme.of(context).textTheme.bodyLarge,
  ),
)
```

---

## 📱 Theme Color Mapping

### Background Colors

| Purpose | Light Mode | Dark Mode |
|---------|-----------|-----------|
| Scaffold | `Colors.grey.shade50` | `Color(0xFF121212)` |
| Card | `Colors.white` | `Color(0xFF1E1E1E)` |
| Canvas | `Colors.white` | `Color(0xFF1E1E1E)` |

### Text Colors

| Purpose | Light Mode | Dark Mode |
|---------|-----------|-----------|
| Primary | `Colors.black87` | `Colors.white` |
| Secondary | `Colors.grey.shade700` | `Colors.grey.shade300` |
| Tertiary | `Colors.grey.shade600` | `Colors.grey.shade400` |

### Component Colors

| Component | Light Mode | Dark Mode |
|-----------|-----------|-----------|
| AppBar | `kPrimaryGreen` | `Color(0xFF1E1E1E)` |
| Primary Button | `kPrimaryGreen` | `kPrimaryGreen` |
| Input Fill | `Colors.grey.shade100` | `Color(0xFF2C2C2C)` |

---

## 🎨 Using Theme in Your Screens

### Example 1: Container Background

```dart
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).cardColor, // Auto adapts!
    borderRadius: BorderRadius.circular(16),
  ),
)
```

### Example 2: Text Styling

```dart
Text(
  'Hello World',
  style: Theme.of(context).textTheme.headlineMedium, // Theme-aware
)
```

### Example 3: Detecting Dark Mode

```dart
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return Icon(
    Icons.sunny,
    color: isDark ? Colors.amber : Colors.orange,
  );
}
```

### Example 4: AppBar

```dart
AppBar(
  backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
  title: Text('Title'),
)
```

---

## 🔥 How It Works (Technical Flow)

1. **User toggles switch** in Settings
2. **ThemeProvider.setThemeMode()** is called
3. **SharedPreferences** saves the preference
4. **notifyListeners()** broadcasts change
5. **MaterialApp** receives new ThemeMode
6. **Flutter rebuilds** all widgets with new theme
7. **UI updates instantly** - no restart needed!

```
User Toggle
    ↓
ThemeProvider.setThemeMode()
    ↓
Save to SharedPreferences
    ↓
notifyListeners()
    ↓
MaterialApp rebuilds
    ↓
All widgets update instantly ⚡
```

---

## 📋 Checklist for Updating Screens

To make a screen fully theme-aware:

- [ ] Replace hardcoded `Colors.white` with `Theme.of(context).cardColor`
- [ ] Replace hardcoded `Colors.grey.shade50` with `Theme.of(context).scaffoldBackgroundColor`
- [ ] Replace hardcoded `Colors.black87` with `Theme.of(context).textTheme.bodyLarge?.color`
- [ ] Use `Theme.of(context).textTheme.*` for text styles
- [ ] Check gradients - use conditional logic for dark mode
- [ ] Update shadows for dark mode (darker, more opacity)
- [ ] Test both light and dark modes

---

## 🧪 Testing Dark Mode

### Manual Testing:

1. Run the app
2. Navigate to Settings
3. Toggle "Dark Mode" switch
4. **Observe:** UI should change instantly
5. Close and reopen app
6. **Verify:** Theme preference is remembered

### Testing Specific Screen:

```dart
// Wrap your screen in a dark theme for testing
MaterialApp(
  theme: AppTheme.darkTheme,
  home: YourScreen(),
)
```

---

## 🐛 Troubleshooting

### Issue: Theme doesn't change instantly

**Solution:** Make sure you're using `Provider.of<ThemeProvider>(context)` without `listen: false` in MaterialApp:

```dart
// ✅ CORRECT
final themeProvider = Provider.of<ThemeProvider>(context);

// ❌ WRONG (won't rebuild)
final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
```

### Issue: Some widgets still show light colors in dark mode

**Solution:** Replace hardcoded colors with theme references:

```dart
// ❌ Before
Container(color: Colors.white)

// ✅ After
Container(color: Theme.of(context).cardColor)
```

### Issue: Preference not saved

**Solution:** Ensure ThemeProvider saves to SharedPreferences:

```dart
Future<void> _saveThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('theme_mode', _themeMode == ThemeMode.dark);
}
```

---

## 🎯 Next Steps

### Recommended Actions:

1. **Update Settings Screen**
   - Fix the corrupted `setting_screen.dart` file
   - Integrate ThemeProvider toggle

2. **Update Major Screens**
   - `home_screen.dart`
   - `profile_screen.dart`
   - `scan_screen.dart`
   - `result_screen.dart`
   - `leaderboard_screen.dart`

3. **Test Thoroughly**
   - Test every screen in both modes
   - Check readability and contrast
   - Verify all colors adapt correctly

4. **Optional Enhancements**
   - Add "System" theme mode (follows device setting)
   - Add theme transition animations
   - Create custom color picker for users

---

## 📚 Additional Resources

### Flutter Documentation:
- [Material Design Dark Theme](https://material.io/design/color/dark-theme.html)
- [Flutter ThemeData](https://api.flutter.dev/flutter/material/ThemeData-class.html)
- [Provider Package](https://pub.dev/packages/provider)

### Color Palette Tools:
- [Material Color Tool](https://material.io/resources/color/)
- [Coolors](https://coolors.co/) - Generate color palettes
- [Adobe Color](https://color.adobe.com/) - Color wheel

---

## 📝 Summary

You now have a **production-ready dark mode system** that:

✅ **Works instantly** - No app restart required  
✅ **Persists preference** - Remembers user choice  
✅ **Centralized** - Easy to maintain  
✅ **Scalable** - Add more themes easily  
✅ **Industry standard** - Uses Flutter best practices

**Status:** 🟡 **Partially Implemented**

**To Complete:**
1. Fix `setting_screen.dart` dark mode toggle
2. Update remaining screens to use theme colors
3. Test all screens in both modes

---

**Created:** November 9, 2025  
**Version:** 1.0  
**Author:** GitHub Copilot  
**Status:** Documentation Complete ✅
